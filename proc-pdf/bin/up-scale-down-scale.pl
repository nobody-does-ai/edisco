#!/usr/bin/env perl
use common::sense;
use Path::Tiny qw(path);
use lib "gather";
use lib "lib";
use Nobody::Util;
use Nobody::PP;
use Carp::Always;

# ocr_grid_math_v2.pl
#
# Changes requested:
#  (1) Dump "max magnification" view (scaled lattice) for eyeballing/experiments.
#  (2) Downscale based on AVERAGE density, then adjust DOWNWARD (i.e. reduce k => wider output)
#      until the scaling can be applied WITHOUT DISCARDING any characters (no collisions).
#
# Input: TSV with text + geometry.
#  - Must contain a text column (text/chr/char/token/value/glyph).
#  - And either (x,y,w,h) OR (x1,y1,x2,y2).
#
# Output:
#  - Header lines with computed parameters
#  - MAX MAGNIFICATION dump (ASCII)
#  - COLLISION-FREE downscaled grid (ASCII)
#
# Notes:
#  - If collisions remain even at k=1 (true identical/rounded coords), we DO NOT discard.
#    Instead we keep k=1 and "spill right" within the row to preserve every glyph.

#    sub usage {
#      die <<"USAGE";
#    Usage:
#      $0 input.tsv > out.txt
#    
#    Optional env vars:
#      OCR_GRID_TEXT_COL   OCR_GRID_X_COL OCR_GRID_Y_COL OCR_GRID_W_COL OCR_GRID_H_COL
#      OCR_GRID_X1_COL OCR_GRID_Y1_COL OCR_GRID_X2_COL OCR_GRID_Y2_COL
#    
#      OCR_GRID_FILL=' '            fill char (default space)
#      OCR_GRID_PAD=1               padding cells around grids (default 1)
#    
#      OCR_MAG_MAX_DIM=8000         safety cap for max-magnification (default 8000)
#      OCR_GRID_MAX_COLS=2000       safety cap for downscaled cols (default 2000)
#      OCR_GRID_MAX_ROWS=2000       safety cap for downscaled rows (default 2000)
#    
#      OCR_GRID_SPILL=right|mark    when k==1 still collides: spill right (default right) or mark with '#'
#    USAGE
#    }

#    my $i_text = pick_col('OCR_GRID_TEXT_COL', qw(text chr char token value glyph));
#    my $i_x    = pick_col('OCR_GRID_X_COL',    qw(x cx x_center xcenter));
#    my $i_y    = pick_col('OCR_GRID_Y_COL',    qw(y cy y_center ycenter));
#    my $i_w    = pick_col('OCR_GRID_W_COL',    qw(w width));
#    my $i_h    = pick_col('OCR_GRID_H_COL',    qw(h height));
#    
#    my $i_x1   = pick_col('OCR_GRID_X1_COL',   qw(x1 left l));
#    my $i_y1   = pick_col('OCR_GRID_Y1_COL',   qw(y1 top  t));
#    my $i_x2   = pick_col('OCR_GRID_X2_COL',   qw(x2 right r));
#    my $i_y2   = pick_col('OCR_GRID_Y2_COL',   qw(y2 bottom b));

#    die "Need a text column (e.g. text/chr/char/token)\n" unless defined $i_text;

