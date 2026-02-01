#!/usr/bin/perl
# vim: ts=2 sw=2 ft=perl
# Download Gmail messages via IMAP and store in PostgreSQL
use strict;
use warnings;
use autodie;
use Mail::IMAPClient;
use IO::Socket::SSL;
use Email::MIME;
use DBI;
use Getopt::Long;
use POSIX qw(strftime);
use Digest::MD5 qw(md5_hex);

# Configuration
my $gmail_user = '';
my $gmail_pass = '';
my $imap_server = 'imap.gmail.com';
my $imap_port = 993;

my $dbname = 'messages';
my $dbuser = $ENV{PGUSER} || $ENV{USER};
my $dbpass = $ENV{PGPASSWORD} || '';
my $dbhost = $ENV{PGHOST} || 'localhost';
my $dbport = $ENV{PGPORT} || 5432;

my $folder = 'INBOX';
my $limit = 0;  # 0 = all messages
my $since_days = 0;  # 0 = all time

GetOptions(
  'gmail-user=s' => \$gmail_user,
  'gmail-pass=s' => \$gmail_pass,
  'folder=s' => \$folder,
  'limit=i' => \$limit,
  'since-days=i' => \$since_days,
  'dbname=s' => \$dbname,
  'dbuser=s' => \$dbuser,
  'dbpass=s' => \$dbpass,
  'dbhost=s' => \$dbhost,
  'dbport=i' => \$dbport,
) or die "Usage: $0 --gmail-user=USER --gmail-pass=PASS [options]\n";

die "Gmail username required (--gmail-user)\n" unless $gmail_user;
die "Gmail password required (--gmail-pass)\n" unless $gmail_pass;

# My email addresses (add your addresses here)
my %self_addrs = map { lc($_) => 1 } ($gmail_user);

sub norm_email {
  my ($addr) = @_;
  return undef unless defined $addr && length $addr;
  $addr = lc($addr);
  # Extract email from "Name <email>" format
  if ($addr =~ /<([^>]+)>/) {
    $addr = $1;
  }
  $addr =~ s/^\s+|\s+$//g;  # trim whitespace
  return $addr;
}

