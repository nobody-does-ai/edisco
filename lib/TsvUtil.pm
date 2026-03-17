package TsvUtil;
use common::sense;
use Nobody::Util;
use List::Util;
use Carp qw(croak confess cluck carp);
use File::stat qw(:FIELDS);
use Nobody::PP;
use autodie;
our(@EXPORT,@EXPORT_OK);
BEGIN {
  @EXPORT=qw( vert_sort vert_hash_cmp );
  @EXPORT_OK= qw(
fname_parse
group_find
group_text
get_page_count
pdf_to_pgs
pdf_to_png
png_to_tsv
tsv_to_one
older
trig
  );
};
my(%verbose);
BEGIN {
  $verbose{skips}=1;
};
sub group_text {
  return join(" ", map { $_->text } sort { $a->left <=> $b->left } @_);
};
our(@cols);
BEGIN { 
  *cols=\@TsvWord::cols;
};
use Exporter qw(import);
sub older {
  local(@_)=@_;
  my ($if,$of)=(shift,shift);
  $if=path($if);
  $of=path($of);
  return 0 unless -e $of;
  return 0 unless -e $if;
  $if->stat;
  my ($itime)=min($st_atime,$st_mtime,$st_ctime);
  $of->stat;
  my ($otime)=min($st_atime,$st_mtime,$st_ctime);
  if($itime<=$otime) {
#        say "$if ot $of";
    return 1;
  } else {
    say "$if nt $of";
    return 0;
  };
};
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
  my(%older);
  for(@itsv) {
    if(older($_,$otsv)) {
      eex "$_ ot $otsv";
    } else {
      $older{$_}=0;
      eex "$_ nt $otsv";
    };
  };
  return $otsv unless keys %older;
  for(@itsv) {
    say STDERR "$_ => $otsv";
    local(@_)=$_->lines;
    @_=TsvWord->parse_lines(@_);
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
  if(older($if,$of)) {
    err("skip  $if to $of") if $verbose{skips};
  } else {
    my(@cmd)=qw(pdftoppm -png -r 300 -singlefile $if > $of);
    run($if,$of,@cmd);
  };
  return $of;
};
sub png_to_tsv {
  err("png_to_tsv(@_)\n");
  die "usage: png_to_tsv(\$png)" unless @_;
  return map { png_to_tsv($_) } @_ unless @_==1;
  my($fmt)="tsv/%s.tsv";
  my($base,$dir);
  my $if=shift;
  die "$if not defined" unless defined $if;
  die "$if does not exsit" unless $if->exists;
  my ($of)=path(sprintf($fmt,$if->basename(".png")));
  $of->parent->mkdir;
  if (older($if,$of)) {
    err("skip  $if to $of") if $verbose{skips};
  } else {
    my @tcmd = (
      'tesseract',
      '$if',
      "-",
      '--dpi', 300,
      'tsv',
      '>',
      '$of'
    );
    run($if,$of,@tcmd);
  };
  return $of;
};
INIT {
  my(%trig);
  %trig=(
    qw(
    TRANSACTIONS 2
    INVESTMENTS 2
    INSURED 1
    Page 1
    Program 1
    )
  );
  sub trig {
    return $trig{$_};
  };
};
sub pdf_to_pgs {
  die "usage: pdf_to_pgs(\$pdf)" unless @_;
  return map { pdf_to_pgs($_) } @_ unless 1==@_;
  my($fmt)="pdf/%s-%03d.pdf";
  my ($if)=path(shift);
  my($pages)=get_page_count($if);
  for(my $pg=1;$pg<=$pages;$pg++) {
    my($of)=path(sprintf($fmt,$if->basename(".pdf"),$pg));
    push(@_,$of);
    if(older($if,$of)) {
      err("skip  $if to $of") if $verbose{skips};
    } else {
      my (@cmd)=( qw(qpdf), '$if', qw( --pages .), $pg, '--', '-', '>', '$of');
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
sub vert_hash_cmp {
  return (
    $a->{page} <=> $b->{page}
      or
    $a->{top} <=> $b->{top}
      or
    $a->{left} <=> $b->{left}
  );
};
sub vert_cmp {
  return (
    $a->page <=> $b->page
      or
    $a->top <=> $b->top
      or
    $a->left <=> $b->left
  );
};
sub vert_sort {
  if(@_ == grep { U::blessed($_) } @_) {
    return sort { vert_cmp } @_;
  } elsif (@_==grep { !U::blessed($_) } @_) {
    return sort { vert_hash_cmp } @_;
  } else {
    die "mixed blessed and unblessed";
  };
};
sub group_find {
  local(@_)=@_;
  local(*_)=shift;
  return unless @_;
  @_ = vert_sort @_;
  my($i)=0;
  my(@word)=shift;
  my($bot)=$word[0]->y2;
  while(@_ and $_[0]->cy<$bot) {
    my($word)=shift;
    push(@word,$word);
    $bot=$word->y2 if $bot<$word->y2;
  }
  sort { $a->x1 <=> $b->x1 } @word;
};
my(%pid);
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
  if(my $pid=fork) {
    child_wait;
  } else {
    system("@_");
    if($?) {
      $of->remove;
      warn "@_\n";
      exit(1);
    };
    if($of->move($ff)) {
      exit(0);
    } else {
      exit(1);
    };
  };
};
1;
