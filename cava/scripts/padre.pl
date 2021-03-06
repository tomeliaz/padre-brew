#!/usr/bin/perl

use 5.008005;
use strict;
use warnings;
use Carp ();

local $| = 1;
local $SIG{__DIE__} =
    $ENV{PADRE_DIE}
    ? sub { print STDERR Carp::longmess "\nDIE: @_\n" . ( "-" x 80 ) . "\n" }
    : $SIG{__DIE__};

# Must run using wxPerl on OS X.
if ( $^O eq 'darwin' and $^X !~ m{/wxPerl} ) {
    # do nothing for packaged
} elsif ( $^O eq 'linux' ) {
    $ENV{LIBOVERLAY_SCROLLBAR} = 0;
}

# Handle special command line cases early, because options like --home
# MUST be processed before the Padre.pm library is loaded.
my $USAGE       = '';
my $VERSION     = '';
my $HOME        = undef;
my $RESET       = undef;
my $SESSION     = undef;
my $PRELOAD     = undef;
my $DESKTOP     = undef;
my $ACTIONS     = undef;
my $LOCALE      = undef;
my $WITH_PLUGIN = undef;
if ( grep {/^-/} @ARGV ) {

    # Avoid loading Getopt::Long entirely if we can,
    # sneakily saving a meg or so of RAM.
    require Getopt::Long;
    Getopt::Long::GetOptions(
        'help|usage'    => \$USAGE,
        'version'       => \$VERSION,
        'home=s'        => \$HOME,
        'reset'         => \$RESET,
        'session=s'     => \$SESSION,
        'desktop'       => \$DESKTOP,
        'actionqueue=s' => \$ACTIONS,
        'locale=s'      => \$LOCALE,
        'preload'       => \$PRELOAD,    # Keep this sekrit for now --ADAMK
        'with-plugin=s' => \$WITH_PLUGIN,
    ) or $USAGE = 1;
}





#####################################################################
# Special Execution Modules

# Padre command line usage
if ($USAGE) {
    print <<"END_USAGE";
Usage: $0 [FILENAMES]

--help              Shows this help message
--home=dir          Forces Padre "home" directory to a specific location
--reset             Flush entire local config directory and reset to defaults
--session=name      Open given session during Padre startup
--version           Prints Padre version and quits
--desktop           Integrate Padre with your desktop
--actionqueue=list  Run a list of comma-seperated actions after Padre startup
--locale=name       Locale name to use

END_USAGE
    exit(1);
}

# Padre version
if ($VERSION) {
    require Padre;
    my $msg = "Perl Application Development and Refactoring Environment $Padre::VERSION\n";
    if ( $^O eq 'MSWin32' and $^X =~ /wperl\.exe/ ) {

        # Under wperl, there is no console so we will use
        # a message box
        require Padre::Wx;
        Wx::MessageBox(
            $msg,
            Wx::gettext("Version"),
            Wx::wxOK(),
        );
    } else {
        print $msg;
    }
    exit(0);
}

# Lock in the home and constants, which are needed for everything else
local $ENV{PADRE_HOME} = defined($HOME) ? $HOME : $ENV{PADRE_HOME};
require Padre::Constant;

# Destroy and reinitialise our config directory
if ($RESET) {
    require File::Remove;
    File::Remove::remove( \1, Padre::Constant::CONFIG_DIR() );
    Padre::Constant::init();
}

if ($DESKTOP) {
    require Padre::Desktop;
    unless ( Padre::Desktop::desktop() ) {
        warn "--desktop not implemented for $^O\n";
    }
    exit(1);
}

# local $ENV{PADRE_PAR_PATH} = $ENV{PAR_TEMP} || '';

# If we have an action queue then we are running for automation reasons.
# Avoid the startup logic and continue to the main startup.
unless ( defined $ACTIONS ) {

    # Run the Padre startup sequence before we load the main application
    require Padre::Startup;
    unless ( Padre::Startup::startup() ) {

        # Startup process says to abort the main load and exit now
        exit(0);
    }
}

require Padre;

if ($PRELOAD) {

    # Load the entire application into memory immediately
    Padre->import(':everything');

    #   use Aspect;
    #   aspect( 'NYTProf',
    #       call qr/^Padre::/ &
    #       call qr/\b(?:refresh|update)\w*\z/ & !
    #       call qr/^Padre::(?:Locker|Wx::Progress)::/
    #   );
}

# Build the application
my $ide = Padre->new(
    files          => \@ARGV,
    session        => $SESSION,
    actionqueue    => $ACTIONS,
    startup_locale => $LOCALE,
) or die "Failed to create Padre instance";

$ide->{with_plugin} = {};
$ide->{with_plugin}->{$WITH_PLUGIN} = 1 if defined($WITH_PLUGIN);

# Start the application
$ide->run;

# Copyright 2008-2011 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
