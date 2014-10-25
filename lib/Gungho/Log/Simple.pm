# $Id: /mirror/gungho/lib/Gungho/Log/Simple.pm 3234 2007-10-13T15:12:58.068532Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Log::Simple;
use strict;
use warnings;
use base qw(Gungho::Log::Dispatch);

sub setup {
    my $self   = shift;
    my $c      = shift;
    my $config = shift;

    $config ||= {};
    if (ref $config->{logs} ne 'HASH') {
        $config->{logs} = {};
    }

    $config->{logs}{module} = 'Screen';
    $config->{logs}{name}   = 'simple';
    $self->next::method($c, $config);
}

1;

__END__

=head1 NAME

Gungho::Log::Simple - Simple Gungho Log Class

=head1 SYNOPSIS

  use Gungho::Log::Simple;

  my $log = Gungho::Log::Simple->new();
  $log->setup($c,);

=head1 DESCRIPTION

This is a simple logger, which only logs to stderr.

=head1 METHODS

=head2 setup

Sets up the log

=cut