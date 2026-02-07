package TsvWord;
# vim: ts=2 sw=2 ft=perl
use common::sense;
{
  package U;
  use Nobody::Util;
  use Carp::Always;
  use Carp qw( croak cluck carp confess );
  use TsvUtil;
  use autodie;
  use Nobody::PP;
  our(@VERSION) = qw( 0 1 0 );
  our($DEBUG);
};
use TsvText;
our(@ISA)=qw(TsvText);
our(@cols,%key);
BEGIN {
  for(qw( level page_num block_num par_num line_num word_num conf text rect )){
    $key{$_}=$_;
  };
  for(values %key) {
    s{_num}{};
  };
  *DEBUG=\$Tsv::DEBUG;
  undef &head;
};
my(@word);

sub new {
  local(@_)=@_;
  my($class)=U::class(shift);
  my($self)={@_};
  $self->{rect}=TsvRect->take_data($self);
  for my $old(keys %$self){
    $self->{$key{$old}}=delete $self->{$old} if $key{$old};
  };
#      U::eex( \$self);
  return () if $self->{level}==5 and $self->{text} !~ m{\S};
  return () if $self->{level}==5 and $self->{rect}->dy > 100;
  $self=$class->SUPER::new(%$self);
  warn U::pp($self) if $self->{text} =~ m@Hash@;
  if($self->{text} =~ m{ }){
    $self->{text} =~ s{ }{_}g;
  };
#      U::eex( $self->{text} );
  bless($self,$class);
};
sub rect {
  shift->{rect};
};
sub left {
  shift->rect->left(@_);
}
sub right {
  shift->rect->right(@_);
}
sub cx {
  shift->rect->cx(@_);
};
sub cy {
  shift->rect->cy(@_);
};
sub height {
  shift->rect->height(@_);
};
sub width {
  shift->rect->width(@_);
};
sub top {
  shift->rect->top(@_);
}
sub bottom {
  shift->rect->bottom(@_);
}
sub from {
  local(@_)=@_;
  my($class)=U::class(shift);
  for(@_) {
    $_=TsvWord->new(%{$_});
  };
  return grep { defined } @_;
};
our(%h,@a);
sub hash {
  local(@_)=@_;
  if(U::class($_[0]) eq __PACKAGE__){
    shift;
  };
  for(@_) {
    if(ref eq 'ARRAY') {
      local(@_)=@$_;
      $_={ map { $_, shift } @cols };
#          U::eex($_);
    };
    die "idk how to handle: $_" unless ref($_) eq 'HASH';
  };
  shift if $_->{level} eq 'level';
  @_;
};
sub parse_file {
  die "usage: ".__PACKAGE__."->parse_file(path(\"name\"))" unless (
    @_==2
      and
    $_[0]->isa(__PACKAGE__)
  );
  local(@_)=@_;
  my($class,$file)=@_;
  $file=U::path($file) unless ref($file);
  local(@_)=$file->lines;
  chomp(@_);
#      say STDERR for @_;
  if(substr($_[0],0,1) eq 'l'){
    @cols=map { split m{[\t]} } shift;
  };
  @_=parse_lines(@_);
  $_->{page}=$file->basename(".tsv") for @_;
  @_;
}
sub parse_lines {
  shift if $_[0]->isa(__PACKAGE__);
  chomp(@_);
  $_=[split m{[\t]}] for grep { !ref } @_;
  @_=hash(@_);
#      say scalar(@_), " lines parsed ";
  @_;
};
sub load_file {
  my($self)=shift;
  $self->from($self->parse_file(@_));
};
sub word {
  return [ shift ];
};
sub text {
  local($_)=shift->{text};
  U::eex($_) if m{hash[(]0};
  $_;
};
1;
