#!/usr/bin/perl
use strict;
use warnings;
use XML::LibXML;
use MIME::Base64;
use HTML::Entities;
use File::Path qw(make_path);
use File::Spec;
use Getopt::Long;
use POSIX qw(strftime);

# Command line options
my $input_file;
my $output_file = 'messages.mbox';
my $attachments_dir = 'attachments';
my $skip_mms = 0;
my $filter_file;
my $help = 0;

GetOptions(
    'input=s'       => \$input_file,
    'output=s'      => \$output_file,
    'attachments=s' => \$attachments_dir,
    'skip-mms'      => \$skip_mms,
    'filter=s'      => \$filter_file,
    'help'          => \$help,
) or die "Error in command line arguments\n";

if ($help || !$input_file) {
    print_usage();
    exit 0;
}

die "Input file does not exist: $input_file\n" unless -f $input_file;

# Create attachments directory if it doesn't exist
make_path($attachments_dir) unless -d $attachments_dir;

# Load filter hash if specified
my %filter_hash;
if ($filter_file) {
    load_filter_file($filter_file, \%filter_hash);
    print "Loaded " . scalar(keys %filter_hash) . " filter entries\n";
}

# Parse XML
print "Parsing XML file...\n";
my $parser = XML::LibXML->new();
my $doc = $parser->parse_file($input_file);
my $root = $doc->documentElement();

# Load existing messages BEFORE opening output file for writing
my %seen_messages;
if (-f $output_file) {
    print "Loading existing messages for deduplication...\n";
    load_existing_messages($output_file, \%seen_messages);
    print "Loaded " . scalar(keys %seen_messages) . " existing messages\n";
}

# Open output mbox file (this will truncate it)
open(my $mbox_fh, '>:utf8', $output_file) or die "Cannot open output file $output_file: $!\n";

# Collect all messages (SMS and MMS) with timestamps for sorting
my @messages;

# Process SMS messages
my @sms_nodes = $root->findnodes('//sms');
print "Found " . scalar(@sms_nodes) . " SMS messages\n";

foreach my $sms (@sms_nodes) {
    my $msg = {
        type => 'sms',
        date => $sms->getAttribute('date'),
        address => $sms->getAttribute('address') || 'unknown',
        msg_type => $sms->getAttribute('type'),  # 1=received, 2=sent
        body => decode_entities($sms->getAttribute('body') || ''),
        readable_date => $sms->getAttribute('readable_date') || '',
        contact_name => $sms->getAttribute('contact_name') || 'Unknown',
    };
    push @messages, $msg;
}

# Process MMS messages
unless ($skip_mms) {
    my @mms_nodes = $root->findnodes('//mms');
    print "Found " . scalar(@mms_nodes) . " MMS messages\n";
    
    foreach my $mms (@mms_nodes) {
        my $msg = {
            type => 'mms',
            date => $mms->getAttribute('date'),
            address => $mms->getAttribute('address') || 'unknown',
            msg_type => $mms->getAttribute('msg_box'),  # 1=received, 2=sent
            readable_date => $mms->getAttribute('readable_date') || '',
            contact_name => $mms->getAttribute('contact_name') || 'Unknown',
            parts => [],
            addresses => [],
        };
        
        # Extract all participants
        my @addr_nodes = $mms->findnodes('.//addr');
        foreach my $addr (@addr_nodes) {
            my $addr_val = $addr->getAttribute('address');
            my $addr_type = $addr->getAttribute('type');
            push @{$msg->{addresses}}, {
                address => $addr_val,
                type => $addr_type,  # 137=from, 151=to
            };
        }
        
        # Extract parts
        my @part_nodes = $mms->findnodes('.//part');
        foreach my $part (@part_nodes) {
            my $ct = $part->getAttribute('ct') || '';
            my $seq = $part->getAttribute('seq') || 0;
            
            # Skip SMIL parts (presentation metadata)
            next if $ct =~ /smil/i;
            
            my $part_data = {
                seq => $seq,
                content_type => $ct,
                name => $part->getAttribute('name') || $part->getAttribute('cl') || "part_$seq",
            };
            
            if ($ct eq 'text/plain') {
                # Text part - extract as message body
                $part_data->{text} = decode_entities($part->getAttribute('text') || '');
            } else {
                # Binary attachment - extract base64 data
                $part_data->{data} = $part->getAttribute('data') || '';
            }
            
            push @{$msg->{parts}}, $part_data;
        }
        
        push @messages, $msg;
    }
}

