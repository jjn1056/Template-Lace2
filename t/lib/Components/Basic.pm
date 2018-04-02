package Components::Basic;

use Moo;
extends 'Template::Lace2::Component';

has 'name' => (is=>'ro', required=>1);

sub init_zoom {
  my ($class, $zoom) = @_;
  return $zoom->select('title')
    ->append_content(scalar(localtime));
}

sub process {
  my $self = shift;
  return $self->zoom
    ->replace('#name', $self->name);
}

sub insert_name {
  my ($self, $z, %args) = @_;
  return $self->name;
}

sub copyright { '2018' }

sub items { [qw/aa bb cc/] }

sub html {
  return q[
    <html>
      <head>
        <title>Hello World: </title>
      </head>
      <body>
        Hi there <span id='name'>NAME</span>!
        Hi there <self.name />!
        Hi there <self.insert_name>NAME</self.insert_name>!
        <view.ul list_items="$.items">
          <li><self.* /></li>
        </view.ul>
        <view.Footer copyright="$.copyright">
          <p id="a">Stuff for <self.name /> or <this.name arg1='$.copyright' arg2='$$.text'/></p>
        </view.Footer>
      </body>
    </html>
  ];
}

1;
