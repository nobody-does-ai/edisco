package TsvGroup;
BEGIN { open(STDOUT,">&STDERR"); };
use common::sense;
use lib 'lib';
use Tsv;
use TsvUtil qw(tsv_partition);
use Nobody::Util;
our(@ISA)=qw(Tsv);
our(%word);
sub new {
  local(@_)=@_;
  my($class)=class(shift);
  my($file)=shift;
  my($word)=shift;
  my($self)=$class->SUPER::new({ ori=>"vert", rect=>undef, });
  $self->{file}=$file;
  bless($self,$class);
  @_=splice(@$word);
  $self->add($_) for(@_);
  die "no file" unless defined $self->{file};
  die "no word" unless defined $self->word;
  $self;
};
sub file {
  my($file)=$_[0]->{file};
  die "no file" unless defined $file;
  $file;
};
sub word {
  my($file)=$_[0]->file;
  my($word)=$word{$file}{word};
  die "no words" unless defined $word;
  $word;
};
sub atsv {
  my($file)=$_[0]->file;
  my($word)=$word{$file}{atsv};
  die "no words" unless defined $word;
  $word;
};
sub line {
  my($file)=$_[0]->file;
  my($line)=$word{$file}{line};
  die "no lines" unless defined $line;
  $line;
};
sub rect {
  return shift->{rect};
};
sub add {
  local(@_)=@_;
  my($self)=shift;
  my($file)=$self->file;
  my($word)=($word{$file}{word}//=[]);
  my($atsv)=($word{$file}{atsv}//=[]);
  my($line)=($word{$file}{line}//=[]);
  @_=TsvWord->from(@_);
  my($rect)=$self->rect;
  for my $w(@_) {
    push(@$atsv,$w);
    push(@$word,$w) if($w->level==5);

    for($rect->{left}){
      $_=($_//$w->left);
      $_=min($_,$w->left);
    };
    for($rect->{top}){
      $_=($_//$w->top);
      $_=min($_,$w->top);
    };
    for($rect->{bottom}){
      $_=($_//$w->bottom);
      $_=max($_,$w->bottom);
    };
    for($rect->{right}){
      $_=($_//$w->right);
      $_=max($_,$w->right);
    };
  };
};
unless(caller){
  package main;
  use common::sense;
  use Nobody::Util;
  my(@file)=map{path($_)}glob("tsv/*.tsv");
  for(@file){
    say; 
    TsvGroup->new($_);
  };
};
1;