sub median {
  my (@a) = @_;
  @a = grep { defined && $_ > 0 } @a;
  @a = sort { $a <=> $b } @a;
  my $n = @a;
  return 1 unless $n;
  return $a[int($n/2)] if $n % 2;
  return ($a[$n/2 - 1] + $a[$n/2]) / 2;
}
use TsvDoc;
our($file);
*file=\$TsvDoc::file;
my($tsv)=path("tsv");
my(@kid)=$tsv->children;
eex($_) for $tsv, @kid;
say for splice(@{$_->lines},0);
__DATA__
my(@tsv)=map{path($_)}path("tsv")->ch
my($base)=split(m{.tsv$},shift(@tsv));
my($top)=$$;
my($doc)=TsvDoc->new();
for($file=path(shift(@tsv)))
{
  my($base)=$file->basename(".tsv");
  unless(-e "$base.tsv") {
    my $cmd;
    unless(-e "$base.png") {
      unless(-e "$base.pdf"){
        die "no input files found";
      };
      $cmd="pdftoppm -singlefile -r 300 -png $base.pdf $base";
      say STDERR $cmd;
      system $cmd or die "$cmd failed";
    }
    $cmd="tesseract $base.png $base tsv";
    say STDERR $cmd;
    system $cmd or die "$cmd failed";
  };
  die "no input found" unless -e $file;
};
TsvDoc::set_file("input.tsv");
sub disp {
  my($data)=shift;
  if(ref($data) eq "ARRAY"){
    eex({a=>0+@$data});
    return join(" ", "A", map { disp($_) } @$data);
  } else {
    eex({t=>$data});
    return $data->{txt};
  };
};
my @word;
my @rows = grep { $_->[0] } @{TsvDoc->rows()};
my @text;
*page=\&TsvDoc::page;
my ($px1,$px2)=(page()->{x1}, page()->{x2});
sub stats {

};
sub cols {
  my(@cols)=@_;
  eex(@cols[0]);
  return;
  local(*_)=shift;
  local(@_)=grep { ref($_) eq 'HASH' } @_;

  my(%cols) = map { $_, $_ } @cols;
  my($len,$cnt)=map { delete $cols{$_} } qw(len cnt);
  $_=[] for values %cols;
  $cols{txt}//='';
  for(@_) {
    my($w)=$_;
    for(@cols) {
      my($c)=$_;
      push(@{$cols{$c}},$w->{$c});
    };
  };
  \%cols;
};
sub do_row(@) {
  local(*_)=shift;
  my($cols)=cols(\@_,qw(len txt x1 y1 x2 y2 dx dy));
  eex($cols);
  my($y1,$y2,$ww,$ll);
  for( my $i=0;$i<@_;$i++) {
    local($_)=$_[$i];
    if(ref($_)eq'HASH'){
      $_->{y1}=$y1;
      $_->{y2}=$y2;
      $ww+=$_->{dx};
      $ll+=length($_->{txt})+1;
      push(@word,$_[$i]);
    };
  };
};
for(@rows) {
  eex( join(" ", map { $_->{txt} } @$_ ));
};

#    for(@rows) {
#      my(@row)=@$_;
#      say disp($_);
#    };

my (@ws, @hs);


die "No objects parsed.\n" unless @word;
@ws=TsvDoc->ws;
@hs=TsvDoc->hs;
# "average size of a character"
sub char_height {
  local(@_)=@_;
  for(@_) {
    $_=$_->{h};
  };
  grep { defined } @_;
};
sub char_width {
  local(@_)=@_;
  for(@_) {
    $_=$_->{w}/length($_->{txt});
  };
  grep { defined } @_;
};
my $mw = median(char_width(@word));
eex({mw=>$mw});
my $mh = median(char_height(@word));
eex({mh=>$mh});
my $char_avg = ($mw + $mh) / 2;
eex({char_avg=>$char_avg});
if($char_avg <= 0) {
  die "internal error";
};

# Scale all coords by char_avg ("max magnification lattice")
for my $o (@word) {
  $o->{sx} = $o->{x} * $char_avg;
  $o->{sy} = $o->{y} * $char_avg;
  $o->{sw} = $o->{w} * $char_avg;
  $o->{sh} = $o->{h} * $char_avg;
}

