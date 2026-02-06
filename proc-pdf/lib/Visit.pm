#!/usr/bin/perl
package Visit;
use Nobody::Util;
use common::sense;

sub new {
  my ($class)=class($_[0]);
  my $self={};
  $self->{visit}=sub {
    my($self)=$_[0];
    my($code)=$_[2] if @_>2;
    my($ref)=defined?ref:undef;
    $_=$_[1] if @_>1;
    return unless defined;
    my($sub)=$self->can(ref($_)) if ref($_);
    say STDERR pp($sub, $_, ref($_));
    $self->$sub->() if $sub;
  };
  return bless($self,$class);
};

sub HASH {
  my($self)=$_[0];
  $self->visit($_) for values %$_;
};
sub ARRAY {
  my($self)=$_[0];
  $self->visit for @$_;
};
sub SCALAR {
  my($self)=$_[0];
  $self->visit for $$_;
}

unless(caller){
  my($test)={
  };
  my($s);
  my(@a);
  my(%h);
  my($self)={};
  bless($self,__PACKAGE__);
  for(\( $a, @a, %h),$test ){
  };
  for(\( $a, @a, %h),$test ){
    say ref;
    next unless ref;
  };
};
