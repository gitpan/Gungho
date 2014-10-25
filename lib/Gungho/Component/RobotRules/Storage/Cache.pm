# $Id: /mirror/gungho/lib/Gungho/Component/RobotRules/Storage/Cache.pm 3258 2007-10-14T03:35:40.766816Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Component::RobotRules::Storage::Cache;
use strict;
use warnings;
use base qw(Gungho::Component::RobotRules::Storage);

__PACKAGE__->mk_accessors($_) for qw(expiration);

sub setup
{
    my $self = shift;
    my $c    = shift;
    my %config = %{ $self->{config} };
    my $module = delete $config{module} || 'Cache::Memcached';
    my $expiration = delete $config{expiration} || 86400  * 7;

    Class::Inspector->loaded($module) or $module->require or die;
    $self->storage( $module->new(%config) );
    $self->expiration( $expiration );
    $self->next::method(@_);
}

sub get_rule
{
    my $self    = shift;
    my $c       = shift;
    my $request = shift;

    my $uri  = $request->original_uri;
    my @args;
    my $storage = $self->storage;
    if ($storage->isa('Cache::Memcached::Managed')) {
        @args = (id => $uri->host_port, key => 'robot_rules.rule');
    } else {
        @args = ($uri->host_port);
    }
    my $rule = $self->storage->get( @args );
    $c->log->debug("Fetch robot rules for $uri ($rule)");
    return $rule || ();
}

sub put_rule
{
    my $self    = shift;
    my $c       = shift;
    my $request = shift;
    my $rule    = shift;

    my $uri = $request->original_uri;
    $c->log->debug("Saving robot rules for $uri");

    # Cache:::Memcached::Managed is a bad boy and breaks API compatibility
    # with the rest of the Cache::* modules
    my @args;
    my $storage = $self->storage;
    if ($storage->isa('Cache::Memcached::Managed')) {
        @args = (id => $uri->host_port, key => 'robot_rules.rule', value => $rule, expiration => $self->expiration);
    } else {
        @args = ($uri->host_port, $rule, $self->expiration);
    }
    $self->storage->set( @args );
}

sub get_pending_robots_txt
{
    my ($self, $c, $request) = @_;

    my $uri = $request->original_uri;
    my $host_port = $uri->host_port;
    my @args;
    my $storage = $self->storage;
    my $is_managed = $storage->isa('Cache::Memcached::Managed');

    if ($is_managed) {
        @args = (id => $host_port, key => 'robot_rules.pending_robots_txt');
    } else {
        @args = ($host_port);
    }

    $storage->remove(@args);
    return delete $c->pending_robots_txt->{ $host_port };
}

sub push_pending_robots_txt
{
    my ($self, $c, $request) = @_;

    my $uri = $request->original_uri;
    my $host_port = $uri->host_port;
    my @args;
    my $storage = $self->storage;
    my $is_managed = $storage->isa('Cache::Memcached::Managed');

    if ($is_managed) {
        @args = (id => $host_port, key => 'robot_rules.pending_robots_txt');
    } else {
        @args = ($host_port);
    }

    # If it already exists in the cache, just return
    if ($storage->get(@args)) {
        return 0;
    }

    $c->pending_robots_txt->{ $host_port } ||= {};
    my $h = $c->pending_robots_txt->{ $host_port };

    # pending requests are still stored in-memory
    $c->log->debug("Pushing request $uri to pending list (robot rules)...");

    if ($is_managed) {
        push @args, (value => 1);
    } else {
        push @args, 1;
    }

    $self->storage->set( @args );
    $h->{ $request->id } = $request ;
    return 1;
}

1;

__END__

=head1 NAME

Gungho::Component::RobotRules::Storage::Cache - Cache Storage For RobotRules

=head1 SYNOPSIS

  robotrules:
    cache:
      module: 'Cache::Memcached'
      expiration: 86400
      servers:
        - 127.0.0.1:11211

=head1 METHODS

=head2 setup

=head2 get_rule

=head2 put_rule

=head2 get_pending_robots_txt

=head2 push_pending_robots_txt

=cut
