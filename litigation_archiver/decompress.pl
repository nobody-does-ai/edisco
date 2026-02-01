#!/usr/bin/perl
# vim: ts=2 sw=2 ft=perl
# Decompress raw zlib data (without gzip headers)
use strict;
use warnings;
use Compress::Raw::Zlib;

binmode STDIN;
binmode STDOUT;

my $data = do { local $/; <STDIN> };

my ($inflator, $status) = Compress::Raw::Zlib::Inflate->new(
  -WindowBits => -15  # negative = raw deflate without headers
);

die "Failed to create inflator: $status\n" unless $status == Z_OK;

my $output;
$status = $inflator->inflate($data, $output);
die "Decompression failed: $status\n" unless $status == Z_STREAM_END;

print $output;
