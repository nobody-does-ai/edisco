package TsvPath;
use Nobody::Util;
use common::sense;

use overload (
  q{""}    => 'tostring',
);
sub new {
  my($class)=class(shift);
  my($path)=shift;
  my(%self);
  my($self)=\%self;
  bless($self,$class);
  $self->path($path);
  say "passed: ", pp($path);
  say "built:  ", pp($self->path);
  $self;
};
use Nobody::Util;
#    $_="tsv/2023-Q4-000.tsv";
#    @_=m{(...)/(\d\d\d\d)-Q(\d)-(\d+)[.](...)} ;
#    eex( \@_ );
#    my($res)=sprintf(
#      "%s/%04d-Q%d-%03d.%s",
#      m{(...)/(\d\d\d\d)-Q(\d)-(\d+)[.](...)} 
#    );
#    eex($res);


sub tostring {
  shift->path;
};
sub path {
  my($self)=shift;
  if(@_){
    my($path)=shift;
    if(safe_can($path,"path")){
      $path=$path->path;
    };
    my(@part)=map { m{(...)/(\d\d\d\d)-Q(\d)-(\d+)[.](...)} } $path;
    die "no match" unless @part;
    for(qw(dir year q page ext)) {
      my($name,$part)=($_,shift(@part));
      unless(defined($self->{$name}=$part)){
        die("missing $_")
      }
    };
  };
  my($res)=sprintf("%s/%04d-Q%d-%03d.%s",map { $self->{$_} } qw(
    dir year q page ext
    ));
  $res;
};
sub ext {
  my($self)=shift;
  if(@_){
    $self->{ext}=shift;
  };
  die "@_" if "@_";
  return $self->{ext};
}
sub dir {
  my($self)=shift;
  if(@_){
    $self->{dir}=shift;
  };
  die "@_" if "@_";
  return $self->{dir};
}
sub page {
  my($self)=shift;
  if(@_){
    $self->{page}=shift;
  };
  die "@_" if "@_";
  return $self->{page};
};
sub year {
  my($self)=shift;
  if(@_){
    $self->{year}=shift;
  };
  die "@_" if "@_";
  return $self->{year};
};
sub q {
  my($self)=shift;
  if(@_){
    $self->{q}=shift;
  };
  die "@_" if "@_";
  return $self->{q};
};


1;
