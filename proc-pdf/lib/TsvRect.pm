package TsvRect;
use common::sense;
use Scalar::Util qw(refaddr);
BEGIN { open(STDOUT,">&STDERR"); };
BEGIN {
  use FindBin qw($Script $Bin);
  use lib "$Bin/../lib";
};
our(%key);
BEGIN {
  say refaddr \%key;
  say refaddr \%LimHash::key;
  *LimHash::key=\%key;
};
use Tsv;
use Exporter qw(import);
use common::sense;
use Carp::Always;
use Nobody::PP qw(loc);
use Nobody::Util;
use Carp qw(carp cluck croak confess);
use LimHash;
our(@ISA)=qw(LimHash Tsv);
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
  if(@_) {
    my($odx)=$self->dx;
    my($ndx)=shift;
    my($cdx)=($odx-$ndx); 
    my($ox1,$ox2,$nx1,$nx2);
    $ox1=$self->x1;
    $ox2=$self->x2;
    $nx1=$ox1+$cdx/2;
    $nx2=$ox2-$cdx/2;
    eex([
        [ odx=>$odx,ndx=>$ndx,cdx=>$cdx, ],
        [ ox1=>$ox1,nx1=>$nx1, ],
        [ ox2=>$ox2,nx2=>$nx2, ],
      ]);
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
  $self->{x1}=shift if @_;
   $self->be_defined( $self->{x1} );
};

 sub x2 {
   my($self)=shift;
   $self->{x2}=shift if @_;
  $self->{x2};
   $self->be_defined( $self->{x2} );
 };

 sub y1 {
   my($self)=shift;
   $self->{y1}=shift if @_;
  $self->{y1};
   $self->be_defined( $self->{y1} );
 };

 sub y2 {
   my($self)=shift;
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
sub new {
  local($DEBUG)=2;
  local(@_)=@_;
  my($class)=class(shift);
  @_=map { (ref eq 'ARRAY')?(@$_):($_) } @_;
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
use overload (
  q{""}    => 'tostring',
);
sub tostring {
  local(@_)=@_;
  my($self)=shift;
  for(@_){
    $_=[$_,$self->$_]
  };
  ddx(\$_,\@_);
  $_="";
  while(!ref($_[0])) {
    for(@$_) {
      push(@_,$_,$self->{$_});
    };
    push(@_,{shift,undef, shift,undef});
  };
  for(flatten(@_)){
    say ref($_), $_ ;
  };
  ddx(\@_);
  eex( join(" * ", map { pp($_) } map { m{^([a-z])[a-z]+$} || $_ } @_) );
};
#    sub selfpp {
#      return sprintf("%s(%s)",ref($_[0]),$_[0]->tostring);
#    };
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
unless(caller){
  package main;
  use Nobody::Util;
  TsvRect::import("main");
  my(%d) = map { $_, int(rand(20)) } qw( x1 x2 y1 y2 );
  $d{y2}+=40;
  $d{x2}+=40;
  my($rect)=TsvRect->new( \%d );
  ddx( $rect );
  say $rect->dx;
  say $rect->dx($rect->dx/2);
  ddx( $rect );
};
1;
