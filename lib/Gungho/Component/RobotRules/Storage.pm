# $Id: /mirror/gungho/lib/Gungho/Component/RobotRules/Storage.pm 7191 2007-05-15T02:45:51.609363Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>

package Gungho::Component::RobotRules::Storage;
use strict;
use warnings;
use base qw(Gungho::Base);

__PACKAGE__->mk_accessors($_) for qw(storage);

1;

__END__

=head1 NAME

Gunghoe::Component::RobotRules::Storage - RobotRules Storage Base Class

=cut
