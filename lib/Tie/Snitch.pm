package Tie::Snitch;
use common::sense;
our($AUTOLOAD);
sub AUTOLOAD {
  my($pkg,$sub)=map { m{(.*)::(.*)} } $AUTOLOAD;
  my($self,$ref);$self=\$ref;
  STDERR->print($ref,"\n");
  if(0){
  } elsif ( $sub eq 'TIESCALAR' ) {
    require Tie::StdScalar;
    my($ts);
    $ref=tie $ts, 'Tie::StdScalar';
    return bless($self);
  } elsif($sub eq 'TIEARRAY') {
    require Tie::StdArray;
    my(@ta);
    $ref=tie @ta, 'Tie::StdArray';
    return bless($self);
  } elsif ( $sub eq 'TIEHASH' ) {
    require Tie::StdHash;
    my(%th);
    $ref=tie %th, 'Tie::StdHash';
    return bless($self);
  } else {
    $DB::single=1;
    return ${$self}->$sub(@_);
  };
  die "no return above( $pkg $sub @_ )";
};
unless(caller) {
  package main;
  our($s,@a,%h);
  tie $s,'Tie::Snitch',\$s;
  tie @a,'Tie::Snitch',\@a;
  tie %h,'Tie::Snitch',\%h;
  $s="scalar";
  push(@a,'array','array');
  $#a=19999;
  $h{key1}='value1';
  $h{key2}='value2'; 
  $,=" ";
};
1;


