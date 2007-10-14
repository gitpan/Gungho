# $Id: /mirror/gungho/lib/Gungho/Log/Dispatch.pm 3234 2007-10-13T15:12:58.068532Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Log::Dispatch;
use strict;
use warnings;
use base qw(Gungho::Log);
use Log::Dispatch;

__PACKAGE__->mk_accessors($_) for qw(dispatch);

BEGIN
{
    foreach my $level qw(debug info notice warning error critical alert emergency) {
        eval "sub $level { shift->dispatch->$level(\@_) }"; die if $@;
    }
}

sub setup
{
    my $self   = shift;
    my $c      = shift;
    my $config = shift;
    $self->next::method($c, @_);

    my $list = $config->{logs};
    if (ref $list ne 'ARRAY') {
        $list = [ $list ];
    }

    my %args = ();
    if (my $callbacks = $config->{callbacks}) {
        if (ref $callbacks ne 'ARRAY') {
            $callbacks = [ $callbacks ];
        }
        foreach my $name (@$callbacks) {
            my $cb = ref $name eq 'CODE' ? $name : do {
                no strict 'refs';
                \&{$name};
            };
            if ($cb) {
                $args{callbacks} ||= [];
                push @{ $args{callbacks} }, $cb;
            }
        }
    }
    if (! $args{callbacks}) {
        $args{callbacks} = sub {
            my %args = @_;
            my $message = $args{message};
            if ($message !~ /\n$/) {
                $message =~ s/$/\n/;
            }
            return sprintf('[%s:%s] %s', $args{level}, $$, $message);
        };
    }
    if ($c->config->{debug}) {
        $args{min_level} = 'debug';
    } else {
        $args{min_level} ||= 'critical';
    }
    $args{min_level} ||= $c->config->{debug} ? 'debug' : 'critical';
    my $dispatch = Log::Dispatch->new(%args);
    foreach my $config (map { +{ %$_ } } @$list) {
        my $module = delete $config->{module} || die "no module specified";
        if ($module !~ s/^\+//) {
            $module = "Log::Dispatch::$module";
        }
        Class::Inspector->loaded($module) || $module->require || die "Could not load module $module";
        if ($c->config->{debug}) {
            $config->{min_level} = 'debug';
        } else {
            $config->{min_level} ||= $args{min_level};
        }
        $dispatch->add( $module->new(%$config) );
    }
    $self->dispatch($dispatch);
}

1;

__END__

=head1 NAME

Gungho::Log::Dispatch - Log::Dispatch-Based Log For Gungho

=head1 SYNOPSIS

  use Gungho::Log::Dispatch;

  my $log = Gungho::Log::Dispatch->new();
  $log->setup($c, {
    logs => [
      { module    => 'Screen',
        min_level => 'debug',
        name      => 'stderr',
        stderr    => 1
      },
      { module    => 'File',
        min_level => 'info',
        filename  => '/path/to/filename'
        mode      => 'append'
      }
    ]
  });

=head1 METHODS

=head2 setup($c, \%config)

Sets up the module

=head2 debug

=head2 info

=head2 notice 

=head2 warning 

=head2 error 

=head2 critical 

=head2 alert 

=head2 emergency

Logs to each level

=cut