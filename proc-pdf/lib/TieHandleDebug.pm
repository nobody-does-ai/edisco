package TieHandleDebug;

use base Tie::StdHandle;

sub TIEHANDLE {
  if(@_==1) {
    push(@_,">&STDERR");
  };
  $_[0]->SUPER::TIEHANDLE(@_[1..-1+@_]);
};
our($DEBUG)=1;
sub WRITE {
#      $DB::single=$DEBUG;
  $_[0]->SUPER::WRITE(@_[1..-1+@_]);
};
tie *STDERR, 'TieHandleDebug';
tie *STDOUT, 'TieHandleDebug';
1;
