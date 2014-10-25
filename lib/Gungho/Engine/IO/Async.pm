# $Id: /mirror/gungho/lib/Gungho/Engine/IO/Async.pm 7087 2007-05-08T02:53:07.334658Z lestrrat  $
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
use IO::Socket::INET;

__PACKAGE__->mk_classdata($_) for qw(impl_class);
__PACKAGE__->mk_accessors($_) for qw(context impl loop_delay);

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
    $self->impl->run($c);
}

sub send_request
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
                $c->handle_response($notifier->{request}, $parser->object);
                $notifier->handle_closed();
                $self->impl->remove($notifier);
            }
        },
        on_read_error => sub {
            my $notifier = shift;
            my $res = $self->_http_error(400, "incomplete response", $notifier->{request});
            $c->handle_response($notifier->{request}, $res);
        },
        on_write_error => sub {
            my $notifier = shift;
            my $res = $self->_http_error(500, "Could not write to socket ", $notifier->{request});
            $c->handle_response($notifier->{request}, $res);
        }
    );

    # Not a good thing, I know...
    $buffer->{parser}  = HTTP::Parser->new(response => 1);
    $buffer->{request} = $req;

    $buffer->send($req->format);
    $self->impl->add($buffer);
}

# Stolen from PoCo::Client::HTTP::Request
sub _http_error
{
    my ($self, $code, $message, $request) = @_;

    my $nl = "\n";
    my $r = HTTP::Response->new($code);
    my $http_msg = status_message($code);
    my $m = (
      "<html>$nl"
      . "<HEAD><TITLE>Error: $http_msg</TITLE></HEAD>$nl"
      . "<BODY>$nl"
      . "<H1>Error: $http_msg</H1>$nl"
      . "$message$nl"
      . "</BODY>$nl"
      . "</HTML>$nl"
    );

    $r->content($m);
    $r->request($request);
    return $r;
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

=cut
