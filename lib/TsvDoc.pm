package TsvDoc;
use common::sense;
use lib "lib";
use Nobody::PP @Nobody::PP::EXPORT_OK;
use Nobody::Util;
use Scalar::Util;
use TsvDB;


use vars qw($debug);
use Carp qw( carp cluck confess croak );
our(@subs,@vars);
BEGIN {
#      @vars=qw(
#      @lines @fields @hdr @idx @page @text @objs @rows @ws @hs %debug $debug %idx
#      );

  @subs=grep { length && !/file/ } map { substr($_,1) } @vars;
  require Carp;
  push(@subs,@Carp::EXPORT_OK);
  use Carp;
  use Nobody::PP;
  use Carp @Carp::EXPORT_OK;
  use common::sense;
};
use subs @subs;
use vars @vars;
my($hdr);
my(%key);
our(%raw,%key);
BEGIN {
  %key=qw(
  doc doc
  page_num page
  top_px y1
  left_px x1
  height_px dy
  width_px dx
  text text
  );
  for my $key( keys %key ) {
    for($_=$key) {
      if(s{_num$}{} or s{_px$}{}){
        $key{$_}=$key{$key};
      };
    };
  };
}
sub key {
  local($_)=shift;
  return $key{$_};
};
sub raw();
sub raw() {
  state(@raw);
  unless(@raw){
    my($col)=join(", ", qw( doc page_num top_px left_px height_px width_px text ));
    my($sql)=qq( select $col from tsv where level = 5 order by $col);
    my @r=map { @$_} TsvDB::hash_fetch($sql);
    for(@r) {
      local(*raw)=$_;
      my(%new);
      for(keys %raw) {
        $new{key($_)}=$raw{$_};
      };
      $new{y2}=$new{y1}+$new{dy};
      $new{x2}=$new{x1}+$new{dx};
      $_=\%new;
    };
    @raw=@r;
    return raw;
  };
  die "no shit" unless @raw;
  return \@raw;
};
    
$hdr=[qw(
  level	
  page_num block_num par_num line_num word_num
  left_px	top_px	width_px	height_px
  conf	text
  )];
sub hdr {
  state(@hdr);
  unless(@hdr) {
    @hdr=map { key($_) } @$hdr;
  };
  [ @hdr ];
};
sub idx($) {
  state(%idx);
  unless(%idx) {
    @_=map { key($_) } map { lc } @$hdr;
    %idx = map { $_[$_]=>$_ } keys @_;
    for(keys %idx){
      $idx{key($_)}=$idx{$_};
    };
    eex(\%idx) if $debug;
  };
  $idx{$_[0]};
};
#      BEGIN { $debug = 1 };
sub ysort {
  sort { $a->{y1} <=> $b->{y1} } @_;
};
sub isect {
  my($w1,$w2)=@_;
  die unless defined($w1) and defined($w2);
  return 0 if($w1->{y1} < $w2->{y1} and $w1->{y2} < $w2->{y2});
  return 0 if($w2->{y1} < $w1->{y1} and $w2->{y2} < $w1->{y2});
  return 1;
};
sub rowcmp() { 
  $a->{doc}<=>$b->{doc}
    or
  $a->{page}<=>$b->{page}
    or
  $a->{y1}<=>$b->{y1}
}
sub rows {
  state(%rows);
  my(@a,@g,@i)=[0];
  unless(%rows){
    @_=@{words()};
    my(%r);
    while(@_){
      local($_)=shift;
      my($d)=$_->{doc};
      my($p)=$_->{page};
      push(@{$rows{$d}{$p}},$_);
    };
  };
  return \%rows;
};
sub page {
  state($page);
  unless(defined($page)){
    my($obj)=objs()->[0];
    $page=$obj;
    eex({rows=>scalar(rows())});
  }
  return $page;
};
sub text {
  state($text);
  unless(defined($text)){
    my($page)=page;
    $text="."x($page->{w}*$page->{h});
  };
  $text;
};
sub words {
  state(@words);
  unless(@words) {
    my(@w)=@{objs()};
    @w=grep { defined $_->{text} and length $_->{text} } @w;
    @words=@w;
  };
  return [@words];
};
sub objs {
  state(@objs);
  unless(@objs){
    my(@o)=@{raw()};
    die "nothing in \@o" unless @o;
    for my $o(@o){
      our(%o);
      $o{x}=$o{x1}+$o{w}/2;
      $o{y}=$o{y1}+$o{h}/2;
      $o{x2}=$o{x1}+$o{w};
      $o{y2}=$o{y1}+$o{h};
    };
    @objs=@o;
    eex({objs=>\@objs}) if $debug;
  };
  \@objs;
};
sub ws() {
  state(@ws);
  unless(@ws){
    unless(length($_->{txt})){
      eex( \@ws );
      exit(1);
    };
    @ws=map { $_->{w}/length($_->{txt}) } @{words()};
  };
  @ws;
};
sub hs() {
  state(@hs);
  unless(@hs){
    @hs=map { $_->{h} } @{words()};
  };
  @hs;
};
unless(caller) {
  rows;
}
