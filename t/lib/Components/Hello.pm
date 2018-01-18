package Components::Hello;

use Moo;
extends 'Template::Lace2::Component';

has 'name' => (is=>'ro', required=>1);
has 'footer' => (is=>'ro', required=>1);

sub init_zoom {
  my ($class, $zoom) = @_;
  return $zoom->select('title')
    ->append_content(scalar(localtime));
}

sub process {
  my $self = shift;
  my $footer = $self->footer->process;

  return $self->zoom
    ->select('#name')
    ->replace_content($self->name)
    ->select('body')
    ->append_content($footer->to_events);

}

sub date { '2020' }

sub html {
  return q[
    <html>
      <head>
        <title>Hello World: </title>
      </head>
      <body>
        <$.date />
        <p>Hello <span id='name'></span></p>
        <Lace-CommonX-Footer copyright='2018'>
          <Lace-CommonX-Footer copyright='$.date' />
          <Lace-CommonX-Footer copyright='$$.date' />
        </Lace-CommonX-Footer>
      </body>
    </html>
  ];
}

1;
