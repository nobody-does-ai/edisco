package SMS::Renderer;

use strict;
use warnings;
use MIME::Base64;
use MIME::QuotedPrint;
use Digest::MD5 qw(md5_hex);
use File::Path qw(make_path);
use Encode qw(decode find_encoding);

# Constructor
# Usage: my $renderer = SMS::Renderer->new( attach_dir => '/tmp/blobs' );
sub new {
  my ($class, %args) = @_;
  my $self = {
    attach_dir => $args{attach_dir} || './att',
  };

  # Ensure dump directory exists
  make_path($self->{attach_dir}) unless -d $self->{attach_dir};

  bless $self, $class;
  return $self;
}
{
  sub scrub_nulls;
  my $dispatch;
  $dispatch = {
    'HASH'  => sub { $_ = scrub_nulls($_) for values %{$_[0]}; $_[0] },
    'ARRAY' => sub { $_ = scrub_nulls($_) for @{$_[0]};        $_[0] },
    'REF'   => sub { ${$_[0]} = scrub_nulls(${$_[0]});         $_[0] },
    ''      => sub { (defined $_[0] && $_[0] eq 'null') ? undef : $_[0] },
  };

  sub scrub_nulls {
    my ($node) = @_;
    my $handler = $dispatch->{ref($node)};

    # Execute handler if found, otherwise return node untouched
    return $handler ? $handler->($node) : $node;
  }
}

# Main Interface
# Usage: my $text_view = $renderer->render($message_object);
sub render {
    my ($self, $node) = @_;
    return $self->_process_part($node);
}

# ------------------------------------------------------------------
# Internal Logic
# ------------------------------------------------------------------

sub _process_part {
    my ($self, $part) = @_;

    # 1. Normalize Header Access
    my $head = $part->{head} || {}; 
    my $c_type   = $self->_get_header($head, 'Content-Type') || 'text/plain';
    my $encoding = $self->_get_header($head, 'Content-Transfer-Encoding') || '7bit';

    # 2. Handle Multipart Logic
    if ($c_type =~ m{^multipart/alternative}i) {
        return $self->_handle_alternative($part->{parts});
    }
    elsif ($c_type =~ m{^multipart/}i) {
        return $self->_handle_mixed($part->{parts});
    }

    # 3. Handle Leaf Nodes (Bodies)
    my $body = $part->{body};
    return "" unless defined $body;

    # 4. Decode Transfer Encoding (Base64 / QP)
    my $decoded_bytes = $body;
    if ($encoding =~ /base64/i) {
        $decoded_bytes = decode_base64($body);
    } elsif ($encoding =~ /quoted-printable/i) {
        $decoded_bytes = decode_qp($body);
    }

    # 5. Render Text vs Dump Binary
    if ($c_type =~ m{^text/(plain|html)}i) {
        return $self->_render_text_body($decoded_bytes, $c_type);
    } else {
        return $self->_dump_attachment($decoded_bytes, $c_type);
    }
}

sub _handle_alternative {
    my ($self, $parts) = @_;
    $parts ||= [];
    
    # Priority: text/plain -> text/html -> first available
    my $best_part;
    my $backup_part;

    foreach my $p (@$parts) {
        my $ct = $self->_get_header($p->{head}, 'Content-Type') || '';
        if ($ct =~ m{text/plain}i) {
            $best_part = $p;
            last;
        }
        if ($ct =~ m{text/html}i) {
            $backup_part = $p;
        }
    }
    
    $best_part ||= $backup_part || $parts->[0];
    return $best_part ? $self->_process_part($best_part) : "[Empty Multipart]";
}

sub _handle_mixed {
    my ($self, $parts) = @_;
    $parts ||= [];
    
    my @rendered_parts;
    foreach my $p (@$parts) {
        push @rendered_parts, $self->_process_part($p);
    }
    return join("\n\n" . ('-' x 20) . "\n\n", @rendered_parts);
}

sub _render_text_body {
    my ($self, $bytes, $c_type) = @_;
    
    # Extract charset
    my ($charset) = $c_type =~ /charset=["']?([\w-]+)/i;
    $charset ||= 'UTF-8';

    # Attempt decode
    my $text;
    eval {
        $text = decode($charset, $bytes);
    };
    if ($@) {
        # Fallback to Latin1 or just raw bytes if decode fails hard
        $text = $bytes; 
    }
    
    return $text;
}

sub _dump_attachment {
    my ($self, $data, $c_type) = @_;
    
    # Guess extension
    my $ext = 'bin';
    if ($c_type =~ m{image/(\w+)}) { $ext = $1; }
    elsif ($c_type =~ m{pdf})      { $ext = 'pdf'; }
    elsif ($c_type =~ m{zip})      { $ext = 'zip'; }

    my $sum = md5_hex($data);
    my $filename = "att_${sum}.${ext}";
    my $path = $self->{attach_dir} . "/$filename";

    # Write only if new
    unless (-e $path) {
        if (open(my $fh, '>', $path)) {
            binmode($fh);
            print $fh $data;
            close($fh);
        } else {
            warn "Failed to write attachment $path: $!";
            return "[WRITE ERROR]";
        }
    }
    
    return "file:./$path";
}

sub _get_header {
    my ($self, $head, $key) = @_;
    return undef unless $head;

    # If it's a hash, do case-insensitive lookup
    if (ref $head eq 'HASH') {
        foreach my $k (keys %$head) {
            return $head->{$k} if lc($k) eq lc($key);
        }
    }
    # If it's an object (MIME::Head)
    elsif (eval { $head->can('get') }) {
        return $head->get($key, 0);
    }
    
    return undef;
}

1;
