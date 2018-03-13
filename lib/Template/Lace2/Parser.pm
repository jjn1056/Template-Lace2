package Template::Lace2::Parser;

use strictures 1;
use base qw(HTML::Zoom::SubObject);

use HTML::TokeParser;
use HTML::Entities;

sub html_to_events {
  my ($self, $text) = @_;
  my @events;
  $self->_toke_parser($text => sub {
      push @events, $_[0];
  });
  return \@events;
}

sub html_to_stream {
  my ($self, $text) = @_;
  return $self->_zconfig->stream_utils
    ->stream_from_array(@{$self->html_to_events($text)});
}

sub _toke_parser {
  my ($self, $text, $handler) = @_;
  my $parser = HTML::TokeParser->new(\$text) or return $!;
  $parser->case_sensitive(1);# HTML::Parser downcases by default

  my %commands = ();
  while (my $token = $parser->get_token) {
      my $type = shift @$token;

      # we break down what we emit to stream handler by type
      # start tag
      if ($type eq 'S') {
          my ($tag, $attr, $attrseq, $text) = @$token;
          my $in_place = delete $attr->{'/'}; # val will be '/' if in place
          $attrseq = [ grep { $_ ne '/' } @$attrseq ] if $in_place;
          if (substr($tag, -1) eq '/') {
              $in_place = '/';
              chop $tag;
          }

          if(my ($target, $command) = ($tag=~m/^(.+?)\.(.+)$/)) {

            # Ok, we got something that looks like a Lace command, for example
            # lace.Master or self.user_list, and we need to parse all the
            # attributes and setup meta data for the Producer.

            # Parse attributes for something that looks like a data path, and
            # if so we preparse it to save some time for the producer.
            foreach my $key(%{$attr}) {
              next unless $attr->{$key};
              if($attr->{$key} =~m/^\$*\./) {
                $attr->{$key} = [split '\.', $attr->{$key}];
              }
            }

            # We need to track where we are in the tag hierarchy so that we
            # properly nest commands.
            $commands{$target.'_'.$command}++;

            # Ok, now properly setup the metadata
            $handler->({
              type => 'OPEN',
              name => $tag,
              command => $command,
              target => $target,
              command_id => $target . '_' . $command . '_' . $commands{$target.'_'.$command},
              attrs => $attr,
              is_in_place_close => $in_place,
              attr_names => $attrseq,
              raw => $text,
            });

            # If this is an 'in place' tag ( <view.Include />
            if ($in_place) {
              $handler->({
                type => 'CLOSE',
                name => $tag,
                command => $command,
                target => $target,
                command_id => $target . '_' . $command . '_' . $commands{$target.'_'.$command},
                raw => '', # don't emit $text for raw, match builtin behavior
                is_in_place_close => 1,
              });

              # Since its a self closing tag, we 'un-nest'
              $commands{$target.'_'.$command}--;
            }
          } else {
            $handler->({
              type => 'OPEN',
              name => $tag,
              attrs => $attr,
              is_in_place_close => $in_place,
              attr_names => $attrseq,
              raw => $text,
            });
            if ($in_place) {
                $handler->({
                    type => 'CLOSE',
                    name => $tag,
                    raw => '', # don't emit $text for raw, match builtin behavior
                    is_in_place_close => 1,
                });
            }
          } 
      }

      # end tag
      if ($type eq 'E') {
          my ($tag, $text) = @$token;
          if(my ($target, $command) = ($tag=~m/^(.+?)\.(.+)$/)) {

              # ok, on the way out of a nested command, we need to mark the meta
              # data correctly and also unnest the command level.
              $handler->({
                  type => 'CLOSE',
                  name => $tag,
                  raw => $text,
                  target => $target,
                  command => $command,
                  command_id => $target . '_' . $command . '_' . $commands{$target.'_'.$command},
              });
              $commands{$target.'_'.$command}--;
          } else {
              $handler->({
                  type => 'CLOSE',
                  name => $tag,
                  raw => $text,
              });
          }
      }

      # text
      if ($type eq 'T') {
          my ($text, $is_data) = @$token;
          $handler->({
              type => 'TEXT',
              raw => $text
          });
      }

      # comment
      if ($type eq 'C') {
          my ($text) = @$token;
          $handler->({
              type => 'SPECIAL',
              raw => $text
          });
      }

      # declaration
      if ($type eq 'D') {
          my ($text) = @$token;
          $handler->({
              type => 'SPECIAL',
              raw => $text
          });
      }

      # process instructions
      if ($type eq 'PI') {
          my ($token0, $text) = @$token;
      }
  }
}

sub html_escape { encode_entities($_[1]) }

sub html_unescape { decode_entities($_[1]) }

1;
