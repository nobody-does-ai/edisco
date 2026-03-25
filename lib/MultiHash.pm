package MultiHash;
use Tie::Hash;
our(@ISA)='Tie::StdHash';
use Nobody::Util;
sub TIEHASH {
  my($class)=class(shift);
  my(%self);
  bless(\%self,$class);
};
sub STORE {
  local(@_)=@_;
  my($hash,$key,$val)=@_;
  if(defined($hash->{$key})){
    push(@{$hash->{$key}},@_);
  } else {
    $hash->{$key}=[$val];
  };
};
sub FETCH {
  local(@_)=@_;
  my($hash,$key)=@_;
  $hash->{$key}//=[];
};
