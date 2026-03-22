package JSONUtil;
use lib "lib";
use common::sense;
use Nobody::Util;
BEGIN {
  for(sort @Nobody::Util::EXPORT) {
    say if /c/;
  };
};
use Nobody::Util @Nobody::Util::EXPORT_OK;
use Nobody::Util @Nobody::Util::EXPORT_OK;
use JSON::PP;
require Exporter;
sub import {
  confess("failure");
};
our(@ISA)=qw(Exporter);
our(@EXPORT_OK)=qw( json_load json_save decode_json encode_json );

sub load_json {
    my ($p) = @_;
    return undef unless -e $p;
    my $raw = path($p)->slurp_raw;
    return JSON::PP::decode_json($raw);
}

sub save_json {
    my ($p, $data) = @_;
    $p=path($p);
    my $raw = JSON::PP::encode_json($data);
    return $p->spew_raw($raw);
}

1;
