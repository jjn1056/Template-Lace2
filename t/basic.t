use Test::Most;
use FindBin;
use lib "$FindBin::Bin/lib";

use MyRegistry;

ok my $registry = MyRegistry->new;
ok my $hello1 = $registry->create('Hello', +{name=>'Vanessa'});
ok my $hello2 = $registry->create('Hello', +{name=>'John'});

warn $hello1->to_html;
#warn $hello2->to_html;



ok 1;

done_testing;