# Bounds (in scaled units)
my ($minx,$miny,$maxx,$maxy);
for my $o (@word) {
  my $x1 = $o->{sx} - $o->{sw}/2;
  my $x2 = $o->{sx} + $o->{sw}/2;
  my $y1 = $o->{sy} - $o->{sh}/2;
  my $y2 = $o->{sy} + $o->{sh}/2;
  $minx = defined($minx) ? ($x1 < $minx ? $x1 : $minx) : $x1;
  $miny = defined($miny) ? ($y1 < $miny ? $y1 : $miny) : $y1;
  $maxx = defined($maxx) ? ($x2 > $maxx ? $x2 : $maxx) : $x2;
  $maxy = defined($maxy) ? ($y2 > $maxy ? $y2 : $maxy) : $y2;
}

my $doc_w = $maxx - $minx;  $doc_w = 1 if $doc_w <= 0;
my $doc_h = $maxy - $miny;  $doc_h = 1 if $doc_h <= 0;

my $N = 0;
for my $o (@word) {
  # Place each *character* as a point; multi-char tokens count as multiple glyphs.
  $N += length($o->{txt});
}
$N = 1 if $N < 1;

my $fill = '.';
my $pad  = defined $ENV{OCR_GRID_PAD}  ? int($ENV{OCR_GRID_PAD}) : 1;
$pad = 0 if $pad < 0;

my $MAG_MAX = defined $ENV{OCR_MAG_MAX_DIM} ? int($ENV{OCR_MAG_MAX_DIM}) : 8000;
$MAG_MAX = 1000 if $MAG_MAX < 1000;

my $GRID_MAX_COLS = defined $ENV{OCR_GRID_MAX_COLS} ? int($ENV{OCR_GRID_MAX_COLS}) : 2000;
my $GRID_MAX_ROWS = defined $ENV{OCR_GRID_MAX_ROWS} ? int($ENV{OCR_GRID_MAX_ROWS}) : 2000;
$GRID_MAX_COLS = 200 if $GRID_MAX_COLS < 200;
$GRID_MAX_ROWS = 200 if $GRID_MAX_ROWS < 200;

my $spill = defined $ENV{OCR_GRID_SPILL} ? lc($ENV{OCR_GRID_SPILL}) : 'right';
$spill = 'right' unless $spill eq 'right' || $spill eq 'mark';

# ------------------------------------------------------------
# 1) MAX MAGNIFICATION DUMP
# ------------------------------------------------------------
#    my $mag_w = int($doc_w) + 2;
#    my $mag_h = int($doc_h) + 2;
#    $mag_w = $MAG_MAX if $mag_w > $MAG_MAX;
#    $mag_h = $MAG_MAX if $mag_h > $MAG_MAX;
#    
#    my @mag; # sparse rows
#    for my $o (@word) {
#      my $mx = int(($o->{sx} - $minx));
#      my $my = int(($o->{sy} - $miny));
#      next if $mx < 0 || $my < 0;
#      next if $mx > $mag_w || $my > $mag_h;
#    
#      my @chars = split //, $o->{txt};
#      for my $ch (@chars) {
#        $mag[$my] //= [];
#        my $cur = $mag[$my][$mx] // $fill;
#        if ($cur eq $fill) {
#          $mag[$my][$mx] = $ch;
#        } else {
#          # collision marker at max-magnification (useful signal)
#          $mag[$my][$mx] = '#';
#        }
#        $mx++;
#        last if $mx > $mag_w;
#      }
#    }

#    open(my $stdout,">&STDOUT");
#    open(STDOUT,">$file.mid");
#    say "# char_avg=$char_avg doc_w=$doc_w doc_h=$doc_h glyphs=$N";
#    say "# ----- MAX MAGNIFICATION (capped to ${MAG_MAX}x${MAG_MAX}) -----";
#    for my $r (0..$#mag) {
#      next unless defined $mag[$r];
#      my $line = join('', map { $_ // $fill } @{$mag[$r]});
#      $line =~ s/\s+$//;
#      say $line if length $line;
#    }
#    say "# ----- END MAX MAGNIFICATION -----";
#    say "";
#    open(STDOUT,">&".fileno($stdout));

