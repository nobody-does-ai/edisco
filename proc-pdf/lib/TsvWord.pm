#!/usr/bin/perl
BEGIN { open(STDOUT,">&STDERR"); };
# vim: ts=2 sw=2 ft=perl
eval 'exec perl -x -wS $0 ${1+"$@"}'
  if 0;
$|++;
package TsvWord;
use lib "lib";
use common::sense;
use Nobody::Util;
use Carp::Always;
use TsvUtil;
use autodie;
use Nobody::PP;
our(@VERSION) = qw( 0 1 0 );
our(@ISA)=qw(Tsv);
our($DEBUG);
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
  my($class)=class(shift);
  my(%data)=map { %$_ } shift;
  my(%rect);
  for(qw(left top width height)){
    $rect{$_}=delete$data{$_};
  };
  for(keys %data){
    delete $data{$_} unless defined $data{$_};
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
    die "???", pp($_) unless ref($_) eq "HASH";
    $_=$class->new($_);
  };
  return @_;
};
#    sub tsv_parse {
#      local(@_)=@_;
#      chomp(@_);
#      $_=[split m{[\t\n]}, @_];
#      my @col=map{@$_}shift(@_);
#      for(@_){
#        my(%tsv);
#        @tsv{@col}=@$_;
#        $_=\%tsv;
#      };
#      (\@col,@_);
#    };
sub hash {
  local(@_)=@_;
  say scalar(@_), " rows";
  if(@cols) {
    local(@_)=map { @$_ } shift;
    die "col mismatch (@_ != @cols)" unless "@_" eq "@cols";
  } else {
    @cols=map { @$_ } shift;
  };
  say scalar(@_), " rows";
  for(@_) {
    local(@_)=@$_;
    $_={ map { $_, shift } @cols };
  };
  say scalar(@_), " rows";
  @_;
};
sub load_file {
  my($self)=shift;
  $self->from($self->parse_file(@_));
};
sub parse_file {
  die "usage: TsvWord->load_file(CLASS->path(\"name\"))" unless (
    @_==2
      and
    $_[0] eq __PACKAGE__
  );
  local(@_)=@_;
  my($class,$file)=@_;
  $file=path($file) unless ref($file);
  @_=hash(map { [split m{[\t\n]}] } $file->lines);
  @_;
};
sub text {
  return shift->{text};
};
1;
