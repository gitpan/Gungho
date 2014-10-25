# $Id: /local/gungho/lib/Gungho/Engine/Danga/Socket.pm 1751 2007-07-06T01:13:08.316580Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Engine::Danga::Socket;
use strict;
use warnings;
use base qw(Gungho::Engine);
use Danga::Socket::Callback;
use HTTP::Parser;
use IO::Socket::INET;
use Net::DNS;

# Danga::Socket uses the field pragma, which breaks things
# if we try to subclass from both Gungho::Engine and Danga::Socket.

__PACKAGE__->mk_accessors($_) for qw(active_requests context loop_delay resolver);

sub setup
{
    my $self = shift;
    $self->active_requests({});
    $self->loop_delay( $self->config->{loop_delay} ) if $self->config->{loop_delay};
    $self->next::method(@_);
}

sub run
{
    my ($self, $c) = @_;

    $self->resolver(Net::DNS::Resolver->new);
    $self->context($c);
    Danga::Socket->SetPostLoopCallback(
        sub {
            $c->dispatch_requests();

            my $delay = $self->loop_delay;
            if (! defined $delay || $delay <= 0) {
                $delay = 2;
            }
            select(undef, undef, undef, $delay);

            my $continue =  $c->is_running || Danga::Socket->WatchedSockets();

            if (! $continue) {
                $c->log->info("no more requests, stopping...");
            }
            return $continue;
        }
    );
    Danga::Socket->EventLoop();
}
        
sub send_request
{
    my $self = shift;
    my $c    = shift;
    my $req  = shift;

    if ($req->requires_name_lookup) {
        $self->lookup_name($c, $req);
    } else {
        $self->block_private_ip_address($c, $req, $req->uri->host)
            or $self->start_request($c, $req);
    }
}

sub lookup_name
{
    my ($self, $c, $req) = @_;
    my $resolver = $self->resolver;
    my $bgsock   = $resolver->bgsend($req->uri->host);

    my $danga = Danga::Socket::Callback->new(
        handle => $bgsock,
        on_read_ready => sub { 
            my $ds = shift;
            delete Danga::Socket->DescriptorMap->{ fileno($ds->sock) };
            $self->handle_dns_response(
                $c,
                $req,
                $resolver->bgread($ds->sock)
            );
        },
        on_error => sub {
            my $ds = shift;
            delete Danga::Socket->DescriptorMap->{ fileno($ds->sock) };
            $self->handle_response(
                $c,
                $req,
                $self->_http_error(500, "Failed to resolve host " . $req->uri->host, $req)
            );
        }
    );
}

sub start_request
{
    my ($self, $c, $req) = @_;
    my $uri  = $req->uri;

    my $socket = IO::Socket::INET->new(
        PeerAddr => $uri->host,
        PeerPort => $uri->port || $uri->default_port,
        Blocking => 0,
    );
    if ($@) {
        $self->handle_response(
            $req,
            $self->_http_error(500, "Failed to connect to " . $uri->host . ": $@", $req)
        );
        return;
    }

    $req->headers->push_header(user_agent => $c->default_user_agent);
    my $danga = Danga::Socket::Callback->new(
        handle         => $socket,
        context        => { write_done => 0 },
        on_write_ready => sub {
            my $ds = shift;
            if ($ds->{context}{write_done}) {
                if ($ds->write(undef)) {
                    $ds->watch_write(0);
                }
            }

            my $req_str = $req->format();
            if ($ds->write($req_str)) {
                $ds->watch_write(0);
            }
            $ds->{context}{write_done} = 1;
        },
        on_read_ready => sub {
            my $ds = shift;
            my $parser = $req->notes('parser');
            if (! $parser) {
                $parser = HTTP::Parser->new(response => 1);
                $req->notes('parser', $parser);
            }

            my ($buf, $success);
            while(1) {
                my $bytes = sysread($ds->sock(), $buf, 8192);
                last if ($bytes || 0) <= 0;

                my $parser_status = $parser->add($buf);

                if ($parser_status == 0 ) {
                    $success = 1;
                    last;
                }
            }

            if (! $success) {
                $self->handle_response(
                    $req,
                    $self->_http_error(400, "incomplete response", $req)
                );
                return;
            }

            my $response = $parser->object;
            $response->request($req);
            $ds->watch_read(0);
            delete Danga::Socket->DescriptorMap->{ fileno($ds->sock) };
            $self->handle_response($req, $response);
        }
    );

    $req->notes(danga => $danga);
}

sub handle_response
{
    my $self = shift;
    my $request = shift;
    my $response = shift;
    delete $self->active_requests->{$request->id};
    my $danga = $request->notes('danga');
    $request->notes('danga', undef);
    undef $danga;

    if (my $host = $request->notes('original_host')) {
        $request->uri->host($host);
    }

    $self->context->handle_response($request, $response);
}

1;

__END__

=head1 NAME

Gungho::Engine::Danga::Socket - Gungho Engine Using Danga::Socket

=head1 DESCRIPTION

This class uses Danga::Socket to dispatch requests.

WARNING: This engine is still experimental. Patches welcome!
In particular, this class definitely should cache connections.

=head1 METHODS

=head2 setup

=head2 run

=head2 lookup_name

=head2 send_request

=head2 start_request

=head2 handle_response

=cut
