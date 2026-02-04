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
our(@prim,@head);
INIT {
  @head=qw( top left width height );
  @prim = ( "x1 l left", "x2 r right", "y1 t top", "y2 b bottom" );
  for(@prim) {
    my(@s)=split;
    my($s)=$s[0];
    for(@s) {
      $key{$_}=$s for@s;
      $key{$s}=$s;
    };
  };
  $key{$_}="dx" for qw( w width dx );
  $key{$_}="dy" for qw( h height dy );
};
sub dx {
  die "usage: \$r->dx" unless @_==1;
  my($self)=shift;
  $DB::single++ if $DEBUG;
  return $self->x2-$self->x1;
};
sub dy {
  die "usage: \$r->dy" unless @_==1;
  my($self)=shift;
  $DB::single++ if $DEBUG; return $self->y2-$self->y1;
};
sub be_defined {
  my($self)=shift;
  my($v)=shift;
  return $v if defined $v;
  my($text)=U::pp({%{$self}});
  die "not defined ($text,$v)";
};
sub x1 {
  my($self)=shift;
  die "not a setter" if @_;
  $self->be_defined( $self->{x1} );
};

sub x2 {
  my($self)=shift;
  die "not a setter" if @_;
  $self->{x2}=shift if @_;
  $self->be_defined( $self->{x2} );
};

sub y1 {
  my($self)=shift;
  die "not a setter" if @_;
  $self->{y1}=shift if @_;
  $self->be_defined( $self->{y1} );
};

sub y2 {
  my($self)=shift;
  die "not a setter" if @_;
  $self->{y2}=shift if @_;
  $self->be_defined( $self->{y2} );
};

BEGIN {
  *l=\&x1; *left=\&x1;
  *r=\&x2; *right=\&x2;
  *t=\&y1; *top=\&y1;
  *b=\&y2; *bottom=\&y2;
};
BEGIN {
  *w=\&dx; *width=\&dx;
  *h=\&dy; *height=\&dy;
};
sub new {
  local(@_)=@_;
  my($save)=U::pp(\@_);
  my($class)=U::class(shift);
  @_ = U::flatten(@_);
  @_ = map { $key{$_} or $_ } @_;
  my(%tmp)=@_;
  for( [ qw(dx x1 x2) ], [ qw(dy y1 y2) ] ) {
    my($d,$a,$b)=@$_;
    if(defined($tmp{$d})){
      $d=delete $tmp{$d};
      if(defined($tmp{$a})) {
        if(defined($tmp{$b})) {
          die "$tmp{$a}+$d!=$tmp{$b}" unless $tmp{$a}+$d==$tmp{$b};
        } else {
          $tmp{$b}=$tmp{$a}+$d;
        }
      } elsif(defined($tmp{$b})) {
        $tmp{$a}=$tmp{$b}-$d;
      }
    } elsif (defined($tmp{$a})) {
      $tmp{$b}=$tmp{$a};
    };
  };
  my($self)={%tmp};
  bless($self,$class);
  $self->be_defined($self,$self->{$_}) for keys %$self;
  $self;
};
sub take_data {
  my($class)=U::class(shift);
  my($hash)=shift;
  my(%hash);
  for(keys %$hash) {
    my($rep)=$key{$_};
    next unless defined $rep;
    $hash{$rep}=delete $hash->{$_};
  };
  return () unless keys %hash;
  die "could not find stuff" unless keys(%hash)==4;
  $class->new(\%hash);
};
sub nsort {
  return sort { $a <=> $b } @_;
};
sub union {
  my($class)=shift;
  if(ref($class)){
    TsvRect->union($class,@_);
  } else {
    my(%rect);
    $rect{x1}=U::min(map{$_->x1}grep{defined}@_);
    $rect{y1}=U::min(map{$_->y1}grep{defined}@_);

    $rect{x2}=U::max(map{$_->x2}grep{defined}@_);
    $rect{y2}=U::max(map{$_->y2}grep{defined}@_);

    bless(\%rect,$class);
  };
};
sub rect {
  return shift;
};
sub cy {
  die "usage: \$r->cy" unless @_==1;
  my($self)=shift;
  int(($self->y1+$self->y2)/2);
};
sub cx {
  die "usage: \$r->cy" unless @_==1;
  my($self)=shift;
  int(($self->x1+$self->x2)/2);
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
  my(%d);
  @d{ qw(x1 y1 dx dy ) } = sort {$a<=>$b} map { 200+int(rand(200)) } 0 .. 3;
  my($r);
  eex(\%d);
  ($r)=TsvRect->new(%d);
  eex($r);
  $d{x2}=$r->x2;
  $d{y2}=$r->y2;
  eex(\%d);
  ($r)=TsvRect->new(%d);
  eex($r);
  $d{x2}=$r->x2;
  $d{y2}=$r->y2;
};
1;
