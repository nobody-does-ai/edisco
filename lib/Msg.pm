package Msg;
use Nobody::Util;
our(%filt);
sub new {
  local(@_)=@_;
  my($class)=class(shift);
  our(%data);
  local(*data)=shift;
  my($self)={};
  $self->{date}=main::date(\%data);
  $self->{fr}=main::fr_addr(\%data);
  $self->{to}=main::to_addr(\%data);
  return undef unless $filt{$self->{fr}} or $filt{$self->{to}};
  my(%attach);
  $self->{attach}=\%attach;
  %{$self->{attach}}=%{main::parts(\%data)};
  $self->{body}=main::body(\%data);
  eex($self);
  bless($self,$class);
  $self;
};
sub to {
  return $_[0]->{to};
};
sub fr {
  return $_[0]->{fr};
};
sub body {
  return $_[0]->{body};
};
sub date {
  return $_[0]->{date};
};
sub attach {
  return $_[0]->{attach};
};
1;
