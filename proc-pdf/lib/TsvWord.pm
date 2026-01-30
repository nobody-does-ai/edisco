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
our(@cols);
BEGIN {
  *DEBUG=\$Tsv::DEBUG;
  undef &head;
};
sub new {
  local(@_)=@_;
  my($class)=U::class(shift);
  my(%data)=map { %$_ } shift;
  my(%rect);
#      for(qw(block line word par)) {
#        delete $data{$_."_num"};
#      };
  for(qw(left top width height)){
    $rect{$_}=delete$data{$_};
  };
  for(keys %data){
    delete $data{$_} unless defined $data{$_};
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
    die "???", pp($_) unless ref($_) eq "HASH";
    $_=$class->new($_);
  };
  return @_;
};
sub hash {
  local(@_)=@_;
  if(@cols) {
    local(@_)=map { @$_ } shift;
    die "col mismatch (@_ != @cols)" unless "@_" eq "@cols";
  } else {
    @cols=map { @$_ } shift;
  };
  for(@_) {
    local(@_)=@$_;
    $_={ map { $_, shift } @cols };
  };
  @_;
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
  @_=hash(map { [split m{[\t\n]}] } $file->lines);
  @_;
};
sub block_num {
  my($self)=shift;
  $self->{block_num};
}
sub load_file {
  my($self)=shift;
  $self->from($self->parse_file(@_));
};
sub text {
  return shift->{text};
};
1;
