#!/usr/bin/env perl
use strict;
use warnings;
use JSON::PP;

# Example: How to use the contacts.json file in Perl scripts

# Load contacts
my $contacts = load_contacts('contacts.json');

# Look up a contact by phone number
my $phone = 'XXXXXXXXXXXX';
if (exists $contacts->{$phone}) {
    print "Phone $phone belongs to: $contacts->{$phone}\n";
} else {
    print "Phone $phone not found\n";
}

# Find all contacts with a specific name
my $search_name = 'XXXX';
print "\nContacts matching '$search_name':\n";
foreach my $addr (sort keys %$contacts) {
    if ($contacts->{$addr} =~ /$search_name/i) {
        print "  $addr => $contacts->{$addr}\n";
    }
}

# Count known vs unknown contacts
my $known = 0;
my $unknown = 0;
foreach my $name (values %$contacts) {
    if ($name eq '(Unknown)') {
        $unknown++;
    } else {
        $known++;
    }
}
print "\nStatistics:\n";
print "  Known contacts: $known\n";
print "  Unknown: $unknown\n";
print "  Total: " . scalar(keys %$contacts) . "\n";

# Helper function to load contacts
sub load_contacts {
    my ($filename) = @_;
    
    open(my $fh, '<:utf8', $filename) or die "Cannot open $filename: $!\n";
    local $/;  # Slurp mode
    my $json_text = <$fh>;
    close($fh);
    
    my $json = JSON::PP->new->utf8;
    return $json->decode($json_text);
}
