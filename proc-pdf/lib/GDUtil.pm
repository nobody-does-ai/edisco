package GDUtil;
use Nobody::Util;
our(@EXPORT)=qw( slice_y stack_slices );
use base 'Exporter';

sub slice_y {
  my ($im, $y1, $y2) = @_;

  ($y1,$y2)=(min($y1,$y2),max($y1,$y2));
  die "slice_y: empty slice (y1=$y y2=$h)" if $y2==$y1;

  my $out = GD::Image->new($im->width, ($y2-$y1)+6);
  my $white = $out->colorAllocate(255,0,0);
  $out->filledRectangle(0, 0, $out->width, $out->height, $white);

  $out->copy($im, 0, 3, 0, $y1, $out->width, $y2-$y1-3);
  return $out;
}

sub stack_slices {
  my (@slices) = @_;
  die "stack_slices: need at least one slice" unless @slices;

  my $w = $slices[0]->width;
  my $total_h = 0;
  for my $s (@slices) {
    die "stack_slices: width mismatch" unless $s->width == $w;
    $total_h += $s->height;
  }

  my $out = GD::Image->new($w, $total_h);
  my $white = $out->colorAllocate(255,255,255);
  $out->filledRectangle(0, 0, $w-1, $total_h-1, $white);

  my $y = 0;
  for my $s (@slices) {
    $out->copy($s, 0, $y, 0, 0, $s->width, $s->height);
    $y += $s->height;
  }

  return $out;
}
1;
