#!/usr/bin/perl

use Business::Shipping;
use Business::Shipping::Shipment;
use Business::Shipping::Shipment::UPS;
use Business::Shipping::Shipment::USPS;
use Business::Shipping::Package;
use Business::Shipping::Package::UPS;
use Business::Shipping::Package::USPS;
use Business::Shipping::RateRequest;
use Business::Shipping::RateRequest::Online;
use Business::Shipping::RateRequest::Online::UPS;
use Business::Shipping::RateRequest::Online::USPS;


#show( 'Business::Shipping' );

#show( 'Business::Shipping::RateRequest' );

#show( 'Business::Shipping::RateRequest::Online' );


#show( 'Business::Shipping::RateRequest::Online::UPS' );

#use Business::Shipping::RateRequest::Online::UPS;
#my $ups_online_rate_request = Business::Shipping::RateRequest::Online::UPS->new();
#print $ups_online_rate_request->required();

my $ups_online_rate_request = Business::Shipping->rate_request(
	shipper => 'USPS',
	service => 'Priority',
	from_country => 'US',
	to_country => 'US',
	from_zip => '23943',
	to_zip => '99999',
	weight => 23.3,	
);

use Data::Dumper;
#print Dumper( $ups_online_rate_request->get_unique_hash() );

print Dumper( $ups_online_rate_request->gen_unique_key() );


=pod
use Business::Shipping::RateRequest;
my $rate_request = Business::Shipping::RateRequest->new();
show_ary( $rate_request->required2() );

use Business::Shipping::RateRequest::Online;
my $online_rate_request = Business::Shipping::RateRequest::Online->new();
show_ary( $online_rate_request->required2() );

use Business::Shipping::RateRequest::Online::UPS;
my $ups_online_rate_request = Business::Shipping::RateRequest::Online::UPS->new();
show_ary( $ups_online_rate_request->required2() );
=cut

#use Business::Shipping::RateRequest::Online;
#my $online_rate_request = Business::Shipping::RateRequest::Online->new();
#show_ary( $online_rate_request->find_required() );

#use Business::Shipping::RateRequest::Online::UPS;
#my $ups_online_rate_request = Business::Shipping::RateRequest::Online::UPS->new();
#print join( ', ',  $ups_online_rate_request->required() ) . "\n";
#
#print "showing array: " . show_ary( $ups_online_rate_request->find_required() ) . "\n";



sub show_ary
{
	return print "\t" . join( ', ', @_ ) . "\n";
}

sub show
{
	my $class = shift;
	my $self = eval "require $class; $class->new()";
	die $@ if $@;
	my $name = scalar( $self );
	( $name ) = split ( '=', $name ); 
	print "$name\n";
	print "\tRequired = " . join( ', ', $self->required() ) . "\n";
	#print "\tOptional = " . join( ', ', $self->optional() ) . "\n";
	#return;
	return print "\t" . join( ', ', @_ ) . "\n\n\n";
}
