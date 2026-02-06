package TsvDB;
use base 'Exporter';
use DBI;
use Nobody::Util;
use common::sense;
use Tsv;
use TsvWord;
our(@EXPORT);
BEGIN {
  push(@EXPORT,
    qw(
    head  tsv_insert      hash_fetch      word_fetch
    dbh   line_fetch      tsv_fetch
    )
  );
}
BEGIN {
  use subs (@EXPORT);
  undef &head;
};
#    {
#      my($re)=qr(202(.)-Q(.)(-[0-9][0-9][0-9]|).tsv);
#      sub parse_tsv_name {
#        return map { $_, parse_tsv_name($_) } @_ unless @_==1;
#        local($_)=shift;
#        my(%res)=( name=>$_ );
#        unless(2<=(@res{qw( year quar lpage )}=m{$re})) {
#          die "parse failed";
#        };
#        $res{quar}+=4+($res{year}-3);
#        if(exists $res{lpage}){
#          local(*_)=\$res{lpage};
#          next unless length;
#          s{^-}{};
#          $res{page}=join("",@res{qw(year quar lpage)});
#        };
#        $res{year}+=2020;
#        \%res;
#      }
#    };
#    {
#      my(@pg_cols)=qw(page name year quar lpage);
#      my($sql_fmt)=q{
#      insert into page(%s) values (?,?,?,?,?) on conflict do nothing
#      };
#      sub page_insert {
#        @_=glob("tsv/202?-Q?-???.tsv") unless @_;
#        state($sql);
#        $sql//=sprintf($sql_fmt,join(", ",@pg_cols));
#        state($sth);
#        $sth//=dbh->prepare($sql);
#        dbh->do("delete from page");
#        our(%obj)=parse_tsv_name(@_);
#        for(values(%obj)){
#          local(*obj)=$_;
#          $sth->execute(@obj{@pg_cols});
#        };
#        page_fetch;
#      };
#    }
{
  sub tsv_insert {
    local(@_)=@_;
    state(@head);
    @head=head('db') unless @head;
    eex(\@head);
    state($head);
    $head//=join(", ",@head);
    state($body);
    $body//=join(", ", map { "?" } @head);
    state($sql);
    $sql//="COPY tsv_temp ($head) FROM STDIN WITH (FORMAT text, DELIMITER E'\t', NULL '\\N')";
    state($sth);
    $sth//=dbh->prepare($sql);
    eex(\@head);
    dbh->do("delete from tsv_temp");
    for (@_){
      my($word)=$_;
      my($rect)=$word->{rect};
      my(@data);
      for(@head){
        if($rect->can($_)){
          push(@data,$rect->$_());
        } elsif ( $_ ne "word" and $word->can($_) ) {
          push(@data,$word->$_());
        } else {
          push(@data,$word->{$_});
        };
      };
      $_=join("\t",@data);
    };
    $sth->execute();
    dbh->pg_putcopydata(join("\n",@_,""));
    dbh->pg_endcopy();
    dbh->do("insert into tsv ( $head ) ( select $head from tsv_temp ) on conflict do nothing");
    eex( dbh->selectrow_hashref("select count(*) from tsv") );
  };
};
#    {
#      my %page;
#      sub page_fetch {
#        my(@page)=hash_fetch("select * from page");
#        for(@page){
#          push(@{$_[$_->{level}]},$_);
#        };
#        @page;
#      };
#      sub page {
#        state(%page);
#        unless(%page){
#          %page=map { $_->{page}, $_ } page_fetch;
#        };
#        return \%page
#      };
#    };
sub dsn {
  state($dsn);
  $dsn//= "dbi:Pg:dbname=nn";
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
          $_=$TsvRect::key{$_};
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
sub hash_fetch {
  local(@_)=@_;
  my $sql = shift;
  my $sth;
  if(ref($sql)) {
    $sth=$sql;
  } else {
    $sth=dbh->prepare($sql);
  };
  $sth->execute;
  my(@res);
  while($_=$sth->fetchrow_hashref){
    push(@res,$_);
  };
  return @res;
};
sub tsv_fetch {
  local(@_)=@_;
  my($where)=@_?join("",@_):"null is null";
  my(@tsv)=hash_fetch("select * from tsv where $where");
  @tsv;
}
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
#      eex(page_insert);
  eex(dsn);
  eex(dbh);
  eex(head('db'));
  eex(head('fs'));
#      eex(page);
};
1;
