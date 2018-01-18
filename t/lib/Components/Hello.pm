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
  return $self->zoom
    ->select('#name')
    ->replace_content($self->name)
      ->select('body')
     ->append_content($self->footer->to_events);
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
        <Lace-Footer copyright='2018'>
          <Lace-Footer copyright='$.date' />
          <Lace-Footer copyright='$$.date' />
        </Lace-Footer>
      </body>
    </html>
  ];
}

1;
