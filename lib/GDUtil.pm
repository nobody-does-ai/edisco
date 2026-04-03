package GDUtil;
use Nobody::Util;
use GD::Image;
our(@EXPORT);
BEGIN {
  (@EXPORT)=qw( slice extract_slice stack_slices );
};
require Exporter;
*import=\&Exporter::import;
sub slice {
  my ($im, $c, $y1, $y2) = @_;
  die "slice_y: empty slice (y1=$y1 y2=$y2)" unless $y2>$y1;
  my($w)=$im->width;
  my($h)=($y2-$y1);
  
  my $r = GD::Image->new($w,$h,1);
  $r->copy($im,0,0,0,$y1,$w,$h);
  return $r;
}
sub extract_slice {
  my ($img, $start_y, $height) = @_;
  my ($w, $full_h) = $img->getBounds;

  # Bounds check
  $height = $full_h-$start_y if $start_y + $height > $full_h;

  my $slice = GD::Image->new($w, $height, 1);  # truecolor for quality

  # Copy the band (full width, from start_y to start_y+height)
  $slice->copy($img, 0, 0, 0, $start_y, $w, $height);

  return $slice;
}
sub stack_slices {
  local (@_) = @_;
  die "stack_slices: need at least one slice" unless @_;
  my($dx,$sy)=(0,0);
  my($sx,$sy)=(0,0);
  my $w = max(map{$_->width}@_);
  my $h = sum(map{$_->height}@_);
  my $r = GD::Image->new($w, $h, 1);
  my ($col)=$r->colorAllocate(255,255,255);
  my $y = 0;
  for(@_) {
    say $y;
    $r->copy( $_,  0,$y,   0,0,   $_->width,$_->height);
    $y+=$_->height;
  };
  say $y;
  return $r;
}
1;