sub extract_addresses {
  my ($header_value) = @_;
  return () unless defined $header_value;
  
  my @addrs;
  # Simple email extraction (handles most common formats)
  while ($header_value =~ /([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/g) {
    push @addrs, norm_email($1);
  }
  return @addrs;
}

print "Connecting to Gmail IMAP server...\n";

# Create SSL socket
my $socket = IO::Socket::SSL->new(
  PeerAddr => $imap_server,
  PeerPort => $imap_port,
  SSL_verify_mode => SSL_VERIFY_NONE,
) or die "Cannot connect to $imap_server:$imap_port: $!\n";

# Create IMAP client
my $imap = Mail::IMAPClient->new(
  Socket => $socket,
  User => $gmail_user,
  Password => $gmail_pass,
  Uid => 1,  # Use UIDs instead of sequence numbers
) or die "Cannot create IMAP client: $@\n";

$imap->State(Mail::IMAPClient::Connected);
$imap->login or die "Login failed: ", $imap->LastError, "\n";

print "Connected and authenticated.\n";

# Select folder
$imap->select($folder) or die "Cannot select folder $folder: ", $imap->LastError, "\n";
print "Selected folder: $folder\n";

# Build search criteria
my @search_criteria = ('ALL');
if ($since_days > 0) {
  my $since_date = strftime("%d-%b-%Y", localtime(time - $since_days * 86400));
  @search_criteria = ('SINCE', $since_date);
}

# Search for messages
my @msgs = $imap->search(@search_criteria);
unless (@msgs) {
  print "No messages found.\n";
  $imap->logout;
  exit 0;
}

print "Found ", scalar(@msgs), " messages.\n";

# Limit number of messages if requested
if ($limit > 0 && @msgs > $limit) {
  @msgs = @msgs[-$limit..-1];  # Get last N messages
  print "Processing last $limit messages.\n";
}

# Connect to database
my $dsn = "dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport";
my $dbh = DBI->connect($dsn, $dbuser, $dbpass, {
  AutoCommit => 0,
  RaiseError => 1,
  PrintError => 0,
}) or die "Cannot connect to database: $DBI::errstr\n";

print "Connected to database: $dbname\n";

# Prepare statements
my $insert_msg = $dbh->prepare(q{
  INSERT INTO messages (msgid, their_addr, my_addr, direction, body, message_timestamp)
  VALUES (?, ?, ?, ?, ?, to_timestamp(?))
  ON CONFLICT (msgid) DO NOTHING
});

my $insert_addr = $dbh->prepare(q{
  INSERT INTO address (address, person_id)
  VALUES (?, NULL)
  ON CONFLICT (address) DO NOTHING
});

my $msg_count = 0;
my $addr_count = 0;

# Process each message
for my $uid (@msgs) {
  eval {
    # Fetch message
    my $raw = $imap->message_string($uid);
    unless ($raw) {
      warn "Cannot fetch message UID $uid: ", $imap->LastError, "\n";
      next;
    }
    
    # Parse email
    my $email = Email::MIME->new($raw);
    
    # Extract headers
    my $from = $email->header('From') || '';
    my $to = $email->header('To') || '';
    my $cc = $email->header('Cc') || '';
    my $date_str = $email->header('Date') || '';
    my $subject = $email->header('Subject') || '';
    my $message_id = $email->header('Message-ID') || '';
    
    # Parse date
    my $epoch = 0;
    if ($date_str) {
      # Simple date parsing (could be improved with Date::Parse)
      if ($date_str =~ /(\d{1,2})\s+(\w+)\s+(\d{4})\s+(\d{1,2}):(\d{2}):(\d{2})/) {
        my %months = (
          Jan => 0, Feb => 1, Mar => 2, Apr => 3, May => 4, Jun => 5,
          Jul => 6, Aug => 7, Sep => 8, Oct => 9, Nov => 10, Dec => 11
        );
        my ($day, $mon, $year, $hour, $min, $sec) = ($1, $2, $3, $4, $5, $6);
        if (exists $months{$mon}) {
          use Time::Local;
          $epoch = eval { timegm($sec, $min, $hour, $day, $months{$mon}, $year - 1900) };
          $epoch ||= time;  # fallback to current time
        }
      }
    }
    $epoch ||= time;  # fallback to current time if parsing fails
    
    # Extract body
    my $body = '';
    if ($email->parts > 1) {
      # Multipart message
      for my $part ($email->parts) {
        my $content_type = $part->content_type || '';
        if ($content_type =~ /text\/plain/i) {
          $body .= $part->body_str;
          last;  # Use first text/plain part
        }
      }
      # Fallback to HTML if no plain text
      if (!$body) {
        for my $part ($email->parts) {
          my $content_type = $part->content_type || '';
          if ($content_type =~ /text\/html/i) {
            $body .= $part->body_str;
            last;
          }
        }
      }
    } else {
      # Single part message
      $body = $email->body_str;
    }
    
    # Add subject to body
    if ($subject) {
      $body = "Subject: $subject\n\n$body";
    }
    
    # Extract all addresses
    my @from_addrs = extract_addresses($from);
    my @to_addrs = extract_addresses($to);
    my @cc_addrs = extract_addresses($cc);
    
    # Determine direction and correspondent
    my $my_addr = undef;
    my $their_addr = undef;
    my $direction = undef;
    
    # Check if I'm the sender
    my $i_sent = 0;
    for my $addr (@from_addrs) {
      if ($self_addrs{$addr}) {
        $my_addr = $addr;
        $i_sent = 1;
        last;
      }
    }
    
    if ($i_sent) {
      # I sent this message
      $direction = 's';
      # Find first recipient who is not me
      for my $addr (@to_addrs, @cc_addrs) {
        unless ($self_addrs{$addr}) {
          $their_addr = $addr;
          last;
        }
      }
    } else {
      # I received this message
      $direction = 'r';
      # Sender is the correspondent
      $their_addr = $from_addrs[0] if @from_addrs;
      # Find my address in recipients
      for my $addr (@to_addrs, @cc_addrs) {
        if ($self_addrs{$addr}) {
          $my_addr = $addr;
          last;
        }
      }
    }
    
    # Skip if we can't determine key fields
    unless (defined $my_addr && defined $their_addr && defined $direction) {
      warn "Skipping message UID $uid: cannot determine sender/recipient\n";
      next;
    }
    
    # Generate message ID: use Message-ID header if available, otherwise hash
    my $msgid;
    if ($message_id && $message_id =~ /<([^>]+)>/) {
      $msgid = 'email:' . $1;  # Extract from angle brackets
    } elsif ($message_id) {
      $msgid = 'email:' . $message_id;
    } else {
      # Fallback: generate hash from normalized/processed fields
      my $hash_input = join('|', $their_addr, $my_addr, $epoch, substr($body, 0, 100));
      $msgid = 'email:hash:' . md5_hex($hash_input);
    }
    
    # Insert address into address table
    eval {
      $insert_addr->execute($their_addr);
      $addr_count++;
    };
    # Ignore duplicate key errors
    
    # Insert message
    eval {
      $insert_msg->execute($msgid, $their_addr, $my_addr, $direction, $body, $epoch);
      $msg_count++;
    };
    if ($@) {
      warn "Failed to insert message UID $uid: $@\n" unless $@ =~ /duplicate key/;
    }
    
    # Progress indicator
    if ($msg_count % 100 == 0) {
      print "Processed $msg_count messages...\n";
    }
  };
  if ($@) {
    warn "Error processing message UID $uid: $@\n";
  }
}

$dbh->commit;
$dbh->disconnect;

$imap->logout;

print "\nImport complete:\n";
print "  Messages inserted: $msg_count\n";
print "  Addresses added: $addr_count\n";
