package TsvDB;
use base 'Exporter';
use DBI;
use Carp qw( confess croak );
use Carp::Always;
use Nobody::Util;
use common::sense;
use Time::HiRes qw(time);
use Rosetta;
use lib "lib";
use Tsv;
our(@EXPORT);
BEGIN {
  push(@EXPORT,
    qw(
    head  tsv_insert      hash_fetch      word_fetch
    dbh   line_fetch      tsv_fetch       tsv_fetch_range
    )
  );
}
BEGIN {
  use subs (@EXPORT);
  undef &head;
};
BEGIN {
  package AutoSet;
  sub TIESCALAR {
    *class=*main::class;
    local(@_)=@_;
    my($class)=class(shift);
    my($self)=[undef];
    my($ref)=shift;
    die "not a reference to glob" unless ref($ref)eq'GLOB';
    push(@$self,$ref);
    bless($self,$class);
  };
  sub STORE {
    my $self=shift;
    *{$self->[1]}=$self->[0]=shift;
  };
  sub FETCH {
    my $self=shift;
    $self->[0];
  };
  sub DESTROY {
  };
  package ColList;
  our($self,%self);
  BEGIN { tie $self, 'AutoSet', \*self };
  sub new {
    my($class)=class(shift);
    my($tab)=shift;
    my(@col)=splice(@_);
    $self={};
    bless($self,$class);
  };
  sub call {
    $self=shift;
    die unless \%self eq $self;
  };
};
BEGIN {
  our($self,%self);
  tie $self,'AutoSet', \*self;
  @_= { this => is => a => test => this => is => only => a => test => };
  
  $DB::single=1;
  eex(\%self);
  $self=shift(@_);
  eex(\%self);
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
    our(%key);
    local(*key)=\%Rosetta::key;
    $sql//="COPY tsv_tmp ($head) FROM STDIN WITH (FORMAT text, DELIMITER E'\t', NULL '\\N')";
#        $sql//="insert into tsv($head) values ($body) on conflict do nothing";
    dbh->do("delete from tsv");
    state($sth);
    $sth//=dbh->prepare($sql);
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
    my($where)=@_?join("",@_):"null is null";
    my(@tsv)=hash_fetch("select * from tsv where $where order by doc, page_num, line_num, left_px");
    @tsv;
  }
  sub tsv_fetch_range {
    my($time)=time;
    dbh->selectall_hashref("select * from tsv_range r",["rid","tsv"]);
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
  our(%key);
  *key=\%Rosetta::key;
  sub head {
    state(@fs_head,@db_head);
    unless(@fs_head and @db_head){
      my $file=path("tsv")->child('202?-Q?-???.tsv');
      ($file)=glob("$file");
      (@fs_head)=map { split } qx(head -n 1 $file);
      for my $name(map { "$_" } @fs_head) {
        push(@db_head,$key{$name}{db}//=$name);
      }
      push(@db_head,"reject",pop(@db_head));
      unshift(@db_head,"tsv","doc");
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
  my($stime)=time;
  our($set,$row,$col)=[];
  local($col)=$sth->{NAME};
  for $row(@{$sth->fetchall_arrayref}){
    push(@{$set},{mesh($col,$row)});
  };
  return $set;
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
#      eex(page_insert);
#      eex( tsv_fetch_range );
#      eex(dsn);
#      eex(dbh);
#      eex(head('db'));
#      eex(head('fs'));
#      eex(page);
};
1;
