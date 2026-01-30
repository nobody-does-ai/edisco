package TsvUtil;
use common::sense;
use Nobody::Util;
use List::Util;
use TsvWord;
use Carp qw(croak confess cluck carp);
use File::stat qw(:FIELDS);
use TsvRect;
use Nobody::PP;
use autodie;
our(@EXPORT);
BEGIN {
  @EXPORT= qw(
fname_parse
group_find
group_text
get_page_count
pdf_to_pgs
pdf_to_png
png_to_tsv
tsv_combine_files
tsv_to_one
  );
};
my(%verbose);
BEGIN {
#      $verbose{skips}=1;
#      $verbose{cmds}=1;
};
sub group_text {
  return join(" ", map { $_->text } sort { $a->left <=> $b->left } @_);
};
our(@cols);
BEGIN { 
  *cols=\@TsvWord::cols;
};
use Exporter qw(import);
sub err {
  say STDERR "@_";
};
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
  unshift(@_,join("\t",@cols));
  while(grep { ref } @_) {
    for(my $i=0;$i<@_;$i++) {
      if(ref($_[$i]) eq 'ARRAY') {
        splice(@_,$i,1,@{$_[$i]});
      } elsif(ref($_[$i])) {
        my($hash)=$_[$i];
        $_=join("\t", map { $hash->{$_} } @cols);
        $_[$i]=$_;
      };
    };
  };
  join("\n",@_,"");
};
sub get_page_count {
  my ($pdf) = @_;
  my @cmd = ('pdfinfo', $pdf);
  my $info = qx/@cmd 2>&1/;
  die "pdfinfo failed ($?) on '$pdf': $info" if $?;
  my ($pages_line) = $info =~ /^Pages:\s+(\d+)/mi;
  die "Error: Could not determine page count for $_" unless $pages_line;
  return $pages_line;
}
sub tsv_to_one {
  local(@_)=@_;
  my($otsv,@itsv)=splice@_;
  my(@tsv);
  my(%max)=qw( block_num 0 page_num 0 top 0 );
  my(%off)=%max;
  my($time)=time;
  if(-e $otsv) {
    stat($otsv);
    my($ot)=$st_mtime;
    my($it)=sort { $b <=> $a } map { stat($_); $st_mtime } @itsv;
    $otsv->remove if($ot<$it);
  };
  return $otsv if -e $otsv;
  for(@itsv) {
    say STDERR "$_ => $otsv";
    local(@_)=TsvWord->parse_file($_);
    for my $tsv(@_) {
      for my $key(keys %max) {
        $tsv->{$key}+=$off{$key};
        $max{$key}=max($max{$key},$tsv->{$key});
      };
    };
    push(@tsv,[@_]);
    %off=%max;
  };
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
  } else {
    my(@cmd)=qw(pdftoppm -png -singlefile $if > $of);
    run($if,$of,@cmd);
  };
  return $of;
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
    my @tcmd = (
      'tesseract',
      '-l', 'eng',
      '$if',
      "-",
      'tsv',
      '>',
      '$of'
    );
    run($if,$of,@tcmd);
  };
  return $of;
};
sub pdf_to_pgs {
  return map { pdf_to_pgs($_) } @_ unless 1==@_;
  my($fmt)="pdf/%s-%03d.pdf";
  my ($if)=path(shift);
  my($pages)=get_page_count($if);
  for(my $pg=0;$pg<$pages;$pg++) {
    my($of)=path(sprintf($fmt,$if->basename(".pdf"),$pg));
    push(@_,$of);
    if(-e $of) {
      err("skip  $if to $of") if $verbose{skips};
    } else {
      my (@cmd)=( qw(qpdf), '$if', qw( --pages .), 1+$pg, '--', '-', '>', '$of');
      run($if,$of,@cmd);
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
sub group_find {
  local(@_)=@_;
  local(*_)=shift;
  if($_[0]->text eq "POLLOCK"){
    return shift;
  };
  my($blk,$bot,@word)=map { $_->block_num,$_->bottom, $_ } shift;
#      my(@skip);
  while(@_ and ($_[0]->cy)<$bot) {
#        if($_[0]->block_num == $blk) {
      push(@word,shift);
#        } else {
#          push(@skip,shift);
#        }
  };
#      unshift(@_,@skip);
  @word = sort { $a->left <=> $b->left } @word;
  @word;
};
sub run {
  local(@_)=@_;
  my($if)=shift;
  my($ff)=shift;
  my($of)=path("$ff.tmp");
  $_->touchpath->remove for $ff,$of;
  say STDERR "$if => $ff";
  @_=map { split } @_;
  for(@_){
    if($_ eq '$if') {
      $_=$if;
    } elsif ($_ eq '$of') {
      $_=$of;
    };
  };
  err("@_") if $verbose{cmds};
  system("@_");
  if($?) {
    $of->remove;
    die "@_";
  };
  $of->move($ff);
};
1;