# Sort messages by date
print "Sorting messages chronologically...\n";
@messages = sort { $a->{date} <=> $b->{date} } @messages;

# Write messages to mbox
my $total_messages = scalar(@messages);
my $count = 0;
my $written = 0;
my $skipped = 0;

if (%filter_hash) {
    print "Filtering messages...\n";
    foreach my $msg (@messages) {
        if (should_include_message($msg, \%filter_hash)) {
            if (!is_duplicate($msg, \%seen_messages)) {
                write_mbox_message($mbox_fh, $msg);
                $written++;
            } else {
                $skipped++;
            }
        }
        $count++;
        print "." if $count % 100 == 0;
    }
    print "\nWrote $written of $total_messages messages (filtered)";
    print ", skipped $skipped duplicates" if $skipped > 0;
    print "\n";
} else {
    print "Writing $total_messages messages to mbox...\n";
    foreach my $msg (@messages) {
        if (!is_duplicate($msg, \%seen_messages)) {
            write_mbox_message($mbox_fh, $msg);
            $written++;
        } else {
            $skipped++;
        }
        $count++;
        print "." if $count % 100 == 0;
    }
    print "\nWrote $written messages";
    print ", skipped $skipped duplicates" if $skipped > 0;
    print "\n";
}

print "\n";
close($mbox_fh);

print "Conversion complete!\n";
print "Output: $output_file\n";
print "Attachments: $attachments_dir/\n";

# Subroutines

sub write_mbox_message {
    my ($fh, $msg) = @_;
    
    # Sanitize address for From line
    my $from_addr = sanitize_address($msg->{address});
    
    # Convert timestamp to Unix time (milliseconds to seconds)
    my $unix_time = int($msg->{date} / 1000);
    my $date_str = strftime("%a %b %d %H:%M:%S %Y", localtime($unix_time));
    
    # Mbox "From " separator line (note: space after From, not colon)
    print $fh "From $from_addr $date_str\n";
    
    # Email headers
    my $from_name = $msg->{contact_name};
    my $direction = ($msg->{msg_type} == 1 || $msg->{msg_type} eq '1') ? 'received' : 'sent';
    
    if ($direction eq 'received') {
        print $fh "From: $from_name <$from_addr>\n";
        print $fh "To: Me\n";
    } else {
        print $fh "From: Me\n";
        print $fh "To: $from_name <$from_addr>\n";
    }
    
    print $fh "Date: $msg->{readable_date}\n";
    print $fh "Subject: \n";  # Empty subject
    print $fh "Content-Type: text/plain; charset=UTF-8\n";
    my $msg_type = $msg->{msg_type} || '';
    print $fh "X-Timestamp: $msg->{date}\n";  # For deduplication
    print $fh "X-MsgType: $msg_type\n";  # For deduplication
    print $fh "\n";  # Blank line between headers and body
    
    # Message body
    if ($msg->{type} eq 'sms') {
        # Simple SMS body
        my $body = $msg->{body};
        $body = quote_from_lines($body);
        print $fh "$body\n";
    } else {
        # MMS with parts
        my $body = process_mms_parts($msg);
        $body = quote_from_lines($body);
        print $fh "$body\n";
    }
    
    # Blank line to separate messages
    print $fh "\n";
}

sub process_mms_parts {
    my ($msg) = @_;
    my $body = '';
    my @text_parts;
    my @attachment_refs;
    
    # Sort parts by sequence
    my @sorted_parts = sort { $a->{seq} <=> $b->{seq} } @{$msg->{parts}};
    
    foreach my $part (@sorted_parts) {
        if ($part->{content_type} eq 'text/plain' && defined $part->{text}) {
            # Text part - include in body
            push @text_parts, $part->{text};
        } elsif ($part->{data}) {
            # Binary attachment - save to file
            my $filename = save_attachment($msg->{date}, $part);
            push @attachment_refs, "[Attachment: $filename]";
        }
    }
    
    # Construct body
    if (@text_parts) {
        # If there are text parts, use them as the main body
        $body = join("\n\n", @text_parts);
        
        # Add attachment references at the end
        if (@attachment_refs) {
            $body .= "\n\n" . join("\n", @attachment_refs);
        }
    } elsif (@attachment_refs) {
        # No text, only attachments
        $body = join("\n", @attachment_refs);
    } else {
        # Empty MMS
        $body = "[Empty MMS message]";
    }
    
    return $body;
}

