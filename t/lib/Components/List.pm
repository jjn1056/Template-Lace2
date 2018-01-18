package Components::List;

use Moo;
extends 'Template::Lace2::Component';

has 'name' => (is=>'ro', required=>1);

sub process {

}

sub html {
  return qq[
    <html>
      <head>
        <title>List</title>
      </head>
      <body>
        <ul>
          <li>list item one</li>
        </ul>
      </body>
    </html>
  ];
}

1;

__DATA__


