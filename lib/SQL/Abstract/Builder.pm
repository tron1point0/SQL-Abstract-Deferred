package SQL::Abstract::Builder;

use v5.14;
use DBIx::Simple;
use SQL::Abstract::More;
use List::Util qw(reduce);
use Hash::Merge qw(merge);
Hash::Merge::set_behavior('RETAINMENT_PRECEDENT');

use Exporter qw(import);
our @EXPORT_OK = qw(query build include);

# ABSTRACT: Quickly build & query relational data
# VERSION

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

sub smerge {
    my ($a,$b) = @_;
    for (keys $b) {
        $a->{$_} = $b->{$_} unless defined $a->{$_};
        next if $a->{$_} eq $b->{$_};
        $a->{$_} = [refp $a->{$_}] unless ref $a->{$_} eq ref [];
        push @{$a->{$_}}, refp $b->{$_};
    }
    return $a;
}

sub query (&;@) {
    my @db = (shift)->();
    my $dbh = ref $db[0] eq 'DBIx::Simple' ? $db[0] : DBIx::Simple->connect(@db);
    my ($key,%row);
    $row{$_->{$key}} = smerge $row{$_->{$key}}, $_ for map {{rollup %$_}}
    map {my @q;($key,@q) = $_->(); $dbh->query(@q)->hashes} @_;
    values %row;
}

sub build (&;@) {
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
        sub {$key, $a->select(%p)};
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
