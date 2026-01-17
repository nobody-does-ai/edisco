package TsvFile;
use lib 'lib';
use Nobody::Util;
use common::sense;
our(@ISA)=qw(Tsv);
use vars qw( $d $y $q $p $e );
use TsvUtil qw(tsv_parse);
use TsvWord;
our(%page);
our($DEBUG);
*DEBUG=\$Tsv::DEBUG;
use overload (
  q{""}    => 'tostring',
);
sub new {
  local(@_)=@_;
  say loc(join("",__PACKAGE__,"::new(".main::pp(@_).")")) if $DEBUG>=2;
  my($class)=shift;
  unshift @_, "path" if @_==1;
  my $self=$class->SUPER::new(@_);
  die "no path" unless defined $self->path;
  for($self->{word}){
    $_=tsv_parse($self->{path}) unless defined;
  };
  bless($self,$class);
}
sub lines {
  my($self)=shift;
  $self->{path}->lines;
};
sub rect {
  my($self)=$_[0];
  $self->{rect};
};
sub path {
  my($self)=$_[0];
  $self->{path};
};
sub part {
  my($self)=$_[0];
  my(@part)=@{$_[0]->{part}};
  return \@part unless @_;
  return map { $part[$_] } @_;
};
sub tostring {
  local(@_)=@_;
  my($self)=shift;
  my($part)=$self->{part};
  my(@part)=@$part;
  return sprintf("%s/%s-%s-%03d.tsv",@part);
};
#    sub selfpp {
#      sprintf "%s(%s)", ref($_[0]), $_[0]->tostring;
#    };
1;
