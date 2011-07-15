#!/usr/bin/perl

# rudimentary Perl implementation to satisfy minimal usage
# via Padre::Perl;

my $scriptname;
my $evalstring;

while ( my $carg = shift @ARGV ) {
    if($carg !~ /^-/) {
        $scriptname = $carg;
        last;
    }
    if($carg eq '-e') {
        $evalstring = shift @ARGV;
        last;
    }
    if($carg =~ /^-e.+/) { #'" keep duff editors happy
        $evalstring = $carg;
        $evalstring =~ s/^-e//;
        last;
    }
}

if($evalstring) {
    eval qq($evalstring);
    die $@ if $@;
}

if($scriptname) {
    do $scriptname;
    die $@ if $@;
}

1;

