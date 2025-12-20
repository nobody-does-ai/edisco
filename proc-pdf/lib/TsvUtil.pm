package TsvUtil;
use Nobody::Util;
use base 'Exporter';
use common::sense;
our(@EXPORT_OK)=qw(
tsv_parse tsv_partition
pdf_to_png pdf_to_pgs
png_to_tsv pdf_page_count
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
  return $pages_line ? int($pages_line) : undef;
}
sub pdf_to_png {
  my(@res);
  my($fmt)="img/%s.png";
  my($base);
  for my $if(@_){
    say STDERR "doing $if";
    $base=$if->basename(".pdf");
    my ($of)=path(sprintf($fmt,$base));
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
  };
  @res;
};
sub png_to_tsv {
  my(@res);
  my($fmt)="tsv/%s.tsv";
  my($base);
  for my $if(@_){
    $if=path($if);
    say "doing $if";
    $base=$if->basename(".png");
    my ($of)=path(sprintf($fmt,$if->basename(".png")));
    $of->parent->mkdir;
    say "output: $of";
    push(@res,$of);
    unless ( -e "tsv/$base.tsv" ){
      my @tcmd = (
        'tesseract',
        '-l', 'eng',
        $if,
        "tsv/$base",
        'tsv',
      );
      system(@tcmd);
      die "(@tcmd)" if $?;
    };
  };
  return @res;
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
