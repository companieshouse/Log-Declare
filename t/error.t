#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 12;
use Test::Output;

use JSON;
use POSIX qw(strftime);

use FindBin;
use lib "$FindBin::Bin/../lib";

use Log::Declare::Structured;
Log::Declare->startup_level('ERROR');

stdout_like {
    error {message => 'error output'} [ERROR];
} qr/"event":"ERROR"/, 'error event field in output';

stdout_like {
    error {message => 'error output'} [ERRORTEST];
} qr/"categories":"\[ERRORTEST\]"/, 'error category in output';

stdout_like {
    error {message => 'error output'} [MULTIPLE ERRORTEST];
} qr/"categories":"\[MULTIPLE ERRORTEST\]"/, 'error categories in output';

stdout_like {
    error { message => 'error output' } [ERROR]; 
} qr/"namespace":"main"/, 'error namespace field in output';

my $now_string = strftime "%a %b %e %H:%M", gmtime;
stdout_like { 
   error {message => 'error output'} [ERROR]; 
} qr/"created":"$now_string/, 'created field in output';

stdout_like {
   error {message => 'error output'} [ERROR]; 
} qr/"message":"error output"/, 'error output';

stdout_like {
    error { field => 'value'} [ERROR];
} qr/"field":"value"/, 'field message';

stdout_like {
    error { request => sub { return 'txn123' }} [ERROR REQUEST]; 
} qr/"context":"txn123"/, 'error request output';

stdout_like {
    error { context => 'context str' } [ERROR CONTEXT]; 
} qr/"context":"context str"/, 'error context output';

stdout_like {
    my $a1 = 1;
    error { message => 'error with if conditional' } [DEBUG CONDITIONAL] if $a1; 
} qr/"message":"error with if conditional"/, 'error with if conditional';

stdout_like {
    my $a1 = 0;
    error { message => 'error with unless conditional' } [DEBUG CONDITIONAL] unless $a1; 
} qr/"message":"error with unless conditional"/, 'error with unless conditional';

stdout_like {
    my $a1 = 1;
    error { message => 'error with failing unless conditional' } [DEBUG CONDITIONAL] unless $a1;
} qr/^$/, 'error with failing unless conditional';
