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
    ->append_content($footer->to_events)
    ->then
    ->append_content($self->to_zoom($self->inline));
}

sub date { '2020' }

sub section {
  my ($self, $inner, %args) = @_;
  return $self->to_zoom('<section><Lace-CommonX-Footer copyright="2032" /></section>')
    ->select('section')
    ->append_content($inner->to_events);
}

sub inline { '<Lace-CommonX-Footer copyright="2028" />' }

sub html {
  return q[
    <html>
      <head>
        <title>Hello World: </title>
      </head>
      <body>
        <self.inline />
        <self.section>
        Hi
          <self.section>Bye!</self.section>
        </self.section>
        <p>Hello <span id='name'></span></p>
        <Lace-CommonX-Footer copyright='2018'>
           <p><this.date /></p>
          <Lace-CommonX-Footer copyright='$.date' />
          <Lace-CommonX-Footer copyright='$$.date' />
        </Lace-CommonX-Footer>
      </body>
    </html>
  ];
}

1;
