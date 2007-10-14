# $Id: /mirror/gungho/lib/Gungho/Component/RobotRules/Storage.pm 3257 2007-10-14T03:29:36.340822Z lestrrat  $
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

Gungho::Component::RobotRules::Storage - RobotRules Storage Base Class

=cut
