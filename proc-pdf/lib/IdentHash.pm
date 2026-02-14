package IdentHash;
use Nobody::Util;
our(%k,%v,%self,$self);
use overload qw("")=>sub { '($self)' };
use Nobody::PP;
my(%data);
sub err {
  local(@_)=@_;
  local($_)=join(", ",$_[1],map { pp("$_") } @_[2..$#_]);
  say STDERR $_[0],"($_)";
};
sub TIEHASH  {
  err "TIEHASH",@_;
  $self=bless([{},[@_]]);
}
sub STORE    {
  err "STORE",@_;
  $_[0][0]{$_[1]} = $_[2];
}
sub FETCH    {
  err "FETCH",@_;
  return ($_[0][0]{$_[1]}//=$_[1]);
}
sub FIRSTKEY {
  err "FIRSTKEY",@_;
  my $a = scalar keys %{$_[0][0]};
  each %{$_[0][0]} 
}
sub NEXTKEY  {
  err "NEXTKEY",@_;
  each %{$_[0][0]} 
}
sub EXISTS   {
  err "EXISTS",@_;
  exists $_[0][0]->{$_[1]} 
}
sub DELETE   {
  err "DELETE",@_;
  delete $_[0][0]->{$_[1]} 
}
sub CLEAR    {
  err "CLEAR",@_;
  %{$_[0][0]} = () 
}
sub SCALAR   {
  err "SCALAR",@_;
  scalar %{$_[0][0]} 
}
if(!caller) {
  package main;
  our(%hash);
  tie %hash,'IdentHash';
  $hash{a}="b";
  die "test1" unless $hash{a} eq "b";
  die "test2" unless $hash{b} eq "b";
  die "test2" unless $hash{c} eq "c";
};
