package Tsv;
use common::sense;
BEGIN {
  package U;
  use Nobody::Util;
  use TsvRect;
  use TsvWord;
  use TsvLine;
  use TsvUtil;
};
our($DEBUG)=0;
sub new {
  local(@_)=@_;
  my($class)=U::class(shift);
  my($self)=(ref($_[$#_]) eq 'HASH')?pop:{};
  bless($self,$class);
  $self;
};

sub clone {
  my($self)=$_[0];
  my($guts)=$self->export;
  $self->new($guts);
};
sub export {
  local(@_)=@_;
  my($self)=shift;
  my($guts)={ %$self };
  push(@_,map { \$guts->{$_} } keys %$guts);
  local($_);
  while(@_){
    $_=shift;
    if(U::safe_isa($$_,'TsvRect')) {
      my(%hash);
      for( qw( left top width height ) ){
        $hash{left}=($$_)->left;
        $hash{top}=($$_)->top;
        $hash{width}=($$_)->width;
        $hash{height}=($$_)->height;
      };
      $$_={ %hash };
    } elsif(U::safe_isa($$_,'Tsv')){
      $$_=($$_)->export;
    } elsif ( U::safe_isa($$_,'HASH') ) {
      push(@_,map { \($$_->{$_}) } keys %$$_);
    } elsif ( U::safe_isa($$_,'ARRAY')) {
      push(@_,map { \($$_->[$_]) } keys @$$_);
    } elsif ( !ref($$_) ) {
      $_=$$_;
    } else {
      die "\@_";
    };
  };
  $guts;
};
1;
