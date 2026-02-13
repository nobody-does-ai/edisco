package TsvText;
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
our(@ISA)=qw(Tsv);
our(@cols);
BEGIN {
  *DEBUG=\$Tsv::DEBUG;
  undef &head;
};
#    use overload (
#      q{""}    => 'tostring',
#    );
sub new {
  $_[0]->SUPER::new(@_[1..$#_]);
};
sub level {
  shift->{level};
};
sub pack {
  my($self)=$_[0];
  $self->{rect}=TsvRect->union(map {$_->{rect}} @{$self->word}); 
}
#    sub tostring {
#      my($self)=shift;
#      return join(" || ","",$self->top,$self->text,$self->bottom);
#    };
sub from {
  local(@_)=@_;
  my($class)=U::class(shift);
  @_=sort { $a->cy <=> $b->cy } grep { defined } @_;
  my(@line);
  while(@_) {
    push(@line,TsvLine->new(U::group_find(\@_)));
  };
  @line;
};
sub  x1  {  shift->left    };
sub  x2  {  shift->right   };
sub  dy  {  shift->height  };
sub  dx  {  shift->width   };
sub  y1  {  shift->top     };
sub  y2  {  shift->bottom  };
sub page {
  return shift->{page};
};
1;
