package Business::Shipping::Template::RateRequest;

=head1 NAME

Business::Shipping::Template::RateRequest - Template for new rate requests

See Shipping.pm POD for usage information.

=head1 METHODS

=cut

$VERSION = do { my $r = q$Rev$; $r =~ /\d+/; $&; };

use strict;
use warnings;
use base ( 'Business::Shipping::RateRequest' );
use Business::Shipping::Logging;
use Business::Shipping::Config;

use Class::MethodMaker 2.0
    [
      new => [ qw/ -hash new / ],
    ];
