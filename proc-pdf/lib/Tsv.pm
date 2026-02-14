package Tsv;
use common::sense;
BEGIN {
  package U;
  use Nobody::Util;
  use TsvRect;
  use TsvWord;
  use TsvLine;
  use TsvUtil;
  use TsvCol;
};
our($DEBUG)=0;
{
  package IndirectHash;
};
my @rect=qw( top left width height );
sub new {
  local(@_)=@_;
  my($class)=U::class(shift);
  my($self)={@_};
  bless($self,$class);
  $self;
};

#    sub clone {
#      my($self)=$_[0];
#      my($guts)=$self->export;
#      $self->new($guts);
#    };
#    sub export {
#      local(@_)=@_;
#      my($self)=shift;
#      my($guts)={ %$self };
#      push(@_,map { \$guts->{$_} } keys %$guts);
#      local($_);
#      while(@_){
#        $_=shift;
#        if(U::safe_isa($$_,'TsvRect')) {
#          my(%hash);
#          my($rect)=$$_;
#          $hash{x1}=($rect)->x1;
#          $hash{y1}=($rect)->y1;
#          $hash{dx}=($rect)->dx;
#          $hash{dy}=($rect)->dy;
#          $$_={ %hash };
#        } elsif(U::safe_isa($$_,'Tsv')){
#          $$_=($$_)->export;
#        } elsif ( U::safe_isa($$_,'HASH') ) {
#          push(@_,map { \($$_->{$_}) } keys %$$_);
#        } elsif ( U::safe_isa($$_,'ARRAY')) {
#          push(@_,@$$_);
#        } elsif ( !ref($$_) ) {
#          $_=$$_;
#        } else {
#          die "\@_";
#        };
#      };
#      $guts;
#    };
1;
