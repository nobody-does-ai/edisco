#!/usr/bin/perl
# vim: ts=2 sw=2 ft=perl
#
use common::sense;
package Nobody::Util::Import;
use Nobody::PP;
BEGIN {
  local($_,@_);
  use vars ( 
    qw( @carp %PACK @EXPORT  @EXPORT_OK  @ISA %seen @subs )
  );
}
BEGIN {
  *Nobody::Util::EXPORT=\@EXPORT;
  *Nobody::Util::EXPORT_OK=\@EXPORT_OK;
  @subs=qw(
  QX            WNOHANG      avg       class     
  deparse       dirname      file_id   flatten   
  getcwd        getfds       getfl     lcmp      
  lsort         matrix       max       maybeRef  
  methods       methods_via  min       mkdir_p   
  pasteLines    nonblock     open_fds  mkref     
  safe_blessed  safe_isa     serdate   path      
  serial_maker  setfl        spit      spit_fh   
  stdin_sub     stdout_sub   suck      suckdir   
  sum           uniq         vcmp      vsort     
  basename      sum          avg       max       
  min           mkdir_p      suckdir   getcwd    
  pasteLines    serdate      class     mkref     
  open_fds      deparse      maybeRef  dump_obj
  file_id       WNOHANG      uniq      matrix    
  dirname       capture      safe_can child_wait
  safe_isa      nsort ref_count hdump
  );
  $PACK{'Carp'}='EXPORT_OK';
  $PACK{'Env'}=[qw( $HOME $PWD @PATH )];
  $PACK{'Fcntl'}=[qw(:seek :mode)];
  $PACK{'FindBin'}='EXPORT_OK';
  $PACK{'Nobody::PP'}="EXPORT_OK subs";
  $PACK{'Path::Tiny'}=[qw(path)];
  $PACK{'POSIX'}=[qw(strftime mktime :sys_wait_h )];
  $PACK{'Tie::LoudArray'};
  $PACK{'File::stat'}=[ qw( :FIELDS) ];
  $PACK{"List::Util"}='EXPORT_OK';
  $PACK{'Scalar::Util'}='EXPORT_OK';
  $PACK{'Sub::Util'}='EXPORT_OK';
}
sub export_ok_ref {
  local(@_)=@_;
  my ($pkg) = splice @_;
  die "no package name" unless defined $pkg && length $pkg;

  (my $file = "$pkg.pm") =~ s{::}{/}g;

  require $file;  # loads but does not import

  no strict 'refs';

  if( defined *{"${pkg}::EXPORT"}{ARRAY} ) {
    push(@_,@{"${pkg}::EXPORT"});
  };
  if( defined *{"${pkg}::EXPORT_OK"}{ARRAY} ) {
    push(@_,@{"${pkg}::EXPORT_OK"});
  };
  return \@_;
}
sub export_slots {
  my ($pkg,$name,@type) = @_;
  die "no package name" unless defined $pkg && length $pkg;
  die "no name" unless defined $name && length $name;

  (my $file = "$pkg.pm") =~ s{::}{/}g;

  require $file;  # loads but does not import
  my (%res);
  for( qw(CODE ARRAY SCALAR HASH) ) {
    my(%res);
    next unless  defined *{"${pkg}::${name}"}{$_};
    $res{$_}=*{"${pkg}::${name}"}{$_};
  };
#      eex(\%res);
  \%res;
}
BEGIN {
  no strict 'refs';
  for my $p(sort keys %PACK) {
    my($i)=$PACK{$p};
    (my $r =$p)=~s{::}{/}g;
    local($_)=$p;
    if($PACK{$_} eq 'EXPORT_OK') {
      $PACK{$_}=export_ok_ref($_);
#          eex($PACK{$_});
    };
    if(ref($PACK{$_}) eq 'ARRAY'){
      my(@a)=@{$PACK{$_}};
      @a = grep { $_ ne "set_prototype" } @a;
      for( "        ","::Import") {
        local($_)="package Nobody::Util$_; use $p qw(@a)";
#            eex($_);
        eval;
      };
      push(@EXPORT,@a);
    };
  };
#      eex(\%PACK);
};
BEGIN {
  say blessed(bless {}, 'main');
};
BEGIN {
  @EXPORT_OK= uniq( sort @EXPORT_OK);
  @EXPORT   = uniq( sort @EXPORT   );
};
BEGIN {
  @subs=uniq(@subs);
  use subs @subs;
  push(@EXPORT,@subs);
  our(@carp);
}
package Nobody::Util;
use Nobody::PP;
use Path::Tiny;
BEGIN {
  *blessed=\&builtin::blessed;
  my($ExportLevel);
  my($Verbose);
  my($Debug);
  my(%Cache);
  sub import {
    my $pkg = shift;
    my $callpkg = caller($ExportLevel);
    push(@_,@EXPORT);
    die unless grep { $_ eq "mesh" } @EXPORT;
    *{"$callpkg\::$_"} = \&{"$pkg\::$_"} foreach @_;
  };
}
1;
