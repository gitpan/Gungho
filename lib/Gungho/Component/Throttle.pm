# $Id: /mirror/gungho/lib/Gungho/Component/Throttle.pm 4037 2007-10-25T14:20:48.994833Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>

package Gungho::Component::Throttle;
use strict;
use warnings;
use base qw(Gungho::Component);

sub feature_name { 'Throttle' }
sub throttle { 1 }

sub send_request
{
    my ($c, $request) = @_;

    if (! $request->notes('original_host') && ! $c->throttle($request)) {
        $c->log->debug("Request " . $request->url . " (" . $request->id . ") was throttled");
        $c->provider->pushback_request($c, $request);
    } else {
        $c->next::method($request);
    }
}

1;

__END__

=head1 NAME

Gungho::Component::Throttle - Base Class To Throttle Requests

=head1 SYNOPSIS

  package Gungho::Component::Throttle::Domain;
  use base qw(Gungho::Component::Throttle);

=head1 DESCRIPTION

If you create a serious enough crawler, throttling will become a major issue.
After all, you want to *crawl* the sites, not overwhelm them with requests.

While the concept is simple, implementing this on your own is relatively 
costly, so Gungho provides a few simple ways to work with this problem.

Gungho::Component::Throttle::Simple will throttle simply by the number of
requests being sent at a time, regardless of what they are. This simple
approach will work well if your client-side resources are limited -- for
example, you don't want your requests to hog up too much bandwidth, so
you limit the actual number of requests being sent.

  # throttle down to 100 requests / hour
  components:
    - Throttle::Simple
  throttle:
    simple:
      max_iterms: 100
      interval: 3600

In most cases, however, you will probably want Gungho::Component::Throttle::Domain,
which throttles requests on a per-domain basis. This way you can, for example,
limit the number of requests being sent to one host, while letting the remaining
time slices to be used against some other host.

  # throttle down to 100 requests / host / hour
  components:
    - Throttle::Domain
  throttle:
    domain:
      max_iterms: 100
      interval: 3600

This component utilises Data::Throttler or Data::Throttler::Memcached for the
main engine to keep track of the throttling. Data::Throttler will suffice
if you are working from a single host. You will need Data::Throttler::Memcached if you have a farm of crawlers that may potentially be residing on different
hosts.

By default Data::Throttler will be used. If you want to override this, specify
the throttler argument in the configuration:

  components:
    - Throttle::Domain
  throttle:
    domain:
      throttler: Data::Throttler::Memcached
      cache:
        data: 127.0.0.1:11211
      max_items: 100
      interval: 3600

=head1 METHODS

=head2 feature_name

=head2 throttle

=head2 send_request

=cut