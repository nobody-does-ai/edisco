package TsvFile;
use lib "../lib";
use common::sense;
use Nobody::Util;
sub json;
use Nobody::JSON qw(json);
use TsvGroup;
use List::Util qw(mesh);
use Path::Tiny;
our(@ISA)=qw(TsvGroup);
use vars qw( $d $y $q $p $e );
use TsvUtil;
use TsvWord;

our($file);
sub new {
  local(@_)=@_;
  unless(@_==2 and $_[1]->isa("Path::Tiny")) {
    die "usage: TsvGroup::new( class hash ) (got: ".pp(@_).")";
  };
  my($class)=shift;
  my($hash)={ file=>shift };
  my $self=$class->SUPER::new($hash);
  eex($self) unless ref($self);
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
  $self->word([ sort { $a->y1 <=> $b->y1 } grep { defined } @_ ]);
  $self;
};
sub rect {
  my($self)=$_[0];
  $self->{rect};
};
1;
