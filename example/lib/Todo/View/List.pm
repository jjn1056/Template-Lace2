package Todo::View::List;

use Moo;
extends 'Template::Lace2::Component';

has list => (is=>'ro', required=>1);

sub process {
  my $self = shift;
  return $self->zoom
   ->select('#active-count')
   ->replace_content(scalar @{$self->list});
}

sub html {
  return q[
    <lace.Todo-View-Master>
      <section class="todoapp">
        <header class="header">
          <h1>todos</h1>
          <form id="new_task" method="POST">
            <input name="title" autofocus="" class="new-todo" placeholder="What needs to be done?"/>
          </form>
        </header>
        <self.todo_list />
        <footer class="footer">
          <span class="todo-count"><strong id='active-count'>0</strong> item left</span> 
          <ul class="filters">
            <li>
              <a id='all'>All</a>
            </li>
            <li>
              <a id='active'>Active</a>
            </li>
            <li>
              <a id='completed'>Completed</a>
            </li>
          </ul><!-- Hidden if no completed items are left -->
          <form method="POST" id='clear_completed'>
            <button class="clear-completed" value="1" name="clear-completed">
              Clear completed</button>
          </form>
        </footer>
      </section>
      <footer class="info">
        <p>Click to edit a todo</p>
      </footer>
    </lace.Todo-View-Master>
  ];
}

sub todo_list {
  my ($self, $zoom) = @_;
  return $self->to_zoom(q[
      <section class="main">
        <ul class="todo-list">
          <li id="task">
            <form id="form" method="POST" action='/task/'>
              <div class="view">
                <input class="toggle" name='completed' type="checkbox" onclick="this.form.submit()" />
                <label for='completed'>Buy a unicorn </label>
                <button name='destroy' class="destroy" formaction='/task/'></button>
              </div>
              <input  class="edit" name="title" />
            </form>
          </li>
        </ul>
      </section>
    ])->select('.todo-list')
    ->repeat_content([ map {
      my $todo = $_;
      sub {
        $_->select('label')->replace_content($todo->{label})
          ->then
          ->set_attribute({'data-task'=>$todo->{id}})
          ->select('#task')
          ->set_attribute({
            id=>"task$todo->{id}",
            class=>do { $todo->{status} eq 'completed' ? 'completed' : 'active' },
          })
          ->select('form')
          ->set_attribute({action=>"/task/update/$todo->{id}"})
          ->select('input[name="completed"]')
          ->set_attribute($todo->{status} eq 'completed' ? {checked=>'checked'} : {})
          ->select('button[name="destroy"]')
          ->set_attribute({formaction=>"/task/delete/$todo->{id}"})
      }
    } @{$self->list}])
}

1;
