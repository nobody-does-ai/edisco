package TsvFile;
use lib 'lib';
use Nobody::Util;
use TsvGroup;
use common::sense;
our(@ISA)=qw(TsvGroup);
use vars qw( $d $y $q $p $e );
use TsvUtil qw(tsv_parse);
use TsvWord;
our(%page);
our($DEBUG);
*DEBUG=\$Tsv::DEBUG;
sub new {
  local(@_)=@_;
  my($class)=shift;
  my($path)=shift;
  my $self=$class->SUPER::new($path,tsv_parse($path));
  $self->{path}=$path;
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
#    sub selfpp {
#      sprintf "%s(%s)", ref($_[0]), $_[0]->tostring;
#    };
1;
