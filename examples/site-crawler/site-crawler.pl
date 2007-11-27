#!/usr/local/bin/perl
# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

use strict;
use warnings;
use Gungho;
use Gungho::Request;
use GunghoX::FollowLinks;
use URI;

main();

sub main
{
    my $site   = $ARGV[0];

    $site = URI->new($site) unless eval { $site->isa('URI') } && !$@;

    Gungho->run({
        provider => sub {
            my ($p, $c) = @_;
print STDERR $p->{links}, " more links to receive...\n";

            if (! $p->{started}) {
                $p->{links} = 0;
                $c->send_request( Gungho::Request->new( GET => $site ) );
                $p->{started} = 1;
            } else {
                $p->{next_dispatch} ||= 0;
                if ($p->{next_dispatch} > time()) {
                    return 1;
                }
                my $requests = $p->requests;
                while (my $request = shift @$requests) {
                    $request->uri->fragment(undef);
                    # Make sure to use the original hostname
                    my $original_uri = $request->original_uri;
                    if ( $p->{seen}{$original_uri->as_string}++ ) {
                        next;
                    }
                    $c->send_request( $request );
                    last;
                }
                $p->{next_dispatch} = time() + 3;
            }
            return 1;
        },
        handler  => sub {
            my ($h, $c, $req, $res) = @_;
            $c->provider->{links}--;
            print STDERR "Fetched ", $res->request->uri->as_string, "\n";
            my $links = $c->follow_links($res) || 0;
            print STDERR "  Following $links links\n";
            $c->provider->{links} += $links;
        },
        engine => {
            module => "POE",
        },
        components => [
            '+GunghoX::FollowLinks',
            'RobotRules',
            'Throttle::Simple',
        ],
        throttle => {
            simple => {
                max_items => 10000,
                interval => 3600,
            }
        },
        follow_links => {
            parsers => [
                { module => "HTML",
                  config => {
                      merge_rule => "ALL",
                      rules  => [
                        { module => "HTML::SelectedTags",
                          config => {
                            tags => [ qw(a link) ]
                          }
                        },
                        { module => "URI",
                          config => {
                            match => [ {
                                scheme => qr/^http$/i,
                                host => $site->host,
                                path => "^" . ($site->path || "/"),
                                action_nomatch => "FOLLOW_DENY"
                            } ]
                          }
                        },
                        { module => "MIME",
                          config => {
                            types => [ qw(text/html) ],
                            unknown => "FOLLOW_ALLOW",
                          }
                        },
                      ]
                  }
                }
            ]
        }
    });
}

1;

__END__

=head1 NAME

site-crawler.pl - Crawl Within A Specific Site

=head1 SYNOPSIS

  site-crawler.pl [path]

=head1 DESCRIPTION

This example crawls within the given site, looking for any links that might
be found within the pages. 

It will only look at HTML pages that reside under the url given in the
command line

Please note that this crawler will NOT terminate by itself at this point 
(it's an example toy!). You need to CTRL-C yourself

=cut