sub save_attachment {
    my ($timestamp, $part) = @_;
    
    # Decode base64 data
    my $binary_data = decode_base64($part->{data});
    
    # Generate filename
    my $ext = get_extension_from_mime($part->{content_type});
    my $orig_name = $part->{name};
    
    # Clean up original name
    $orig_name =~ s/[^a-zA-Z0-9._-]/_/g;
    
    # Create unique filename
    my $filename = "${timestamp}_${orig_name}";
    $filename =~ s/\.(txt|bin)$//;  # Remove generic extensions
    $filename .= $ext if $ext && $filename !~ /\.\w+$/;
    
    my $filepath = File::Spec->catfile($attachments_dir, $filename);
    
    # Save to file
    open(my $fh, '>', $filepath) or die "Cannot write attachment $filepath: $!\n";
    binmode($fh);
    print $fh $binary_data;
    close($fh);
    
    return $filename;
}

sub get_extension_from_mime {
    my ($mime) = @_;
    
    my %mime_map = (
        'image/jpeg' => '.jpg',
        'image/jpg'  => '.jpg',
        'image/png'  => '.png',
        'image/gif'  => '.gif',
        'image/bmp'  => '.bmp',
        'image/webp' => '.webp',
        'audio/mpeg' => '.mp3',
        'audio/mp3'  => '.mp3',
        'audio/mp4'  => '.m4a',
        'audio/amr'  => '.amr',
        'audio/3gpp' => '.3gp',
        'video/mp4'  => '.mp4',
        'video/3gpp' => '.3gp',
        'video/mpeg' => '.mpg',
        'application/pdf' => '.pdf',
        'text/plain' => '.txt',
        'text/x-vcard' => '.vcf',
        'text/vcard' => '.vcf',
    );
    
    return $mime_map{lc($mime)} || '';
}

sub sanitize_address {
    my ($addr) = @_;
    
    # Remove special characters that might break mbox format
    $addr =~ s/[^a-zA-Z0-9@.+_-]/_/g;
    
    # If it's a phone number, format it nicely
    if ($addr =~ /^\+?[\d_]+$/) {
        $addr =~ s/_//g;
        $addr = "sms+$addr\@phone.local";
    }
    
    return $addr;
}

sub quote_from_lines {
    my ($text) = @_;
    
    # In mbox format, lines starting with "From " must be quoted with ">"
    # to avoid being interpreted as message separators
    $text =~ s/^From />From /mg;
    
    return $text;
}

sub load_existing_messages {
    my ($filename, $hash_ref) = @_;
    
    open(my $fh, '<:utf8', $filename) or return;  # Silently return if file doesn't exist
    
    my $current_msg = { address => '', timestamp => '', msg_type => '', body => '', in_body => 0 };
    
    while (my $line = <$fh>) {
        if ($line =~ /^From (\S+) /) {
            # Start of new message - save previous if we have one
            if ($current_msg->{timestamp} && $current_msg->{address}) {
                my $body_snippet = substr($current_msg->{body}, 0, 50);
                $body_snippet =~ s/\s+/ /g;  # Normalize whitespace
                my $key = "$current_msg->{timestamp}:$current_msg->{address}:$current_msg->{msg_type}:$body_snippet";
                $hash_ref->{$key} = 1;
            }
            # Start new message
            $current_msg = { address => $1, timestamp => '', msg_type => '', body => '', in_body => 0 };
        } elsif ($line =~ /^X-Timestamp: (\d+)/) {
            # Extract our custom timestamp header
            $current_msg->{timestamp} = $1;
        } elsif ($line =~ /^X-MsgType: (.*)/) {
            # Extract message type
            $current_msg->{msg_type} = $1;
            chomp $current_msg->{msg_type};
        } elsif ($line =~ /^\s*$/ && $current_msg->{address}) {
            # Blank line after headers - body starts next
            $current_msg->{in_body} = 1;
        } elsif ($current_msg->{in_body}) {
            # Body content
            $current_msg->{body} .= $line;
        }
    }
    
    # Save last message
    if ($current_msg->{timestamp} && $current_msg->{address}) {
        my $body_snippet = substr($current_msg->{body}, 0, 50);
        $body_snippet =~ s/\s+/ /g;  # Normalize whitespace
        my $key = "$current_msg->{timestamp}:$current_msg->{address}:$current_msg->{msg_type}:$body_snippet";
        $hash_ref->{$key} = 1;
    }
    
    close($fh);
}

