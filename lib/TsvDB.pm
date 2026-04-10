package TsvDB;
use lib "lib";
use DBI;
use Nobody::PP;
use vars qw(%key);
use Carp::Always;
use Nobody::Util;
use common::sense;
use Time::HiRes qw(time);
use vars qw(%opt);
sub dsn {
  state($dsn);
  $dsn//= "dbi:Pg:";
  return $dsn;
}
sub dbh {
  state($dsn,$dbh);
  $dbh //= DBI->connect(dsn, "", "", { 
      AutoCommit => 1, 
      RaiseError => 1, 
      PrintError => 0 
    });
  return $dbh;
}
sub throw_err($) {
  my($sql)=shift;
  say STDERR "-"x40;
  warn "processing sql: \n\n$sql\n\n";
  say STDERR "-"x40;
  warn "ERROR: ", dbh->errstr, "\n";
  say STDERR "-"x40;
  eex "here"; 
  exit(1);
};
sub prepare {
  shift if($_[0]->isa("TsvDB"));
  my($sth)=shift;
  unless(ref($sth)){
    $sth=dbh->prepare($sth);
    throw_err($@) unless defined $sth;
  };
  return $sth;
}
sub execute {
  shift if($_[0]->isa("TsvDB"));
  my($sth)=prepare(shift);
  $sth->execute;
  $sth;
};
sub insert {
  shift if($_[0]->isa("TsvDB"));
  my($tab)=shift;
  my(@head)=@{+shift};
  my($body)=join(', ', map { '?' } @head);
  my($head)=join(', ', @head);
  my($sql)="insert into $tab ( $head ) values ( $body );";
  my($ddl)="$sql";
  @_=map { @$_ } shift;
  for my $i(keys @_){
    my($obj)=$_[$i];
    $obj=[ map { $obj->{$_} } @head ] if ref($obj)eq'HASH';;
    $_[$i]=$obj;
  };
  my($sth)=prepare($sql); 
  for(@_){
    $@="";
    $sth->execute(map { $_ eq '' ? undef : $_ } @$_);
    eex($@) if $@;
  };
};
sub hash_fetch {
  local(@_)=@_;
  my($sth)=execute(shift);
  die "extra args: @_" if @_;
  while(my $row=$sth->fetchrow_hashref) {
    push(@_,$row);
  };
  return \@_;
};
sub fetchall_arrayref {
  my($sth)=execute(shift);
  die "extra args: @_" if @_;
  $sth->fetchall_arrayref;
};
1;
