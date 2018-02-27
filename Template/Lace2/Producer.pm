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
    if($event->{command} && $event->{type} eq 'OPEN') {
      
      # alias these for simplicity

      my $target = $event->{target}; # lace, view, self, this
      my $command = $event->{command}; # view.Command
      my $command_id = $event->{command_id};

      # collect inner events that the command contains.  Basically
      # tags that are nested as children of the command tag

      my @inner_events = ();
      while(@$events) {
        my $inner_event = shift(@$events);
        if( ($inner_event->{command_id}||'') eq $command_id ) {
          last;
        } else {
          push @inner_events, $inner_event;
        }
      } continue {
        die "Command '$command' was opened but never closed" unless @$events;
      }

      # process attrs that may be data paths.  Basically if the attr is
      # and array ref that is the signal its a data path we need to resolve
      # against the root data context or the current parent context.

      my %args = %{$event->{attrs}};
      foreach my $key(%args) {
        next unless $args{$key};

        warn "..." if $key eq '@';

        if(ref($args{$key})) {
          my ($prefix, @parts) = @{$args{$key}};
          next unless $prefix;
          my $ctx;
          $ctx = $data if $prefix eq '$' or $prefix eq 'self';
          $ctx = $parent if $prefix eq '$$' or $prefix eq 'this';
          die "Not sure what a prefix of '$prefix' is" unless $ctx;
          foreach my $part(@parts) {
            if(Scalar::Util::blessed $ctx) {
              $ctx = $ctx->$part;
            } elsif(ref($ctx) eq 'HASH') {
              $ctx = $ctx->{$part};
            } elsif(ref($ctx) eq 'ARRAY') {
              $ctx = $ctx->[$part];
            } else {
              die "No '$part' for this ctx $ctx";
            }
          }
          $args{$key} = $ctx;
        }
      }

      

      # Begin command handling
      if(($target eq 'lace') || ($target eq 'view')) {   ## lace. or view.
        $args{inner_events} = \@inner_events if @inner_events;
        $args{container} = $data;
        $args{parent} = $parent;
        my $command_namespace = $command; $command_namespace=~s/-/::/g;
        my $html = $self->_zconfig->registry->create($command_namespace, %args)->to_html($data);
        push @html, $html;
      } elsif($target eq 'self') {  ## self.$method
        if(my $cb = $data->can($command)) {
          my $z = HTML::Zoom->new({ zconfig => $self->_zconfig })->from_events(\@inner_events);
          my $response = $cb->($data, $z, %args);
          my $method_events = Scalar::Util::blessed($response) ?
            $response->to_events :
              $self->_zconfig->registry->_zoom($response)->to_events;
          unshift @$events, @{$method_events};
        } else {
          die "$data can't supported $command";
        }
      } elsif($target eq 'this') {  ## this.$method (UNTESTED)
        if(my $cb = $parent->can($command)) {
          my $z = HTML::Zoom->new({ zconfig => $self->_zconfig })->from_events(\@inner_events);
          my $response = $cb->($parent, $z, %args);
          my $method_events = Scalar::Util::blessed($response) ?
            $response->to_events :
              $self->_zconfig->registry->_zoom($response)->to_events;
          unshift @$events, @{$method_events};
        } else {
          die "$parent can't supported $command";
        }
      } else {
        die "Not sure how to generate HTML for command '$command'";
      }
      # End command handling.  TODO this sucks as a pile of nested If-Then!
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
