package TsvDB;
use lib "lib";
use DBI;
use Nobody::PP;
use vars qw(%key);
use Carp qw( confess croak );
use Carp::Always;
use Nobody::Util;
use Nobody::PP;
use common::sense;
use Time::HiRes qw(time);
use vars qw(%opt);
our(@EXPORT);
BEGIN {
  push(@EXPORT,
    qw(
    tsv_insert      hash_fetch      word_fetch
    dbh   line_fetch      tsv_fetch       tsv_fetch_range
    )
  );
}
BEGIN {
  use base qw(Exporter);
};
{
  sub tsv_insert {
    local(@_)=@_;
    state(@head);
    @head=head('db') unless @head;
    confess "left is in head!" if grep { $_ eq "left" } @head;
    shift(@head) while $head[0]eq'tsv';
    state($head);
    $head//=join(", ",@head);
    state($body);
    $body//=join(", ", map { "?" } @head);
    state($sql);
    $sql//="COPY tsv_tmp ($head) FROM STDIN WITH (FORMAT text, DELIMITER E'\t', NULL '\\N')";
#        $sql//="insert into tsv($head) values ($body) on conflict do nothing";
    dbh->prepare("delete from tsv")->execute();
    state($sth);
    $sth//=prepare(prepare($sql));
    my(@xlate)=map { $key{$_}{tsv} || $_ } @head;
    eex("$#head @head");
    eex("$#xlate @xlate");
    if($sql =~ m{^insert}i) {
      for (@_) {
        my($data)=$_;
        if($data->{text} =~ m{\S}){
          my(@data)=map { $data->{$_} } @xlate;
          eval {
            $sth->execute(@data);
          };
          if("$@") {
            eex("$#data @data");
            die "$@";
          };
        } else {
          $_=undef;
        };
      };
    } else {
      @_=grep { defined } @_;
      @_=map { split m{\n} } @_;
      $_=join("\n",@_,"");
      $sth->execute();
      dbh->pg_putcopydata(join("\n",$_,""));
      dbh->pg_endcopy();
    };
  }
  sub tsv_select {
    local(@_)=@_;
    my($where)=join(" ","where",@_);
    my(@tsv)=hash_fetch("select * from tsv $where order by doc, page_num, line_num, left_px");
    @tsv;
  }
  sub tsv_fetch_range {
    my($time)=time;
    dbh->selectall_hashref("select * from tsv_range r",["rid","tsv"]);
  };
};
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
{
  my(%head);
#      sub head {
#        state(@fs_head,@db_head);
#        unless(@fs_head and @db_head){
#          my $file=path("tsv")->child('202?-Q?-???.tsv');
#          ($file)=glob("$file");
#          (@fs_head)=map { split } qx(head -n 1 $file);
#          for my $name(map { "$_" } @fs_head) {
#            push(@db_head,$key{$name}{db}//=$name);
#          }
#          push(@db_head,"reject",pop(@db_head));
#          unshift(@db_head,"tsv","doc");
#        };
#        if($_[0] eq 'db') {
#          return @db_head;
#        } elsif($_[0] eq 'fs') {
#          return @fs_head;
#        } else {
#          die "whcih header set?"
#        };
#      }
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
}
sub execute {
  if($_[0]->isa("TsvDB")){
    shift;
  };
  my($sth)=shift;
  unless(ref($sth)){
    $sth=dbh->prepare($sth);
  };
  throw_err(@_) unless defined $sth;
  $sth->execute;
  $sth;
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
sub word_fetch {
  my(@tsv)=tsv_fetch(@_);
  for(@tsv){
    push(@{$_[$_->{level}]},$_);
  };
  my(@res)=undef;
  for my $level(1 .. 5) {
    my(@tmp)=grep { $_->{level}==$level } @tsv;
    push(@res,\@tmp);
  };
  @{$res[5]}=TsvWord->from(@{$res[5]});
  @res;
};
sub line_fetch {
  local(@_)=@_;
  my(@tsv)=word_fetch;
  my($words)=$tsv[5];
  @{$tsv[0]}=TsvLine->from(@{$words});
  return @tsv;
};
unless(caller(0)){
  my(@col);
#      eex(hash_fetch(
#          "select     doc, page_num, top_px, height_px, left_px, width_px, text    \n".
#          "from         tsv where text <> '-' and level =5              \n".
#          " order by  doc, page_num, top_px, height_px, left_px, width_px, text    \n"
#        )
#      );
};
#      eex(hash_fetch("select * from information_schema.tables"));
#      eex(hash_fetch("select * from pg_tabs"));
#      eex(my $sth=prepare("select * from pg_tabs"));
#      $sth->execute();
#      eex($sth->fetchrow_hashref());
#      eex(dbh->prepare("select * from pg_tabs"));
#      eex(hash_fetch("select * from pg_tabs"));
#      eex(hash_fetch("select table_schema, count(*) from pg_tabs group by table_schema"));
#      eex(hash_fetch("create view pg_tabs as select * from information_schema.tables"));
#      eex(dbh->selectall_arrayref("select * from tsv limit 5"));
#      eex(dbh->selectall_arrayref("select * from information_schema.tables limit 5"));
1;
