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
Log::Declare->startup_level('DEBUG');

stdout_like {
    debug {message => 'debug output'} [DEBUG];
} qr/"event":"DEBUG"/, 'debug event field in output';

stdout_like {
    debug {message => 'debug output'} [DEBUGTEST];
} qr/"categories":"\[DEBUGTEST\]"/, 'debug category in output';

stdout_like {
    debug {message => 'debug output'} [MULTIPLE DEBUGTEST];
} qr/"categories":"\[MULTIPLE DEBUGTEST\]"/, 'debug categories in output';

stdout_like {
    debug { message => 'debug output' } [DEBUG]; 
} qr/"namespace":"main"/, 'debug namespace field in output';

my $now_string = strftime "%a %b %e %H:%M", gmtime;
stdout_like { 
   debug {message => 'debug output'} [DEBUG]; 
} qr/"created":"$now_string/, 'created field in output';

stdout_like {
   debug {message => 'debug output'} [DEBUG]; 
} qr/"message":"debug output"/, 'debug output';

stdout_like {
    debug { field => 'value'} [DEBUG];
} qr/"field":"value"/, 'field message';

stdout_like {
    debug { request => sub { return 'txn123'} } [DEBUG REQUEST]; 
} qr/"context":"txn123"/, 'debug request output';

stdout_like {
    debug { context => 'context str' } [DEBUG CONTEXT]; 
} qr/"context":"context str"/, 'debug context output';

stdout_like {
    my $a1 = 1;
    debug { message => 'debug with if conditional' } [DEBUG CONDITIONAL] if $a1; 
} qr/"message":"debug with if conditional"/, 'debug with if conditional';

stdout_like {
    my $a1 = 0;
    debug { message => 'debug with unless conditional' } [DEBUG CONDITIONAL] unless $a1; 
} qr/"message":"debug with unless conditional"/, 'debug with unless conditional';

stdout_like {
    my $a1 = 1;
    debug { message => 'debug with failing unless conditional' } [DEBUG CONDITIONAL] unless $a1;
} qr/^$/, 'debug with failing unless conditional';
