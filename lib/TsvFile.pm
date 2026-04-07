package TsvFile;
use lib 'lib';
use Nobody::Util;
use TsvGroup;
use common::sense;
use Path::Tiny;
our(@ISA)=qw(TsvGroup);
use vars qw( $d $y $q $p $e );
use TsvUtil;
use TsvWord;
our($file);
sub new {
  local(@_)=@_;
  die "usage: class->new({})" unless @_==2 and ref($_[1])=='HASH';
  my($class)=shift;
  my($hash)=shift;
  my $self=$class->SUPER::new($hash);
  $hash->{file}=path($hash->{file});
  bless($self,$class);
  $self->load;
  $self;
}
sub load {
  my($self)=shift;
  local(@_)=$self->{file}->lines;
  @_=map { [ split ] } @_;
  @_=map { TsvWord->new(
};
sub word {
  my($self)=shift;
  return ($self->{word});
};
sub rect {
  my($self)=$_[0];
  $self->{rect};
};
1;
