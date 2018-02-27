use Test::Most;
use FindBin;
use lib "$FindBin::Bin/lib";

use MyRegistry;

ok my $registry = MyRegistry->new(component_namespace=>['CommonX','Components']);
ok my $hello1 = $registry->create('Hello', +{name=>'Vanessa'});
#ok my $hello2 = $registry->create('Hello', +{name=>'John'});

warn $hello1->to_html;
#warn $hello2->to_html;



ok 1;

done_testing;

__END__

produces output like:

<html>
   <head>
      <title>Hello World: Thu Jan 18 11:57:33 2018</title>
   </head>
   <body>
      <$.date />
      <p>Hello <span id='name'>Vanessa</span></p>
      <p class="footer">Copyright 2018</p>
      <p class="footer">Copyright 2020</p>
      <p class="footer">Copyright 2022</p>
      <p class="footer">Copyright 2010</p>
   </body>
</html>

