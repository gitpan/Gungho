use strict;
use Test::More;
use lib("t/lib");
use GunghoTest;

BEGIN
{
    if (! GunghoTest::assert_engine()) {
        plan(skip_all => "No engine available");
    } elsif ( ! eval "use IO::Scalar" || $@) {
        plan(skip_all => "IO::Scalar not installed: $@");
    } else {
        plan(tests => 5);
        use_ok("Gungho::Inline");
    }
}

my ($fh, $output);
$fh = IO::Scalar->new(\$output) || die "Failed to open handle to scalar \$output";

# If we're not connect to the net the request itself may fail, but we're
# not interested in that
Gungho::Inline->run(
    {
        plugins => [
            { module => "RequestLog",
              config => [
                  { module => "Handle", name => 'request_log', handle => $fh, min_level => 'debug'}
              ]
            },
        ],
    },
    {
        provider => sub {
            my($p, $c) = @_;
            $p->add_request(Gungho::Request->new(GET => $_)) for qw(
                http://www.perl.com
                http://search.cpan.org
            )
        }
    }
);

like($output, qr{^# \d+(?:\.\d+)? | http://www\.perl\.com | (?:[a-f0-9]+)}, "fetch start for www.perl.com");
like($output, qr{^# \d+(?:\.\d+)? | http://search\.cpan\.org | (?:[a-f0-9]+)}, "fetch start for search.cpan.org");
like($output, qr{^\d+(?:\.\d+)? | \d+(?:\.\d+)? | \d{3} | http://www\.perl\.com | (?:[a-f0-9]+)}, "http://www.perl.com is properly logged");
like($output, qr{^\d+(?:\.\d+)? | \d+(?:\.\d+)? | \d{3} | http://search\.cpan\.org | (?:[a-f0-9]+)}, "http://search.cpan.org is properly logged");