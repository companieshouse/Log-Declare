#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;
use Log::Declare;

{
package TestAppender;

sub new {
    return bless {}, 'TestAppender';
}

sub trace {
   my ($self, $message) = @_;

   print STDOUT $message;
}
1;
}

test_method_import();
test_default_output();
test_output_to_appender();

done_testing();

# =============================================================================

sub test_method_import {
    subtest "Test import" => sub {
        plan tests => 6;

        ok(defined &{'main::trace'}, "Trace level is defined");
        ok(defined &{'main::debug'}, "Debug level is defined");
        ok(defined &{'main::error'}, "Error level is defined");
        ok(defined &{'main::warn' }, "Warn level is defined");
        ok(defined &{'main::info' }, "Info level is defined");
        ok(defined &{'main::audit'}, "Audit level is defined");
    };
}

sub test_default_output {
    subtest "Test log messages on standard error" => sub {
        plan tests => 2;

        # Capture STDERR and reopen it attached to a variable
        open SAVEERR, ">&STDERR";
        close STDERR;
        my $stderr = '';
        open STDERR, '>', \$stderr;

        # Capture STDOUT and reopen it attached to a variable
        open SAVEOUT, ">&STDOUT";
        close STDOUT;
        my $stdout = '';
        open STDOUT, '>', \$stdout;

        # Revert STDOUT to the original standard out, to display the results of the
        # tests
        close STDOUT;
        open STDOUT, ">&SAVEOUT";

        Log::Declare->startup_level('TRACE');

        trace "log message to standard error";
        like $stderr, qr/log message to standard error/, 'trace to standard error';
        is $stdout, '', 'no trace to standard out';
    };
}

sub test_output_to_appender {
    subtest "Test log messages appender" => sub {
        plan tests => 2;

        # Capture STDERR and reopen it attached to a variable
        open SAVEERR, ">&STDERR";
        close STDERR;
        my $stderr = '';
        open STDERR, '>', \$stderr;

        # Capture STDOUT and reopen it attached to a variable
        open SAVEOUT, ">&STDOUT";
        close STDOUT;
        my $stdout = '';
        open STDOUT, '>', \$stdout;

        Log::Declare->startup_level('TRACE');
        Log::Declare->appender(TestAppender->new());

        trace "log message to standard out";

        # Revert STDOUT to the original standard out, to display the results of the
        # tests
        close STDOUT;
        open STDOUT, ">&SAVEOUT";

        like $stdout, qr/log message to standard out/, 'appender trace to standard out';
        is $stderr, '', 'no trace to standard error';
    };
}
