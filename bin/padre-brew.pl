#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long ();
use Cwd          ();
use File::Path   ();
use File::Spec   ();
use File::Copy   ();
use FileHandle;

our $VERSION = '0.01';
my $opt = {
  basedir      => Cwd::getcwd,
  name         => 'PadreApp',
  perlver      => '5.14.1',
  notest       => 0,
  v            => 0,
  modules_only => 0,
  url_cpanm    => 'http://xrl.us/cpanm',
  url_perlbrew => 'http://xrl.us/perlbrewinstall',
  all_plugins  => [
    qw/Wx::Scintilla Padre::Plugin::XS Padre::Plugin::Catalyst Padre::Plugin::Parrot Padre::Plugin::NYTProf Padre::Plugin::WxWidgets Padre::Plugin::PerlTidy Padre::Plugin::SpellCheck Padre::Plugin::PerlCritic Padre::Plugin::DataWalker Padre::Plugin::JavaScript Padre::Plugin::Autoformat Padre::Plugin::Mojolicious Padre::Plugin::Plack Padre::Plugin::DistZilla Padre::Plugin::XML Padre::Plugin::Git Padre::Plugin::SVN Padre::Plugin::Debugger/
  ],
  core_plugins    => [qw/Wx::Scintilla Padre::Plugin::PerlTidy Padre::Plugin::PerlCritic/],
  add_module      => [],
  base_module     => [qw/Padre Alien::wxWidgets/],
  use_all_plugins => 0,
  keep_man        => 0,
  _rootdir        => undef,
  _perldirname    => 'perl5',
  _builds         => {
    linux => '-Dcc=gcc -Dld=g++ -Dusethreads -Duseithreads -Duseshrplib',
    osx =>
      '-Dcc=gcc -Dld=g++ -Dusethreads -Duseithreads -Duseshrplib -Accflags="-arch i386 -DUSE_SITECUSTOMIZE -Duselargefiles -fno-merge-constants" -Aldflags="-Wl,-search_paths_first -arch i386" -Alddlflags="-Wl,-search_paths_first -arch i386"',
  },
  _platform => 'linux', };

Getopt::Long::GetOptions(
  $opt,
  'h|help',
  'basedir:s', # Where should we place the bundle directory, default is CWD
  'name:s'
  , # What should we call the padre bundle directory put under basedir, defaults to the PadreApp
  'perlver:s',                     # Which perl version should we use, defaults to 5.14.1
  'notest|no-test|bythesword',     # Skip testing perl and cpan, live dangerous
  'add_module:s@',                 # Add module
  'use_all_plugins|use-all-plugins'
  ,           # Defaults to FALSE, we normally only include the core_plugins and add_plugins
  'v|verbose',
  'modules_only|modules-only'
  , # Set if you want to SKIP directly to installing modules (you already did the perl setup)
  'url_cpanm:s',    # cpanm url if not default
  'keep_man',       # default to false
  'base_module:s@', # Core to padre such as Padre itself, and Alien-wxWidgets
);

if ( $opt->{h} ) {
  print <<'HELP';
    Sorry, help yet, pop open the script to see all the geopts.
HELP
  exit;
}

if ( $^O eq 'darwin' ) {
  $opt->{_platform} = 'osx';
}

if ( !$opt->{modules_only} ) {
  set_paths($opt);
  create_base_dir($opt);
  create_root_dir($opt);
  create_bin_dir($opt);
  create_perl_dir($opt);
  setup_cpanm($opt);
  setup_perlbrew($opt);
  build_perl($opt);
  clean_perlbrew($opt);
}

pre_modules_prep($opt);
setup_modules( $opt, $opt->{base_module} );
setup_modules( $opt, $opt->{core_plugins} );
setup_modules( $opt, $opt->{all_plugins} ) if $opt->{use_all_plugins};
setup_modules( $opt, $opt->{add_module} );
copy_padre_to_bin($opt);
clean_perl($opt);

print_helpful_message($opt);
exit;

# Set all the paths we're going to use in $opt
sub set_paths {
  my $opt = shift;

  $opt->{_basedir} = Cwd::abs_path( $opt->{basedir} );
  my $rootdir = $opt->{_rootdir} = File::Spec->catfile( $opt->{_basedir}, $opt->{name} );

  $opt->{_bindir}          = File::Spec->catfile( $rootdir,        'bin' );
  $opt->{_perlbrewinstall} = File::Spec->catfile( $opt->{_bindir}, 'perlbrewinstall' );
  $opt->{_cpanm}           = File::Spec->catfile( $opt->{_bindir}, '.cpanm.orig' );
  $opt->{_sandboxedcpanm}  = File::Spec->catfile( $opt->{_bindir}, 'cpanm' );

  $opt->{_perldir} = File::Spec->catfile( $rootdir, $opt->{_perldirname} );
  $opt->{_perlbrew} = File::Spec->catfile( $opt->{_perldir}, 'bin', 'perlbrew' );
  $opt->{_perltmpbuild} = File::Spec->catfile( $opt->{_perldir}, 'build' );
  $opt->{_perl} =
    File::Spec->catfile( $opt->{_perldir}, 'perls', 'perl-' . $opt->{perlver}, 'bin', 'perl' );
  $opt->{_perlmans} =
    File::Spec->catfile( $opt->{_perldir}, 'perls', 'perl-' . $opt->{perlver}, 'man' );
  $opt->{_perldisttgz} =
    File::Spec->catfile( $opt->{_perldir}, 'dists', 'perl-' . $opt->{perlver} . 'tar.gz' );
  $opt->{_padre_perlbin} =
    File::Spec->catfile( $opt->{_perldir}, 'perls', 'perl-' . $opt->{perlver}, 'bin', 'padre' );
  $opt->{_padre_root} = File::Spec->catfile( $opt->{_rootdir}, 'padre' );

} # end set_paths

