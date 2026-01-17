package TsvUtil;
use common::sense;
use Nobody::Util;
use lib "lib";
use TsvWord;
our(@EXPORT);
BEGIN {
  @EXPORT= qw(
  tsv_parse tsv_partition
  pdf_to_png pdf_to_pgs
  png_to_tsv pdf_page_count
  tsv_to_tsv
  paths trace
  );
};
sub tsv_to_tsv {
  trace(@_);
  my($out,@list)=@_;
};
use Exporter qw(import);
sub err {
  say STDERR "@_";
};
sub paths {
  -e or die "$_ does not exist" for @_;
  @_ = map { safe_isa($_,'Path::Tiny') ? $_ : path($_) } @_;
  my($max)=max(map { length } @_);
  say scalar(@_), " paths ($max)";
  for(@_) {
    say " => ", $_;
  };
  @_;
};
sub ddx { goto \&eex };
my(%verbose)={ skip=>0, trace=>0 };
sub gather {
  local(@_)=@_;
  my(%res);
  for(@_) {
    die "bad pair(@$_)" unless reftype($_)eq'ARRAY' and 2==@$_;
    my($key,$val)=@$_;
    push(@{$res{$key}},$val);
  };
  return %res if wantarray;
  return \%res;
};
sub trace {
  my(@caller)=caller(0);
  @caller[3]=[caller(1)]->[3];
  my($pkg)=__PACKAGE__;
  for(@caller[3]){
    s{^${pkg}::}{};
  };
  my($msg);
  if($verbose{trace}==3){
    ($msg)=join(":",@caller[1,2,3],"@_");
  } elsif($verbose{trace}==2) {
    ($msg)=join(":",@caller[3],"@_");
  } elsif($verbose{trace}==1) {
    ($msg)=$caller[3];
  };
  say STDERR $msg if $msg;
};
sub tsv_parse {
  trace(@_);
  my $path=path(shift);
  my(@rows)=$path->lines ;
  my(@cols)=map { split } shift(@rows);
  my(@word);
  for(@rows) {
    my(@vals)=split;
    my(@pair);
    die ppx(
      \@vals, \@cols
    ) if @cols<@vals;
    for(my $i=0;$i<@cols;$i++) {
      push(@pair,$cols[$i],@vals[$i])
    };
    push(@word,{ @pair });
  };
  @word=TsvWord->from(@word);
  \@word;
};
sub pdf_page_count {
  trace(@_);
  my ($pdf) = @_;
  my @cmd = ('pdfinfo', $pdf);
  my $info = qx/@cmd 2>&1/;
  die "pdfinfo failed ($?) on '$pdf': $info" if $?;
  my ($pages_line) = $info =~ /^Pages:\s+(\d+)/mi;
  die "Error: Could not determine page count for $_" unless $pages_line;
  return $pages_line;
}
sub get_page_count {
  trace(@_);
  goto &pdf_page_count;
}
sub pdf_to_png {
  die "usage: pdf_to_png(\$png)" unless @_;
  return map { pdf_to_png($_) } @_ unless @_==1;
  trace(@_);
  my($if)=path($_[0]);
  die "$if does not exist" unless -e $if;
  my($of)=path(sprintf("png/%s.png",$if->basename(".pdf")));
  if($of->exists) {
    err("skip  $if to $of") if $verbose{skips};
    return $of;
  };
  if(my $pid=fork){
    while($pid!=waitpid($pid,0)){
      eex "??? $?";
    };
    die "pdftoppm:$?" if $?;
  } else {
    $of->parent->mkdir;
    open(STDOUT,">",$of->stringify);
    exec(qw(pdftoppm -png -singlefile), $if);
    die "exec:pdftoppm:$!";
  };
  return path($of);
};
sub png_to_tsv {
  die "usage: png_to_tsv(\$png)" unless @_;
  return map { png_to_tsv($_) } @_ unless @_==1;
  trace(@_);
  my($fmt)="tsv/%s.tsv";
  my($base,$dir);
  my $if=shift;
  die "$if does not exsit" unless $if->exists;
  my ($of)=path(sprintf($fmt,$if->basename(".png")));
  $of->parent->mkdir;
  if ( -e "$of" ) {
    err("skip  $if to $of") if $verbose{skips};
  } else {
    err("xform $if to $of");
    open(my $tmp,">&STDOUT");
    open(STDOUT,">",$of);
    my @tcmd = (
      'tesseract',
      '-l', 'eng',
      '$if',
      "-",
      'tsv',
    );
    run($if,$of,@tcmd);
    die "(@tcmd)" if $?;
  };
  return $of;
};
sub pdf_to_pgs {
  trace(@_);
  return map { pdf_to_pgs($_) } @_ unless 1==@_;
  my($fmt)="pdf/%s-%03d.pdf";
  my ($if)=path(shift);
  my($pages)=pdf_page_count($if);
  for(my $pg=0;$pg<$pages;$pg++) {
    my($of)=path(sprintf($fmt,$if->basename(".pdf"),$pg));
    push(@_,$of);
    if(-e $of) {
      err("skip  $if to $of") if $verbose{skips};
    } else {
      err "xform $if to $of";
      $of->parent->mkdir;
      my (@cmd)=( qw(qpdf), $if, qw( --pages .), 1+$pg, '--', $of);
      system(@cmd);
      die "(@cmd) failed" if $?;
    };
  };
  return @_;
}
sub next_set {
  my(@word)=@_;
  my($top)=$word[0]->top;
  my($bot)=$word[0]->bottom;
  eex( { top=>$top, bot=>$bot } );
  while($word[0]->top<$bot){
    $bot=max($bot,shift(@word)->bottom);
  };
};
sub tsv_partition {
  trace(@_);
  my(@word)=@_;
  return () unless @word;
  my(@part);
  @word=sort {
    $a->top <=> $b->top
      or
    $a->bottom <=> $b->bottom
      or
    refaddr($a) <=> refaddr($b)
  } @word;
  my(@set)=next_set(@word);;
};
sub run {
  if(my $pid=fork) {
    my($key);
    while(($key=waitpid(0,0))>1) {
      say "$key returned $?";
      return if $key==$pid;      
    };
    die "waitpid: $key";
  };
  my($if)=shift;
  my($of)=shift;
  my($tf)=path($of.".tmp");
  open(STDOUT,">",$tf);
  local(@_)=@_;
  eex(\@_);
  for(@_) {
    $_=eval $_ if m{^\$};
  };
  eex(\@_);
  system(@_);
  if($?) {
    $tf->remove;
    die "($if,$of,@_)";
  };
  $tf->move($of);
  $of;
};
1;
