package Nobody::JSON;
use FindBin qw($RealBin);
use Carp::Always;
use lib "$RealBin/../lib", "$RealBin/lib";
use Nobody::Auto qw( common::sense JSON::XS );
use common::sense;
use JSON::XS qw( encode_json decode_json );
our @ISA = qw(JSON::XS );
our $VERSION = '0.01';
sub json;
our @EXPORT    = qw( json );
our @EXPORT_OK = qw( encode_json decode_json );
our %EXPORT_TAGS = ( all => [ @EXPORT_OK ] );

# Lazy-initialised encoder configured for maximum readability:
# - ascii: escape non-ASCII so output is safe in any context
# - pretty: human-readable indented output
# - allow_nonref: encode bare scalars, not just objects/arrays
INIT {
  sub new {
    my($class)=class(shift);
    my($self)=$class->SUPER::new;
    $self->ascii;
    $self->encode(1);
    $self->pretty;
    $self->allow_nonref;
    $self;
  }; 
};
sub json {
  local(@_)=@_;
  state($json);
  $json//=Nobody::JSON->new;
  $json;
};
sub load {
  die "you can't do that!" unless safe_can($_[0],"load");
  die "usage: json->load( *FH | path(x) | '/etc/passwd'" unless @_==1;
  local(@_)=@_;
  my($self)=shift;
  my($src)=shift;
  if(safe_can($src,"readline")){
    @_=<$src>;
  } elsif ( safe_can($src,"slurp") ) {
    @_=$src->slurp;
  } elsif ( ref($src) ) {
    die "don't know how to count this blessing";
  } else {
    @_=path($src)->slurp;
  };
  json_decode("@_");
};
sub save {
  die "you can't do that!" unless safe_can($_[0],"save");
  my($self)=shift;
  my($src)=shift;
  die "noo many args" if @_>1;
  local($_)=$self->encode(shift);
  if(safe_can($src,"print")){
    $src->print("@_");
  } elsif ( safe_can("spew") ) {
    $src->spew(@_);
  }
};
sub json_encode {
  local(@_)=@_;
  json->encode(@_);
};
sub json_decode {
  local(@_)=@_;
  json->decode(@_);
};
sub encode_json($) { json->encode(shift) }
sub decode_json($) {  json->decode(shift) }
sub encode {
  local(@_)=@_;
  die "you can't do that!" unless safe_can($_[0],"encode");
  my($self)=shift;
  $self->SUPER::encode(@_);
};
sub decode {
  local(@_)=@_;
  die "you can't do that!" unless safe_can($_[0],"decode");
  my($self)=shift;
  $self->SUPER::decode("@_");
}
if(0){
  unless(caller){
    say STDERR ( "b4" );
    use Nobody::Util;
    my($json)=Nobody::JSON->json();
    say($json->encode({ []=>[] }));
    say STDERR ( "ok" );
  };
};
1;

=head1 NAME

Nobody::JSON - JSON encoding with the prettiest possible output

=head1 SYNOPSIS

  use Nobody::JSON;

  my $json = encode_json({ key => "value", list => [1, 2, 3] });
  my $data = decode_json($json);

=head1 DESCRIPTION

C<Nobody::JSON> is a thin wrapper around C<JSON::XS> that configures the
encoder for maximum human readability: ASCII-safe output, pretty-printed
with indentation, and support for non-reference scalars.

The interface is intentionally compatible with C<JSON::XS>, C<JSON::PP>,
C<Cpanel::JSON::XS>, and any other JSON module that exports C<encode_json>
and C<decode_json> with the same prototypes.

=head1 EXPORTS

C<encode_json> and C<decode_json> are exported by default.
C<json_encode> and C<json_decode> are available as aliases via C<:all>
or explicit import.

=head1 FUNCTIONS

=head2 encode_json( $data )

Encodes C<$data> to a pretty-printed, ASCII-safe JSON string.

=head2 decode_json( $json )

Decodes a JSON string to a Perl data structure.  Thin pass-through to
C<JSON::XS::decode_json>.

=head1 AUTHOR

Rich Paul, C<< <nobody at cpan.org> >>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