sub create_base_dir {
  my $opt = shift;

  my $full_basedir = $opt->{_basedir};

  if ( !-d $full_basedir ) {
    my $cmd = 'Create Base Directory since it does not exist: ' . $full_basedir;
    verb( $opt, $cmd );
    if ( !File::Path::make_path($full_basedir) ) {
      die "Could not create base directory " . $full_basedir . " $?";
    }
  }
} # end create_root_dir

sub create_root_dir {
  my $opt     = shift;
  my $rootdir = $opt->{_rootdir};
  verb( $opt, "Using this root dir $rootdir" );

  if ( -d $rootdir ) {
    die "Root directory already exists, we cannot work in an existing directory: $rootdir";
  }

  my $cmd = "Create Root Directory since it does not exist: $rootdir";
  verb( $opt, $cmd );
  if ( !File::Path::make_path($rootdir) ) {
    die "Could not create root directory $rootdir $?";
  }

} # end create_root_dir

sub create_bin_dir {
  my $opt            = shift;
  my $only_if_needed = shift;
  util_create_dir( $opt, $opt->{_bindir}, $only_if_needed );
} # end create_bin_dir

sub create_perl_dir {
  my $opt            = shift;
  my $only_if_needed = shift;
  util_create_dir( $opt, $opt->{_perldir}, $only_if_needed );
}

sub setup_perlbrew {
  my $opt       = shift;
  my $perlbrewi = $opt->{_perlbrewinstall};

  my $perlbrew_source = $opt->{url_perlbrew};
  verb( $opt, "Downloading perlbrew $perlbrew_source to $perlbrewi" );
  downloadfile( $opt, $perlbrew_source, $perlbrewi );

  $ENV{PERLBREW_HOME} = $opt->{_perldir};
  $ENV{PERLBREW_ROOT} = $opt->{_perldir};

  my @brewcommand = ( 'bash', $perlbrewi, 'init' );
  verb( $opt, "Executing @brewcommand" );
  system(@brewcommand) == 0 or die "system @brewcommand failed: $?";

  check_perlbrew($opt);
} # setup_perlbrew

sub build_perl {
  my $opt = shift;

  verb( $opt, 'Building Perl' );

  my $notest = $opt->{notest} ? '--notest' : '';
  my $buildstr =
      $opt->{_perlbrew}
    . " install "
    . $opt->{perlver}
    . " $notest "
    . $opt->{_builds}->{ $opt->{_platform} };

  $ENV{PERLBREW_HOME} = $opt->{_perldir};
  $ENV{PERLBREW_ROOT} = $opt->{_perldir};

  verb( $opt, "Executing $buildstr" );
  system($buildstr) == 0 or die "system $buildstr failed: $?";

  check_perl($opt);

} # end build_perl

sub check_perl {
  my $opt = shift;
  if ( !-x $opt->{_perl} ) {
    die 'We thought we built a perl at ' . $opt->{_perl} . ' but it is not there or not executable';
  }
} # end check_perl

sub check_cpanm {
  my $opt   = shift;
  my $nodie = shift;
  if ( !-f $opt->{_cpanm} ) {
    if ($nodie) {
      return 0;
    }
    else {
      die 'We thought we had cpanm set up at ' . $opt->{_cpanm} . ' but we did not';
    }
  }

  return 1;
} # end check_cpanm

sub check_perlbrew {
  my $opt = shift;
  if ( !-x $opt->{_perlbrew} ) {
    die 'We thought we built a perlbrew at '
      . $opt->{_perlbrew}
      . ' but it is not there or not executable';
  }
}

