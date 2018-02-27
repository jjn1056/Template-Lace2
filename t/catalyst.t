BEGIN {
  use FindBin;
  use lib "$FindBin::Bin/lib";
}

use Test::Most;
use Catalyst::Test 'MyApp';

{
  ok my $res = request '/hello';
  warn $res->content; 


}



done_testing;
