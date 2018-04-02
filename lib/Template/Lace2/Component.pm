package Template::Lace2::Component;

use Moo;

has 'zoom' => (is=>'rw', required=>1);
has 'registry' => (is=>'ro', required=>1);
has 'parent' => (is=>'ro', required=>0); ## component I'm inside (if any)

has 'inner_events_cb' => (
  is=>'ro',
  required=>0,
  predicate=>'has_inner_events_cb');

has 'inner_events' => (
  is=>'ro',
  required=>1,
  lazy=>1,
  builder=>'_build_inner_events',
  predicate=>'has_inner_events');

  # We do this dance because inner events need to have a different
  # context (so that self and this do the right this).
  sub _build_inner_events {
    my $self = shift;
    if($self->has_inner_events_cb) {
      return [ $self->inner_events_cb->($self, $self->parent) ];
    } else {
      return;
    }
  }

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
  $ctx = +{
    container => $self,
    parent => ($self->parent || $self),
  } unless $ctx;

  $self->registry->process($self);
  $self->zoom->zconfig->producer->html_from_stream($self->zoom->to_stream, $ctx);
}

sub to_zoom {
  my ($self, $html) = @_;
  return my $zoom = $self->registry->_zoom($html);
}

sub to_fh { shift->zoom->to_fh }
sub to_stream { shift->zoom->to_stream }
sub to_events { shift->zoom->to_events }

1;
