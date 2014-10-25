# $Id: /mirror/gungho/lib/Gungho/Component/Throttle/Throttler.pm 6746 2007-04-24T01:05:24.535007Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Component::Throttle::Throttler;
use strict;
use warnings;
use base qw(Gungho::Component::Throttle);
use Data::Throttler;

__PACKAGE__->mk_classdata($_) for qw(throttler);

sub prepare_throttler
{
    my $self = shift;
    my %args = @_;
    $self->throttler(
        Data::Throttler->new(
            max_items => $args{max_items} || 1000,
            interval  => $args{interval} || 3600,
            db_file   => $args{db_file} || undef,
        )
    );
}

1;

__END__

=head1 NAME

Gungho::Component::Throttle::Throttler - Data::Throttler Based Throttling

=head1 METHODS

=head2 prepare_throttler(%args)

=cut
