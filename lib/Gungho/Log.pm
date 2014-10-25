# $Id: /mirror/gungho/lib/Gungho/Log.pm 3234 2007-10-13T15:12:58.068532Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Log;
use strict;
use warnings;
use base qw(Gungho::Base);

BEGIN
{

    foreach my $level qw(debug info warn error fatal) {
        eval <<"        EOM";
            sub is_$level {
                Carp::carp("Gungho::Log->is_$level has been deprecated. Configure logs using 'min_level' parameter");
                return 0;
            }
        EOM
    }
}

1;