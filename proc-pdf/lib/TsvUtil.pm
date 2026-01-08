package TsvUtil;
use Nobody::Util;
use base 'Exporter';
use common::sense;
our(@EXPORT_OK)=qw(
tsv_parse tsv_partition
pdf_to_png pdf_to_pgs
png_to_tsv pdf_page_count
get_page_count
);
sub tsv_parse {
  my $path=path(map { "$_" } shift);
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
  my ($pdf) = @_;

  my @cmd = ('pdfinfo', $pdf);
  my $info = qx/@cmd 2>&1/;
  if ($? != 0) {
    warn "pdfinfo failed on '$pdf': $info";
    return undef;
  }

  my ($pages_line) = $info =~ /^Pages:\s+(\d+)/mi;
  die "Error: Could not determine page count for $_\n" unless $pages_line;
  return $pages_line;
}
sub get_page_count {
  goto &pdf_page_count;
}
sub pdf_to_png($) {
  die "usage: pdf_to_png(\$png)" unless @_==1;
  my(@res);
  my($fmt)="%s/%s.png";
  my($base,$dir);
  my($if)=$_[0];
  say STDERR "doing $if";
  $base=$if->basename;
  $dir=$if->parent->basename;
  my ($of)=path(sprintf($fmt,$dir,$base));
  push(@res,$of);
  next if -e $of;
  if(my $pid=fork){
    while($pid!=waitpid($pid,0)){
      say "??? $?";
    };
    die "pdftoppm:$?" if $?;
  } else {
    $of->parent->mkdir;
    open(STDOUT,">",$of->stringify);
    exec(qw(pdftoppm -png -singlefile), $if);
    die "exec:pdftoppm:$!";
  };
  say readlink($_) for glob "/proc/$$/fd/*";
  return $of;
};
sub png_to_tsv {
  die "usage: png_to_tsv(\$png)" unless @_==1;
  my(@res);
  my($fmt)="%s/%s";
  my($base,$dir);
  my $if=$_[0];
  $if=path($if);
  $base=$if->basename(".png");
  $dir=$if->parent->basename;
  my ($of)=path(sprintf($fmt,$dir,$base));
  say "doing png_to_tsv $if => $of";
  $of->parent->mkdir;
  unless ( -e "$of" ) {
    my @tcmd = (
      'tesseract',
      '-l', 'eng',
      $if,
      $of,
      'tsv',
    );
    system(@tcmd);
    die "(@tcmd)" if $?;
  };
  return $of;
};
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
sub pdf_to_pgs {
  my(@res);
  my($fmt)="pgs/%s-%03d.pdf";
  for my $if(@_) {
    my($pages)=pdf_page_count($if);
    for(my $pg=0;$pg<$pages;$pg++) {
      my($of)=sprintf($fmt,$if->basename(".pdf"),$pg);
      push(@res,$of);
      unless(-e $of) {
        say STDERR "xform $if to $of\n";
        path("pgs")->mkdir;
        my (@cmd)=( qw(qpdf), $if, qw( --pages .), 1+$pg, '--', $of);
        system(@cmd);
        die "(@cmd) failed" if $?;
      };
    };
  };
  @res;
}

1;
