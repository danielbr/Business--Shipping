# Copyright (c) 2003 Kavod Technologies, and Dan Browning.  
# All rights reserved. This program is free software; you can 
# redistribute it and/or modify it under the same terms as Perl 
# itself.
# $Id $
package Business::Ship;
use strict;
use warnings;

=pod

use Business::Ship;

my $shipment = new Business::Ship( 'UPS');
$shipment->set(
	user_id		=> '',
	password	=> '',
	weight		=> '',
);
$shipment->submit_rate_query();

if( $shipment->rate_success() ) {
	print $shipment->total_charges();
}
else {
	print $shipment->error();
}

=cut

use Carp;

my %vals = (
	user_id				=> undef,
	password			=> undef,
	is_success			=> undef,
	tx_type				=> undef,
	error				=> undef,
	server_response		=> undef,
);

my %rate_vals = (
	origination_zip		=> undef,
	destination_zip		=> undef,
	weight				=> undef,
);


sub new {
	my( $class, $shipper, %args) = @_;
	
	Carp::croak("unspecified shipper") unless $shipper;
	
	my $subclass = "${class}::$shipper";
	
	if ( !defined( &$subclass ) ) {
		eval "use $subclass";
		Carp::croak("unknown shipper $shipper ($@)") if $@;
	}
	
	my $self = bless {shipper => $shipper}, $subclass;
	$self->build_subs(keys %vals);
	
	if($self->can("set_defaults")) {
		$self->set_defaults();
	}
	
	foreach(keys %args) {
		my $key = lc( $_ );
		my $value = $args{$_};
		$key =~ s/^\-//;
		$self->build_subs( $key );
		$self->$key( $value );
	}
	
	return $self;
}

sub set {
    my( $self, %args ) = @_;

    if( %args ) {
        $self->tx_type( $args{'type'} ) if $args{'type'};
        %{$self->{'_vals'}} = %args;
    }
    return %{$self->{'_vals'}};
}

sub required_fields {
    my( $self, @fields ) = @_;

    my %vals = $self->set();
    foreach( @required_fields ) {
        Carp::croak("missing required field $_") unless exists $vals{$_};
    }
}

1;
