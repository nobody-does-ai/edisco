package TsvGroup;
BEGIN { open(STDOUT,">&STDERR"); };
use common::sense;
use lib 'lib';
use Tsv;
use TsvUtil qw(tsv_parse);
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
  unless(defined($word)){
    $word{$file}{word}=tsv_parse($file);
  };
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
  push(@$word,@_);
  my(@x2,@x1,@y2,@y1);
  for(@_) {
    push(@x2,$_->rect->x2);
    push(@x1,$_->rect->x1);
    push(@y1,$_->rect->y1);
    push(@y2,$_->rect->y2);
  };
  @x2=max(@x2);
  @x1=min(@x1);
  @y1=min(@y1);
  @y2=min(@y2);
  $self->{rect}=TsvRect->new(x1=>$x1[0], x2=>$x2[0], y1=>$y1[0], y2=>$y2[0]);
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
