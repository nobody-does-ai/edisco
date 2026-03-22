#!/usr/bin/env perl
# Generate the Limited Objection PDF.
# Install: sudo apt install libpdf-api2-perl
use common::sense;
use autodie;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Encode qw(encode);
use PDF::API2;
use List::Util qw(sum);

use constant INCH => 72;
use constant PW   => 8.5 * INCH;
use constant PH   => 11.0 * INCH;
use constant ML   => 1.0  * INCH;
use constant MR   => 1.0  * INCH;
use constant MT   => 0.85 * INCH;
use constant MB   => 0.85 * INCH;
use constant TW   => PW - ML - MR;

# --- Authorities ---
my @AUTHORITIES;
sub register_authority { push @AUTHORITIES, {@_} }

sub mcl_url {
  my ($sec) = @_;
  (my $obj = "mcl-$sec") =~ s/\./-/g;
  "https://www.legislature.mi.gov/Laws/MCL?objectName=$obj"
}

sub mcl_link {
  my ($sec, $sub) = @_;
  my $label = "MCL $sec" . (defined $sub ? "($sub)" : "");
  my $url   = mcl_url($sec);
  register_authority(kind => "statute", system => "MCL", sec => $sec,
                     sub  => ($sub // ""), label => $label, url => $url);
  qq{<link href="$url"><u><font color="blue">$label</font></u></link>}
}

# ---------------------------------------------------------------------------
# Markup parser → list of run hashrefs
# Each run: { text, bold, italic, color, url, ul }
# text eq "\n" means hard line break
# ---------------------------------------------------------------------------
sub parse_markup {
  my ($raw, $base_bold, $base_italic) = @_;
  $base_bold   //= 0;
  $base_italic //= 0;
  my (@runs, @stk);
  push @stk, { bold => $base_bold, italic => $base_italic,
               color => 'black', url => '', ul => 0 };
  pos($raw) = 0;
  while (pos($raw) < length $raw) {
    if    ($raw =~ /\G([^<]+)/gc)                         { push @runs, {%{$stk[-1]}, text => $1}   }
    elsif ($raw =~ /\G<br\s*\/>/gci)                       { push @runs, {%{$stk[-1]}, text => "\n"} }
    elsif ($raw =~ /\G<b>/gci)                             { push @stk, {%{$stk[-1]}, bold   => 1}   }
    elsif ($raw =~ /\G<\/b>/gci)                           { pop @stk if @stk > 1                     }
    elsif ($raw =~ /\G<i>/gci)                             { push @stk, {%{$stk[-1]}, italic => 1}   }
    elsif ($raw =~ /\G<\/i>/gci)                           { pop @stk if @stk > 1                     }
    elsif ($raw =~ /\G<u>/gci)                             { push @stk, {%{$stk[-1]}, ul     => 1}   }
    elsif ($raw =~ /\G<\/u>/gci)                           { pop @stk if @stk > 1                     }
    elsif ($raw =~ /\G<font\s+color="([^"]+)">/gci)        { push @stk, {%{$stk[-1]}, color  => $1}  }
    elsif ($raw =~ /\G<\/font>/gci)                        { pop @stk if @stk > 1                     }
    elsif ($raw =~ /\G<link\s+href="([^"]+)">/gci)         { push @stk, {%{$stk[-1]}, url    => $1}  }
    elsif ($raw =~ /\G<\/link>/gci)                        { pop @stk if @stk > 1                     }
    else                                                    { $raw =~ /\G<[^>]*>/gc                    }
  }
  @runs
}

# ---------------------------------------------------------------------------
# Font management
# ---------------------------------------------------------------------------
my %FONTS;
sub get_font {
  my ($pdf, $bold, $italic) = @_;
  my $name = $bold && $italic ? 'Times-BoldItalic'
           : $bold            ? 'Times-Bold'
           : $italic          ? 'Times-Italic'
           :                    'Times-Roman';
  $FONTS{$name} //= $pdf->corefont($name, -encode => 'latin1')
}
sub run_font { get_font($_[0], $_[1]{bold}, $_[1]{italic}) }

