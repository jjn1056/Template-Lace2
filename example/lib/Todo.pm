package Todo;

use Web::Simple;
use Todo::View;
use Plack::App::File;

my $view_factory = Todo::View->new(component_namespace=>['Todo::View']);
my $root = "./example/static";
my $idx = 0;
my @list = (
  {id=>$idx++, label=>"Buy Milk", status=>'active'},
  {id=>$idx++, label=>"Walk Dog", status=>'completed'}
);

sub show_list {
  my $self = shift;
  return $view_factory->create('Todo-View-List', list=>\@list)->to_html;
}

sub dispatch_request {
  '/static/...' => sub { Plack::App::File->new(root => $root) },
  '/' => sub {
    GET => sub {
      return [ 200, [ 'Content-type', 'text/html' ], [ shift->show_list ] ];
    },
  },
}

__PACKAGE__->run_if_script;
