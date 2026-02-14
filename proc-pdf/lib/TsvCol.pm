package TsvCol;
# vim: ts=2 sw=2 ft=perl
use common::sense;
use autodie;
use TsvText;
use TsvRow;
use Nobody::Util;
our(@ISA)=qw(TsvText);

sub new {
  local(@_)=@_;
  my($class)=shift;
  my(@word)=grep { defined } @_;
  my($self)=$class->SUPER::new();
  $self->{word}=\@word;
  $self;
};

sub word {
  my($self)=$_[0];
  if(defined($_[1])){
    return $self->word->[$_[1]];
  } else {
    return $self->{word};
  };
}

sub left {
  min(map { $_->left } @{shift->word});
}
sub top {
  min(map { $_->top } @{shift->word});
}
sub right {
  max(map { $_->right } @{shift->word});
}
sub bottom {
  max(map { $_->bottom } @{shift->word});
}
sub width {
  max(map { $_->width } @{shift->word});
};
sub height {
  max(map { $_->height } @{shift->word});
};

sub _row_cells {
  my($row,$gap)=@_;
  my(@word)=sort { $a->left <=> $b->left } @{$row->word};
  return () unless @word;
  my(@cell, @cells);
  my($last)=-9e9;
  for my $w(@word){
    if(!@cell or $w->left - $last <= $gap) {
      push(@cell,$w);
    } else {
      push(@cells,[ @cell ]);
      @cell=($w);
    }
    $last=$w->right;
  }
  push(@cells,[ @cell ]) if @cell;
  return @cells;
}

sub _cell_metrics {
  my($cell)=@_;
  my($left)=min(map { $_->left } @$cell);
  my($right)=max(map { $_->right } @$cell);
  my($cx)=($left+$right)/2;
  return ($left,$right,$cx);
}

sub from {
  local(@_)=@_;
  my($class)=shift;
  my(@word)=grep { defined and $_->{level} == 5 } @_;
  if(grep { ref($_) eq 'HASH' } @word){
    @word=TsvWord->from(@word);
  };
  return () unless @word;

  my($gap)=45;
  my($slop)=25;
  my(@rows)=TsvRow->from(@word);
  my(@col);

  for my $row(@rows){
    for my $cell(_row_cells($row,$gap)){
      my($left,$right,$cx)=_cell_metrics($cell);
      my($best,$best_score);

      for my $i(0 .. $#col){
        my $c=$col[$i];
        my $overlap=min($right,$c->{right})-max($left,$c->{left});
        my $dist=abs($cx-$c->{cx});
        next if $overlap < -$slop and $dist > 80;
        my $score=($overlap * 2) - $dist;
        if(!defined($best_score) or $score > $best_score){
          $best=$i;
          $best_score=$score;
        }
      }

      if(defined($best)){
        my $c=$col[$best];
        push(@{$c->{word}}, @$cell);
        $c->{left}=min($c->{left},$left);
        $c->{right}=max($c->{right},$right);
        $c->{cx}=($c->{cx}*$c->{n} + $cx)/($c->{n}+1);
        $c->{n}++;
      } else {
        push(@col,{
          word=>[ @$cell ],
          left=>$left,
          right=>$right,
          cx=>$cx,
          n=>1,
        });
      }
    }
  }

  @col=sort { $a->{left} <=> $b->{left} } @col;
  return map { $class->new(@{$_->{word}}) } @col;
}

1;
