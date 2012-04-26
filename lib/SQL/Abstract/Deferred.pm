package SQL::Abstract::Deferred;

use v5.14;
use DBIx::Simple;
use SQL::Abstract::More;
use List::Util qw(reduce);
use Hash::Merge qw(merge);
Hash::Merge::set_behavior('RETAINMENT_PRECEDENT');

use Exporter qw(import);
our @EXPORT_OK = qw(query base include);

use Data::Dump qw(pp);

sub refp {
    return unless defined $_[0];
    return @{$_[0]} if ref $_[0] eq ref [];
    return @_;
}

sub rollup {
    my %row = @_;
    my @fields = grep {m/\w+:\w+/} keys %row;
    for (@fields) {
        my ($t,$c) = split ':';
        $row{$t}{$c} = delete $row{$_};
    }
    %row;
}

sub query (&;@) {
    my @db = (shift)->();
    my $dbh = ref $db[0] eq 'DBIx::Simple' ? $db[0] : DBIx::Simple->connect(@db);
    map {{rollup %$_}}
    map {$dbh->query($_->())->hashes} @_;
}

sub base (&;@) {
    my ($fn,@includes) = @_;
    my %params = $fn->();
    my $table = $params{'-from'};
    $params{'-columns'} = [map {"$table.$_"} refp $params{'-columns'}];
    my $key = delete $params{'-key'};
    my $a = SQL::Abstract::More->new;
    map {
        my %p = %{merge \%params, {$_->()}};
        $p{'-from'} = [-join =>
            map {ref $_ eq ref sub {} ? ($_->($table,$key)) : $_ } refp $p{'-from'}
        ];
        sub {$a->select(%p)};
    } @includes;
}

sub include (&;@) {
    my ($fn,@rest) = @_;
    my %params = $fn->();
    my ($jtable,$jfield) = @params{qw(-from -key)};
    $params{'-columns'} = [
        map {"$jtable.$_|'$jtable:$_'"}
        refp $params{'-columns'}
    ];
    $params{'-from'} = sub {"=>{$_[0].$_[1]=$jtable.$jfield}",$jtable};
    delete $params{'-key'};
    return sub {%params}, @rest;
}

1;
