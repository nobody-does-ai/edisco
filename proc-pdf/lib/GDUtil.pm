package GDUtil;

sub slice_y {
  my ($im, $y, $h) = @_;
  my $w = $im->width;
  my $H = $im->height;

  $y = 0 if $y < 0;
  $h = $H - $y if $y + $h > $H;
  die "slice_y: empty slice (y=$y h=$h H=$H)" if $h <= 0;

  my $out = GD::Image->new($w, $h);     # palette image is fine for white docs
  my $white = $out->colorAllocate(255,255,255);
  $out->filledRectangle(0, 0, $w-1, $h-1, $white);

  $out->copy($im, 0, 0, 0, $y, $w, $h);
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
