# $Id: /mirror/gungho/lib/Gungho/Handler/Null.pm 6417 2007-04-07T10:46:29.321551Z lestrrat  $
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
    my $req  = shift;
    my $res  = shift;

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