# ------------------------------------------------------------
# 2) DOWNSCALE BASED ON AVERAGE DENSITY, THEN ADJUST DOWNWARD
# ------------------------------------------------------------
# Typical cell area ~= area / N. Let k0 = floor(sqrt(area/N)).
my $area = $doc_w * $doc_h;
my $k = int( sqrt($area / $N) );
$k = 1 if $k < 1;

# Collision checker for a given k:
sub collisions_for_k {
  my ($k) = @_;
  my %seen;
  my $coll = 0;

  for my $o (@word) {
    my $mx = int(($o->{sx} - $minx));
    my $my = int(($o->{sy} - $miny));

    my $gx = int($mx / $k);
    my $gy = int($my / $k);

    my @chars = split //, $o->{txt};
    for my $ch (@chars) {
      my $key = "$gx,$gy";
      if ($seen{$key}++) { $coll++ }
      $gx++; # naive advance for multi-char tokens
    }
  }
  return $coll;
}

my $coll = collisions_for_k($k);

# Adjust DOWNWARD (smaller k => wider grid) until collision-free or k==1.
while ($coll > 0 && $k > 1) {
  $k--;
  $coll = collisions_for_k($k);
}

# Compute grid size from k
my $cols = int($doc_w / $k) + 2*$pad + 2;
my $rows = int($doc_h / $k) + 2*$pad + 2;

# safety caps (won't discard; it just prevents your terminal from dying)
$cols = $GRID_MAX_COLS if $cols > $GRID_MAX_COLS;
$rows = $GRID_MAX_ROWS if $rows > $GRID_MAX_ROWS;

my @grid;
for my $r (0..$rows-1) {
  $grid[$r] = [ ($fill) x $cols ];
}

sub in_bounds {
  my ($r,$c) = @_;
  return 0 if $r < 0 || $c < 0;
  return 0 if $r >= $rows || $c >= $cols;
  return 1;
}

sub place {
  my ($r,$c,$ch) = @_;
  return 0 unless in_bounds($r,$c);
  return 0 unless $grid[$r][$c] eq $fill;
  $grid[$r][$c] = $ch;
  return 1;
}

# Place all glyphs; if k==1 still collides, preserve by spilling right or marking.
for my $o (@word) {
  my $mx = int(($o->{sx} - $minx));
  my $my = int(($o->{sy} - $miny));

  my $gx = int($mx / $k) + $pad;
  my $gy = int($my / $k) + $pad;

  my @chars = split //, $o->{txt};
  for my $ch (@chars) {
    my $r = $gy;
    my $c = $gx;

    if (place($r,$c,$ch)) {
      $gx++;
      next;
    }

    # Collision happened.
    if ($k > 1) {
      # Shouldn't happen (we tuned k), but keep the glyph anyway.
      my $cc = $c;
      $cc++ while $cc < $cols && !place($r,$cc,$ch);
      if ($cc >= $cols && $spill eq 'mark' && in_bounds($r,$cols-1)) {
        $grid[$r][$cols-1] = '#';
      }
      $gx = $cc + 1;
      next;
    }

    # k == 1: "no discarding" guarantee means we must resolve collisions locally.
    if ($spill eq 'right') {
      my $cc = $c;
      $cc++ while $cc < $cols && !place($r,$cc,$ch);
      if ($cc >= $cols && in_bounds($r,$cols-1)) {
        # still no room; mark the last cell
        $grid[$r][$cols-1] = '#';
      }
      $gx = $cc + 1;
    } else {
      # mark
      $grid[$r][$c] = '#';
      $gx++;
    }
  }
}

open(my $stdout,">&STDOUT");
open(STDOUT,">$file.upd");
say "# ----- DOWNSCALED GRID (density k0 -> adjusted downward until collision-free; k=$k; collisions_at_k=$coll) -----";
for my $r (0..$#grid) {
  my $line = join('', @{$grid[$r]});
  $line =~ s/\s+$//;
  say $line if length $line;
}
say "# ----- END DOWNSCALED GRID -----";
open(STDOUT,">&".fileno($stdout));
