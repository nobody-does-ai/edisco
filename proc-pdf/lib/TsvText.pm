package TsvText;
# vim: ts=2 sw=2 ft=perl
use common::sense;
{
  package U;
  use Nobody::Util;
  use Carp::Always;
  use Carp qw( croak cluck carp confess );
  use TsvWord;
  use TsvUtil;
  use autodie;
  use Nobody::PP;
  our(@VERSION) = qw( 0 1 0 );
  our($DEBUG);
};
our(@ISA)=qw(Tsv);
our(@cols);
BEGIN {
  *DEBUG=\$Tsv::DEBUG;
  undef &head;
};
use overload (
  q{""}    => 'tostring',
);
sub rect {
  my($self)=$_[0];
  $self->{rect};
};
sub level {
  my($self)=shift;
  return $self->{level};
};
sub cx {
  shift->rect->cx(@_);
};
sub cy {
  return undef unless ref $_[0] and ref($_[0]->{rect});;
  shift->rect->cy(@_);
};
sub left {
  shift->rect->left(@_);
}
sub right {
  shift->rect->right(@_);
}
sub height {
  shift->rect->height(@_);
};
sub width {
  shift->rect->width(@_);
};
sub top {
  shift->rect->top(@_);
}
sub bottom {
  shift->rect->bottom(@_);
}
sub pack {
  my($self)=$_[0];
  $self->{rect}=TsvRect->union(map {$_->{rect}} @{$self->word}); 
}
sub tostring {
  my($self)=shift;
  return join(" || ","",$self->top,$self->text,$self->bottom);
};
sub from {
  local(@_)=splice(@_);;
  my($class)=U::class(shift);
  @_=sort { $a->cy <=> $b->cy } grep { defined } @_;
  my(@line);
  while(@_) {
    push(@line,TsvLine->new(U::group_find(\@_)));
  };
  @line;
};
sub page {
  return shift->{page};
};
sub word {
  my($self)=$_[0];
  my($text)=$self->{text};
  return (defined ? $text->[$_] : $text) for $_[1];
};
sub text {
  my($self)=$_[0];
  die ref($self), "did not override text!";
};
1;
