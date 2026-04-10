package TsvRect;
use common::sense;
our(%key);
use Carp qw(carp cluck croak confess);
use Carp::Always;
use Exporter qw(import);
use Nobody::PP qw(loc);
use Nobody::Util;
use Tsv;
our(@ISA)=qw(Tsv);
use common::sense;
our($DEBUG);
*DEBUG=\$Tsv::DEBUG;
our(@prim,%key,@head,%head);
our(%key);
BEGIN {
  @head=qw( top left width height );
  $_=1 for @head{+@head};
};
sub dx {
  my($self)=shift;
  die "usage: rect->dx()" if(@_);
  return $self->{x2}-$self->{x1};
};
sub dy {
  my($self)=shift;
  die "usage: rect->dy()" if(@_);
  return $self->{y2}-$self->{y1};
};
sub x1 {
  my($self)=shift;
  die unless $self->isa("TsvRect");
  $self->{x1}=shift if @_;
  return $self->{x1};
};
sub x2 {
  my($self)=shift;
  die unless $self->isa("TsvRect");
  $self->{x2}=shift if @_;
  return $self->{x2};
};
sub y1 {
  my($self)=shift;
  die unless $self->isa("TsvRect");
  $self->{y1}=shift if @_;
  return $self->{y1};
};
sub y2 {
  my($self)=shift;
  die unless $self->isa("TsvRect");
  $self->{y2}=shift if @_;
  return $self->{y2};
};

BEGIN {
  @prim = ( "x1 l left", "x2 r right", "y1 t top", "y2 b bottom" );
  for(@prim) {
    my(@s)=split;
    my($s)=$s[0];
    for(@s) {
      $key{$_}=$s for@s;
    };
  };
  *l=\&x1; *left=\&x1;
  *r=\&x2; *right=\&x2;
  *t=\&y1; *top=\&y1;
  *b=\&y2; *bottom=\&y2;
};
our(%del);
BEGIN {
  %del=(
    dx=>[qw( x1 x2 )],
    dy=>[qw( y1 y2 )],
  );
  $key{$_}="dx" for qw( w width dx );
  $key{$_}="dy" for qw( h height dy );
  *w=\&dx; *width=\&dx;
  *h=\&dy; *height=\&dy;
};
our(%rect);
sub new {
  local(@_)=@_;
  die "usage: TsvRect->new({})" unless @_==2 and (
    $_[0]->isa("TsvRect") and ref($_[1])eq'HASH'
  );
  my($class)=class(shift);
  my(%tmp);
  {
    local(*rect)=shift;
    for my $f(keys %rect) {
      my($t)=$key{$f};
      next unless length($t);
      $tmp{$t}=delete $rect{$f};
    };
  };

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
};
sub nsort {
  return sort { $a <=> $b } @_;
};
sub union {
  local(@_)=@_;
  my($self)=$_[0];
  shift unless ref($self);
  my(@v,@h);
  @_=map { $_->rect } @_;
  for(@_) {
    ddx($_);
    push(@h,$_->left,$_->right);
    push(@v,$_->top,$_->bottom);
    ddx([\@h,\@v]);
  };
  @h=nsort(@h);
  @v=nsort(@v);
  return TsvRect->new({ 
      left=>shift @h, top=>shift @v, right=>pop @h, bottom=>pop @v 
    });
};
sub clone {
  return class($_[0])->new(%{$_[0]});
};
sub rect {
  return shift;
};
sub tostring {
  local(@_)=@_;
  my($self)=shift;
  for(@_){
    $_=[$_,$self->$_]
  };
  $_="";
  while(!ref($_[0])) {
    for(@$_) {
      push(@_,$_,$self->{$_});
    };
    push(@_,{shift,undef, shift,undef});
  };
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
  return map { $_, $self->$_ } qw( left top right bottom );
};
sub key {
  my($self)=shift;
  my($key)=shift;
  if(exists $key{$key}) {
    return $key{$key};
  };
  die "bad key: $key";
};
sub keys {
  return qw(x1 y1 x2 y2);
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
