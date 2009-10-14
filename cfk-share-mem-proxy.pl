#!/usr/bin/perl
use strict;
use warnings;

use Find::Lib './lib';
use Getopt::Long;
use AnyEvent();
use Data::Dumper;

use ControlFreak::Proxy::Process;
use Carp;
use Pod::Usage;

my %options;
GetOptions(
    "p|preload=s"    => \$options{preload},
    "c|command-fd=i" => \$options{'command-fd'},
    "s|status-fd=i"  => \$options{'status-fd'},

    'h|help'         => \$options{help},
    'm|man'          => \$options{man},
);

pod2usage(1)             if $options{help};
pod2usage(-verbose => 2) if $options{man};

croak "Please, specify a preload option" unless $options{preload};
require $options{preload};
croak "Error preloading: $@" if $@;

my $cfd = $options{'command-fd'} || 3;
my $sfd = $options{'status-fd'}  || 4;

open my $cfh, "<&=$cfd"
    or die "Cannot open Command filehandle, is descriptor correct?";

open my $sfh, ">>&=$sfd"
    or die "Cannot open Status filehandle, is descriptor correct?";

AnyEvent::Util::fh_nonblocking($_, 1) for ($cfh, $sfh);

my $proxy = ControlFreak::Proxy::Process->new(
    command_fh => $cfh,
    status_fh  => $sfh,
);

AnyEvent->condvar->recv;

__END__

=head1 NAME

cfk-share-mem-proxy.pl - a proxy process aimed at memory savings

=head1 SYNOPSIS

cfk-share-mem-proxy.pl [options]

Options:

 -p, --preload        a module/file that will be preloaded (using 'require')

 -h, --help           Help
 -m, --man            More help

=head1 OPTIONS

Please see L<SYNOPSIS>.

=head1 DESCRIPTION

Load some code/data in process' memory, and listen to C<ControlFreak> commands.
When instructed fork and exec a new command for a managed service. Reports
children events back to C<ControlFreak>.

=cut
