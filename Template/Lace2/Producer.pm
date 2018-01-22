package Template::Lace2::Producer;

use strictures 1;
use Scalar::Util;
use base qw(HTML::Zoom::SubObject);

sub html_from_stream {
  my ($self, $stream, $data, $parent) = @_;
  my @events = $self->_zconfig->stream_utils->stream_to_array($stream);
  return $self->html_from_events(\@events, $data, $parent);
}

sub html_from_events {
  my ($self, $events, $data, $parent) = @_;
  my @html = ();
  while(@$events) {
    my $event = shift(@$events);
    if($event->{component} && $event->{type} eq 'OPEN') {
      my $component_id = $event->{component_id};
      my $component = $event->{component};
      my @inner_events = ();
      while(@$events) {
        my $inner_event = shift(@$events);
        if( ($inner_event->{component_id}||'') eq $component_id ) {
          last;
        } else {
          push @inner_events, $inner_event;
        }
      }
      my %args = %{$event->{attrs}};
      foreach my $key(%args) {
        next unless $args{$key};
        if(ref($args{$key})) {
          my ($prefix, @parts) = @{$args{$key}};
          next unless $prefix;
          my $ctx = $data;
          $ctx = $parent if $prefix eq '$$';
          foreach my $part(@parts) {
            if(Scalar::Util::blessed $ctx) {
              $ctx = $ctx->$part;
            } elsif(ref($ctx) eq 'HASH') {
              $ctx = $ctx->{$part};
            } else {
              die "No '$part' for this ctx $ctx";
            }
          }
          $args{$key} = $ctx;
        }
      }
      
      $args{inner_events} = \@inner_events if @inner_events;
      $args{container} = $data;
      $args{parent} = $parent;
      my $html = $self->_zconfig->registry->create($component, %args)->to_html($data);
      push @html, $html;
    } elsif($event->{method} && $event->{type} eq 'OPEN') {
      my $method_id = $event->{method_id};
      my $method = $event->{method};
      my @inner_events = ();
      while(@$events) {
        my $inner_event = shift(@$events);
        if( ($inner_event->{method_id}||'') eq $method_id ) {
          last;
        } else {
          push @inner_events, $inner_event;
        }
      }
      my %args = %{$event->{attrs}};
      my $target = $event->{target} eq 'self' ?
        $data :
          $event->{target} eq 'this' ?
            $parent :
              die "No target for $event->{target}";

      if(my $cb = $target->can($method)) {
        my $z = HTML::Zoom->new({ zconfig => $self->_zconfig })->from_events(\@inner_events);
        my $response = $cb->($data, $z, %args);
        my $method_events = Scalar::Util::blessed($response) ?
          $response->to_events :
            $self->_zconfig->registry->_zoom($response)->to_events;
        unshift @$events, @{$method_events};
      } else {
        die "$target can't supported $method";
      }
    } else {
      my $html = $self->event_to_html($event);
      push @html, $html;
    }
  }
  return my $html = join '', @html;
}

sub event_to_html {
  my ($self, $evt) = @_;
  # big expression
  if (defined $evt->{raw}) {
    $evt->{raw}
  } elsif ($evt->{type} eq 'OPEN') {
    '<'
    .$evt->{name}
    .(defined $evt->{raw_attrs}
        ? $evt->{raw_attrs}
        : do {
            my @names = @{$evt->{attr_names}};
            @names
              ? join(' ', '', map qq{${_}="${\$evt->{attrs}{$_}}"}, @names)
              : ''
          }
     )
    .($evt->{is_in_place_close} ? ' /' : '')
    .'>'
  } elsif ($evt->{type} eq 'CLOSE') {
    '</'.$evt->{name}.'>'
  } elsif ($evt->{type} eq 'EMPTY') {
    ''
  } else {
    die "No raw value in event and no special handling for type ".$evt->{type};
  }
}

1;
