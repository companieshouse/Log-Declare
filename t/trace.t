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
Log::Declare->startup_level('TRACE');

stdout_like {
    trace {message => 'trace output'} [TRACE];
} qr/"event":"TRACE"/, 'trace event field in output';

stdout_like {
    trace {message => 'trace output'} [TRACETEST];
} qr/"categories":"\[TRACETEST\]"/, 'trace category in output';

stdout_like {
    trace {message => 'trace output'} [MULTIPLE TRACETEST];
} qr/"categories":"\[MULTIPLE TRACETEST\]"/, 'trace categories in output';

stdout_like {
    trace { message => 'trace output' } [TRACE]; 
} qr/"namespace":"main"/, 'trace namespace field in output';

my $now_string = strftime "%a %b %e %H:%M", gmtime;
stdout_like { 
   trace {message => 'trace output'} [TRACE]; 
} qr/"created":"$now_string/, 'created field in output';

stdout_like {
   trace {message => 'trace output'} [TRACE]; 
} qr/"message":"trace output"/, 'trace output';

stdout_like {
    trace { field => 'value'} [TRACE];
} qr/"field":"value"/, 'field message';

stdout_like {
    trace { request => sub { return 'txn123' }} [TRACE REQUEST]; 
} qr/"context":"txn123"/, 'trace request output';

stdout_like {
    trace { context => 'context str' } [TRACE CONTEXT]; 
} qr/"context":"context str"/, 'trace context output';

stdout_like {
    my $a1 = 1;
    trace { message => 'trace with if conditional' } [DEBUG CONDITIONAL] if $a1; 
} qr/"message":"trace with if conditional"/, 'trace with if conditional';

stdout_like {
    my $a1 = 0;
    trace { message => 'trace with unless conditional' } [DEBUG CONDITIONAL] unless $a1; 
} qr/"message":"trace with unless conditional"/, 'trace with unless conditional';

stdout_like {
    my $a1 = 1;
    trace { message => 'trace with failing unless conditional' } [DEBUG CONDITIONAL] unless $a1;
} qr/^$/, 'trace with failing unless conditional';
