package TsvLine;
our(@ISA)=qw(TsvText);
# vim: ts=2 sw=2 ft=perl
use common::sense;
{
  package U;
  use Nobody::Util;
  use Carp::Always;
  use Carp qw( croak cluck carp confess );
  use Tsv;
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
  my($self)=$class->SUPER::new();
  $self->{word}=\@word;
#      my($y1,$y2)=($self->y1,$self->y2);
#      $_->{rect}->{y1}=$y1 for @word;
#      $_->{rect}->{y2}=$y2 for @word;
  $self;
};
sub refCount {
  my(%cnt);
  for(@_) {
    my($ref)=ref;
    $cnt{$ref}++;
  }
  \%cnt;
};
sub from {
  local(@_)=@_;
  my($class)=U::class(shift);
  @_=grep { defined and  $_->{level} == 5 } @_;
  if(grep { ref($_) eq 'HASH' } @_){
    @_=TsvWord->from(@_);
  };
  @_=vsort @_;
  my(@line);
  while(@_){
    my(@tmp)=TsvUtil::group_find(\@_);
    push(@line,TsvLine->new(@tmp));
  };
  @line;
};
sub left {
  U::min(map { $_->left } @{shift->word});
}
sub top {
  U::min(map { $_->top } @{shift->word});
}
sub right {
  U::max(map { $_->right } @{shift->word});
}
sub bottom {
  U::max(map { $_->bottom } @{shift->word});
}
sub width {
  U::max(map { $_->width } @{shift->word});
};
sub height {
  U::max(map { $_->height } @{shift->word});
};
sub load_file {
  my($self)=shift;
  my(@word)=TsvWord->load_file(@_);
  for(@word) {
    die "needed words, got ",U::pp($_) unless ref($_) eq 'TsvWord';
  };
  my(@line)=TsvLine->from(@word);
  @line;
};
sub word {
  my($self)=$_[0];
  if(defined($_[1])){
    return $self->word->[$_[1]];
  } else {
    return $self->{word};
  };
}
sub line {
  return shift->word(0)->line;
};
sub text {
  my($self)=$_[0];
  my(@word)=$self->word($_[1]);
  if(ref($word[0])eq'ARRAY'){
    return join(" ",map { $_->text } @{$word[0]});
  } else {
    return $word[0]->text;
  };
  $_;
};
1;
