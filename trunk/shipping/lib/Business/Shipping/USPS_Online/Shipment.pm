=head1 NAME

Business::Shipping::USPS_Online::Shipment

=head1 VERSION

$Rev$

=head1 DESCRIPTION

See Business::Shipping POD for usage information.

=head1 METHODS

=head2 pounds

=head2 ounces

=head2 weight

=head2 container

=head2 size

=head2 machinable

=head2 mail_type

=cut

package Business::Shipping::USPS_Online::Shipment;

$VERSION = do { my $r = q$Rev$; $r =~ /\d+/; $&; };

use strict;
use warnings;
use base ( 'Business::Shipping::Shipment' );
use Business::Shipping::Logging;
use Business::Shipping::Config;
use Business::Shipping::Util;
use Business::Shipping::USPS_Online::Package;
use Class::MethodMaker 2.0 
    [ 
      new   =>  [ { -hash    => 1, -init => '_this_init' }, 'new' ],
      array =>  [ { -type    => 'Business::Shipping::USPS_Online::Package',
                    -default_ctor => 'new' }, 'packages' ],
      scalar => [ { -static  => 1, 
                    -default => 'packages=>Business::Shipping::USPS_Online::Package' 
                  }, 
                  'Has_a' 
                ],
];

sub _this_init
{
    $_[ 0 ]->from_country( 'US'   );
    return;
}

foreach my $attribute ( 'pounds', 'ounces', 'weight', 'container', 'size', 'machinable', 'mail_type' ) {
    eval "sub $attribute { shift->package0->$attribute( \@_ ); }";
}


=head2 Required()

International USPS does not require the service or from_zip parameters, but 
domestic does. 

=cut

sub Required
{
    return 'service, from_zip' if $_[ 0 ]->domestic;
    return '';
}


=head2 from_country

Always returns 'US'.

=cut

sub from_country { return 'US'; }

=head2 to_country( $to_country ) 

Uses the name translaters of Shipping::Shipment::to_country(), then applies its
own translations.  The former may not be necessary, but the latter is.

=cut

sub to_country
{
    #trace '( ' . uneval( \@_ ) . ' )';
    my ( $self, $to_country ) = @_;    
    
    if ( defined $to_country ) {
        #
        # Apply any Shipping::Shipment conversions, then apply our own.
        #
        $to_country = $self->SUPER::to_country( $to_country );
        my $countries = config_to_hash(
            cfg()->{ usps_information }->{ usps_country_name_translations }
        );
        $to_country = $countries->{ $to_country } || $to_country; 
        
        debug3( "setting to_country to \'$to_country\'" );
        $self->{ to_country } = $to_country;
    } 
    debug3( "SUPER::to_country now is " . ( $self->SUPER::to_country() || '' ) );
    
    return $self->{ to_country };
}

1;

__END__

=head1 AUTHOR

Dan Browning E<lt>F<db@kavod.com>E<gt>, Kavod Technologies, L<http://www.kavod.com>.

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself. See LICENSE for more info.

=cut