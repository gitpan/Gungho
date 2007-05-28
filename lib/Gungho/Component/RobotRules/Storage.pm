# $Id: /local/gungho/lib/Gungho/Component/RobotRules/Storage.pm 7192 2007-05-15T04:06:52.376453Z lestrrat  $
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
