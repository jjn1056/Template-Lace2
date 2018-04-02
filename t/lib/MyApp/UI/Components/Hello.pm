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


sub section($$) {
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
           <p id="xxx"><this.date /></p>
          <lace.Footer copyright='$.date' />
          <lace.Footer copyright='$$.date'>
            <b>fff</b>
          </lace.Footer>
        </lace.Footer>
        <self.todo_list />
        <hr/>
        <lace.ul class="todo-list" list_items="$.items">
          <self.li>
            <self.li_in .='$this'>
              My age is: <this.age /> and I live in <this.state />
            </self.li_in>
          </self.li>
        </lace.ul>
      </body>
    </html>
  ];
}

sub li {
  my ($self, $inner, %args) = @_;
  return $inner;
}

sub li_in($) {
  my ($self, $inner, %args) = @_;
  return $self->to_zoom('<li>items</li>')
    ->select('li')
    ->replace_content($inner);
    #   ->select('.age')
    #  ->replace_content($args{age})
    #  ->select('.state')
    #  ->replace_content($args{state});
}


sub items {
  return [
    {age=>11, state=>'NY'},
    {age=>21, state=>'TX'},
    {age=>31, state=>'AL'},
  ];
}

sub class { 'e' }

sub list_item {
  my ($self, $inner, %args) = @_;
  return "<li classx='$args{classx}'>$args{task}</li>";
}


sub todo_list {
  my ($self, $zoom) = @_;
  return $self->to_zoom(q[
        <ul class="todo-list">
          <self.list_item class='list' classx='$.class' task={task} />
        </ul>
    ])->select('.todo-list')
    ->repeat_content([ map {
      my $todo = $_;
      sub {
          # 'self.list_item@task' => $todo->{task}
          # 'self.list_item' => +{ task => $todo->{task} }
          $_->set_attribute('self\.list_item' => { task => $todo->{task} })
      }
    } ({task=>'Milk'},{task=>'Dogs'})])
}



1;

__END__

<self.todo_list>
  <self.list_item>
    <li>TASK</li>
  <self.list_item>
</self.todo_list>


use Template::Lace2::Zoom;

[ list => +{ task=>$todo->{task} ]

list => sub { $_->loop({task=>'Milk'},{task=>'Dogs'}) },

my @tasks = ({task=>'Milk'},{task=>'Dogs'});
my @commands = map {} @tasks

->loop(@array_of_arrays||&sub,@array)

sub process_commands {
  my ($self, $ctx, $stream) = @_;
  my @events = @{$stream->{_array}||[]};
  my $z1 = Template::Lace2::Zoom->new({ zconfig => $self->registry->_zconfig })->from_events(\@events);
  my $html = $z1->zconfig->producer->html_from_stream($z1->to_stream, $self, $ctx);
  my $z2 = Template::Lace2::Zoom->new({ zconfig => $self->registry->_zconfig })->from_html($html);
  return $z2->to_stream;
}


<lace.ul class="todo-list" list_items="$.items">
  <self.list_item id="f" class='$.class' task='$$.task' />  
</ul>


sub ul::loop {
  my ($self, $inner, $item_itr) = @_;
  my $expanded_zoom = $self->zoom->select('ul')
    ->loop(sub {
      my $zoom$self->loop, @items);
  return 
  $zoom->repeat_contents([
    map {
      $item=$_;
      sub {
        $loop->($_, $item);
      } @{$self->items};
    ]
  );
}

sub items {
 return [
  { name=>'John' },
  { name=>'Joe' },
 ];
}

sub html {
  return q[<lace.ul
      items='$self->items' 
      loop='$inner->replace_contents("li", $_->{name})' >
    <li>Hi </li>
  </lace.ul>];
}

sub html {
  return q[<lace.ul
      list_items='$self->items' 
    <li>Hi <this.name />!</li>
  </lace.ul>];
}

sub items {
  return [
    {name=>'John', age=>25},
    {name=>'Jane', age=>35},
  ];
}

sub html {
  return q[
    <lace.ul list_items='$self->items'>
      <li>
        <view.PersonTagLine name='$this->{name}' age='$this->{age}' />
      </li>
  </lace.ul>];
}


sub html {
  return q[
    <lace.ul for='$item in $self->items'>
      <li>
        <view.PersonTagLine name='$item->{name}' age='$item->{age}' />
      </li>
  </lace.ul>];
}

<span {class}="$self->class">FFF</span>

<lace.ul>
  <lace.li>.map {
    $li->replace_contents($_->{name});
  } $self->items;
</lace.ul>


<lace.ul>
  <lace.li map = 'sub {
    $li->replace_contents($_->{name});
  } $self->items' />
</lace.ul>
