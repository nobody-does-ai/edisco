package TsvDoc;
use lib "lib";
use Nobody::Util;
use Nobody::PP @Nobody::PP::EXPORT_OK;
use Scalar::Util;
use Tie::TsvHash;
use common::sense;
use subs qw( lines key fields hdr  ws hs objs );
*key=\&Tie::TsvHash::key;
use vars qw($debug);
use Carp qw( carp cluck confess croak );
our($file);
sub set_file {
  $DB::single=1;
  return if(safe_isa($_[0],"TsvDoc"));
  $file=path(shift);
};
sub lines() {
  state(@lines);
  unless(@lines) {
    unless(defined($file)){
      confess "Must call set_file before lines";
    };
    @lines=$file->lines;
    eex({lines=>\@lines}) if $debug;
  };
  return @lines;
};
my($hdr);
sub fields() {
  state(@fields);
  unless(@fields) {
    @fields=grep { @$_ } map { [ split ] } lines;
    $hdr=shift(@fields);
    eex({fields=>\@fields, hdr=>$hdr}) if $debug;
  };
  \@fields;
};
sub hdr {
  state(@hdr);
  unless(defined($hdr)) {
    fields();
    @hdr=@$hdr;
    eex({hdr=>\@hdr}) if $debug;
  };
  $hdr;
};
sub idx($) {
  state(%idx);
  unless(%idx) {
    fields unless $hdr;
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
sub page {
  state($page);
  unless($page){
    my($obj)=objs->[0];
    $page=$obj;
    rows();
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
sub word {
  return [ grep { $_->{level}==5 and defined $_->{text} and length $_->{text} } @{objs()} ];
};
sub objs {
  state(@objs);
  unless(@objs){
    my(@r)=@{fields()};
    my(@k)=map { key($_) } @$hdr;
    $_=$r[0];
    my(@o)=map { [ mesh(\@k,$_) ] } @r;
    for(keys @o) {
      local(*_)=\$o[$_];
      my(%h);
      tie %h, 'Tie::TsvHash';
      %h=@$_;
      $_=\%h;
    };
    my(%k)=map { $_, $_ } @k;

    for my $o(@o){
      our(%o);
      *o=$o;
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
sub ysort {
  sort { $a->{y1} <=> $b->{y1} } @_;
};
sub inter {
  my($w1,$w2)=@_;
  die unless defined($w1) and defined($w2);
  return 0 if($w1->{y1} < $w2->{y1} and $w1->{y2} < $w2->{y2});
  return 0 if($w2->{y1} < $w1->{y1} and $w2->{y2} < $w1->{y2});
  return 1;
};
sub rows {
  state(@rows);
  unless(@rows){
    my(@o)=@{word()};
    my(@a,@g,@i)=[0];
    while(@o) {
      my($y2) = 1+min(map { $_->{y1} } @o );
      while(@i=grep { $o[$_]->{y1}<=$y2 } keys @o){
        push(@g,map { $o[$_] } @i);
        @o[@i]=();
        @o=grep { defined } @o;
        $y2=max(map{$_->{y2}} @g);
      };
      @g=sort { $a->{x1} <=> $b->{x1} } @g;
      push(@a,[0+@g,splice(@g)]);
    };
    for(@a) {
      shift(@$_) unless ref $_->[0];
    };
#        my $msg={ _a=>"END", o=>0+@o, g=>0+@g, a=>sum(map {$_->[0]} @a)};
#        $msg->{_b}=sum(map { $msg->{$_} } qw(o g a));
#        eex($msg);
    @rows=@a;
  };
  \@rows;
};
unless(caller) {
  $file=path("input.tsv");
  rows();
};
sub ws() {
  state(@ws);
  unless(@ws){
    @ws=map { $_->{w}/length($_->{txt}) } @{word()};
  };
  @ws;
};
sub hs() {
  state(@hs);
  unless(@hs){
    @hs=map { $_->{h} } @{word()};
  };
  @hs;
};

1;
