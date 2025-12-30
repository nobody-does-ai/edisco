#!/usr/bin/perl
BEGIN { open(STDOUT,">&STDERR"); };
# vim: ts=2 sw=2 ft=perl
eval 'exec perl -x -wS $0 ${1+"$@"}'
  if 0;
$|++;
package TsvWord;
use lib "lib";
use common::sense;
use TsvRect;
use autodie;
use Nobody::Util;
use Nobody::PP;
our(@VERSION) = qw( 0 1 0 );
use Tsv;
our(@ISA)=qw(Tsv);
our($DEBUG);
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
  my($class)=class(shift);
  my(%data)=map { %$_ } shift;
  my(%rect);
  for(qw(left top width height)){
    $rect{$_}=delete$data{$_};
  };
  my($self)={ %data };
  $self->{rect}=TsvRect->new( %rect );
  bless($self,$class);
};
sub from {
  use Carp qw( croak cluck carp confess );
  local(@_)=@_;
  my($class)=class(shift);
  for(@_) {
    next if(safe_isa($_,'TsvWord'));
    die "???" unless ref($_) eq "HASH";
    $_=TsvWord->new($_);
  };
  return @_;
};
sub text {
  return shift->{text};
};
#    sub tostring {
#      local(@_)=@_;
#      my($self)=shift;
#      return pp(%{ %$self });
#    };
#    sub selfpp {
#      say loc(join("",__PACKAGE__,"::new(".pp(@_).")")) if $DEBUG>=-1;
#      local(@_)=@_;
#      my($self)=shift;
#      join("",
#        sprintf("%s(%s){", ref($self), $self->tostring),
#        "\n  ",
#        pp({%$self}),
#        "\n}",
#        "\n");
#    };
unless(caller) {
  my (@lines);# = map {m{\S}?[split]:() } split m{\n}, q{
#      level	page_num	block_num	par_num	line_num	word_num	left	top	width	height	conf	text
#      1	1	0	0	0	0	0	0	1275	1650	-1	
#      };
  my($path)=path([glob("tsv/*.tsv")]->[0]);
  @lines=map { join(" ", split) } $path->lines;
};
1;
