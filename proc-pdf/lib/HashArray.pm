package HashArray;
use Nobody::Util;
our(@data,@arr);

sub rem_grep(&;@) {
  local(@_)=@_;
  eex(\@_);
  my($p,$n);
  my($code)=shift;
  while(@_) {
    $_=shift;
    my($arr)=$code->()?\@p:\@n;
    push(@$arr,$_);
  };
};
my(@x)=grep { chomp; 1; } qx(find);
rem_grep sub{ m{004} }, @x;

sub new {
  local(@_)=@_;
  my($class) = class(shift);
  my(@arg)=rem_grep { ref($_) eq 'HASH' } @_;
  eex(\@argv);
  my(@path)=grep { $_=path($_) unless ref; 1 } @_;
  my($id)=@arr;
};

1;
