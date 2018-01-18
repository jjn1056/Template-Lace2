package MyRegistry;

use Moo;
extends 'Template::Lace2::Registry';

sub config {
  'Components-Hello' => sub {
    my ($self) = @_;
    return +{
      footer => $self->create('CommonX-Footer', copyright=>2018),
    };
  },
}

1;
