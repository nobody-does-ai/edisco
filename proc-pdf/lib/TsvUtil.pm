package TsvUtil;
use common::sense;
use Nobody::Util;
use List::Util;
use lib "lib";
use TsvWord;
use TsvRect;
our(@EXPORT);
BEGIN {
  @EXPORT= qw(
fname_parse
group_find
group_text
pdf_page_count
pdf_to_pgs
pdf_to_png
png_to_tsv
tsv_combine_files
tsv_parse
tsv_parse_file
tsv_partition
tsv_to_one
  );
};
sub group_text {
  return join(" ", map { $_->text } @_);
};
our(@cols);
BEGIN { 
  *cols=\@TsvWord::cols;
};
use Exporter qw(import);
sub err {
  say STDERR "@_";
};
#    sub paths {
#      -e or die "$_ does not exist" for @_;
#      @_ = map { safe_isa($_,'Path::Tiny') ? $_ : path($_) } @_;
#      my($max)=max(map { length } @_);
#      say scalar(@_), " paths ($max)";
#      for(@_) {
#        say " => ", $_;
#      };
#      @_;
#    };
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
sub tsv_format {
  local(@_)=@_;
  die "no cols" unless @cols>10;
  while(grep { ref } @_) {
    say scalar(@_), " objs";
    for(my $i=0;$i<@_;$i++) {
      if(ref($_[$i]) eq 'ARRAY') {
        splice(@_,$i,1,@{$_[$i]});
        say scalar(@_), " objs";
      } elsif(ref($_[$i])) {
        my($hash)=$_[$i];
        $_=join("\t", map { $hash->{$_} } @cols);
        $_[$i]=$_;
      };
    };
  };
  join("\n",@_,"");
};
#      our(%hash);
#      say scalar(@_), " things to write";
#      my(@rows);
#      while (@_){
#        say scalar(@rows), " rows";
#        my($data)=shift;
#        my($type)=ref($data);
#        eex({type=>$type});
#        if($type eq 'ARRAY') {
#          unshift(@_,@{$data});
#        } elsif ($type eq 'HASH') {
#          local(*hash)=$data;
#          unshift(@_,join("\t",@hash{@cols})."\n");
#        } elsif ($type eq "") {
#          push(@rows,$data);
#          say scalar(@rows), " rows", length($data);
#        };
#      };
#      say scalar(@rows), "lines";
#      say length for @rows;
#      @rows=join("\n",@rows);
#      say length for @rows;
sub pdf_page_count {
  my ($pdf) = @_;
  my @cmd = ('pdfinfo', $pdf);
  my $info = qx/@cmd 2>&1/;
  die "pdfinfo failed ($?) on '$pdf': $info" if $?;
  my ($pages_line) = $info =~ /^Pages:\s+(\d+)/mi;
  die "Error: Could not determine page count for $_" unless $pages_line;
  return $pages_line;
}
sub get_page_count {
  goto &pdf_page_count;
}
my(%verbose);
sub tsv_to_one {
  die "send paths" unless @_==(grep { safe_isa($_,'Path::Tiny') } @_);
  local(@_)=@_;
  my($otsv,@itsv)=splice@_;
  my(@tsv);
  my(%max)=qw( block_num 0 page_num 0 height 0 );
  my(%off)=%max;
  say scalar(@itsv), " files to parse";
  for(@itsv) {
    local(@_)=TsvWord->parse_file($_);
    say "read ", scalar(@_), " lines from $_";
    for my $tsv(@_) {
      say ref($tsv);
      for my $key(keys %max) {
        $tsv->{$key}+=$off{$key};
        $max{$key}=max($max{$key},$tsv->{$key});
      };
    };
    push(@tsv,[@_]);
    %off=%max;
  };
  say "read ", scalar(@tsv), " files";
  for(@tsv) {
    say "read ", scalar(@$_), " objects";
  };
  $otsv->remove;
  say "read ", scalar(@tsv), " files";
  @tsv=tsv_format(@tsv);
  $otsv->touchpath->spew(
    @tsv
  );
};
sub pdf_to_png {
  die "usage: pdf_to_png(\$png)" unless @_;
  return map { pdf_to_png($_) } @_ unless @_==1;
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
sub tsv_combine {
  local(@_)=@_;
  my(%off)=%{+shift};
  my(%max);
  if(@_) {
    %max=map { $_, 0 } qw( block_num page_num );
  };
  for my $word(@_) {
    $word->{top}+=$off{top};
    $word->{page_num}+=$off{page_num};
    $word->{block_num}+=$off{block_num};
    for(keys %max){
      $max{$_}=max($max{$_},$word->{$_}) if exists $word->{$_};
    };
  };
  $max{top}=$off{top}+$_[0]->{height};
  %off=%max;
  \%off;
};
sub find_group {
  local(@_)=@_;
  local(*_)=shift;
  my(@word)=shift;
  my($top,$bot)=($word[0]->top,$word[0]->bottom);
  ($top,$bot)=(min($top,$bot),max($top,$bot));
  for (my $i=0;$i<@_;$i++) {
    my($word)=$_[$i];
    my($a)=int(sum($word->top,$word->bottom)/2);
    next unless (($a>$top && $a<$bot));
    push(@word,splice(@_,$i,1,undef));
  };
  @_=grep { defined } @_;
  @word=sort { $a->left <=> $b->left } @word;
  \@word;
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
