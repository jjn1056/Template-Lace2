package MyApp::UI::Components::Hello;

use Moo;
extends 'Template::Lace2::Component';

has 'age' => (is=>'ro', required=>1);
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
    ->append_content($self->to_zoom($self->inline))
    ->then
    ->append_content($self->age);
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
        <self.inline />
        <self.section>
          Hi
          <self.section>
            Bye!
          </self.section>
        </self.section>
        <p>Hello <span id='name'></span></p>
        <lace.Footer copyright='2018'>
           <p><this.date /></p>
          <lace.Footer copyright='$.date' />
          <lace.Footer copyright='$$.date'>
            <b>fff</b>
          </lace.Footer>
        </lace.Footer>
      </body>
    </html>
  ];
}

sub todo_list {
  my ($self, $zoom) = @_;
  return $self->to_zoom(q[
        <ul class="todo-list">
          <view.ListItem task='$$.task' status='$$.status' />
        </ul>
    ])->select('.todo-list')
    ->repeat_content([ map {
      my $todo = $_; # $_->task, $_->status
      sub {
        $_->context($todo);
        $_->to_html($todo);
      }
    } @{$self->list}])
}
1;
