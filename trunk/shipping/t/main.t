# testing subs

use Business::Ship::USPS;
our $shipment = new Business::Ship( 'shipper' => 'USPS' );
	
sub test_domestic
{
	my ( %args ) = @_;
	
	$shipment->set( %args );
	
	my $out;
	$out .= $shipment->weight() . " lbs from " . $shipment->from_zip() . " to " . $shipment->to_zip()
		. " = \$";
	$shipment->submit or die 'error on submit: ' . $shipment->error();
	$out .= $shipment->get_charges( $shipment->service() ) . "\n";
	#$out .= $shipment->total_charges() . "\n";
	return $out;
}

1;
