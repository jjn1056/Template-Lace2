package Template::Lace2::Producer;

use strictures 1;
use Scalar::Util;
use base qw(HTML::Zoom::SubObject);

sub html_from_stream {
  my ($self, $stream, $ctx) = @_;
  my @events = $self->_zconfig->stream_utils->stream_to_array($stream);
  return $self->html_from_events(\@events, $ctx);
}

sub html_from_events {
  my ($self, $events, $ctx) = @_;

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
      # against the root container context or the current parent context.

      my %args = %{$event->{attrs}};
      foreach my $key(%args) {
        next unless $args{$key};

        if(ref($args{$key}) eq 'ARRAY') {
          my ($prefix, @parts) = @{$args{$key}};
          next unless $prefix;
          my $data;
          $data = ($ctx->{container}||die "No Container!") if $prefix eq '$' or $prefix eq 'self';
          $data = $ctx->{parent} if $prefix eq '$$' or $prefix eq 'this';

          #die "Can't figure out what to do with prefix of '$prefix' for '@parts'" unless $data;

          if($data) {
            foreach my $part(@parts) {
              if(Scalar::Util::blessed $data) {
                $data = $data->$part;
              } elsif(ref($data) eq 'HASH') {
                $data = $data->{$part};
              } elsif(ref($data) eq 'ARRAY') {
                $data = $data->[$part];
              } else {
                die "No '$part' for this ctx $data";
              }
            }
            $args{$key} = $data;
          } 
          if($key eq '.') {
          %args = %{$data};
          }
        }
      }

      # Begin command handling
      if($target eq 'lace') {
        if($command eq 'ctx') {
          my $html = $self->html_from_events(\@inner_events, \%args);
          push @html, $html;
        }
      } elsif($target eq 'view') {
        $args{inner_events_cb} = sub {
          my ($this_component, $parent) = @_;
          return +{
            attr_names => [
              qw/container parent/, 
              grep { $_ ne 'container' || $_ ne 'container'} keys %args],
            attrs => {
              %args,
              container => $parent,
              parent => $this_component,
            },
            command => "ctx",
            command_id => "lace_ctx_XX",
            is_in_place_close => "/",
            name => "lace.ctx",
            raw => "<lace.ctx />",
            target => "lace",
            type => "OPEN",
          }, @inner_events, +{
            name=>'lace.ctx',
            target=>'lace',
            command=>'ctx',
            command_id=>'lace_ctx_XX',
            is_in_place_close=>1,
            raw=>'',
            type=>'CLOSE',
          };
        } if @inner_events;
        $args{parent} = $ctx->{container};
        my $command_ns = $command; $command_ns=~s/-/::/g;
        my $inner_component = $self->_zconfig->registry->create($command_ns, (%args));
        my $html = $inner_component->to_html();
        push @html, $html;
      } elsif($target eq 'self') {  ## self.$method
        if(my $cb = $ctx->{container}->can($command)) {
          my @args = ();
          push @args, HTML::Zoom->new({zconfig => $self->_zconfig})->from_events(\@inner_events)
            if @inner_events;
          push @args, %args if %args;
          my $response = $cb->($ctx->{container}, @args);
          my $method_events = Scalar::Util::blessed($response) ?
            $response->to_events :
              $self->_zconfig->registry->_zoom($response)->to_events;
          unshift @$events, @{$method_events};
        } else {
          die "$ctx->{container} can't supported $command";
        }
      } elsif($target eq 'this') {
        if(Scalar::Util::blessed($ctx->{parent})) {
          if(my $cb = $ctx->{parent}->can($command)) {
            my @args = ();
            push @args, HTML::Zoom->new({zconfig => $self->_zconfig})->from_events(\@inner_events)
              if @inner_events;
            push @args, %args if %args;
            my $response = $cb->($ctx->{parent}, @args);
            my $method_events = Scalar::Util::blessed($response) ?
              $response->to_events :
                $self->_zconfig->registry->_zoom($response)->to_events;
            unshift @$events, @{$method_events};
          } else {
            die "$ctx->{parent} can't supported $command";
          }
        } elsif(ref($ctx->{parent}) eq 'HASH') {
          if(exists $ctx->{parent}->{$command}) {
            push @html, $ctx->{parent}->{$command}; ## TODO surely this isn;t enough
          } else {
            die "$ctx->{parent} has no key called $command";
          }
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
