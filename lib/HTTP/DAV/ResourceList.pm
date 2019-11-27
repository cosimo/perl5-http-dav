package HTTP::DAV::ResourceList;

use strict;
use vars qw($VERSION);

$VERSION = '0.11';

####
# Construct a new object and initialize it
sub new {
   my $class = shift;
   my $self = bless {}, ref($class) || $class;
   $self->_init(@_);
   return $self;
}

sub _init {
   my ($self,@p) = @_;

   ####
   # This is the order of the arguments unless used as 
   # named parameters
   my @arg_names = qw (
      RESOURCE_TYPE
   );

   my @pa = HTTP::DAV::Utils::rearrange( \@arg_names, @p);

   $self->{_resources} = [];
   $self->{_resource_indexes} = {};
}

####
# List Operators

sub get_resources {
   my ($self) =shift;

   return @{$self->{_resources}};
}

sub get_urls {
   return map { $_->get_uri } shift->get_resources;
}


sub count_resources {
   return $#{$_[0]->{_resources}}+1;
}

sub get_member {
   my ($self,$uri) = @_;
   $uri = HTTP::DAV::Utils::make_uri_canonical($uri);

   my $idx = $self->{_resource_indexes}{$uri};
   return $idx ? $self->{_resources}[$idx] : 0;
}

sub add_resource {
   my ($self,$resource) = @_;

   $self->remove_resource($resource);
   $resource->set_parent_resourcelist($self);

   push @{$self->{_resources}}, $resource;

   my $uri = HTTP::DAV::Utils::make_uri_canonical($resource->get_uri);
   $self->{_resource_indexes}{$uri} = $self->count_resources - 1;
}


# Synopsis: $list->remove_resource( resource_obj : HTTP::DAV::Resource );
sub remove_resource {
   my ($self, $resource) = @_;
   my $ret;

   my $uri = HTTP::DAV::Utils::make_uri_canonical($resource->get_uri);

   my $idx = $self->{_resource_indexes}{$uri};
   return 0 unless $idx;

   $resource = splice(@{$self->{_resources}}, $idx, 1);
   $resource->set_parent_resourcelist();
   delete $self->{_resource_indexes}{$uri};

   return $resource;
}

###########################################################################
# %tokens = get_locktokens( "http://localhost/test/dir" )
# Look for all of the lock tokens given a URI:
# Returns:
# %$tokens = (
#    'http://1' => ( token1, token2, token3 ),
#    'http://2' => ( token4, token5, token6 ),
# );
#
sub get_locktokens {
   my ($self,@p) = @_;
   my($uri,$owned) = HTTP::DAV::Utils::rearrange(['URI','OWNED'],@p);
   $owned = 0 unless defined $owned;

   my %tokens;
  
   my @uris;
   if (ref($uri) =~ /ARRAY/ ) {
      @uris = map { HTTP::DAV::Utils::make_uri($_) } @{$uri};
   } else {
      push( @uris, HTTP::DAV::Utils::make_uri($uri) );
   }


   # OK, let's say we hold three locks on 3 resources:
   #    1./a/b/c/ 2./a/b/d/ and 3./f/g
   # If you ask me for /a/b you'll get the locktokens on 1 and 2.
   # If you ask me for /a and /f you'll get 1,2 and 3.
   # If you ask me for /a/b/c/x.txt you'll get 1
   # If you ask me for /a/b/e you'll get nothing
   # So, for each locked resource, if it is a member
   #    of the uri you specify, I'll tell you what the 
   #    locked resource tokens were

   foreach my $resource ( $self->get_resources ) {

      my $resource_uri = $resource->get_uri;
      foreach my $url ( @uris ) {

         # if $resource_uri is in $uri
         # e.g. u=/a  r=/a/b/e
         # e.g. u=/a  r=/a/b/c.txt
         my $r = $resource_uri->canonical();
         my $u = $url->canonical();

         # Add a trailing slash
         $r =~ s{/*$}{/};
         $u =~ s{/*$}{/};

         if ($u =~ m{\Q$r}) {
            my @locks = $resource->get_locks(-owned=>$owned);
            foreach my $lock (@locks) {
               my @lock_tokens = @{$lock->get_locktokens()};
               push(@{$tokens{$resource_uri}}, @lock_tokens);
            }
         }

      } # foreach uri

   } # foreach resource

   return \%tokens;
}

# Utility to convert lock tokens to an if header
# %$tokens = (
#    'http://1' => ( token1, token2, token3 ),
#    'http://2' => ( token4, token5, token6 ),
# )
#   to
# if tagged:
#    <http://1> (<opaquelocktoken:1234>)
# or if not tagged:
#    (<opaquelocktoken:1234>)
#
sub tokens_to_if_header {
   my ($self, $tokens, $tagged) = @_;
   my $if_header;
   foreach my $uri (keys %$tokens ) {
      $if_header .= "<$uri> " if $tagged;
      foreach my $token (@{$$tokens{$uri}}) {
         $if_header .= "(<$token>) ";
      }
      $if_header=~ s/\s+$//g;
   }
   return $if_header;
}

###########################################################################
# Dump the objects contents as a string
sub as_string {
   my ($self,$space,$depth,$verbose) = @_;
   $verbose=1 if (!defined $verbose || $verbose!=0);
   $space||="   ";
   my ($return) = "";
   $return .= "${space}ResourceList Object ($self)\n";
   $space  .= "   ";
   foreach my $resource ( $self->get_resources() ) {
      if ($verbose) {
         $return .= $resource->as_string($space,$depth);
      } else {
         $return .= $space . $resource . " " . $resource->get_uri. "\n";
      }
   }

   $return;
}

sub showlocks {
   my ($self,$space,$depth) = @_;
   $space||="   ";
   my ($return) = "";
   foreach my $resource ( $self->get_resources() ) {
      $return .= $resource->as_string("$space",2);
   }
   $return;
}

1;