sub str_w {
  my ($font, $size, $text) = @_;
  my $enc = eval { encode('latin1', $text, Encode::FB_CROAK) } // $text;
  $font->width($enc) * $size
}

# ---------------------------------------------------------------------------
# Line-wrapping
# Given an arrayref of runs, returns an array of line arrayrefs.
# Each element of a line: { text, bold, italic, color, url, ul, _w }
# ---------------------------------------------------------------------------
sub wrap_runs {
  my ($pdf, $runs, $size, $max_w) = @_;
  my (@lines, @cur, $cur_w);
  $cur_w = 0;

  my $flush = sub {
    pop @cur while @cur && $cur[-1]{text} =~ /^ +$/;
    push @lines, [@cur] if @cur;
    @cur = (); $cur_w = 0;
  };

  for my $run (@$runs) {
    my $font = run_font($pdf, $run);
    if ($run->{text} eq "\n") { $flush->(); next }

    for my $part (grep { length } split /(\s+)/, $run->{text}) {
      my $w = str_w($font, $size, $part);
      if ($part =~ /^\s+$/) {
        if (@cur) { push @cur, {%$run, text => $part, _w => $w}; $cur_w += $w }
      } else {
        if (@cur && $cur_w + $w > $max_w + 0.5) { $flush->() }
        push @cur, {%$run, text => $part, _w => $w};
        $cur_w += $w;
      }
    }
  }
  $flush->();
  @lines
}

# ---------------------------------------------------------------------------
# Page state
# ---------------------------------------------------------------------------
my ($PDF, $CUR_PAGE, $CUR_Y);

sub new_page {
  $CUR_PAGE = $PDF->page;
  $CUR_PAGE->mediabox(0, 0, PW, PH);
  $CUR_Y = PH - MT;
}

sub need {
  my ($pts) = @_;
  new_page() if $CUR_Y - $pts < MB;
}

# ---------------------------------------------------------------------------
# Renderers
# ---------------------------------------------------------------------------
sub render_spacer {
  my ($h) = @_;
  need($h);
  $CUR_Y -= $h;
}

sub render_para {
  my ($markup, %s) = @_;
  my $size    = $s{size}         // 11;
  my $leading = $s{leading}      // 14;
  my $sp_bef  = $s{space_before} //  0;
  my $sp_aft  = $s{space_after}  // 10;
  my $align   = $s{align}        // 'left';
  my $bold    = $s{bold}         //  0;
  my $italic  = $s{italic}       //  0;

  need($sp_bef + $leading);
  $CUR_Y -= $sp_bef;

  my @runs  = parse_markup($markup, $bold, $italic);
  my @lines = wrap_runs($PDF, \@runs, $size, TW);

  for my $line (@lines) {
    need($leading);
    $CUR_Y -= $leading;

    my $lw = @$line ? sum(map { $_->{_w} } @$line) : 0;
    my $x0 = $align eq 'center' ? ML + (TW - $lw) / 2 : ML;
    my $cx = $x0;

    for my $run (@$line) {
      next unless length $run->{text};
      my $font = run_font($PDF, $run);
      my $enc  = eval { encode('latin1', $run->{text}, Encode::FB_CROAK) }
                 // $run->{text};

      my $txt = $CUR_PAGE->text;
      $txt->font($font, $size);
      $txt->fillcolor($run->{color} eq 'blue' ? 'blue' : 'black');
      $txt->translate($cx, $CUR_Y);
      $txt->text($enc);

      if ($run->{ul}) {
        my $gfx = $CUR_PAGE->gfx;
        $gfx->strokecolor($run->{color} eq 'blue' ? 'blue' : 'black');
        $gfx->linewidth(0.5);
        $gfx->move($cx, $CUR_Y - 1.5);
        $gfx->line($cx + $run->{_w}, $CUR_Y - 1.5);
        $gfx->stroke;
      }

      if ($run->{url}) {
        my $ann = $CUR_PAGE->annotation;
        $ann->url($run->{url});
        $ann->rect($cx, $CUR_Y - 2, $cx + $run->{_w}, $CUR_Y + $size);
        $ann->border(0, 0, 0);
      }

      $cx += $run->{_w};
    }
  }
  $CUR_Y -= $sp_aft;
}

