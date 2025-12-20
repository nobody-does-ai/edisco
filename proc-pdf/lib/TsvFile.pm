package TsvFile;
BEGIN { open(STDOUT,">&STDERR"); };
use lib 'lib';
use TsvGroup;
use common::sense;
our(@ISA)=qw(TsvGroup);
use vars qw( $d $y $q $p $e );
use Nobody::Util;
use TsvUtil qw(tsv_parse);
use TsvPath;
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
  my($path)=shift;
  my $word=tsv_parse($path);
  my $self=$class->SUPER::new($path,$word);
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
unless(caller){
  ddx( map { TsvFile->new($_) } glob("tsv/*.tsv") );
};
1;
