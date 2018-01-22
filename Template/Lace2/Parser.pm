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

  my %components = ();
  my %methods = ();

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

          if(my ($component_name) = ($tag=~m/^Lace\-(.+)$/)) {
            $components{$component_name}++;
            foreach my $key(%{$attr}) {
              next unless $attr->{$key};
              if($attr->{$key} =~m/^\$*\./) {
                $attr->{$key} = [split '\.', $attr->{$key}];
              }
            }

            $handler->({
              type => 'OPEN',
              name => $tag,
              component => $component_name,
              component_id => $component_name . '_' . $components{$component_name},
              attrs => $attr,
              is_in_place_close => $in_place,
              attr_names => $attrseq,
              raw => $text,
            });
            if ($in_place) {
                $handler->({
                    type => 'CLOSE',
                    name => $tag,
                    component => $component_name,
                    component_id => $component_name . '_' . $components{$component_name},
                    raw => '', # don't emit $text for raw, match builtin behavior
                    is_in_place_close => 1,
                });
                $components{$component_name}--;
            }
          } elsif(my ($target, $method) = ($tag=~m/^([st]...)\.(.+)$/)) {
            $methods{$target.'_'.$method}++;
            $handler->({
              type => 'OPEN',
              name => $tag,
              method => $method,
              target => $target,
              method_id => $target . '_' . $method . '_' . $methods{$target.'_'.$method},
              attrs => $attr,
              is_in_place_close => $in_place,
              attr_names => $attrseq,
              raw => $text,
            });
            if ($in_place) {
                $handler->({
                    type => 'CLOSE',
                    name => $tag,
                    method => $method,
                    target => $target,
                    method_id => $target . '_' . $method . '_' . $methods{$target.'_'.$method},
                    raw => '', # don't emit $text for raw, match builtin behavior
                    is_in_place_close => 1,
                });
                $methods{$target.'_'.$method}--;
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
          if(my ($component_name) = ($tag=~m/^Lace\-(.+)$/)) {
              $handler->({
                  type => 'CLOSE',
                  name => $tag,
                  raw => $text,
                  component => $component_name,
                  component_id => $component_name . '_' . $components{$component_name},
                  # is_in_place_close => 1  for br/> ??
              });
              $components{$component_name}--;
          } elsif(my ($target, $method) = ($tag=~m/^([st]...)\.(.+)$/)) {
              $handler->({
                  type => 'CLOSE',
                  name => $tag,
                  raw => $text,
                  target => $target,
                  method => $method,
                  method_id => $target . '_' . $method . '_' . $methods{$target.'_'.$method},,
                  # is_in_place_close => 1  for br/> ??
              });
              $methods{$target.'_'.$method}--;
          } else {
              $handler->({
                  type => 'CLOSE',
                  name => $tag,
                  raw => $text,
                  # is_in_place_close => 1  for br/> ??
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
