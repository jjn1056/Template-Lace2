package Template::Lace2::Component;

use Moo;

has 'zoom' => (is=>'rw', required=>1);
has 'registry' => (is=>'ro', required=>1);
has 'parent' => (is=>'ro', required=>0);
has 'container' => (is=>'ro', required=>0);

sub init_zoom {
  my ($class, $zoom, $config) = @_;
  return $zoom;
}

sub process {
  my ($self) = @_;
  return $self->zoom;
}

sub html {
  die "You failed to create an 'html' method in component: " .ref(shift);
}

sub to_html {
  my ($self, $ctx) = @_;
  $ctx = $self unless $ctx;
  $self->registry->process($self);
  $self->zoom->zconfig->producer->html_from_stream($self->zoom->to_stream, $ctx, $self);
}

sub to_zoom {
  my ($self, $html) = @_;
  return my $zoom = $self->registry->_zoom($html);
}

sub to_fh { shift->zoom->to_fh }
sub to_stream { shift->zoom->to_stream }
sub to_events { shift->zoom->to_events }

1;
