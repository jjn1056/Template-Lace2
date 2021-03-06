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
    ->replace_content('#name', $self->name)
    ->append_content('body', $footer->to_events)
    ->then
    ->append_content($self->to_zoom($self->inline));
}

sub date { '2020' }

sub list { [
  { val => 1 },  
  { val => 2 },  
  { val => 3 },  
  { val => 4 },  
]}

sub li {
  my ($self, $inner, %args) = @_;
  return $self->to_zoom('<li>items</li>')
    ->select('li')
    ->replace_content($args{value});
}

sub section {
  my ($self, $inner, %args) = @_;
  return $self->to_zoom('<section><lace.Footer copyright="2032" /></section>')
    ->select('section')
    ->append_content($inner->to_events);
}

sub inline { '<lace.Footer copyright="2028" />' }

sub html {
  return q[
    <html>
      <head>
        <title>Hello World:&nbsp;</title>
      </head>
      <body>
        <ul>
          <!-- self.li $this='$.list' value='$this.val' -->
        </ul>
        <self.inline />
        <self.section>
          Hi
          <self.section>
            Bye!
          </self.section>
        </self.section>
        <p>Hello <span lace_id='name' id='name'></span></p>
        <lace.Footer copyright='2018'>
           <p><this.date /></p>
          <lace.Footer copyright='$.date' />
          <view.Footer copyright='$$.date'>
            <b>fff</b>
          </view.Footer>
        </lace.Footer>
      </body>
    </html>
  ];
}

1;
