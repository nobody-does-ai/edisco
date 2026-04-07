package TsvGroup;
use common::sense;
use lib 'lib';
use Tsv;
use TsvUtil qw(tsv_parse);
use Nobody::Util;
our(@ISA)=qw(Tsv);
sub new {
  local(@_)=@_;
  eex(\@_);
  die "usage: TsvGroup::new( class hash ) (got: ".pp(@_).")" unless @_==2 and ref($_[1]) eq 'HASH';
  my($class)=class(shift);
  my($hash)=shift;
  for($hash->{file}){
    $_=path($_);
  };
  my($self)=$class->SUPER::new($hash);
  bless($self,$class);
};
sub file {
  my($file)=$_[0]->{file};
  die "no file" unless defined $file;
  $file;
};
sub word {
  return (shift->{word}//=[]);
};
sub line {
  my($line)=shift->{line};
  die "no lines" unless defined $line;
  $line;
};
sub rect {
  return shift->{rect};
};
1;
