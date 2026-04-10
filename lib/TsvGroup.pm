package TsvGroup;
use common::sense;
use lib 'lib';
use Tsv;
use TsvUtil qw(tsv_parse);
use Nobody::Util;
our(@ISA)=qw(Tsv);
sub new {
  local(@_)=@_;
  die "usage: TsvGroup::new( class hash ) (got: ".pp(@_).")" unless (
    $_[0]->isa("TsvGroup") and @_==2 and ref($_[1]) eq 'HASH'
  );
  my($class)=class(shift);
  my($hash)=shift;
  for($hash->{file}){
    $_=path($_) if defined;
  };
  my($self)=$class->SUPER::new($hash);
  if(defined($self->{word})){
    $self->word(delete $self->{word});
  };
  $self;
};
{
  my %word;
  sub word {
    my($self)=shift;
    die "usage: word() or word([words])" if @_>1;
    if(@_) {
      $word{$self}=shift;
    }
    $word{$self};
  };
};
sub file {
  my($file)=$_[0]->{file};
  die "no file" unless defined $file;
  $file;
};
sub line {
  my($line)=shift->{line};
  die "no lines" unless defined $line;
  $line;
};
sub rect {
  my($rect)=shift->{rect};
  die "no rect" unless defined $rect;
  $rect;
};
1;
