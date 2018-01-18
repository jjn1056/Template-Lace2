package CommonX::Footer;

use Moo;
extends 'Template::Lace2::Component';

has 'copyright' => (is=>'ro', required=>1, default=>'2021');
has 'inner_events' => (is=>'ro', required=>0);

sub process {
  my ($self) = @_;
  my $z = $self->zoom
    ->select('.footer')
    ->append_content($self->copyright);

  if($self->inner_events) {
    $z = $z->select('.footer')
    ->add_after($self->inner_events);
  }

  return $z;
}

sub date { '2022' }

sub html {
  return qq[
  <p class="footer">Copyright </p>
  ];
}

1;

__DATA__


