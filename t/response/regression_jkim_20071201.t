use strict;
use Test::More (tests => 2);

BEGIN
{
    use_ok("Gungho::Response");
}

my $request = Gungho::Response->new(GET => "http://search.cpan.org");
$request->notes( foo => 1 );
$request->notes( bar => 2 );
$request->notes( baz => 3 );

my $cloned = $request->clone;

is_deeply($request->notes, $cloned->notes);