sub is_duplicate {
    my ($msg, $seen_ref) = @_;
    
    return 0 unless %$seen_ref;  # No deduplication if hash is empty
    
    my $msg_type = $msg->{msg_type} || '';
    my $body = get_message_body($msg);
    my $body_snippet = substr($body, 0, 50);
    $body_snippet =~ s/\s+/ /g;  # Normalize whitespace
    my $key = "$msg->{date}:$msg->{address}:$msg_type:$body_snippet";
    
    if (exists $seen_ref->{$key}) {
        return 1;  # It's a duplicate
    }
    
    # Not seen before - add to hash
    $seen_ref->{$key} = 1;
    return 0;
}

sub get_message_body {
    my ($msg) = @_;
    
    if ($msg->{type} eq 'sms') {
        return $msg->{body};
    } else {
        # MMS - reconstruct body
        my $body = '';
        my @sorted_parts = sort { $a->{seq} <=> $b->{seq} } @{$msg->{parts}};
        foreach my $part (@sorted_parts) {
            if ($part->{content_type} eq 'text/plain' && defined $part->{text}) {
                $body .= $part->{text} . "\n";
            }
        }
        return $body;
    }
}

sub load_filter_file {
    my ($filename, $hash_ref) = @_;
    
    open(my $fh, '<', $filename) or die "Cannot open filter file $filename: $!\n";
    
    while (my $line = <$fh>) {
        chomp $line;
        $line =~ s/^\s+|\s+$//g;  # Trim whitespace
        next if $line eq '' || $line =~ /^#/;  # Skip empty lines and comments
        
        # Support both "name" and "+1234567890" formats
        $hash_ref->{$line} = 1;
    }
    
    close($fh);
}

sub should_include_message {
    my ($msg, $hash_ref) = @_;
    
    # Check contact name
    if ($msg->{contact_name} && $hash_ref->{$msg->{contact_name}}) {
        return 1;
    }
    
    # Check address (phone number)
    if ($msg->{address} && $hash_ref->{$msg->{address}}) {
        return 1;
    }
    
    # For MMS, check all participant addresses
    if ($msg->{addresses}) {
        foreach my $addr_info (@{$msg->{addresses}}) {
            if ($hash_ref->{$addr_info->{address}}) {
                return 1;
            }
        }
    }
    
    # Check if contact name contains any filter term (partial match)
    if ($msg->{contact_name}) {
        foreach my $filter_term (keys %$hash_ref) {
            if (index($msg->{contact_name}, $filter_term) != -1) {
                return 1;
            }
        }
    }
    
    return 0;
}

sub print_usage {
    print <<'USAGE';
SMS/MMS XML to Mbox Converter

Usage: sms2mbox.pl --input <xml_file> [options]

Required:
  --input <file>        Input XML file from SMS Backup & Restore

Options:
  --output <file>       Output mbox file (default: messages.mbox)
  --attachments <dir>   Directory for attachments (default: attachments/)
  --filter <file>       Filter file with contact names/numbers (one per line)
  --skip-mms            Skip MMS messages, only convert SMS
  --help                Show this help message

Example:
  sms2mbox.pl --input sms-backup.xml --output my-messages.mbox

The script will:
  - Convert SMS messages to mbox format
  - Extract MMS text content as message body
  - Save MMS attachments (images, audio, etc.) to separate files
  - Ignore SMIL presentation parts
  - Sort all messages chronologically

USAGE
}
