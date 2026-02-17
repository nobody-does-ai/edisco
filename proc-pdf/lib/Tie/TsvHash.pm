package Tie::TsvHash;
use lib "gather";
use lib "lib";
use Tie::Hash;
use Nobody::Util;
use Nobody::PP;
our(@ISA)=qw(Tie::ExtraHash);
use subs qw( pp eex class );
require Carp;
use Carp @Carp::EXPORT_OK;
use vars qw( $debug );
use feature qw(state say);
use TsvDoc;
sub import {
#      cluck("import: ", pp(\@_));
};
sub key {
  state(%key);
  unless(%key) {
    my(%n) =(
      txt=>[ qw{ text chr char token value glyph } ],
      cx=>[ qw( x x_center xcenter ) ],
      cy=>[ qw( y y_center ycenter ) ],
      dx=>[ qw( dx width w ) ],
      dy=>[ qw( dy height h ) ],
      x1=>[ qw( left l ) ],
      x2=>[ qw( right r ) ],
      y1=>[ qw( top ) ],
      y2=>[ qw( bottom b ) ],
    );
    my(@p);
    my(%k) = map { $_=>$_ } keys %n;
    for my $n(keys %n) {
      for (@{$n{$n}}) {
        next if $_ eq $n;
        die "key collision!  call a locksmith! k=$n, a=$_" if defined $k{$_};
        $k{$_}=$n
      };
    };
#        if(safe_isa("TsvDoc","TsvDoc")) {
      my(@hdr)=@{TsvDoc->hdr()};
      for my $i(keys @hdr){
        my($k)=$hdr[$i];
        local(@_)=split(m{_(num)},$k);
        if(@_==2) {
          $k{$k}=$_[0];
          $k=$_[0];
        };
        $k{$k}//=$k;
        die "key collision!  call a locksmith! k=$k v=$k{$k}" if defined ($k{$i});
        $k{$i}=$k{$k};
#            eex($i, $k, "$k{$k}", $k{$i});
      };
#        }
    for(keys %k) {
      die "$k{$_}!=$k{$k{$_}} ($_ $k{$_} $k{$k{$_}}" unless $k{$_} eq $k{$k{$_}};
    };
    %key=%k;
#        local($debug)=1;
    eex({key=>\%key}) if $debug;
  };
  if(@_) {
    local($_)=shift;
    $key{$_}//=$_;
  } else {
    \%key;
  };
};
sub TIEHASH
{
  my(@in)=@_;
  local(@_)=@_;
  my($c)=class(shift);
  my $h = bless [{}], $c;
  while(@_) {
    $_=shift;
    if(ref($_) eq 'HASH'){
      unshift(@_,%{$_});
    } elsif(ref($_) eq 'ARRAY'){
      unshift(@_,@$_);
    } elsif(ref($_)) {
      die "unexpected ref: $_", pp(@_);
    } elsif ( @_ ) {
      #            eex(ref($h),$h);
      $h->STORE($_,shift);
    } else {
      die "key with no value: '".pop(@in)."'", pp({in=>\@in});
    };
  };
  $h;
}
sub STORE
{
  $_[1]=key($_[1]);
  $_[0][0]{$_[1]} = $_[2]//"";
}
sub FETCH
{
  (my $tmp, $_[1])=($_[1],key($_[1]));
  local($_)=$_[0][0]{$_[1]};
  die "no value for $_[1]", pp('FETCH',{i=>$tmp,k=>$_[1]},\@_) unless defined;
  $_;

}
sub DELETE
{
  $_[0]->FETCH($_[1]);
  delete $_[0][0]->{$_[1]}
}
1;
