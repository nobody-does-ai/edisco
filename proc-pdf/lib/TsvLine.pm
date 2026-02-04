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
*vsort=\&U::vsort;
sub new {
  local(@_)=@_;
  my($class)=shift;
  my(@word)=map { U::safe_isa($_[$_],'TsvWord')?delete($_[$_]):() } 0 .. $#_;
  my($self)=$class->SUPER::new(@_);
  $self->{text}=\@word;
  #U::eex($self->word);
  #U::eex($self);
  #U::eex($self);
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
  my(%ref);
  for(map { ref } @_ ){
    $ref{$_}++;
  };
  @_=grep { defined and  $_->level == 5 } @_;
  @_=vsort @_;
  my(@line);
  while(@_){
    my(@tmp)=TsvUtil::group_find(\@_);
    push(@line,TsvLine->new(@tmp));
  };
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
sub text {
  my($self)=$_[0];
  if(defined($_[1])) {
    return map { $_->text } grep { defined } $self->word($_[1]);
  } else {
    local(@_)=map { ref($_)?$_->text:$_ } @{$self->{text}};
    return join("\n    ",split(" \n ",join(" ",@_)));
  };
};
1;
