# $Id: /local/gungho/lib/Gungho/Handler.pm 7199 2007-05-16T01:24:11.741951Z daisuke  $
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
     my ($self, $request, $response) = @_;
  }

=head1 METHODS

=head2 handle_response($request, response)

This is where you want to process the response.

=cut
