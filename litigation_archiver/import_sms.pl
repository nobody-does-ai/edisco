#!/usr/bin/perl
# vim: ts=2 sw=2 ft=perl
# Import SMS/MMS messages into PostgreSQL
use strict;
use warnings;
use autodie;
use JSON::PP;
use DBI;
use Getopt::Long;
use Digest::MD5 qw(md5_hex);

# Configuration
my $dbname = 'messages';
my $dbuser = $ENV{PGUSER} || $ENV{USER};
my $dbpass = $ENV{PGPASSWORD} || '';
my $dbhost = $ENV{PGHOST} || 'localhost';
my $dbport = $ENV{PGPORT} || 5432;

GetOptions(
  'dbname=s' => \$dbname,
  'dbuser=s' => \$dbuser,
  'dbpass=s' => \$dbpass,
  'dbhost=s' => \$dbhost,
  'dbport=i' => \$dbport,
) or die "Usage: $0 [--dbname=...] [--dbuser=...] [--dbpass=...] [--dbhost=...] [--dbport=...] <sms.json> [mms.json ...]\n";

die "No input files specified\n" unless @ARGV;

# My phone numbers (normalized 10-digit)
my %self_lines = map { $_ => 1 } qw(6037573283 6034000820);

sub norm_phone {
  my ($n) = @_;
  return undef unless defined $n && length $n;
  $n =~ s/\D//g;                  # strip non-digits
  $n =~ s/^1(\d{10})$/$1/;        # strip leading 1 (NANP)
  return $n;
}

sub norm_epoch {
  my ($raw) = @_;
  return undef unless defined $raw && $raw =~ /^\d+$/;
  return int($raw / 1000) if $raw > 2_000_000_000;  # ms → s
  return $raw;
}

sub direction_for_sms_type {
  my ($t) = @_;
  return undef unless defined $t;
  return 'r' if $t == 1;              # inbox = received
  return 's' if $t == 2 || $t == 4;   # sent/outbox = sent
  return undef;  # skip system messages
}

sub direction_for_mms_box {
  my ($b) = @_;
  return undef unless defined $b;
  return 'r' if $b == 1;              # inbox = received
  return 's' if $b == 2 || $b == 4;   # sent/outbox = sent
  return undef;  # skip system messages
}

sub as_arrayref {
  my ($v) = @_;
  return [] unless defined $v;
  return $v if ref $v eq 'ARRAY';
  return [$v];
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

my @sms_files = grep { /sms/i } @ARGV;
my @mms_files = grep { /mms/i } @ARGV;

my $msg_count = 0;
my $addr_count = 0;

# Process SMS files
for my $file (@sms_files) {
  print "Processing SMS file: $file\n";
  
  open my $fh, '<:encoding(UTF-8)', $file;
  my $json_text = do { local $/; <$fh> };
  close $fh;
  
  my $rows = decode_json($json_text);
  
  for my $m (@$rows) {
    my $epoch = norm_epoch($m->{date});
    next unless defined $epoch;
    
    # Figure out my number
    my $self_norm = norm_phone($m->{self_phone});
    my $my_addr = (defined $self_norm && $self_lines{$self_norm})
                  ? $self_norm
                  : undef;
    
    # Collect candidate peers (everyone except me)
    my @candidates = @{ as_arrayref($m->{recipients}) };
    @candidates = ($m->{address}) unless @candidates;
    
    my @peers;
    for my $a (@candidates) {
      next unless defined $a;
      my $n = norm_phone($a);
      # Strip me out
      next if defined $n && $self_lines{$n};
      push @peers, $a;
    }
    
    next unless @peers;  # Skip if no peer found
    next unless defined $my_addr;  # Skip if we can't identify our number
    
    my $their_addr = $peers[0];  # Primary correspondent
    my $dir = direction_for_sms_type($m->{type});
    next unless defined $dir;  # Skip system messages
    
    my $body = $m->{body} // '';
    
    # Generate unique message ID from hash of normalized/processed fields
    my $hash_input = join('|', $their_addr, $my_addr, $epoch, substr($body, 0, 100));
    my $msgid = 'sms:' . md5_hex($hash_input);
    
    # Insert address into address table
    eval {
      $insert_addr->execute($their_addr);
      $addr_count++;
    };
    # Ignore duplicate key errors
    
    # Insert message
    eval {
      $insert_msg->execute($msgid, $their_addr, $my_addr, $dir, $body, $epoch);
      $msg_count++;
    };
    if ($@) {
      warn "Failed to insert SMS message: $@\n" unless $@ =~ /duplicate key/;
    }
  }
}

# Process MMS files
for my $file (@mms_files) {
  print "Processing MMS file: $file\n";
  
  open my $fh, '<:encoding(UTF-8)', $file;
  my $json_text = do { local $/; <$fh> };
  close $fh;
  
  my $rows = decode_json($json_text);
  
  for my $m (@$rows) {
    my $epoch = norm_epoch($m->{date});
    next unless defined $epoch;
    
    # Find me: prefer explicit self_phone; else infer from mms_addresses
    my $self_norm = norm_phone($m->{self_phone});
    if (!defined $self_norm) {
      for my $a (@{ as_arrayref($m->{mms_addresses}) }) {
        my $n = norm_phone($a->{address});
        if (defined $n && $self_lines{$n}) {
          $self_norm = $n;
          last;
        }
      }
    }
    my $my_addr = (defined $self_norm && $self_lines{$self_norm})
                  ? $self_norm
                  : undef;
    
    next unless defined $my_addr;  # Skip if we can't identify our number
    
    my @peers;
    for my $a (@{ as_arrayref($m->{mms_addresses}) }) {
      my $addr = $a->{address};
      next unless defined $addr && length $addr;
      
      my $n = norm_phone($addr);
      my $is_self = (defined $n && $self_norm && $n eq $self_norm);
      
      # Filter me out
      next if $is_self;
      
      push @peers, $addr;
    }
    
    next unless @peers;  # Skip if no peer found
    
    my $their_addr = $peers[0];  # Primary correspondent
    my $dir = direction_for_mms_box($m->{msg_box});
    next unless defined $dir;  # Skip system messages
    
    my $body = $m->{mms_body} // '';
    my $subject = $m->{sub};
    if (defined $subject && length $subject) {
      $body = "Subject: $subject\n\n$body";
    }
    
    # Generate unique message ID from hash of normalized/processed fields
    my $hash_input = join('|', $their_addr, $my_addr, $epoch, substr($body, 0, 100));
    my $msgid = 'mms:' . md5_hex($hash_input);
    
    # Insert address into address table
    eval {
      $insert_addr->execute($their_addr);
      $addr_count++;
    };
    # Ignore duplicate key errors
    
    # Insert message
    eval {
      $insert_msg->execute($msgid, $their_addr, $my_addr, $dir, $body, $epoch);
      $msg_count++;
    };
    if ($@) {
      warn "Failed to insert MMS message: $@\n" unless $@ =~ /duplicate key/;
    }
  }
}

$dbh->commit;
$dbh->disconnect;

print "\nImport complete:\n";
print "  Messages inserted: $msg_count\n";
print "  Addresses added: $addr_count\n";
