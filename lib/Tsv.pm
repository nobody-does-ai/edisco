package Tsv;
use Nobody::Util;
use Nobody::Util qw(sum);
use common::sense;
use TsvWord;
our($DEBUG)=0;
sub new {
  local(@_)=@_;
  my($class)=class(shift);
  my($self)=(ref($_[$#_]) eq 'HASH')?pop:{};
  bless($self,$class);
};
1;
