# $Id: /mirror/gungho/lib/Gungho/Component/RobotRules/Storage/DB_File.pm 9009 2007-11-12T15:00:57.083186Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>

package Gungho::Component::RobotRules::Storage::DB_File;
use strict;
use warnings;
use base qw(Gungho::Component::RobotRules::Storage);
use DB_File;
use Storable qw(nfreeze thaw);

sub setup
{
    my $self = shift;
    my $config = $self->{config};
    $config->{filename} ||= File::Spec->catfile(File::Spec->tmpdir, 'robots.db');

    my %o;
    my $dbm = tie %o, 'DB_File', $config->{filename};
    if (! $dbm) {
        die "Failed to tie $config->{filename} to hash: $!";
    }

    $self->storage( $dbm );
    $self->next::method(@_);
}

sub get_rule
{
    my $self    = shift;
    my $c       = shift;
    my $request = shift;
    my $v;

    my $uri = $request->original_uri;
    if ($self->storage->get( $uri->host_port, $v ) == 0) {
        return thaw($v);
    }
    return ();
}

sub put_rule
{
    my $self    = shift;
    my $c       = shift;
    my $request = shift;
    my $rule    = shift;

    my $uri = $request->original_uri;
    $self->storage->put( $uri->host_port, nfreeze($rule) );
}

sub get_pending_robots_txt
{
    my ($self, $c, $request) = @_;
    my $uri = $request->original_uri;
    delete $c->pending_robots_txt->{ $uri->host_port };
}

sub push_pending_robots_txt
{
    my ($self, $c, $request) = @_;
    my $uri = $request->original_uri;
    my $h = $c->pending_robots_txt->{ $uri->host_port };
    if (! $h) {
        $h = {};
        $c->pending_robots_txt->{ $uri->host_port } = $h;
    }

    if(! exists $h->{ $request->id }) {
        $c->log->debug("Pushing request " . $request->uri . " to pending list (robot rules)...");
        $h->{ $request->id } = $request ;
        return 1;
    }
    return 0;
}

1;

__END__

=head1 NAME

Gungho::Component::RobotRules::Storage::DB_File - DB_File Storage For RobotRules

=head1 METHODS

=head2 setup

=head2 get_rule

=head2 put_rule

=head2 get_pending_robots_txt

=head2 push_pending_robots_txt

=cut
