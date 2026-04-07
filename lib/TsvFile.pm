package TsvFile;
use TsvGroup;
use common::sense;
use List::Util qw(mesh);
use Path::Tiny;
our(@ISA)=qw(TsvGroup);
use vars qw( $d $y $q $p $e );
use TsvUtil;
use TsvWord;
use Nobody::JSON qw( json );

our($file);
sub new {
  local(@_)=@_;
  die "usage: TsvGroup::new( class hash ) (got: ".pp(@_).")" unless @_==2 and ref($_[1]) eq 'HASH';
  my($class)=shift;
  my($hash)=shift;
  my $self=$class->SUPER::new($hash);
  $hash->{file}=path($hash->{file});
  bless($self,$class);
  $self->load;
  $self;
}
sub load {
  local(@_)=@_;
  my($self)=shift;
  local(@_)=$self->{file}->lines;
  @_=map { [ split ] } @_;
  my(@c)=map { @$_ } shift;
  for(@_){
    $_=TsvWord->new({ mesh(\@c,\@$_) });
  };
  @_=sort { $a->y1 <=> $b->y1 } grep { defined } @_;
  for(@_){
    say json->encode(($_));
  };
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
