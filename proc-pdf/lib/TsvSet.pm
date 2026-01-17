package TsvSet;
use lib 'lib';
use Nobody::Util;
use common::sense;
use TsvFile;
our(@ISA)=qw(Tsv);
use TsvUtil qw(tsv_parse);
use vars qw($coder);
*coder=\$Tsv::coder;
*DEBUG=\$Tsv::DEBUG;
use overload (
  q{""}    => 'tostring',
);

sub new {
  local(@_)=@_;
  my(%self)=@_[1..$#_];
  my($self)=$_[0]->SUPER::new(@_);
  for($self->{path}){
    $_//=path(".");
  };
  unless($self->{files}){
    my(%files);
    $self->{files}=\%files;
    my(@tsv)=sort $self->{path}->child("tsv")->children(m{.tsv$});
    for(@tsv) {
      my($year,$q,$p)=m{(\d\d\d\d)-(Q\d)-(\d\d\d).tsv};
      $files{$year}{$q}{$p}=TsvFile->new({path=>$_});
    };
  };
  $self; 
};
sub load {
  my($self)=$_[0]->new;
  $self->FR_JSON;
  $self;
};
sub store {
  local(@_)=@_;
  my($self)=shift;
  my($path);
  $path=path(shift) if @_;
  $path//=$self->{path};
  $path->touchpath->spew($coder->encode($self));
};
sub files {
  return shift->{files};
};
sub tsv {
  my($self)=shift;
  my(%res);
  my($tsv)=$self->files;
  for my $y(keys %$tsv){
    my($Y)=$tsv->{$y};
    for my $q(keys %$Y){
      my($Q)=$Y->{$q};
      for my $p(keys %$Q) {
        my($P)=$Q->{$p};
        say $P;
      }
    };
  };
};
sub words {
  my($self)=shift;
  my(@hash,@words) = $self->{files};
  while(@hash) {
    my($hash)=shift(@hash);
    for my $key(sort keys %{$hash}){
      my($val)=$hash->{$key};
      if(ref($val)eq'HASH'){
        for my $key(sort keys %{$hash}){
          my($val)=$hash->{$key};
          push(@hash,$val);
        };
      }
    };
  };
  \@words;
};
sub tostring {
  my($self)=shift;
  return ref($self)."()";
};
