# $Id: /mirror/gungho/lib/Gungho/Handler/Null.pm 6394 2007-04-06T06:37:56.614962Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Handler::Null;
use strict;
use base qw(Gungho::Handler);

sub handle_response
{
    my $self = shift;
    my $c    = shift;
    my $res  = shift;
    my $req  = $res->request;

    $c->log->info($req->uri . " responded with code " . $res->code)
        if $c->log->is_info;
    $self->next::method($c, $res);
}

1;

=head1 NAME

Gungho::Handler::Null - A Handler That Does Nothing

=head1 METHODS

=head2 handle_response

Prints out the URI that just got fetched and its status code

=cut
