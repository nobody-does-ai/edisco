package TsvDoc;
use common::sense;
use Nobody::Util;
use lib "lib";
use Tsv;
use base 'Tsv';

sub new {
  my($class)=class(shift);
  my($key)=shift;
  my($pages)=shift;
  my($self)=$class->SUPER::new({ key=>$key, pages=>$pages });
  $self;
};

sub key   { $_[0]->{key} };
sub pages { $_[0]->{pages} };
1;
