package PgDb;
use lib "lib";
use DBI;
use Nobody::PP;
use Carp::Always;
use Nobody::Util;
use common::sense;
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
  shift if safe_isa($_[0],"PgDb");
  my($sql)=shift;
  push(@_,"-"x40,"\n");
  push(@_,"processing sql: \n\n$sql\n\n");
  push(@_,"-"x40,"\n");
  push(@_,"ERROR: ", dbh->errstr, "\n");
  push(@_,"-"x40,"\n");
  local($_)=join("",@_);
  warn $_;
  die $_;
};
sub prepare {
  shift if safe_isa($_[0],"PgDb");
  my($sth)=shift;
  unless(ref($sth)){
    $sth=dbh->prepare($sth);
    throw_err($@) unless defined $sth;
  };
  return $sth;
}
sub execute {
  shift if safe_isa($_[0],"PgDb");
  my($sth)=prepare(shift);
  $sth->execute;
  $sth;
};
sub insert {
  shift if($_[0]->isa("PgDb"));
  my($tab)=shift;
  my(@head)=@{+shift};
  my($body)=join(', ', map { '?' } @head);
  my($head)=join(', ', @head);
  my($sql)="insert into $tab ( $head ) values ( $body );";
  my($ddl)="$sql";
  local(@_)=map { @$_ } shift;
  for my $i(keys @_){
    my($obj)=$_[$i];
    $obj=[ map { $obj->{$_} } @head ] if ref($obj)eq'HASH';
    die "expected a hash or array" unless ref($obj)eq'ARRAY';
    $_[$i]=$obj;
  };
  my($sth)=prepare($sql); 
  for(@_){
    $@="";
    $sth->execute(map { $_ eq '' ? undef : $_ } @$_);
    eex($@) if $@;
  };
};
sub copy_bulk {
  shift if safe_isa($_[0],"PgDb");
  local(@_)=@_;
  shift if($_[0]->isa("PgDb"));
  my($tab) = shift;
  my($cols) = shift;
  my($rows) = shift;
  my(@head) = @{$cols};
  my($head) = join(", ",@head);
  my($body) = join(", ", map { "?" } @head);
  my($sql) = (
    "COPY $tab ($head) FROM STDIN ".
    " WITH (FORMAT text, DELIMITER E'\t', NULL '\\N')"
  );
  my($sth) = dbh->prepare($sql);
  my(@rows)=grep { defined } @$rows;
  for my $row(@rows){
    if(ref($row)eq'HASH'){
      $row=[ map { $row->{$_} } @head ];
    };
    if(ref($row)eq'ARRAY'){
      local(@_)=@$row;
      for(@_){
        $_="\\N" unless length;
      };
      $row=join("\t",grep{s{\t}{ }g;1} @_);
    } else {
      die "expected ARRAY or HASH, got ",pp($row);
    };
  };
  $sth->execute();
  dbh->pg_putcopydata(join("\n",@rows,""));
  dbh->pg_endcopy();
}
sub hash_fetch {
  shift if safe_isa($_[0],"PgDb");
  local(@_)=@_;
  my($sth)=execute(shift);
  die "extra args: @_" if @_;
  while(my $row=$sth->fetchrow_hashref) {
    push(@_,$row);
  };
  return \@_;
};
sub fetchall_arrayref {
  shift if safe_isa($_[0],"PgDb");
  my($sth)=execute(shift);
  die "extra args: @_" if @_;
  $sth->fetchall_arrayref;
};
1;
