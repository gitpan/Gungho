# $Id: /mirror/gungho/lib/Gungho/Component.pm 6394 2007-04-06T06:37:56.614962Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Component;
use strict;
use base qw(Class::Accessor::Fast);
use Class::C3;
INIT { Class::C3::initialize() }

__PACKAGE__->mk_accessors($_) for qw(config);

sub new
{
    my $class  = shift;
    my $config = shift;

    my $self = bless {}, $class;
    $self->config($config);
    $self->setup();

    return $self;
}

sub setup {}

1;

__END__

=head1 NAME

Gungho::Component - Base Class For Various Gungho Components

=head1 SYNOPSIS

  package Gungho::Something;
  use base qw(Gungho::Component);

=head1 MMETHODS

=head2 new(\%config)

Creates a new component instance. Takes a config hashref. 

=head2 setup()

Sets up the components. Use it like this in your component:

  sub setup
  {
     my $self = shift;
     # do custom setup
     $self->next::method(@_);
  }

=cut
