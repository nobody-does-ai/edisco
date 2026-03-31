package Nobody::GMailConfig;
use Nobody::Util;
use Nobody::JSON;

require Exporter;
*import=\&Exporter::import;
our(@EXPORT)=qw(load_config);



sub resolve {
  my ($arg) = @_;

  return $arg if defined($arg) && length($arg) && $arg =~ m{/};
  return "gmail/$arg" if defined($arg) && length($arg);
  return "gmail/rich.freeman.paul";
}

sub load_config {
  my ($entry) = resolve(shift);
  my $raw = qx(pass show -- $entry);
  die "Failed to read pass entry $entry\n" if $? != 0;

  my $cfg = &Nobody::JSON::coder()->decode($raw);
  die "Invalid JSON in pass entry $entry: $@\n" if $@;
  die "Config in pass entry $entry must be a JSON object\n" unless ref($cfg) eq 'HASH';

  $cfg->{imap_server} //= 'imap.gmail.com';
  $cfg->{imap_port}   //= 993;
  $cfg->{target_label}  //= '[Gmail]/All Mail';
  $cfg->{pass} //= delete $cfg->{password} if exists $cfg->{password};
  $cfg->{targets} //= [];

  my @required = qw(user pass target_label maildir targets);
  for my $key (@required) {
    die "Missing required config key '$key' in pass entry $entry\n"
      unless exists($cfg->{$key});
  }

  die "Config key 'user' must be a non-empty string\n"
    unless defined($cfg->{user}) && !ref($cfg->{user}) && length($cfg->{user});
  die "Config key 'pass' must be a non-empty string\n"
    unless defined($cfg->{pass}) && !ref($cfg->{pass}) && length($cfg->{pass});
  die "Config key 'imap_server' must be a non-empty string\n"
    unless defined($cfg->{imap_server}) && !ref($cfg->{imap_server}) && length($cfg->{imap_server});
  die "Config key 'imap_port' must be numeric\n"
    unless defined($cfg->{imap_port}) && $cfg->{imap_port} =~ /\A\d+\z/;
  die "Config key 'target_label' must be a non-empty string\n"
    unless defined($cfg->{target_label}) && !ref($cfg->{target_label}) && length($cfg->{target_label});
  die "Config key 'maildir' must be a non-empty string\n"
    unless defined($cfg->{maildir}) && !ref($cfg->{maildir}) && length($cfg->{maildir});
  die "Config key 'targets' must be a JSON array\n"
    unless ref($cfg->{targets}) eq 'ARRAY';
  for my $term (@{$cfg->{targets}}) {
    die "Each target must be a non-empty string\n"
      unless defined($term) && !ref($term) && length($term);
  }

  if ($entry =~ m{\Agmail-imap/([^/]+)\z}) {
    die "Pass entry user '$1' does not match config user '$cfg->{user}'\n"
      unless $cfg->{user} eq $1;
  }

  return $cfg;
}

1;
