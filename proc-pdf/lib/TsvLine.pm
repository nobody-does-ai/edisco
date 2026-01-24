package TsvLine;
use lib "lib";
# vim: ts=2 sw=2 ft=perl
use common::sense;
{
  package U;
  use Nobody::Util;
  use Carp::Always;
  use TsvWord;
  use TsvUtil;
  use autodie;
  use Nobody::PP;
  our(@VERSION) = qw( 0 1 0 );
  our($DEBUG);
};
our(@ISA)=qw(TsvWord);
our(@cols);
BEGIN {
  *DEBUG=\$Tsv::DEBUG;
  undef &head;
};
#    use overload (
#      q{""}    => 'tostring',
#    );
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
sub new {
  local(@_)=@_;
  my($class)=ref($_[0])?$_[0]:shift;
  my($word)=shift;
  my(%data)=%$word;
  $data{rect}=$data{rect}->clone;
  $data{text}=[$word];
  $data{rect}=$data{rect}->union(map { $_->rect } @_);
  push(@{$data{text}},@_);
  my($self)=\%data;
  bless($self,$class);
  $self;
};
sub vsort {
  local(@_)=@_;
  @_=map { [ $_->cy, $_->cx, $_ ] } @_;
  @_=sort { $a->[0] <=> $b->[0] or $a->[1] <=> $b->[1]  } @_;
  map { $_->[2] } @_;
};
sub from {
  local(@_)=splice(@_);;
  my($class)=U::class(shift);
  use Carp qw( croak cluck carp confess );
  @_=sort { $a->cy <=> $b->cy } grep { defined } @_;
  my(@line);
  while(@_) {
    push(@line,TsvLine->new(U::group_find(\@_)));
  };
  @line;
};
sub word {
  my($self)=shift;
  my($text)=$self->{text};
  return $text->[shift//0];
};
sub hash {
  local(@_)=@_;
  if(@cols) {
    local(@_)=map { @$_ } shift;
    die "col mismatch (@_ != @cols)" unless "@_" eq "@cols";
  } else {
    @cols=map { @$_ } shift;
  };
  for(@_) {
    local(@_)=@$_;
    $_={ map { $_, shift } @cols };
  };
  @_;
};
sub load_file {
  my($self)=shift;
  $self->from($self->parse_file(@_));
};
sub text {
  my($self)=$_[0];
  local(@_)=map { $_->text } @{$self->{text}};
  return join(" ",@_);
};
1;
