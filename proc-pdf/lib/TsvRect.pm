package TsvRect;
use common::sense;
use Tsv;
our(@ISA)=qw(TSV);
use common::sense;
{
  package U;
  use Carp::Always;
  use Nobody::PP qw(loc);
  use Nobody::Util;
  use Carp qw(carp cluck croak confess);
};
use Exporter qw(import);
our(%key);
our(@ISA)=qw(Tsv);
our($DEBUG);
*DEBUG=\$Tsv::DEBUG;
our(@prim,@head,%head);
BEGIN {
  @head=qw( top left width height );
  $_=1 for @head{+@head};
};
sub dx {
  my($self)=shift;
  if(@_) {
    my($odx)=$self->dx;
    my($ndx)=shift;
    my($cdx)=($odx-$ndx); 
    my($ox1,$ox2,$nx1,$nx2);
    $ox1=$self->x1;
    $ox2=$self->x2;
    $nx1=$ox1+$cdx/2;
    $nx2=$ox2-$cdx/2;
  };
  return $self->{x2}-$self->{x1};
};
sub dy {
  my($self)=shift;
  if(@_) {
    my($new)=0.5*shift;
    $new=-$new if $new<0;
    my($avg)=0.5*($self->{y1}+$self->{y2});
    $self->{y1}=int($avg-$new);
    $self->{y2}=int($avg+$new);
  };
  return $self->{y2}-$self->{y1};
};
sub be_defined {
  my($self)=shift;
  my($v)=shift;
  return $v if defined $v;
  die "not defined";
};
sub x1 {
  my($self)=shift;
  die unless $self->isa("TsvRect");
  die "not a setter" if @_;
  $self->{x1}=shift if @_;
  $self->be_defined( $self->{x1} );
};

sub x2 {
  my($self)=shift;
  die "not a setter" if @_;
  $self->{x2}=shift if @_;
  $self->{x2};
  $self->be_defined( $self->{x2} );
};

sub y1 {
  my($self)=shift;
  die "not a setter" if @_;
  $self->{y1}=shift if @_;
  $self->{y1};
  $self->be_defined( $self->{y1} );
};

sub y2 {
  my($self)=shift;
  die "not a setter" if @_;
  $self->{y2}=shift if @_;
  $self->be_defined( $self->{y2} );
};

BEGIN {
  @prim = ( "x1 l left", "x2 r right", "y1 t top", "y2 b bottom" );
  for(@prim) {
    my(@s)=split;
    my($s)=$s[0];
    for(@s) {
      $key{$_}=$s for@s;
      $key{$s}=$s;
    };
  };
  *l=\&x1; *left=\&x1;
  *r=\&x2; *right=\&x2;
  *t=\&y1; *top=\&y1;
  *b=\&y2; *bottom=\&y2;
};
BEGIN {
  $key{$_}="dx" for qw( w width dx );
  $key{$_}="dy" for qw( h height dy );
  *w=\&dx; *width=\&dx;
  *h=\&dy; *height=\&dy;
};
sub new {
  local(@_)=@_;
  my($class)=U::class(shift);
  @_ = map { (ref eq 'ARRAY')?(@$_):($_) } @_;
  @_ = map { (ref eq 'HASH') ? %$_ : $_ } @_;
  @_ = map { $key{$_} or $_ } @_;
  my(%tmp)=@_;
  for( [ qw(dx x1 x2) ], [ qw(dy y1 y2) ] ) {
    my($d,$a,$b)=@$_;
    if(defined($tmp{$d})){
      if(defined($tmp{$a})){
        $tmp{$b}=$tmp{$a}+delete $tmp{$d};
      } elsif(defined($tmp{$b})){
        $tmp{$a}=$tmp{$b}-delete $tmp{$d};
      } else {
        die pp(\%tmp);
      };
    };
  };
  my($self)={%tmp};
  bless($self,$class);
  $self;
};
sub nsort {
  return sort { $a <=> $b } @_;
};
sub union {
  local(@_)=grep{defined}@_;
  my($self)=$_[0];
  shift unless ref($self);
  my(@v,@h);
  @_=map { $_->rect } @_;
  for(@_) {
    unless(defined($_->{x1})){
      U::confess(U::pp($self,\@v,\@h,\@_));
    };
    push(@h,$_->left,$_->right);
    push(@v,$_->top,$_->bottom);
  };
  @h=nsort(@h);
  @v=nsort(@v);
  return TsvRect->new({ 
      left=>shift @h, top=>shift @v, right=>pop @h, bottom=>pop @v 
    });
};
sub clone {
  return U::class($_[0])->new(%{$_[0]});
};
sub rect {
  return shift;
};
sub cy {
  die "usage: \$r->cy" unless @_==1;
  return int(U::sum(map { $_[0]->$_ } qw(y1 y2))/2); 
};
sub cx {
  local(@_)=@_;
  die "usage: \$r->cx" unless @_==1;
  my($self)=shift;
  (U::sum(map { $self->$_ } qw(x1 x2))/2); 
};
use overload (
  q{""}    => 'tostring',
);
sub tostring {
  local(@_)=@_;
  my($self)=shift;
  local(@_)=qw(x1 cx x2 y1 cy y2);
  for(@_){
    $_=[$_,$self->$_]
  };
  for(@_){
    if($_->[0] =~ m{c}) {
      $_=sprintf("%3s => %6.1f", @$_);
    } else {
      $_=sprintf("%3s => %6d", @$_);
    };
  };
  my($txt)=join(", ",@_);
  join(" ","{",$txt,"}");
};
sub horz {
  my($self)=shift;
  return ($self->top, $self->bottom);
};
sub vert {
  my($self)=shift;
  return ($self->left, $self->right);
};
sub lwth {
  my($self)=shift;
  return map { $_, $self->$_ } qw( left width top height );
};
sub ltrb {
  my($self)=shift;
  return map { $_, $self->$_ } qw( x1 y1 x2 y2 );
};
sub key {
  my($self)=shift;
  my($key)=shift;
  if(exists $key{$key}) {
    return $key{$key};
  };
  die "bad key: $key";
};
unless(caller){
  package main;
  use Nobody::Util;
  TsvRect::import("main");
  my(%d) = map { $_, int(rand(20)) } qw( x1 x2 y1 y2 );
  $d{y2}+=40;
  $d{x2}+=40;
  my($rect)=TsvRect->new( \%d );
};
1;
