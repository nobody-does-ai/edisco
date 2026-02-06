package TsvLine;
our(@ISA)=qw(TsvText);
# vim: ts=2 sw=2 ft=perl
use common::sense;
{
  package U;
  use Nobody::Util;
  use Carp::Always;
  use Carp qw( croak cluck carp confess );
  use TsvWord;
  use TsvUtil qw( group_find vsort vcmp);
  use autodie;
  use Nobody::PP;
  our(@VERSION) = qw( 0 1 0 );
  our($DEBUG);
};
sub vsort;
*eex=\&U::eex;
*vsort=\&U::vsort;
sub new {
  local(@_)=@_;
  my($class)=shift;
  my(@word)=splice(@_);
  my($rect) = @word[0]->{rect}->clone() if @word;
  my($self)=$class->SUPER::new(rect=>$rect);
  $self->{word}=\@word;
  $self->pack;
  $self;
};
sub pack {
  my($self)=$_[0];
  #  U::eex($self);
  $self->{rect}=TsvRect->union(
    map { U::safe_can($_,'rect') ? $_->rect : $_ }
    ($self->{rect}, @{$self->{text}})
  ); 
  #  for(@{$self->word}){
  #  U::eex $_;
  #};
  $self->{rect};
}
sub from {
  local(@_)=@_;
  my($class)=U::class(shift);
  my(@other)=grep { defined and $_->level != 5 } @_;
  @_=grep { defined and  $_->level == 5 } @_;
  @_=vsort @_;
  my(@line);
  while(@_){
    my(@tmp)=TsvUtil::group_find(\@_);
    push(@line,TsvLine->new(@tmp));
  };
  @line=vsort(@line,@other);
  @line;
};
sub extra {
  local(@_)=@_;
  my($self)=shift;
  my($width)=$self->width;
  my($word)=$self->word;
  for(@$word){
    $width-=($_->width);
  };
  $width;
};
sub load_file {
  my($self)=shift;
  my(@word)=TsvWord->load_file(@_);
  my(@line)=TsvLine->from(@word);
  @line;
};
sub word {
  my($self)=$_[0];
  return $self->{word};
}
sub text {
  my($self)=$_[0];
  "$self";
};
1;
