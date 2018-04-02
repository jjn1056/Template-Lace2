package MyApp::Controller::Hello;

use warnings;
use strict;
use base 'Catalyst::Controller';

sub hello :Path('') Args(0) {
  my ($self, $c) = @_;
  my $view = $c->view('HTML::Hello', +{name=>'Vanessa'})
    ->http_ok;
}

sub empty :Local Args(0) {
  my ($self, $c) = @_;
  $c->res->body("helloworld");
}

1;
