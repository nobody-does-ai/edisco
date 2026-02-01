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
  my $TEXT=join(" ", map { $_->text } @{$self->word});
  $self->{TEXT}=$TEXT;
  $self->{rect};
}
sub from {
  local(@_)=@_;
  my($class)=U::class(shift);
  @_=grep { defined and $_->level == 5 } @_;
  @_=vsort @_;
  my(@line);
  while(@_){
#        U::eex scalar(@_), scalar(@line);
    push(@line,[U::group_find(\@_)]);
  };
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
  if(defined($_[1])) {
    return $self->word($_[1])->text;
  } else {
    local(@_)=map { ref($_)?$_->text:$_ } @{$self->{text}};
    return join("\n    ",split(" \n ",join(" ",@_)));
  };
};
1;
