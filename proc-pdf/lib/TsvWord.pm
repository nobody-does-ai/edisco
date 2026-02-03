package TsvWord;
# vim: ts=2 sw=2 ft=perl
use common::sense;
{
  package U;
  use Nobody::Util;
  use Carp::Always;
  use Carp qw( croak cluck carp confess );
  use TsvUtil;
  use autodie;
  use Nobody::PP;
  our(@VERSION) = qw( 0 1 0 );
  our($DEBUG);
};
use TsvText;
our(@ISA)=qw(TsvText);
our(@cols,@bad);
BEGIN {
  *DEBUG=\$Tsv::DEBUG;
  undef &head;
};
my(@word);
sub new {
  local(@_)=@_;
  my($class)=U::class(shift);
  my(%data)=map { %$_ } shift;
  my(%rect);
  for(qw(left top width height)){
    $rect{$_}=delete$data{$_};
  };
  if(defined($data{text})) {
    s{"}{-}g;
    s{&}{+}g;
  } else {
    $data{text}="<UNDEFINED>";
  };
  if($rect{top}%3){
    $rect{top}-=$rect{top}%3;
  };
  if($rect{height}%3){
    $rect{height}+=3-$rect{height}%3;
  };
  if($rect{left}%3){
    $rect{left}-=$rect{left}%3;
  };
  if($rect{width}%3){
    $rect{width}+=3-$rect{width}%3;
  };
  my($self)={ %data };
  $self->{rect}=TsvRect->new( \%rect );
  bless($self,$class);
};
sub from {
  local(@_)=@_;
  my($class)=U::class(shift);
  for(@_) {
    next if(U::safe_isa($_,'TsvWord'));
    die "???", U::pp($_) unless ref($_) eq "HASH";
    $_=$class->new($_);
  };
  return @_;
};
sub hash {
  local(@_)=@_;
  if($_[0] eq __PACKAGE__){
    shift;
  };
  if(@cols) {
    local(@_)=map { @$_ } shift;
    die "col mismatch (@_ != @cols)" unless "@_" eq "@cols";
  } else {
    @cols=map { @$_ } shift;
    @bad=grep { m{_num} } @cols;
  };
  for(@_) {
    local(@_)=@$_;
    my(%data)=map {$_,shift} @cols;
    delete $data{$_} for @bad;
    $_=\%data;
  };
  @_;
};
sub fixup {
  local(*_)=shift;
  if($_[$#_] =~ m{^(account:)(.*)}){
    my($a,$b)=(hash(@_),hash(@_));
    U::eex($a);
    U::eex($b);
  };
  return \@_;
};
sub parse_file {
  die "usage: ".__PACKAGE__."->parse_file(path(\"name\"))" unless (
    @_==2
      and
    $_[0]->isa(__PACKAGE__)
  );
  local(@_)=@_;
  my($class,$file)=@_;
  $file=U::path($file) unless ref($file);
  local(@_)=$file->lines;
  parse_lines(@_);
}
sub parse_lines {
  shift if $_[0]->isa(__PACKAGE__);
  @_=map { [split m{[\t\n]}] } grep { m{^[5l]} } @_;
  @_=hash(@_);
  @_ = map { ref($_)eq'ARRAY'?(@$_):$_ } @_;
  @_;
};
sub load_file {
  my($self)=shift;
  $self->from($self->parse_file(@_));
};
sub word {
  return [ shift ];
};
sub text {
  return shift->{text};
};
1;
