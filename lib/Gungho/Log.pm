# $Id: /mirror/gungho/lib/Gungho/Log.pm 6394 2007-04-06T06:37:56.614962Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Log;
use strict;
use warnings;
use base qw(Gungho::Component);
use Data::Dump;

our %LEVELS = ();
__PACKAGE__->mk_accessors($_) for qw(level body abort autoflush);

{
    my @levels = qw[ debug info warn error fatal ];

    for ( my $i = 0 ; $i < @levels ; $i++ ) {

        my $name  = $levels[$i];
        my $level = 1 << $i;

        $LEVELS{$name} = $level;

        no strict 'refs';

        *{$name} = sub {
            my $self = shift;

            if ( $self->{level} & $level ) {
                $self->_log( $name, @_ );
            }
        };

        *{"is_$name"} = sub {
            my $self = shift;
            return $self->{level} & $level;
        };
    }
}

sub new {
    my $class = shift;
    my $self  = $class->next::method(autoflush => 1, @_);
    $self->levels( scalar(@_) ? @_ : keys %LEVELS );
    return $self;
}

sub levels {
    my ( $self, @levels ) = @_;
    $self->level(0);
    $self->enable(@levels);
}

sub enable {
    my ( $self, @levels ) = @_;
    $self->{level} |= $_ for map { $LEVELS{$_} } @levels;
}

sub disable {
    my ( $self, @levels ) = @_;
    $self->{level} &= ~$_ for map { $LEVELS{$_} } @levels;
}

sub _dump {
    my $self = shift;
    $self->info( Data::Dump::dump(@_) );
}

sub _log {
    my $self    = shift;
    my $level   = shift;
    my $message = join( "\n", @_ );
    $message .= "\n" unless $message =~ /\n$/;
    $self->{body} .= sprintf( "[%s] %s", $level, $message );
    $self->_flush if $self->autoflush;
}

sub _flush {
    my $self = shift;
    if ( $self->abort || !$self->body ) {
        $self->abort(undef);
    }
    else {
        $self->_send_to_log( $self->body );
    }
    $self->body(undef);
}

sub _send_to_log {
    my $self = shift;
    print STDERR @_;
}

1;

__END__

=head1 NAME

Catalyst::Log - Catalyst Log Class

=head1 SYNOPSIS

    $log = $c->log;
    $log->debug($message);
    $log->info($message);
    $log->warn($message);
    $log->error($message);
    $log->fatal($message);

    if ( $log->is_debug ) {
         # expensive debugging
    }


See L<Catalyst>.

=head1 DESCRIPTION

This module provides the default, simple logging functionality for Catalyst.
If you want something different set C<< $c->log >> in your application module,
e.g.:

    $c->log( MyLogger->new );

Your logging object is expected to provide the interface described here.
Good alternatives to consider are Log::Log4Perl and Log::Dispatch.

If you want to be able to log arbitrary warnings, you can do something along
the lines of

    $SIG{__WARN__} = sub { MyApp->log->warn(@_); };

however this is (a) global, (b) hairy and (c) may have unexpected side effects.
Don't say we didn't warn you.

=head1 LOG LEVELS

=head2 debug

    $log->is_debug;
    $log->debug($message);

=head2 info

    $log->is_info;
    $log->info($message);

=head2 warn

    $log->is_warn;
    $log->warn($message);

=head2 error

    $log->is_error;
    $log->error($message);

=head2 fatal

    $log->is_fatal;
    $log->fatal($message);

=head1 METHODS

=head2 new

Constructor. Defaults to enable all levels unless levels are provided in
arguments.

    $log = Catalyst::Log->new;
    $log = Catalyst::Log->new( 'warn', 'error' );

=head2 levels

Set log levels

    $log->levels( 'warn', 'error', 'fatal' );

=head2 enable

Enable log levels

    $log->enable( 'warn', 'error' );

=head2 disable

Disable log levels

    $log->disable( 'warn', 'error' );

=head2 is_debug

=head2 is_error

=head2 is_fatal

=head2 is_info

=head2 is_warn

Is the log level active?

=head2 abort

Should Catalyst emit logs for this request? Will be reset at the end of 
each request. 

*NOTE* This method is not compatible with other log apis, so if you plan
to use Log4Perl or another logger, you should call it like this:

    $c->log->abort(1) if $c->log->can('abort');

=head2 _send_to_log

 $log->_send_to_log( @messages );

This protected method is what actually sends the log information to STDERR.
You may subclass this module and override this method to get finer control
over the log output.

=head1 SEE ALSO

L<Catalyst>.

=head1 AUTHOR

Sebastian Riedel, C<sri@cpan.org>
Marcus Ramberg, C<mramberg@cpan.org>
Christian Hansen, C<ch@ngmedia.com>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

1;