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
our(@cols,%key);
BEGIN {
  for(qw( level page_num block_num par_num line_num word_num conf text rect )){
    $key{$_}=$_;
  };
  for(values %key) {
    s{_num}{};
  };
  *DEBUG=\$Tsv::DEBUG;
  undef &head;
};
my(@word);

sub new {
  local(@_)=@_;
  my($class)=U::class(shift);
  my($self)={@_};
  $self->{rect}=TsvRect->take_data($self);
  for my $old(keys %$self){
    $self->{$key{$old}}=delete $self->{$old} if $key{$old};
  };
  $self=$class->SUPER::new(%$self);
#      my(%data)=map { %$_ } shift;
#      my($rect)=TsvRect->take_data(\%data);
#      my($self)={ %data };
#      $self->{rect}=$rect;
  bless($self,$class);
};
sub from {
  local(@_)=@_;
  my($class)=U::class(shift);
  for(@_) {
    next if(U::safe_isa($_,'TsvWord'));
    die "Expected hash, got: ", U::pp($_) unless ref($_) eq "HASH";
    $_=$class->new(%$_);
  };
  return @_;
};
our(%h,@a);
sub hash {
  local(@_)=@_;
  if(U::class($_[0]) eq __PACKAGE__){
    shift;
  };
  for(@_) {
    if(ref eq 'ARRAY') {
      local(@_)=@$_;
      $_={ map { $_, shift } @cols };
    };
    die "idk how to handle: $_" unless ref($_) eq 'HASH';
  };
  shift if $_->{level} eq 'level';
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
  if(substr($_[0],0,1) eq 'l'){
    @cols=map { split m{[\t\n]} } shift;
  };
  @_=parse_lines(@_);
  $_->{page}=$file->basename(".tsv") for @_;
  @_;
}
sub parse_lines {
  shift if $_[0]->isa(__PACKAGE__);
  $_=[split m{[\t\n]}] for grep { !ref } @_;
  @_=hash(@_);
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
