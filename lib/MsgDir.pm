package MsgDir;
use strict;
use warnings;
use Nobody::Util;
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(write_maildir_message);

# Atomically deliver $bytes (raw octets) to $maildir/new/$filename via tmp/.
# Creates cur/, new/, tmp/ as needed. Returns the Path::Tiny object for the
# delivered message in new/.
sub write_maildir_message {
  die "usage: write_maildir_message(maildir, filename, bytes)" unless @_ == 3;
  my ($maildir, $filename, $bytes) = @_;
  $maildir->child($_)->mkdir for qw(cur new tmp);
  my $tmp = $maildir->child('tmp', $filename);
  my $new = $maildir->child('new', $filename);
  $tmp->spew_raw($bytes);
  $tmp->move($new);
  return $new;
}

1;
