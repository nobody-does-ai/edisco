package LimHash;
use common::sense;
BEGIN { open(STDOUT,">&STDERR"); };
use Nobody::Util;
our(@ISA)=qw(Tie::StdHash);
use Tie::Hash;
use Scalar::Util qw(refaddr);
our(%back);
our(%key);
BEGIN {
  *key=\%TsvRect::key;
  say refaddr( \%TsvRect::key );
  say refaddr( \%key );
};
sub TIEHASH {
  my($class)=class(shift);
  my($self,%self);
  $self=\%self;
  $self{x1}=$self{x2}=$self{y1}=$self{y2};
  return bless($self,$class);
};
sub STORE {
  my($self,$key,$val)=@_;
  $key=$key{$key};
  if($key eq 'dy' || $key eq 'dx') {
    local(@_)=grep { defined } $val;
    return $back{$self}->dx(@_);
  } elsif ($self->EXISTS($key)) {
    return $self->SUPER::STORE($key,$val);
  };
  die "bad key: ",pp($key),pp(\%key),"FUCK!" unless $self->EXISTS($key);
};
sub FETCH {
  my($self,$key)=@_;
  $key=$key{$key};
  die "bad key: $key" unless $self->EXISTS($key);
  return $self->SUPER::FETCH($key);
};
1;
