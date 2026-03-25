package TsvUtil;
use common::sense;
use lib "lib";
use Nobody::Util;
use Tsv;
use Scalar::Util qw(blessed);
our(@EXPORT);
BEGIN {
  @EXPORT= qw(
  tsv_parse tsv_partition
  pdf_to_png pdf_to_pgs
  png_to_tsv pdf_page_count
  tsv_to_tsv
  paths trace
  vert_hash_cmp vert_cmp vert_sort group_find words_merge
  split_lines is_num clean_num parse_xact parse_ivst
  );
};
sub group_text {
  return join(" ", map { $_->text } sort { $a->left <=> $b->left } @_);
};
# Salvaged from the older ../lib/TsvUtil.pm line. It depends on helpers and
# column metadata that do not exist in this local branch yet, so keep it out of
# the active code path until we decide to restore the round-trip TSV writer.
#
# sub tsv_format { ... }
# sub tsv_combine { ... }
# sub vert_sort { ... }
# sub group_find { ... }
sub _rect {
  my($obj)=@_;
  return $obj->rect if blessed($obj) && $obj->can('rect');
  return $obj;
}
sub _field {
  my($obj,@names)=@_;
  for my $name (@names) {
    if(blessed($obj) && $obj->can($name)) {
      return $obj->$name();
    }
    if(ref($obj) eq 'HASH' && exists $obj->{$name}) {
      return $obj->{$name};
    }
  }
  return undef;
}
sub _geom {
  my($obj,$axis)=@_;
  my $rect=_rect($obj);
  if($axis eq 'page') {
    my $page=_field($obj, qw(page page_num));
    return defined($page) ? $page : 0;
  }
  if($axis eq 'top') {
    my $v=_field($rect, qw(top y1 t));
    return defined($v) ? $v : 0;
  }
  if($axis eq 'bottom') {
    my $v=_field($rect, qw(bottom y2 b));
    return defined($v) ? $v : _geom($obj,'top');
  }
  if($axis eq 'left') {
    my $v=_field($rect, qw(left x1 l));
    return defined($v) ? $v : 0;
  }
  die "bad axis: $axis";
}
sub vert_hash_cmp {
  return (
    _geom($a,'page') <=> _geom($b,'page')
      or
    _geom($a,'top') <=> _geom($b,'top')
      or
    _geom($a,'left') <=> _geom($b,'left')
  );
};
sub vert_cmp {
  return vert_hash_cmp();
};
sub vert_sort {
  return sort { vert_hash_cmp } @_;
};
sub group_find {
  local(@_)=@_;
  return unless @_;
  @_ = vert_sort(@_);
  my(@group)=shift;
  return @group if ($group[0]->text//'') eq 'POLLOCK';
  my($bot)=_geom($group[0],'bottom');
  while(@_ && _geom($_[0],'top') <= $bot) {
    my($word)=shift;
    push(@group,$word);
    my($wbot)=_geom($word,'bottom');
    $bot=$wbot if $bot < $wbot;
  }
  return sort { _geom($a,'left') <=> _geom($b,'left') } @group;
};
sub words_merge {
  local(@_)=@_;
  my(@chars)=grep{length($_->text//'')}@_;
  return @_ unless @chars;
  my($char_w)=(sum(map{_rect($_)->dx}@chars)/sum(map{length($_->text)}@chars));
  my(@out)=(shift);
  for my $w (@_){
    my($gap)=_geom($w,'left')-_rect($out[-1])->x2;
    if($gap <= $char_w){
      my($a)=$out[-1];
      my($merged)=TsvWord->new({
        text  => ($a->text//'').' '.($w->text//''),
        left  => _rect($a)->x1,
        top   => _geom($a,'top'),
        width => _rect($w)->x2 - _rect($a)->x1,
        height=> _rect($a)->dy,
      });
      $out[-1]=$merged;
    } else {
      push(@out,$w);
    };
  };
  return @out;
};
sub split_lines {
  my(@words)=vert_sort(grep{defined $_->text}@_);
  my(@rows);
  while(@words){
    my(@row)=group_find(@words);
    push(@rows,\@row);
    my(%seen)=map{$_=>1}@row;
    @words=grep{!$seen{$_}}@words;
  };
  return @rows;
};
sub is_num { ($_[0]//'') =~ m{^-?[\d,]*\.?\d+$} }
sub clean_num { my $n=shift//return undef; $n=~s/,//g; $n }
sub parse_xact {
  my($text)=join(' ', map{$_->text//''}@_);
  my(@tok)=split(/\s+/,$text);
  return unless @tok >= 2;
  my($date)=$tok[0];
  return unless $date =~ m{^\d{1,2}/\d{2}/\d{4}$};
  my($amount)=$tok[-1];
  return unless is_num($amount);
  my($desc)=join(' ',@tok[1..$#tok-1]);
  return { date=>$date, desc=>$desc, amount=>clean_num($amount) };
};
sub parse_ivst {
  my(@w)=@_;
  my(@nums);
  while(@w && is_num($w[-1]->text)){
    unshift @nums, clean_num((pop @w)->text);
  };
  return unless @nums >= 3;
  my($desc)=join(' ', map{$_->text//''}@w);
  return unless $desc =~ /\w/;
  return if $desc =~ /^Total\b/i;
  my($num,$sprice,$total,$basis,$unreal);
  if    (@nums==5){ ($num,$sprice,$total,$basis,$unreal)=@nums }
  elsif (@nums==4){ ($sprice,$total,$basis,$unreal)=@nums }
  elsif (@nums==3){ ($total,$basis,$unreal)=@nums };
  my(%h)=(desc=>$desc);
  $h{num}   =$num    if defined $num;
  $h{sprice}=$sprice if defined $sprice;
  $h{total} =$total  if defined $total;
  $h{basis} =$basis  if defined $basis;
  $h{unreal}=$unreal if defined $unreal;
  return \%h;
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
my(%verbose)={ skip=>0, trace=>1 };
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
  if($verbose{trace}==2){
    ($msg)=join(":",@caller[1,2,3],"@_");
  } elsif($verbose{trace}==1) {
    ($msg)=join(":",@caller[3],"@_");
  } else {
    ($msg)=$caller[3];
  };
  say STDERR $msg;
};
sub tsv_parse {
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
  $of->parent->mkdir;
  err("xform $if to $of (convert -density 300 -colorspace Gray)");
  system(qw(convert -density 300 -colorspace Gray), $if, $of);
  die "convert failed: $?" if $?;
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
    my $oem=1;
    my $oem_name=(qw(legacy lstm legacy+lstm default))[$oem];
    err("xform $if to $of (tesseract oem=$oem $oem_name)");
    open(my $tmp,">&STDOUT");
    open(STDOUT,">",$of);
    my @tcmd = (
      'tesseract',
      '--oem', $oem,
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
