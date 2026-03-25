package Tie::LoudArray;
use Nobody::Util;
my sub x {
  $DB::single=1;
  local(@_)=@_;
  my(@caller)=caller(1);
  ee(@caller);
};
sub new {
  x(@_);
  my($class)=class(shift);
  my(@self);
  tie @self, $class, @_;
  \@self;
};
sub TIEARRAY  { x(@_); bless [], $_[0] }
sub FETCHSIZE { x(@_); scalar @{$_[0]} }
sub STORESIZE { x(@_); $#{$_[0]} = $_[1]-1 }
sub STORE     { x(@_); $_[0]->[$_[1]] = $_[2] }
sub FETCH     { x(@_); $_[0]->[$_[1]] }
sub CLEAR     { x(@_); @{$_[0]} = () }
sub POP       { x(@_); pop(@{$_[0]}) }
sub PUSH      { x(@_); my $o = shift; push(@$o,@_) }
sub SHIFT     { x(@_); shift(@{$_[0]}) }
sub UNSHIFT   { x(@_); my $o = shift; unshift(@$o,@_) }
sub EXISTS    { x(@_); exists $_[0]->[$_[1]] }
sub DELETE    { x(@_); delete $_[0]->[$_[1]] }

sub SPLICE
{
  x(@_);
  my $ob  = shift;
  my $sz  = $ob->FETCHSIZE;
  my $off = @_ ? shift : 0;
  $off   += $sz if $off < 0;
  my $len = @_ ? shift : $sz-$off;
  return splice(@$ob,$off,$len,@_);
}
1;
