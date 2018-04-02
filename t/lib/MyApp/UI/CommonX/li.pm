package MyApp::UI::CommonX::li;

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
  return q[<li><lace.ctx>ITEM</lace.ctx></li>];
}

1;

__DATA__

sub todo {
  return [
    {name=>'John', age=>17},
    {name=>'Mike', age=>37},
    {name=>'Mary', age=>27},
  ];
}

<l.ul list_items='$.todo'>
  <l.li>
    Hi <$this.name />!  You are <$this.name /> years old!
  </l.li>
</l.ul>

<ul>[% FOREACH todo %]
  <li>
    Hi [% name %]! you are [% age %] years old!
  </li>
[% END %]</ul>
