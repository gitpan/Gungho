# $Id: /mirror/gungho/lib/Gungho/Handler.pm 2907 2007-09-28T10:39:52.301767Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Handler;
use strict;
use warnings;
use base qw(Gungho::Base);
use Gungho::Request;

sub handle_response {}

1;

=head1 NAME

Gungho::Handler - Base Class For Gungho Handlers

=head1 SYNOPSIS

  sub handle_response
  {
     my ($self, $c, $request, $response) = @_;
  }

=head1 METHODS

=head2 handle_response($c, $request, response)

This is where you want to process the response.

=cut
