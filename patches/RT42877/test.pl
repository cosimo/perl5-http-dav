#!/usr/bin/perl

use strict;
use warnings;

my $h = {};
my $curr = $h->{basic_auth}->{netloc}->{realm};

print (( defined $curr ? "\$curr defined" : "\$curr undefined"), "\n");

@{ $h->{basic_auth}->{netloc}->{realm} } = (1, 2, 3);

print (( defined $curr ? "\$curr defined" : "\$curr undefined"), "\n");

print join(":", @{ $h->{basic_auth}->{netloc}->{realm} }), "\n";
