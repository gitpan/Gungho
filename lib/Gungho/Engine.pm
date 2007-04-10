# $Id: /mirror/gungho/lib/Gungho/Engine.pm 6450 2007-04-10T01:52:17.416998Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Engine;
use strict;
use base qw(Gungho::Base);

sub run {}

1;

__END__

=head1 NAME

Gungho::Engine - Base Class For Gungho Engine

=head1 SYNOPSIS

  package Gungho::Engine::SomeEngine;
  use strict;
  use base qw(Gungho::Engine);

  sub run
  {
     ....
  }

=head1 METHODS

=head2 run()

Starts the engine. The exact behavior differs between each engine

=cut
