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

__END__
use Benchmark qw(:all) ;

my $t0 = Benchmark->new;
foreach (1..1000) {
  request '/hello';
}
my $t1 = Benchmark->new;
my $td = timediff($t1, $t0);
diag "the code took:",timestr($td),"\n";

my $t2 = Benchmark->new;
foreach (1..1000) {
  request '/hello/empty';
}
my $t3 = Benchmark->new;
my $td2 = timediff($t2, $t3);
diag "the code took:",timestr($td2),"\n";

