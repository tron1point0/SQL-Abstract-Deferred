#!/usr/bin/env perl

use v5.14;
use warnings;
use lib '.';
use Deferred;

my ($q,@bind) = Deferred::base {
    -columns => [qw(id foo bar)],
    -from => 'table1',
    -where => {foo => '1'},
} Deferred::include {
    -columns => [qw(id baz glarch)],
    -from => [qw(=>{table1.id=table2.table1_id} table2)],
    -where => {'table1.id' => 'table2.table1_id'},
} -limit => 100;

say $q;
say join ',',@bind;
