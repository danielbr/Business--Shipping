#!/usr/bin/perl

use Data::Dumper;

print "Test name: What fields are required?\n";
print "====================================\n\n";

show( 'Business::Shipping::UPS_Offline::RateRequest' );
#show( 'Business::Shipping::UPS_Online::RateRequest' );
#show( 'Business::Shipping::USPS_Online::RateRequest' );


#my $ups = Business::Shipping->rate_request( shipper => 'UPS_Offline' );
#show_ary( $ups->Required );
#show_ary( $ups::Required );

sub show_ary
{
    return print "\t" . join( ', ', @_ ) . "\n";
}

sub show
{
    my $class = shift;
    my $self = eval "require $class; $class->new()";
    die $@ if $@;
    %Business::Shipping::Debug::event_handlers = (
        debug  => 'STDERR',
        #debug3 => 'STDERR',
        #trace  => 'STDERR',
        error  => 'STDERR',
    );
    my $name = scalar( $self );
    ( $name ) = split ( '=', $name ); 
    print "$name\n";
    #print "\tRequired (2) = " . join( ', ', Business::Shipping::ClassAttribs::get_grouped_attrs( 'Required', object => $self ) ) . "\n";
    print "\tRequired (2) = " . join( ', ', $self->get_grouped_attrs( 'Required', object => $self ) ) . "\n";
    #print "\tOptional = " . join( ', ', $self->optional() ) . "\n";
    #return;
    return print "\t" . join( ', ', @_ ) . "\n\n\n";
}
