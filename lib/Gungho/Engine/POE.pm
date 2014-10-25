# $Id: /mirror/gungho/lib/Gungho/Engine/POE.pm 6394 2007-04-06T06:37:56.614962Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Engine::POE;
use strict;
use base qw(Gungho::Engine);
use POE;
use POE::Component::Client::HTTP;

__PACKAGE__->mk_accessors($_) for qw(alias);

use constant UserAgentAlias => 'Gungho_Engine_POE_UserAgent_Alias';

sub setup
{
    my $self = shift;
    $self->alias('MainComp');
    $self->next::method(@_);
}

sub run
{
    my ($self, $c) = @_;

    my $config = $self->config->{http_comp_args};
    POE::Component::Client::HTTP->spawn(%$config, 'Alias' => &UserAgentAlias);

    POE::Session->create(
        heap => { CONTEXT => $c },
        object_states => [
            $self => {
                _start => 'session_start',
                _stop  => 'session_stop',
                session_loop => 'session_loop',
                handle_response => 'handle_response',
            }
        ]
    );
    
    POE::Kernel->run();
}

sub session_start
{
    $_[KERNEL]->alias_set( $_[OBJECT]->alias );
    $_[KERNEL]->yield('session_loop');
}

sub session_stop
{
    $_[KERNEL]->alias_remove( $_[OBJECT]->alias );
}

sub session_loop
{
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    my $c = $heap->{CONTEXT};

    foreach my $request ( $c->get_requests() ) {
        $kernel->post(&UserAgentAlias, 'request', 'handle_response', $request);
    }

    if ($c->has_requests) {
        $kernel->yield('session_loop');
    } else {
        $kernel->yield('_stop');
    }
}

sub handle_response
{
    my ($heap, $req_packet, $res_packet) = @_[ HEAP, ARG0, ARG1 ];

    my $c = $heap->{CONTEXT};
    $c->handle_response($res_packet->[0]);
}

1;

__END__

=head1 NAME

Gungho::Engine::POE - POE Engine For Gungho

=head1 DESCRIPTION

=head1 METHODS

=head2 setup

sets up the engine.

=head2 run

Instantiates a PoCo::Client::HTTP session and a main session that handles the
main control.

=head2 handle_response

=head2 session_start

=head2 session_stop

=head2 session_loop

These are used as POE session states

=head1 TODO

Xango, Gungho's predecessor, tried really hard to overcome one of my pet-peeves
with PoCo::Client::HTTP -- which is that, while it can handle hundreds and
thousands of requests, all the requests are unnecessarily stored on
memory. Xango tried to solve this, but it ended up bloating the software.
We may try to tackle this later.

=cut