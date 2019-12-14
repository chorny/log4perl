#!/usr/local/bin/perl -w

BEGIN { 
    if($ENV{INTERNAL_DEBUG}) {
        require Log::Log4perl::InternalDebug;
        Log::Log4perl::InternalDebug->enable();
    }
}

use strict;
use warnings;
use Test::More;
use Config;

our $SIGNALS_AVAILABLE = 0;

BEGIN {
    no warnings;
    # Check if this platform supports signals
    if (length $Config{sig_name} and length $Config{sig_num}) {
        eval {
            $SIG{USR1} = sub { $SIGNALS_AVAILABLE = 1 };
            # From the Config.pm manpage
            my(%sig_num);
            my @names = split ' ', $Config{sig_name};
            @sig_num{@names} = split ' ', $Config{sig_num};

            kill $sig_num{USR1}, $$;
        };
        if($@) {
            $SIGNALS_AVAILABLE = 0;
        }
    }
        
    if ($SIGNALS_AVAILABLE) {
        plan tests => 4;
    }else{
        plan skip_all => "only on platforms supporting signals";
    }
}

use Log::Log4perl::Config::Watch;

my $EG_DIR = "eg";
$EG_DIR = "../eg" unless -d $EG_DIR;

  # sample file to run tests on
my $file = "$EG_DIR/log4j-manual-1.conf";

my $w = Log::Log4perl::Config::Watch->new(
    file   => $file,
    signal => 'USR1',
);

$w->change_detected();
$Log::Log4perl::Config::Watch::L4P_TEST_CHANGE_DETECTED = 0;
$Log::Log4perl::Config::Watch::L4P_TEST_CHANGE_CHECKED  = 0;
$w->change_detected();

is($Log::Log4perl::Config::Watch::L4P_TEST_CHANGE_CHECKED,
   0, "no change checked without signal");
is($Log::Log4perl::Config::Watch::L4P_TEST_CHANGE_DETECTED,
   0, "no change detected without signal");

$w->force_next_check();
$w->change_detected();

is($Log::Log4perl::Config::Watch::L4P_TEST_CHANGE_CHECKED,
   1, "change checked after force_next_check()");
is($Log::Log4perl::Config::Watch::L4P_TEST_CHANGE_DETECTED,
   0, "no change detected after force_next_check()");
