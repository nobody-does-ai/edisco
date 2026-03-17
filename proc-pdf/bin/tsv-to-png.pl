#!/usr/bin/env perl
use common::sense;
use utf8;
use lib 'lib';
use lib 'gather';
use TsvDoc;
use Tie::TsvHash;
use Nobody::Util;

use Path::Tiny qw(path);
use GD;

# If your TsvDoc/Tie::TsvHash live in a file, uncomment + adjust:
# use lib 'lib';
# require 'TsvDoc.pm';
unshift(@ARGV,"input.tsv") unless @ARGV;
push(@ARGV,"$ARGV[0].png") unless @ARGV>1;
TsvDoc::set_file($ARGV[0]);
sub usage {
  die <<"USAGE";
Usage:
  $0 in.tsv out.png

Env:
  OCR_FONT=/path/to/monospace.ttf   (required unless OCR_DRAW_TEXT=0)
  OCR_FONT_SIZE=14                 (default 14)
  OCR_SCALE=1                      (default 1; multiplies coords/sizes)
  OCR_PAD=20                       (default 20px border)
  OCR_DRAW_BOXES=1                 (default 0)
  OCR_DRAW_TEXT=1                  (default 1)
  OCR_MAX_DIM=30000                (default 30000; safety cap)
USAGE
}

my $in  = shift @ARGV // usage();
my $out = shift @ARGV // usage();

our $file = $in;     # <-- your TsvDoc->lines() uses path($file)

my $scale = 0 + ($ENV{OCR_SCALE} // 1);
$scale = 1 if $scale <= 0;

my $pad = int($ENV{OCR_PAD} // 20);
$pad = 0 if $pad < 0;

my $draw_boxes = ($ENV{OCR_DRAW_BOXES} // 1) ? 1 : 0;
my $draw_text  = ($ENV{OCR_DRAW_TEXT}  // 1) ? 1 : 0;

my $font = $ENV{OCR_FONT};
my $font_size = int($ENV{OCR_FONT_SIZE} // 14);
$font_size = 14 if $font_size < 6;

my $MAX_DIM = int($ENV{OCR_MAX_DIM} // 30000);
$MAX_DIM = 5000 if $MAX_DIM < 5000;

# Pull ONLY level-5 word rows via your TsvDoc
my $rows = TsvDoc->rows();  # your rows() already undef's non-level-5 (quirky but ok)

my @w = grep { defined && $_->{level} == 5 } @$rows;
@w or die "No level-5 words found in $in\n";

# Compute bounds purely from claimed geometry (x1/y1/w/h)
my ($maxx, $maxy);
for(TsvDoc->page()){
  eex({page=>$_});
  $maxx=$_->{x};
  $maxy=$_->{y};
};
eex($maxx,$maxy);
for my $o (@w) {
  my $x2 = ($o->{x1} + $o->{w}) * $scale;
  my $y2 = ($o->{y1} + $o->{h}) * $scale;
  eex( $x2, $maxx );
  $maxx = $x2 if $x2 > $maxx;
  eex( $y2, $maxy );
  $maxy = $y2 if $y2 > $maxy;
}

my $img_w = $maxx;
my $img_h = $maxy;
$img_w = $MAX_DIM if $img_w > $MAX_DIM;
$img_h = $MAX_DIM if $img_h > $MAX_DIM;

my $im = GD::Image->newTrueColor($img_w, $img_h);
my $white = $im->colorAllocate(255,255,255);
my $black = $im->colorAllocate(0,0,0);
my $gray  = $im->colorAllocate(160,160,160);
$im->filledRectangle(0, 0, $img_w-1, $img_h-1, $white);

if ($draw_text) {
  defined($font) or die "Set OCR_FONT=/path/to/font.ttf or OCR_DRAW_TEXT=0\n";
  -f $font or die "OCR_FONT not found: $font\n";
}

# Render each word literally at its claimed box top-left.
for my $o (@w) {
  my $txt = $o->{text};
  next unless defined($txt) && length($txt);

  my $x = int($o->{x1} * $scale) + $pad;
  my $y = int($o->{y1} * $scale) + $pad;
  my $w = int($o->{w}  * $scale);
  my $h = int($o->{h}  * $scale);

  if ($draw_boxes) {
    my $x2 = $x + $w;
    my $y2 = $y + $h;
    $x2 = $img_w-1 if $x2 > $img_w-1;
    $y2 = $img_h-1 if $y2 > $img_h-1;
    $im->rectangle($x, $y, $x2, $y2, $gray);
  }

  next unless $draw_text;

  # Baseline: use bottom of the claimed box (works well for tesseract bboxes)
  my $baseline = $y + ($h > 0 ? $h : $font_size);
  $baseline = $y + $font_size if $baseline < $y + $font_size;

  # clip-ish
  next if $x < 0 || $baseline < 0 || $x > $img_w || $baseline > $img_h;

  $im->stringFT($black, $font, $font_size, 0, $x, $baseline, $txt);
}

path($out)->spew_raw($im->png);
say STDERR "Wrote $out (${img_w}x${img_h}), words=" . scalar(@w) . ", scale=$scale";
