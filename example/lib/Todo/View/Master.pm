package Todo::View::Master;

use Moo;
extends 'Template::Lace2::Component';

has inner_events => (is=>'ro', requires=>1);

sub process {
  my $self = shift;
  return $self->zoom
    ->select('body')
    ->replace_content($self->inner_events);
}

sub html {
  return q[
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta content="width=device-width, initial-scale=1" name="viewport">
      <title>Page Title</title>
      <link href="/static/base.css" rel="stylesheet">
      <link href="/static/index.css" rel="stylesheet">
    </head>
    <body>
      <p>It goes here...</p>
    </body>
    </html>
  ];
}

1;
