package SQL::Abstract::Deferred;

use v5.14;
use SQL::Abstract::More;

use Data::Dump qw(pp);

sub refp {
    return unless defined $_[0];
    return @{$_[0]} if ref $_[0] eq ref [];
    return @_;
}

sub merge (\%\%) {
    my %a = %{+shift};
    my %b = %{+shift};
    my $table = ref $a{'-from'} eq ref [] ? $a{'-from'}[-1] : $a{'-from'};

    my @columns = (
        (map {"$table.$_|$table:$_"} @{$a{'-columns'}}),
        (refp $b{'-columns'}),
    );
    my @from = (
        (refp $a{'-from'}),
        (refp $b{'-from'}),
    );
    my @where = (
        (refp $a{'-where'}),
        (refp $b{'-where'}),
    );

    delete($a{$_}),delete($b{$_}) for qw(-columns -from -where);

    my %m = (
        -columns => \@columns,
        -from => \@from,
        -where => \@where,
        %a,%b
    );

    return %m;
}

sub base (&;@) {
    my ($fn,%rest) = @_;
    my $a = SQL::Abstract::More->new;
    my %params = %{{$fn->()}};
    my %m = merge %params, %rest;
    $m{'-from'} = [-join => @{$m{'-from'}}];
    $m{'-where'} = $a->merge_conditions(@{$m{'-where'}});
    return $a->select(%m);
}

sub include (&;@) {
    my ($fn,%rest) = @_;
    my %params = %{{$fn->()}};
    return merge %params, %rest;
}

1;
