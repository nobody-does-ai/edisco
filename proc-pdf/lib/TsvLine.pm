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
  use TsvUtil;
  use autodie;
  use Nobody::PP;
  our(@VERSION) = qw( 0 1 0 );
  our($DEBUG);
};
sub new {
  local(@_)=@_;
  my($class)=ref($_[0])?$_[0]:shift;
  my($word)=shift;
  my(%data)=%$word;
  $data{text}=[$word];
  push(@{$data{text}},@_);
  my($self)=\%data;
  bless($self,$class);
  $self->pack;
  $self;
};
sub pack {
  my($self)=$_[0];
  $self->{rect}=TsvRect->union(map {$_->{rect}} @{$self->{text}}); 
}
sub from {
  local(@_)=@_;
  my($class)=U::class(shift);
  @_=grep { defined and $_->level == 5 } @_;
  @_=sort { $a->cy <=> $b->cy } @_;
  my(@line);
  while(@_) {
    push(@line,TsvLine->new(U::group_find(\@_)));
  };
  @line;
};
sub word {
  my($self)=$_[0];
  my($text)=$self->{text};
  return (defined ? $text->[$_] : $text) for $_[1];
};
sub load_file {
  my($self)=shift;
  $self->from($self->parse_file(@_));
};
sub text {
  my($self)=$_[0];
  local(@_)=map { $_->text } @{$self->{text}};
  return join(" ",@_);
};
1;
