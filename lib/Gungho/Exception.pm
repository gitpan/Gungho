# $Id: /mirror/gungho/lib/Gungho/Exception.pm 7061 2007-05-07T03:31:40.439848Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Exception;
use strict;
use warnings;
use Exception::Class
    'Gungho::Exception',
    map {
        ($_ => { isa => 'Gungho::Exception' })
    } qw(Gungho::Exception::RequestThrottled)
;

1;

__END__

=head1 NAME

Gungho::Exception - Gungho Exceptions

=cut
