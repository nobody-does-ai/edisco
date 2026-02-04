package TsvDB;
use base 'Exporter';
use DBI;
use Nobody::Util;
use common::sense;
use Tsv;
use TsvWord;
our(@EXPORT);
BEGIN {
  push(@EXPORT,qw( dbh dsn page head ins_tsv fetch_hash fetch_words fetch_lines fetch_pages));
  undef &head;
};
our($dsn,$dbh,%page);
use subs qw( dbh );
INIT {
  $dsn = "dbi:Pg:dbname=nn";
  $dbh = DBI->connect($dsn, "", "", { 
      AutoCommit => 1, 
      RaiseError => 1, 
      PrintError => 0 
    });
  *page=$dbh->selectall_hashref( "select * from page order by year,quar,lpage", 'name');
};
{
  my($ins_tsv);
  sub ins_tsv {
    my(@head)=head('db');
    my($head)=join(", ",@head);
    my($str)="COPY tsv_raw ($head) FROM STDIN WITH (FORMAT text, DELIMITER E'\t', NULL '\\N')";
    unless(defined($ins_tsv)) {
      $ins_tsv=$dbh->prepare($str);;
    };
    $ins_tsv->execute;
    for(@_){
      local(@_)=split;
      push(@_,undef) if @_<12;
      die "@_ != 12" unless @_==12;
      $_=join("\t",@_);
    };
    dbh->pg_putcopydata(join("\n",@_,''));
    dbh->pg_endcopy();
    my $row = dbh->selectrow_hashref("select count(*) from tsv");
  };
};
sub page { return \%page };
sub dbh { return $dbh; }
sub dsn { return $dsn; }
{
  my(%head);
  my(@fs_head,@db_head);
  sub head {
    unless(@fs_head and @db_head){
      my $file=path("tsv")->child('202?-Q?-???.tsv');
      ($file)=glob("$file");
      (@fs_head)=map { split } qx(head -n 1 $file);
      (@db_head);
      for(map { "$_" } @fs_head) {
        s{_num}{};
        if(m{left|top|width|height}){
          substr($_,1)="";
        };
        push(@db_head, $_);
      };
    };
    if($_[0] eq 'db') {
      return @db_head;
    } elsif($_[0] eq 'fs') {
      return @fs_head;
    } else {
      die "whcih header set?"
    };
  }
}
sub fetch_hash {
  local(@_)=@_;
  my $sql = shift;
  my $sth;
  if(ref($sql)) {
    $sth=$sql;
  } else {
    $sth=dbh->prepare("select * from tsv");
  };
  $sth->execute;
  my(@res);
  while($_=$sth->fetchrow_hashref){
    push(@res,$_);
  };
  return @res;
};
sub fetch_pages {
  my(@page)=fetch_hash("select * from page");
  for(@page){
    next if ref($_) eq 'ARRAY';
    push(@{$_[$_->{level}]},$_);
  };
  @page;
};
sub fetch_words {
  local(@_)=@_;
  my(@tsv)=fetch_hash("select * from tsv where page in (select id from page where quar==3 and year==2024)");
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
sub fetch_lines {
  local(@_)=@_;
  my(@tsv)=fetch_words;
  my($words)=$tsv[5];
  @{$tsv[0]}=TsvLine->from(@{$words});
  return @tsv;
};
unless(caller(0)){
  my(@db)=head('db');
  my(@fs)=head('fs');
  my(@head);
  while(@db or @fs) {
    my($db)=shift(@db);
    my($fs)=shift(@fs);
    if($db eq $fs) {
      push(@head,$db);
    } else {
      push(@head,{fs=>$fs,db=>$db});
    };
  };
  eex(\@head);
};
1;
