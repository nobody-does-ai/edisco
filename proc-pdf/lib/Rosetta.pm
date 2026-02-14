package Rosetta;
use lib "lib";
use Nobody::Util;
use Data::Dumper;
use common::sense;
use Tie::Hash;
our(%key);
BEGIN {
  my(%rect)=(
    qw(left  x1  right  x2  top  y1  bottom  y2  width  dx  height  dy   )
  );
  my(%tsv)=(
    map({ ( "${_}_num", $_ ) } qw( page line block par word )),
    map({ $_, $_ } qw( conf ) ),
  );
  for my $k(keys %tsv) {
    $key{$k}{tsv}=$k;
    $key{$k}{perl}=$tsv{$k};
  };
  for my $k(keys %rect) {
    $key{$k}{perl}=$rect{$k};
    $key{$k}{tsv}=$k;
    $key{$k}{db}=join("",$k,"_px");
    $key{substr($k,0,1)}=$key{$k};
  };
  for my $k(keys %key){
    for my $v(values %{$key{$k}}){
      $key{$v}//=$key{$k};
    };
  };
  hdump(\%key);
#      say hdump(\%key);
#      eex( tied %key );
#      eex( $key{foo}{bar} );
#      $key{foo}{baz}=$key{foo};
#      eex( {%{$key{foo}}} );

};
1;
