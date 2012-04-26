#!/usr/bin/env perl

package Table1;

sub query {
    -columns => [qw(id foo bar)],
    -from => 'table1',
    (@_ == 1 ? (-where => $_[0]) : @_),
}

package Table2;

sub query {
    -columns => [qw(id baz glarch)],
    -from => 'table2',
    (@_ == 1 ? (-where => $_[0]) : @_),
}

package Table3;

sub query {
    -columns => [qw(id alfa)],
    -from => 'table3',
    (@_ == 1 ? (-where => $_[0]) : @_),
}

package main;

use v5.14;
use warnings;
use lib './lib';
use SQL::Abstract::Deferred qw(query base include);

use Data::Dump qw(pp);

my @qs = base {
    Table1::query -where => {foo => 't1.foo1'}, -key => 'id', -limit => 100,
} include {
    Table2::query -key => 'table1_id',
} include {
    Table3::query -key => 'table1_id',
};

my @res = query {'dbi:mysql:test','root'} @qs;

say pp \@res;
