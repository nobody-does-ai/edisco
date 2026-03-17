package GDUtil;
use Nobody::Util;
use GD::Image;
our(@EXPORT)=qw( slice_y stack_slices );
use base 'Exporter';
sub slice_y {
  my ($im, $c, $y1, $y2) = @_;
  die "slice_y: empty slice (y1=$y1 y2=$y2)" unless $y2>$y1;
  my($w)=$im->width;
  my($h)=($y2-$y1);
  
  my $r = GD::Image->new($w,$h,1);
  $r->copy($im,0,0,0,$y1,$w,$h);
  return $r;
}
sub render_text {
  local(@_)=@_;
  my($text)=join("\r\n",split(m{\r?\n},"@_"));
};
sub stack_slices {
  local (@_) = @_;
  die "stack_slices: need at least one slice" unless @_;
  my($dx,$sy)=(0,0);
  my($sx,$sy)=(0,0);
  my $w = max(map{$_->width}@_);
  my $h = sum(map{$_->height}@_);
  my $r = GD::Image->new($w, $h, 1);
  my ($col)=$r->colorAllocate(255,255,255);
  $r->filledRectangle(0,0,$w,$h,$col);
  ($col)=$r->colorAllocate(0,255,255);
  $r->filledRectangle(0,0,$w,40,$col);
  ($col)=$r->colorAllocate(0,255,0);
  $r->filledRectangle(0,40,$w,80,$col);
  my $y = 0;
  for(@_) {
    $r->copy( $_,  0,$y,   0,0,   $_->width,$_->height);
    $y+=$_->height;
  };
  return $r;
}
unless(caller){
  eex(render_text(path("lib/GDUtil.pm")->lines));
};
1;
