#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use JSON::PP;

# Extract all address->contact_name mappings from SMS/MMS backup XML
# Outputs: JSON object mapping addresses to contact names

my $input_file = $ARGV[0] or die "Usage: $0 <input.xml>\n";

open(my $fh, '<:utf8', $input_file) or die "Cannot open $input_file: $!\n";

my %contacts;  # address => contact_name

while (my $line = <$fh>) {
    # Match address and contact_name attributes
    if ($line =~ /address="([^"]+)".*contact_name="([^"]+)"/) {
        my ($addr, $name) = ($1, $2);
        
        # Skip if already seen with a better name
        if (exists $contacts{$addr}) {
            # Prefer named contacts over (Unknown)
            next if $name eq '(Unknown)' && $contacts{$addr} ne '(Unknown)';
        }
        
        $contacts{$addr} = $name;
    }
}

close($fh);

# Output as JSON
my $json = JSON::PP->new->utf8->pretty->canonical;
print $json->encode(\%contacts);
