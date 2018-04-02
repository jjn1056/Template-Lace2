package MyApp::UI::CommonX::ul;

use Moo;
extends 'Template::Lace2::Component';

has 'list_items' => (is=>'ro', required=>1);

sub process {
  my ($self) = @_;
  my $z = $self->zoom
    ->select('ul')
    ->repeat_content([ map {
      my $items = $_;
      sub {
          $_->select('lace\.ctx')->set_attribute({model=>$items})
          ->select('li')->replace($self->inner_events);
      }
    } @{$self->list_items}]);

#warn $z->to_html;

  return $z;
}


sub html {
  return q[<ul><lace.ctx><li></li></lace.ctx></ul>];
}

1;

__DATA__

process_loop {
  my ($self) = @_;

}


