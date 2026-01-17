package Tsv;
BEGIN { open(STDOUT,">&STDERR"); };
use Nobody::Util;
use common::sense;
use JSON::XS;
our($DEBUG)=0;
our($coder) = JSON::XS->new->ascii->pretty->allow_nonref->allow_blessed ->convert_blessed;
sub new {
  local(@_)=@_;
  my($class)=class(shift);
  my($self)=(ref($_[$#_]) eq 'HASH')?pop:{};
  bless($self,$class);
};
sub TO_JSON {
  my($self)=shift;
  my($class)=ref($self);
  my(%data)=%{$self};
  $data{bless}=$class;
  \%data;
};
sub FR_JSON {
  for (@_) {
    my($self)=$_;
    if(ref($self)eq'HASH'){
      for($self->{bless}){
        bless($self,delete $self->{bless}) if defined;
      };
    };
  };
  @_;
};
1;
