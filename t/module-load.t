#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 8;

BEGIN { use_ok('Log::Declare::Structured'); }

ok $main::{debug}, 'debug present in symbol table';
ok $main::{trace}, 'trace present in symbol table';
ok $main::{error}, 'error present in symbol table';
ok $main::{info},  'info present in symbol table';
ok $main::{warn},  'warn present in symbol table';
ok $main::{audit}, 'audit present in symbol table';

is $Log::Declare::Structured::NAMESPACE, 'main', 'namespace correct';
