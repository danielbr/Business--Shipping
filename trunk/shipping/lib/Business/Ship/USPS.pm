# Copyright (c) 2003 Kavod Technologies, Dan Browning, 
# and Kevin Old.
# All rights reserved. This program is free software; you can 
# redistribute it and/or modify it under the same terms as Perl 
# itself.

package Business::Ship::USPS;
use strict;
use warnings;

=head1 NAME

Business::Ship::USPS - A USPS module 

Documentation forthcoming.

=cut

use vars qw(@ISA $VERSION);
$VERSION = sprintf("%d.%03d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);
use Business::Ship;
use LWP::UserAgent ();
use HTTP::Request ();
use HTTP::Response ();
use XML::Simple ();
use Carp ();

use Data::Dumper;

@ISA = qw( Business::Ship );

sub set_defaults
{
	my $self = shift;
	
    $self->server( 'www.ups.com' );
    $self->protocol( 'https://' );
    $self->path( '/blah/blah.dll' );
	
	return;
}

# _gen_request_xml()
# Generate the XML document.
sub _gen_request_xml
{
	my ( $self ) = shift;

	my $request_tree = {
		'RateRequest' => [{
			'USERID' => $self->user_id(),
			'PASSWORD' => $self->password(),
			'Package' => [{
				'ID' => '0',
				'Service' => [ $self->service() ],
				'ZipOrigination' => [ '98682' ],
				'ZipDestination' => [ '98270' ],
				'Pounds' => [ '5' ],
				'Ounces' => [ '3' ],
				'Container' => [ 'NONE' ],
				'Size' => [ 'Regular' ],
				'Machineable' => [ 'False' ],
			}]
		}]
	};

	my $request_xml = '<?xml version="1.0"?>' . "\n"
		. $self->{xs}->XMLout( $request_tree );

	$self->debug( "request xml = \n" . $request_xml );
	
	return ( $request_xml );
}

sub build_subs
{
	my $self = shift;
	
	my @usps_required_vals = qw/
		usps_custom1
		usps_custom2
	/;
	
	my @usps_optional_vals = qw/
		usps_custom3
		usps_custom4
	/;
	
	$self->SUPER::build_subs( @_, @usps_required_vals, @usps_optional_vals );
}

=head1 SEE ALSO

	http://www.uspswebtools.com/

=head1 AUTHOR

	Initially developed by Kevin Old, later rewritten by Dan Browning.
	
	Dan Browning <db@kavod.com>
	Kavod Technologies
	http://www.kavod.com
	
	Kevin Old <kold@carolina.rr.com>

=head1 COPYRIGHT

Copyright (c) 2003 Kavod Technologies, Dan Browning,
and Kevin Old. 
All rights reserved. This program is free software; you can 
redistribute it and/or modify it under the same terms as Perl 
itself. 

=cut

1;