# Delete the dist,
sub clean_perl {
  my $opt = shift;

  if ( -f $opt->{_perldisttgz} ) {
    verb( $opt, "Removing dist gz " . $opt->{_perldisttgz} );
    unlink $opt->{_perldisttgz} or warn "Could not remove perl dist at " . $opt->{_perldisttgz};
  }

  my $err_list = [];
  if ( !$opt->{keep_man} && -d $opt->{_perlmans} ) {
    verb( $opt, "Removing perl man dir " . $opt->{_perlmans} );
    File::Path::remove_tree( $opt->{_perlmans},
                             { verbose => 0,
                               error   => \$err_list, } );
  }

  if (@$err_list) {
    warn "Got errors while removing perl man dir " . join( ' ', @$err_list );
  }

  $err_list = [];
  if ( -d $opt->{_perltmpbuild} ) {
    verb( $opt, "Removing perl tmp build dir " . $opt->{_perltmpbuild} );
    File::Path::remove_tree( $opt->{_perltmpbuild},
                             { verbose => 0,
                               error   => \$err_list, } );
  }

  if (@$err_list) {
    warn "Got errors while removing perl tmp build dir " . join( ' ', @$err_list );
  }

} # end clean_perl

sub clean_perlbrew {
  my $opt = shift;

  verb( $opt, "Removing perlbrew install " . $opt->{_perlbrewinstall} );
  unlink $opt->{_perlbrewinstall}
    or warn "Could not remove perlbrew install at " . $opt->{_perlbrewinstall};
}

# Execute this prep before modules are installed, to double check
# everything we need is in place
sub pre_modules_prep {
  my $opt = shift;
  set_paths($opt);

  if ( !check_cpanm( $opt, 1 ) ) { # don't die on error
    create_bin_dir( $opt, 1 );     # conditional create
    setup_cpanm($opt);
  }

  check_perl($opt);
} # end pre_modules_prep

sub setup_modules {
  my $opt     = shift;
  my $modlist = shift;

  return if !$modlist;
  map { cpanm_install_module( $opt, $_ ) } @$modlist;
} # end setup_modules

sub cpanm_install_module {
  my $opt        = shift;
  my $modulename = shift;

  my $notest  = $opt->{notest} ? '--notest' : '';
  my $verbose = $opt->{v}      ? '-v'       : '';
  my @cpanmcommand = ( $opt->{_perl}, $opt->{_cpanm} );
  push( @cpanmcommand, $verbose ) if $verbose;
  push( @cpanmcommand, $notest )  if $notest;
  push( @cpanmcommand, '--no-man-pages' ) unless $opt->{keep_man};
  push( @cpanmcommand, $modulename );

  verb( $opt, "Executing @cpanmcommand" );
  system(@cpanmcommand) == 0 or die "system @cpanmcommand failed: $?";

} # end cpanm_install_module

sub util_create_dir {
  my $opt            = shift;
  my $dir            = shift;
  my $only_if_needed = shift;

  verb( $opt, "Creating Directory $dir" );

  if ( $only_if_needed && -d $dir ) {
    verb( $opt, "No need to create, already exists and ok: $dir" );
    return;
  }

  if ( !File::Path::make_path($dir) ) {
    die "Could not create Dir ($dir) $?";
  }

} # end util_create_dir

sub setup_cpanm {
  my $opt   = shift;
  my $cpanm = $opt->{_cpanm};

  my $cpanm_source = $opt->{url_cpanm};
  verb( $opt, "Downloading cpanm $cpanm_source to $cpanm" );
  downloadfile( $opt, $cpanm_source, $opt->{_cpanm} );

  create_sandboxed_cpanm($opt);
} # end setup_cpanm

sub create_sandboxed_cpanm {
  my $opt = shift;

  my $fh = FileHandle->new( $opt->{_sandboxedcpanm}, "w" );
  if ( defined $fh ) {
    my $orig_cpan = $opt->{_cpanm};
    my $perl      = $opt->{_perl};

    print $fh <<"CPANM";
#!/bin/bash
$perl $orig_cpan "\$\@"
CPANM

    $fh->close;
    chmod 0755, $opt->{_sandboxedcpanm};
  }
  else {
    warn "Could not create our sandboxed cpanm at " . $opt->{_sandboxedcpanm};
  }

} # end create_sandboxed_cpanm

sub copy_padre_to_bin {
  my $opt        = shift;
  my $padre_root = $opt->{_padre_root};
  if ( !-f $padre_root ) {
    verb( $opt, "Copying padre to our root" );
    File::Copy::copy( $opt->{_padre_perlbin}, $padre_root )
      or warn "Copy failed of Padre from perl bin to root: $!";
    chmod 0755, $padre_root;
  }
}

sub print_helpful_message {
  my $opt   = shift;
  my $padre = $opt->{_padre_root};
  my $cpanm = $opt->{_sandboxedcpanm};
  print <<"MESS";

Install future modules: $cpanm
Run Padre: $padre
MESS
} # end print_helpful_message

sub downloadfile {
  my $opt         = shift;
  my $url         = shift;
  my $tofile      = shift;
  my @curlcommand = ( 'curl', '-L', $url, '-#', '-k', '-o', $tofile );
  verb( $opt, "Executing  @curlcommand" );
  system(@curlcommand) == 0 or die "system @curlcommand failed: $?";

} # end downloadfile

sub verb {
  my $opt = shift;
  my $str = shift;
  print STDERR "$str\n" if $opt->{v};
}

