use strict;
use warnings;
use Test::More tests => 3;

=pod

=head1 Mon Nov 06 10:49:04 2017 rjbs [...] cpan.org - Ticket created 

B<Subject>:	the clone method doesn't properly respect class

It does "$self = @_" which means $self is 1, which means ref($self) is undef, and bless into undef means bless into __PACKAGE__

Patch attached.

-- 
rjbs

=head1 Subject:	0001-clone-fix-how-self-comes-off-the-stack.patch

 From 8c18a38f155daeaa23a44f3f6cd487e3f243d9e2 Mon Sep 17 00:00:00 2001
 From: Ricardo Signes <rjbs@cpan.org>
 Date: Mon, 6 Nov 2017 10:47:24 -0500
 Subject: [PATCH] clone: fix how $self comes off the stack

 without this, cloning will lose class
 ---
  lib/HTTP/DAV.pm | 2 +-
  1 file changed, 1 insertion(+), 1 deletion(-)
 
 diff --git a/lib/HTTP/DAV.pm b/lib/HTTP/DAV.pm
 index cd2995d..81062f9 100644
 --- a/lib/HTTP/DAV.pm
 +++ b/lib/HTTP/DAV.pm
 @@ -36,7 +36,7 @@ sub new {
 
 ###########################################################################
  sub clone {
 -    my $self  = @_;
 +    my ($self) = @_;
      my $class = ref($self);
      my %clone = %{$self};
      bless {%clone}, $class;
 -- 
 2.14.2

=cut

use_ok('HTTP::DAV');

note "Normal new";
my $d = HTTP::DAV->new();
isa_ok( $d, "HTTP::DAV" );

note "Clone";
my $c = $d->clone();
isa_ok( $c, "HTTP::DAV" );


done_testing();