# Style presets
sub S_body   { (size => 11, leading => 14, space_after => 10, align => 'left'  )                        }
sub S_h1     { (size => 12, leading => 14, space_after => 10, align => 'left',   bold => 1, space_before => 8) }
sub S_center { (size => 12, leading => 14, space_after => 10, align => 'center', bold => 1)              }

# ---------------------------------------------------------------------------
# Document content
# ---------------------------------------------------------------------------
sub build_doc {
  new_page();

  render_para("STATE OF MICHIGAN",                    S_center());
  render_para("PROBATE COURT \x{2013} WASHTENAW COUNTY", S_center());
  render_spacer(0.15 * INCH);

  render_para(
    "<b>In the Matter of:</b><br/>"
    . "ARA G. PAUL AND SHIRLEY W. PAUL<br/>"
    . "CHARITABLE REMAINDER UNITRUST<br/>"
    . "DATED MAY 12, 2023",
    S_body());
  render_spacer(0.10 * INCH);

  render_para(
    "<b>Case No.:</b> 25-001332-TV<br/>"
    . "<b>Judge:</b> Hon. Darlene A. O\x{2019}Brien",
    S_body());
  render_spacer(0.20 * INCH);

  render_para("LIMITED OBJECTION TO PETITION FOR DIVISION OF TRUST", S_center());
  render_spacer(0.15 * INCH);

  render_para(
    "Objector, <b>Richard Nobody Paul</b>, appearing <i>pro se</i>, submits this "
    . "Limited Objection to the Petition for Division of Trust filed by John B. Paul "
    . "and Lisa J. Paul, Co-Trustees, and states as follows:",
    S_body());

  render_para("I. INTEREST AND CONSENT", S_h1());
  render_para(
    "1. Objector is a lifetime income beneficiary of the Trust and therefore an "
    . "interested person under " . mcl_link('700.1105', 'c') . ".",
    S_body());
  render_para(
    "2. Objector consents to the division of the Trust into two separate charitable "
    . "remainder unitrusts as proposed in the Petition and the attached Instrument of "
    . "Division, as such division is authorized by the Trust instrument (Article II.A.5) "
    . "and " . mcl_link('700.7417') . ", and may facilitate more orderly administration "
    . "going forward.",
    S_body());
  render_para(
    "3. This Objection is limited and specific. Objector does not oppose division itself.",
    S_body());

  render_para("II. OBJECTION TO DISCHARGE AND RELEASE OF CO-TRUSTEES", S_h1());
  render_para(
    "4. Objector objects to Paragraph G of the Petition\x{2019}s Prayer for Relief, "
    . "which seeks to discharge the Co-Trustees \x{201c}without liability to any person.\x{201d}",
    S_body());
  render_para(
    "5. Such a discharge is premature, overbroad, and improper where: no final "
    . "accounting has been rendered; material disputes exist regarding past "
    . "administration; and beneficiaries have not been afforded full disclosure "
    . "sufficient to evaluate trustee conduct.",
    S_body());
  render_para(
    "6. Michigan law does not permit trustees to obtain a blanket discharge under "
    . "these circumstances. Trustees owe ongoing duties of loyalty, prudence, "
    . "impartiality, and candor to beneficiaries, including a duty to furnish "
    . "information reasonably necessary to protect beneficiary interests. "
    . "See " . mcl_link('700.7801') . ", " . mcl_link('700.7814') . ".",
    S_body());
  render_para(
    "7. Where unresolved issues remain concerning administration, distributions, "
    . "investment strategy, and professional fees, any order purporting to discharge "
    . "trustees would unlawfully prejudice beneficiary rights and improperly insulate "
    . "fiduciaries from potential surcharge or other remedies. "
    . "See " . mcl_link('700.7901') . "\x{2013}" . mcl_link('700.7902') . ".",
    S_body());
  render_para(
    "8. Objector further objects to any implied or express release of liability arising "
    . "from the proposed division, resignation, or transfer of trusteeship. Division of "
    . "a trust does not, by itself, extinguish existing fiduciary obligations or claims.",
    S_body());
  render_para(
    "9. The Trust instrument already provides substantial protection to the Trustees "
    . "for the exercise or nonexercise of their powers when undertaken in good faith, "
    . "expressly stating that such actions are conclusive upon all persons. This "
    . "protection is consistent with Michigan law, which likewise shields trustees from "
    . "liability for discretionary decisions made in good faith. Accordingly, the "
    . "additional release, indemnification, and hold-harmless provisions sought by "
    . "Petitioners would have operative effect only if applied to conduct outside the "
    . "scope of good faith, including conduct as to which liability could not otherwise "
    . "be waived under Michigan law. To the extent the requested relief seeks to extend "
    . "protection beyond what the Trust instrument and governing law already provide, it "
    . "is unnecessary, legally ineffective, and prejudicial to the interests of the "
    . "beneficiaries. For this reason, approval of any blanket release or indemnification "
    . "prior to a full accounting and resolution of disputed issues would be improper.",
    S_body());

  render_para("III.A. ADDITIONAL OBJECTION REGARDING THE INSTRUMENT OF DIVISION", S_h1());
  render_para(
    "10. Objector further notes that the proposed Instrument of Division (Exhibit D) "
    . "contains provisions that mirror the same overbroad discharge and release of "
    . "liability objected to above.",
    S_body());
  render_para(
    "11. Objector expressly advised Petitioners weeks prior to filing that he would "
    . "not execute the Instrument of Division while it contained such a release, and "
    . "his refusal was based solely on that provision.",
    S_body());
  render_para(
    "12. Petitioners\x{2019} decision to proceed with litigation rather than remove "
    . "the offending release language from the Instrument of Division is the sole "
    . "reason attorney fees are now being incurred.",
    S_body());
  render_para(
    "13. Accordingly, any attorney fees incurred in connection with drafting, "
    . "defending, or attempting to enforce release or exculpatory "
    . "language\x{2014}whether in the Petition or the Instrument of "
    . "Division\x{2014}were not incurred for the benefit of the Trust, but to secure "
    . "personal protection for the Co-Trustees, and are not properly chargeable to "
    . "Trust assets.",
    S_body());

  render_para("IV. REQUESTED RELIEF", S_h1());
  render_para("WHEREFORE, Objector respectfully requests that the Court:", S_body());
  render_para(
    "1. Summarily approve the division of the Trust as proposed, as there is no "
    . "genuine controversy regarding the authority to divide the Trust or the "
    . "mechanics of the proposed division;",
    S_body());
  render_para(
    "2. Enter an order expressly providing that approval of the division is without "
    . "prejudice to, and does not adjudicate, release, discharge, surcharge, or "
    . "liability issues relating to the Co-Trustees;",
    S_body());
  render_para(
    "3. Limit any remaining controversy in this proceeding to the discrete issues of: "
    . "(a) whether the Co-Trustees are entitled to any discharge or release of "
    . "liability; and (b) whether attorney fees incurred in connection with release or "
    . "exculpatory provisions may properly be charged to Trust assets;",
    S_body());
  render_para(
    "4. Order the immediate release and transfer of Trust funds to the successor "
    . "Trustee(s) without further obstruction;",
    S_body());
  render_para(
    "5. Grant such other and further relief as the Court deems just and proper.",
    S_body());

  render_spacer(0.20 * INCH);
  render_para("<b>Respectfully submitted,</b>", S_body());
  render_para(
    "Richard Nobody Paul<br/>Objector, <i>pro se</i><br/>[Address]<br/>[Telephone]<br/>[Email]",
    S_body());
  render_para("Date: December ___, 2025", S_body());
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
my $out = "Limited_Objection_updated_goodfaith.pdf";
$PDF = PDF::API2->new;
$PDF->info(
  Title  => "Limited Objection to Petition for Division of Trust",
  Author => "Richard Nobody Paul",
);
build_doc();
$PDF->save($out);
print "Wrote $out\n";

# vim: ts=2 sw=2 et
