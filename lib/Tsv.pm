package Tsv;
use lib 'lib';
use TsvRect;
for(qw(x1 x2 y1 y2 dx dy cx xy)){
  *{$_}=TsvRect->can($_);
};
use Nobody::Util;
use Nobody::Util qw(sum);
use common::sense;
use TsvWord;
our(@ISA)=qw();
our($DEBUG)=0;
my(%word);
sub new {
  local(@_)=@_;
  die "usage: Tsv::new ( class, hash )" unless @_==2 and ref($_[1])eq'HASH';
  my($class)=class(shift);
  my($self)=shift;
  bless($self,$class);
  $self;
};
sub TO_JSON {
  return { class=>ref($_[0]), map { $_=>$_[0]->$_() } sort $_[0]->keys };
};
1;
