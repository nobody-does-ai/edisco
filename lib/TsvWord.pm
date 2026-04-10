#!/usr/bin/perl
# vim: ts=2 sw=2 ft=perl
eval 'exec perl -x -wS $0 ${1+"$@"}'
  if 0;
$|++;
package TsvWord;
use lib "lib";
use common::sense;
use Nobody::Util;
use TsvRect;
use autodie;
use Nobody::PP;
our(@VERSION) = qw( 0 1 0 );
use Tsv;
our(@ISA)=qw(Tsv);
our($DEBUG);
BEGIN {
  *DEBUG=\$Tsv::DEBUG;
  undef &head;
};
sub rect {
  my($self)=$_[0];
  $self->{rect};
};
sub level {
  my($self)=shift;
  return $self->{level};
};
BEGIN {
  no strict 'refs';
  for my $n(qw( y1 y2 x1 x2 dx xy cx xy )){
    *{$n}=sub { shift->rect->$n(@_) };
  }
};
my(@bad);
sub new {
  local(@_)=@_;
  die "usage: TsvWord->new(attrs)" unless @_==2;
  my($class)=class(shift);
  my(%data)=map { %$_ } shift;
  my($self)={ %data };
  $self->{rect}=TsvRect->new( \%data );
  if($self->{level}==5) {
    unless($self->{text} =~ /\S/){
      push(@bad,$self);
      return undef;
    };
  };
  bless($self,$class);
  $self;
};
sub keys {
  return qw( text rect level );
};
sub text {
  return shift->{text};
};
1;
