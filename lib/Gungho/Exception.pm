# $Id: /mirror/gungho/lib/Gungho/Exception.pm 6461 2007-04-11T03:53:55.931149Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

use Exception::Class
    'Gungho::Exception',
    map {
        ($_ => { isa => 'Gungho::Exception' })
    } qw(Gungho::Exception::RequestThrottled)
;

1;

__END__

=head1 NAME

Gungho::Exception

=cut
