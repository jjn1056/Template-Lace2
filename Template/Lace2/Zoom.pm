package Template::Lace2::Zoom;
 
use strictures 1;
use Template::Lace2::ZConfig;
use base 'HTML::Zoom';

sub _new_zconfig {
  my ($class, $args) = @_;
  return my $zconfig = Template::Lace2::ZConfig->new($args);
}

sub new {
  my ($class, $args) = @_;
  my $new = +{ zconfig => $class->_new_zconfig($args->{zconfig}||{}) };
  return my $zoom = bless($new, $class);
} 

1;
