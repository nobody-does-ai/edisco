package TsvRect;
use common::sense;
use Tsv;
use Rosetta;
our(@ISA)=qw(TSV);
use common::sense;
use Nobody::PP qw(pp);
use Nobody::PP;
{
  package U;
  use Carp::Always;
  use Nobody::PP qw(loc);
  use Nobody::Util;
  use Carp qw(carp cluck croak confess);
};
use Exporter qw(import);
our(@ISA)=qw(Tsv);
our($DEBUG);
*DEBUG=\$Tsv::DEBUG;
our(@prim);
#    BEGIN {
#      for my $a(keys %Rosetta::key){
#        next unless exists $Rosetta::key{$a}{perl};
#        $xkey{$a}=$Rosetta::key{$a};
#        $key{$a}=$Rosetta::key{$a}{perl};
#      };
#      @xkey=@Rosetta::spec;
#    }
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
our(%key);
BEGIN {
  *key=\%Rosetta::key;
};
sub new {
  local(@_)=@_;
  my($save)=U::pp(\@_);
  my($class)=U::class(shift);
  @_ = U::flatten(@_);
  @_ = map { $key{$_}{perl} or $_ } @_;
  my(%tmp)=@_;
  for( [ qw(dx x1 x2) ], [ qw(dy y1 y2) ] ) {
    my($d,$a,$b)=map { \$tmp{$_} } @$_;
    my($t)=delete $tmp{$_->[0]};
    $d=\$t;
    for(0 .. 1) {
#          U::eex( \%tmp, 0+$$a, 0+$$b, 0+$$d );
      if(defined($$d)){
        if(defined($$a)) {
          if(defined($$b)) {
            die "$$a+$$d!=$$b" unless $$a+$$d==$$b;
#                U::eex("$$a-$$d==$$b");
          } else {
            $$b=$$a+$$d;
          }
        } elsif(defined($$b)) {
          $$a=$$b-$$d;
        } else {
          die "too few values: ", pp(\%tmp);
        };
      } elsif (defined($$a) and defined($$b)) {
        $$d=$$b-$$a;
      } else {
        eex(\%tmp);
        die "too few values: ", pp(\%tmp);
      };
#          U::eex( \%tmp, 0+$$a, 0+$$b, 0+$$d );
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
  my(%xlat)=do {
    @_=map { @$_, reverse @$_ } map { [ $key{$_}{perl}, $key{$_}{tsv} ]  } qw(dx dy x1 x2 y1 y2);
  };
  for(map { $xlat{$_} } grep { defined } map { $xlat{$_} } keys %{$hash}) {
    $hash{$xlat{$_}}=delete $hash->{$_};
  };
  $class->new(%hash);
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
#        U::eex(\@_);
    $rect{x1}=U::min(map{$_->x1}grep{defined}@_);
    $rect{y1}=U::min(map{$_->y1}grep{defined}@_);

    $rect{x2}=U::max(map{$_->x2}grep{defined}@_);
    $rect{y2}=U::max(map{$_->y2}grep{defined}@_);

    my($self)=$class->new(\%rect);
#        U::eex(\@_,$self);
    $self;
  };
};
sub rect {
  return shift;
};
sub cy {
  die "usage: \$r->cy" unless @_==1;
  my($self)=shift;
  ($self->y1+$self->y2)/2;
};
sub cx {
  die "usage: \$r->cy" unless @_==1;
  my($self)=shift;
  ($self->x1+$self->x2)/2;
};
#    use overload (
#      q{""}    => 'tostring',
#    );
#    sub tostring {
#      local(@_)=@_;
#      my($self)=shift;
#      local(@_)=qw(x1 cx x2 y1 cy y2);
#      for(@_){
#        $_=[$_,$self->$_]
#      };
#      for(@_){
#        if($_->[0] =~ m{c}) {
#          $_=sprintf("%3s => %6.1f", @$_);
#        } else {
#          $_=sprintf("%3s => %6d", @$_);
#        };
#      };
#      my($txt)=join(", ",@_);
#      join(" ","{",$txt,"}");
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
  my($r1)=TsvRect->new({x1=>10,x2=>20,y1=>30,y2=>50});
  die "failed: ", pp($r1) unless (
    $r1->x1 == 10 and $r1->x2 == 20
      and
    $r1->y1 == 30 and $r1->y2 == 50
      and
    $r1->dx == 10 and $r1->dy == 20
  );
#      eex($r1);
  my($r2)=TsvRect->new({x1=>110,x2=>120,y1=>130,y2=>150});
  die "failed: ", pp($r2) unless (
    $r2->x1 == 110 and $r2->x2 == 120
      and
    $r2->y1 == 130 and $r2->y2 == 150
      and
    $r2->dx == 10 and $r2->dy == 20
  );
  my($r3)=TsvRect->union($r1,$r2);
  die "failed: ", pp($r3, $r3->cx, $r3->cy) unless (
    $r3->x1 == 10 and $r3->x2 == 120
      and
    $r3->y1 == 30 and $r3->y2 == 150
      and
    $r3->dx == 110 and $r3->dy == 120
      and
    $r3->cx == 65  and $r3->cy == 90
  );
  ($r3)=TsvRect->new({x1=>1,dx=>9,y1=>1,dy=>19});
  die "failed: ", pp($r3, $r3->cx, $r3->cy) unless (
    $r3->x1 == 1 and $r3->x2 == 10
      and
    $r3->y1 == 1 and $r3->y2 == 20
      and
    $r3->dx == 9 and $r3->dy == 19
      and
    $r3->cx == 5.5  and $r3->cy == 10.5
  );
  ($r3)=TsvRect->new({x2=>10,dx=>9,y2=>20,dy=>19});
  die "failed: ", pp($r3, $r3->cx, $r3->cy) unless (
    $r3->x1 == 1 and $r3->x2 == 10
      and
    $r3->y1 == 1 and $r3->y2 == 20
      and
    $r3->dx == 9 and $r3->dy == 19
      and
    $r3->cx == 5.5 and $r3->cy == 10.5
  );
#      ($r3)=TsvRect->new({x1=>10,cx=>20,y1=>20,cy=>20});
#      die "failed: ", pp($r3) unless (
#        $r3->x1 == 1 and $r3->x2 == 10
#          and
#        $r3->y1 == 1 and $r3->y2 == 20
#          and
#        $r3->dx == 9 and $r3->dy == 19
#      );
#      eex($r3);
#      ($r3)=TsvRect->new({x1=>10,cx=>20,y1=>20,cy=>20});
#      die "failed: ", pp($r3) unless (
#        $r3->x1 == 1 and $r3->x2 == 10
#          and
#        $r3->y1 == 1 and $r3->y2 == 20
#          and
#        $r3->dx == 9 and $r3->dy == 19
#      );
#      eex($r3);
};
unless(caller) {
  exec "vi-perl", "bin/tsv-pg";
} 
1;

