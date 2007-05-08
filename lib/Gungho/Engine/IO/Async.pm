# $Id: /mirror/gungho/lib/Gungho/Engine/IO/Async.pm 7095 2007-05-08T11:46:52.290398Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Engine::IO::Async;
use strict;
use warnings;
use base qw(Gungho::Engine);
use HTTP::Parser;
use HTTP::Status;
use IO::Async::Buffer;
use IO::Async::Notifier;
use IO::Socket::INET;
use Net::DNS;

__PACKAGE__->mk_classdata($_) for qw(impl_class);
__PACKAGE__->mk_accessors($_) for qw(context impl loop_delay resolver);

# probe for available impl_class
use constant HAVE_IO_POLL => (eval { use IO::Poll } && !$@);

sub setup
{
    my ($self, $c) = @_;

    $self->context($c);
    $self->setup_impl_class($c);

    $self->loop_delay( $self->config->{loop_delay} ) if $self->config->{loop_delay};

}

sub setup_impl_class
{
    my ($self, $c) = @_;

    my $loop = $self->config->{loop};
    if (! $loop) {
        $loop = HAVE_IO_POLL ?
            'IO_Poll' :
            'Select'
        ;
    }
    my $pkg = $c->load_gungho_module($loop, 'Engine::IO::Async::Impl');
    $self->impl_class($pkg);

    my $obj = $pkg->new();
    $obj->setup($c);
    $self->impl( $obj );
}

sub run
{
    my ($self, $c) = @_;
    $self->resolver(Net::DNS::Resolver->new);
    $self->impl->run($c);
}

sub send_request
{
    my ($self, $c, $request) = @_;

    if ($request->requires_name_lookup) {
        $self->lookup_host($c, $request);
    } else {
        $self->start_request($c, $request);
    }
}

sub handle_response
{
    my ($self, $c, $req, $res) = @_;
    if (my $host = $req->notes('original_host')) {
        # Put it back
        $req->uri->host($host);
    }
    $c->handle_response($req, $res);
}

sub lookup_host
{
    my ($self, $c, $request) = @_;

    my $resolver = $self->resolver;
    my $bgsock   = $resolver->bgsend($request->uri->host);
    my $notifier = IO::Async::Notifier->new(
        handle => $bgsock,
        on_read_ready => sub {
            $self->impl->remove($_[0]);
            my $packet = $resolver->bgread($bgsock);
            foreach my $rr ($packet->answer) {
                next unless $rr->type eq 'A';
                $request->notes('original_host', $request->uri->host);
                $request->push_header('Host', $request->uri->host);
                $request->uri->host($rr->address);
                $self->start_request($c, $request);
                return;
            }

            $self->handle_response(
                $c,
                $request,
                $self->_http_error(500, "Failed to resolve host " . $request->uri->host, $request)
            );
        }
    );
    $self->impl->add($notifier);
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
    die if $@;

    my $buffer = IO::Async::Buffer->new(
        handle => $socket,
        on_incoming_data => sub {
            my ($notifier, $buffref, $closed) = @_;

            my $parser = $notifier->{parser};
            my $st = $parser->add($$buffref);
            $$buffref = '';

            if ($st == 0) {
                $self->handle_response($c, $notifier->{request}, $parser->object);
                $notifier->handle_closed();
                $self->impl->remove($notifier);
            }
        },
        on_read_error => sub {
            my $notifier = shift;
            my $res = $self->_http_error(400, "incomplete response", $notifier->{request});
            $c->handle_response($c, $notifier->{request}, $res);
        },
        on_write_error => sub {
            my $notifier = shift;
            my $res = $self->_http_error(500, "Could not write to socket ", $notifier->{request});
            $self->handle_response($c, $notifier->{request}, $res);
        }
    );

    # Not a good thing, I know...
    $buffer->{parser}  = HTTP::Parser->new(response => 1);
    $buffer->{request} = $req;

    $buffer->send($req->format);
    $self->impl->add($buffer);
}

package Gungho::Engine::IO::Async::Impl::Select;
use strict;
use warnings;
use base qw(IO::Async::Set::Select Class::Accessor::Fast);

__PACKAGE__->mk_accessors($_) for qw(context);

sub setup
{
}

sub run
{
    my ($self, $c) = @_;
    $self->context($c);

    my $engine = $c->engine;
    my ($rvec, $wvec, $evec);
    my $timeout;
    while ($c->is_running || keys %{$self->{notifiers}}) {
        $c->dispatch_requests();

        $timeout = $engine->loop_delay;
        if (! defined $timeout || $timeout <= 0) {
            $timeout = 5;
        }
        ($rvec, $wvec, $evec) = ('' x 3);

        $self->pre_select(\$rvec, \$wvec, \$evec, \$timeout);
        select($rvec, $wvec, $evec, $timeout);
        $self->post_select($rvec, $wvec, $evec);
    }
}

1;

__END__

=head1 NAME

Gungho::Engine::IO::Async - IO::Async Engine

=head1 DESCRIPTION

This class uses IO::Async to dispatch requests.

WARNING: This engine is still experimental. Patches welcome!
In particular, this class definitely should cache connections.

=head1 METHODS

=head2 run

=head2 setup

=head2 setup_impl_class

=head2 send_request

=head2 handle_response

=head2 start_request

=head2 lookup_host

=cut
