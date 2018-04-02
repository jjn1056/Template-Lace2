package CommonX::Footer;

use Moo;
extends 'Template::Lace2::Component';

has 'copyright' => (is=>'ro', required=>1);

sub process {
  my ($self) = @_;
  my $z = $self->zoom
    ->select('.footer')
    ->append_content($self->copyright);


  if(my $inner_events = $self->inner_events) {
    $z = $z->select('.footer')
    ->add_after($inner_events);
  }

  return $z;
}

sub text { 'Copyright' }
sub name { 
  my $self = shift;
  use Devel::Dwarn; Dwarn \@_;
  return 'wrong one!!!';
}

sub html {
  return qq[
  <p class="footer"><self.text/> </p>
  ];
}

1;

__DATA__


