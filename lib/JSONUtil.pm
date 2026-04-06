package JSONUtil;
use lib "lib";
use Tie::Snitch;
use Carp qw(confess);
use JSON::PP;
use Nobody::JSON;
use Nobody::Util @Nobody::Util::EXPORT_OK;
use Nobody::Util;
use common::sense;
require Exporter;
sub import {
  goto \&Exporter::import;
};
our(@ISA)=qw(Exporter);
our(@EXPORT)=qw( load_json save_json decode_json encode_json );

sub load_json {
    my ($p) = @_;
    return undef unless -e $p;
    my $raw = path($p)->slurp_raw;
    return {} unless length($raw);
    return JSON::PP::decode_json($raw);
}

sub save_json {
    my ($p, $data) = @_;
    my($pretty)=1;
    $p=path($p);
    my $raw = (
      $pretty?
      Nobody::JSON::encode_json($data):
      JSON::PP::encode_json($data)
    );
    return $p->spew_raw($raw);
}

1;
