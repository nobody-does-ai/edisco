package Tsv;
BEGIN { open(STDOUT,">&STDERR"); };
use common::sense;
use Nobody::Util;
our($DEBUG)=0;
sub new {
  local(@_)=@_;
  my($class)=class(shift);
  my($self)=(ref($_[$#_]) eq 'HASH')?pop:{};
  bless($self,$class);
  $self;
};
sub clone {
  my($self)=$_[0];
  my($guts)=$self->export;
  $self->new($guts);
};
sub export {
  local(@_)=@_;
  my($self)=shift;
  my($guts)={ %$self };
  push(@_,map { \$guts->{$_} } keys %$guts);
  local($_);
  while(@_){
    $_=shift;
    if(safe_isa($$_,'Tsv')){
      $$_=($$_)->export;
    } elsif ( safe_isa($$_,'HASH') ) {
      push(@_,map { \($$_->{$_}) } keys %$$_);
    } elsif ( safe_isa($$_,'ARRAY')) {
      push(@_,map { \($$_->[$_]) } keys @$$_);
    } else {
      say $_;
    };
  };
  $guts;
};
unless(caller){
  my($obj)=Tsv->new({test=>1});
  for(my $i=0;$i<10;$i++){
    my($key)="key$i";
    $obj=$obj->new({$key=>$obj});
  };
  eex($obj);
};
1;
