#!/usr/local/perl/bin/perl

use strict;
use warnings;

use Business::Shipping;

#Business::Shipping->log_level( 'debug' );

my $UPS_rate_request = Business::Shipping->rate_request(shipper => 'UPS_Online');
my %UPS_domestic = (
    from_zip   => '98683',
    to_zip     => '98270',
);
if (0) {
$UPS_rate_request->submit(
    user_id    => $ENV{UPS_USER_ID},
    password   => $ENV{UPS_PASSWORD},
    access_key => $ENV{UPS_ACCESS_KEY},    
    cache      => 0,
    service    => 'shop',
    weight     => 12,
    %UPS_domestic
) or die $UPS_rate_request->user_error();
    
show_results($UPS_rate_request->results());
}
    


my $rate_request = Business::Shipping->rate_request(shipper => 'USPS_Online');

my %domestic = (
    from_zip   => '98682',
    to_zip     => '98270',
    size       => 'LARGE',
    #container  => 'Flat Rate Box',
    #machinable => 'FALSE',
);

my %australia = (
    from_zip   => '98682',
    to_zip     => '5041',
    to_country => 'AU',
);

$rate_request->submit(
    user_id    => $ENV{ USPS_USER_ID },
    password   => $ENV{ USPS_PASSWORD },    
    cache      => 0,
    service    => 'all',
    weight     => 0.50,
    %australia
) or die $rate_request->user_error();

show_results($rate_request->results());

use Data::Dumper;
#print Dumper( $rate_request );
#print Dumper( $results );
#print $rate_request->total_charges();

sub show_results {
    my ($results) = @_;
    
    foreach my $shipper ( @$results ) {
        print "Shipper: $shipper->{name}\n\n";
        foreach my $rate ( @{ $shipper->{ rates } } ) {
            my $name = $rate->{name};
            #next if $name =~ /Envelope/;
            #next if $name =~ /Flat[- ]Rate/;
            #next if $name =~ /Non-Document/;
            #next if $name eq 'Bound Printed Matter';
            #next if $name =~ /PO to PO/;
            #next if $name =~ /Media Mail/;
            #next if $name =~ /Library Mail/;
            #next if $name =~ /Parcel Post/;
            #next if $name =~ /Global Express Guaranteed/;
            print "  Service:  $rate->{name}\n";
            print "  Charges:  $rate->{charges_formatted}\n";
            print "  Delivery: $rate->{deliv_date_formatted}\n" 
                if $rate->{ deliv_date_formatted };
            print "\n";
        }
    }
    
    return;
}
