# $Id: /mirror/gungho/lib/Gungho/Handler.pm 6394 2007-04-06T06:37:56.614962Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Handler;
use strict;
use base qw(Gungho::Component);
use Gungho::Request;

sub handle_response {}

1;

=head1 NAME

Gungho::Handler - Base Class For Gungho Handlers

=head1 SYNOPSIS

  sub handle_response
  {
     my ($self, $response) = @_;
  }

=head1 METHODS

=head2 handle_response($response)

This is where you want to process the response.

=cut
