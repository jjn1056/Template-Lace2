package MyRegistry;

use Moo;
extends 'Template::Lace2::Registry';

sub config {
  'Hello' => sub {
    my ($self) = @_;
    return +{
      footer => $self->create('Footer', copyright=>2010),
    };
  },
}

1;
