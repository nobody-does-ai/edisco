package Nobody::Exes;
require Exporter;
our(@EXPORT);
BEGIN {
  push(@EXPORT,path_find,editor);
};
use Env qw(@PATH @PERL5LIB @LD_LIBRARY_PATH @MANPATH);
use Nobody::Util;

sub path_find {
  my($cb)=shift;
  local($_,@_)=@_;
  if(m{^/}){
    @_="";
  } else {
    my($tgt)=$_;
    @_=grep { s{\/*$}{/$tgt} } @_;
  };
  @_=grep { -e } @_;
  @_ = grep { $cb->($_) } @_;
};
sub exe {
  sub { -x };
};
sub editor {
  my(%res);
  for($ENV{EDITOR}, $ENV{VISUAL}, "vim", "vi") {
    $res{$_}=1 for path_find(exe(),$_,@PATH);
  }
  sort keys %res;
};
unless(caller){
  eex path_find(exe(), "sh",@PATH);
};
