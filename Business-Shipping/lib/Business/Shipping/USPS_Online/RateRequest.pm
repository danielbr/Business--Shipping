package Business::Shipping::USPS_Online::RateRequest;

=head1 NAME

Business::Shipping::USPS_Online::RateRequest 

=head1 VERSION

2.2.0

=head1 SERVICE TYPES

=head2 Domestic

    All
    EXPRESS
    Priority
    Parcel
    Library
    BPM
    Media

=head2 International
 
Global Express Guaranteed
Global Express Guaranteed Non-Document Rectangular
Global Express Guaranteed Non-Document Non-Rectangular
Express Mail International (EMS)
Express Mail International (EMS) Flat Rate Envelope
Priority Mail International
Priority Mail International Flat Rate Box
Priority Mail International Flat Rate Envelope
First Class Mail International

=head1 METHODS

=cut

use Moose;
use Business::Shipping::Logging;
use Business::Shipping::USPS_Online::Shipment;
use Business::Shipping::USPS_Online::Package;
use XML::Simple 2.05;
use XML::DOM;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use version; our $VERSION = qv('2.2.0');

=head2 domestic

=head2 to_zip

Note that some methods are handled by the parent class:

to_zip, from_zip, to_city, from_city, to_country, from_country.

=cut

extends 'Business::Shipping::RateRequest::Online';

has 'domestic' => (is => 'rw', default => 1);

has 'prod_url' => (
    is      => 'rw',
    default => 'http://production.shippingapis.com/ShippingAPI.dll'
);

has 'test_url' => (
    is      => 'rw',
    default => 'http://testing.shippingapis.com/ShippingAPItest.dll',
);

has 'shipment' => (
    is      => 'rw',
    isa     => 'Business::Shipping::USPS_Online::Shipment',
    default => sub { Business::Shipping::USPS_Online::Shipment->new() },
    handles => [
        'ounces', 'pounds',     'weight',    'container',
        'size',   'machinable', 'mail_type', 'shipper',
        'width',  'length',     'height',    'girth',
        'service',
    ]
);

=head2 Required()

International USPS does not require the service or from_zip parameters, but 
domestic does. 

We use a hand-written "Required()" method for this class, because we require one
of the following: pounds, ounces, or weight.  It doesn't matter which one it is,
but if none of them are defined, then we pick 'weight' to Require.

=cut

sub Required {
    my ($self) = @_;

    my @required;

    if ($self->domestic) {
        @required = qw/ service from_zip /;
    }
    else {
        @required = ();
    }

    my $need_weight = 1;
    for (qw/ weight pounds ounces /) {
        if ($self->$_) {
            $need_weight = 0;
        }
    }
    push @required, 'weight' if $need_weight;

    return ($self->SUPER::Required, @required);
}

sub Optional {
    return ($_[0]->SUPER::Optional,
        qw/ container size machinable mail_type pounds ounces /);
}

# Note that we use 'weight' as the unique value (specified in Parent),
# which should convert automatically from pounds/ounces during uniqueness
# calculations.
sub Unique {
    return ($_[0]->SUPER::Unique, qw/ container size machinable mail_type /);
}

=head2 _gen_request_xml

Generate the XML document.

=cut

sub _gen_request_xml {
    trace '()';
    my $self = shift;

# Note: The XML::Simple hash-tree-based generation method wont work with USPS,
# because they enforce the order of their parameters (unlike UPS).
    my $rateReqDoc = XML::DOM::Document->new();
    my $rateReqEl  = $rateReqDoc->createElement(
        $self->domestic() ? 'RateV3Request' : 'IntlRateRequest');

    # Note that these are required even for test mode transactions.
    $rateReqEl->setAttribute('USERID',   $self->user_id());
    $rateReqEl->setAttribute('PASSWORD', $self->password());
    $rateReqDoc->appendChild($rateReqEl);

    my $package_count = 0;
    logdie "No packages defined internally."
        unless ref $self->shipment->packages();
    foreach my $package (@{ $self->shipment->packages() }) {
        my $id;
        $id = $package->id();
        $id = $package_count++ unless $id;
        my $packageEl = $rateReqDoc->createElement('Package');
        $packageEl->setAttribute('ID', $id);
        $rateReqEl->appendChild($packageEl);

        if ($self->domestic()) {
            my $serviceEl = $rateReqDoc->createElement('Service');
            my $serviceText
                = $rateReqDoc->createTextNode($self->shipment->service());
            $serviceEl->appendChild($serviceText);
            $packageEl->appendChild($serviceEl);

            my $zipOrigEl = $rateReqDoc->createElement('ZipOrigination');
            my $zipOrigText
                = $rateReqDoc->createTextNode($self->shipment->from_zip());
            $zipOrigEl->appendChild($zipOrigText);
            $packageEl->appendChild($zipOrigEl);

            my $zipDestEl = $rateReqDoc->createElement('ZipDestination');
            my $zipDestText
                = $rateReqDoc->createTextNode($self->shipment->to_zip());
            $zipDestEl->appendChild($zipDestText);
            $packageEl->appendChild($zipDestEl);
        }

        my $poundsEl   = $rateReqDoc->createElement('Pounds');
        my $poundsText = $rateReqDoc->createTextNode($package->pounds());
        $poundsEl->appendChild($poundsText);
        $packageEl->appendChild($poundsEl);

        my $ouncesEl   = $rateReqDoc->createElement('Ounces');
        my $ouncesText = $rateReqDoc->createTextNode($package->ounces());
        $ouncesEl->appendChild($ouncesText);
        $packageEl->appendChild($ouncesEl);

        if ($self->domestic()) {
            if (defined($package->container())) {
                my $containerEl = $rateReqDoc->createElement('Container');
                my $containerText
                    = $rateReqDoc->createTextNode($package->container());
                $containerEl->appendChild($containerText);
                $packageEl->appendChild($containerEl);
            }

            my $oversizeEl   = $rateReqDoc->createElement('Size');
            my $oversizeText = $rateReqDoc->createTextNode($package->size());
            $oversizeEl->appendChild($oversizeText);
            $packageEl->appendChild($oversizeEl);

            my $widthEl   = $rateReqDoc->createElement('Width');
            my $widthText = $rateReqDoc->createTextNode($package->width());
            $widthEl->appendChild($widthText);
            $packageEl->appendChild($widthEl);

            my $lengthEl   = $rateReqDoc->createElement('Length');
            my $lengthText = $rateReqDoc->createTextNode($package->length());
            $lengthEl->appendChild($lengthText);
            $packageEl->appendChild($lengthEl);

            my $heightEl   = $rateReqDoc->createElement('Height');
            my $heightText = $rateReqDoc->createTextNode($package->height());
            $heightEl->appendChild($heightText);
            $packageEl->appendChild($heightEl);

            my $girthEl   = $rateReqDoc->createElement('Girth');
            my $girthText = $rateReqDoc->createTextNode($package->girth());
            $girthEl->appendChild($girthText);
            $packageEl->appendChild($girthEl);

            if ($self->service() =~ /all/i
                and not defined $package->machinable())
            {
                $package->machinable('False');
            }

            if (defined($package->machinable())) {
                my $machineEl = $rateReqDoc->createElement('Machinable');
                my $machineText
                    = $rateReqDoc->createTextNode($package->machinable());
                $machineEl->appendChild($machineText);
                $packageEl->appendChild($machineEl);
            }
        }
        else {
            my $mailTypeEl = $rateReqDoc->createElement('MailType');
            my $mailTypeText
                = $rateReqDoc->createTextNode($package->mail_type());
            $mailTypeEl->appendChild($mailTypeText);
            $packageEl->appendChild($mailTypeEl);

            my $countryEl = $rateReqDoc->createElement('Country');
            my $countryText
                = $rateReqDoc->createTextNode($self->shipment->to_country());
            $countryEl->appendChild($countryText);
            $packageEl->appendChild($countryEl);
        }

    }    #/foreach package
    my $request_xml = $rateReqDoc->toString();

    # We only do this to provide a pretty, formatted XML doc for the debug.
    my $request_xml_tree
        = XML::Simple::XMLin($request_xml, KeepRoot => 1, ForceArray => 1);

    # Large debug
    debug3(XML::Simple::XMLout($request_xml_tree, KeepRoot => 1));

    return ($request_xml);
}

=head2 _gen_request

=cut

sub _gen_request {
    my ($self) = shift;
    trace('called');

    my $request = $self->SUPER::_gen_request();

    # This is how USPS slightly varies from Business::Shipping
    my $new_content
        = 'API='
        . ($self->domestic() ? 'RateV3' : 'IntlRate') . '&XML='
        . $request->content();
    $request->content($new_content);
    $request->header('content-length' => CORE::length($request->content()));

    # Large debug
    debug3('HTTP Request: ' . $request->as_string());

    return ($request);
}

=head2 _massage_values

=cut

sub _massage_values {
    my $self = shift;

    $self->_domestic_or_intl();

    return;
}

=head2 _handle_response

=head2 error_details()

See L<Business::Shipping::RateRequest> for full documentation.
Adds the following keys to each error:

 package_id	: The unique package id in which the error occurred
 error_source	: The component that generated the error

=cut

sub _handle_response {
    trace '()';
    my $self = shift;

    ### Keep the root element, because USPS might
    ### return an error and 'Error' will be the root element
    my $response_tree = XML::Simple::XMLin(
        $self->response()->content(),
        ForceArray => 0,
        KeepRoot   => 1
    );
    ### Discard the root element if it is RateV3Response
    $response_tree = $response_tree->{RateV2Response}
        if (exists($response_tree->{RateV2Response}));
    $response_tree = $response_tree->{RateV3Response}
        if (exists($response_tree->{RateV3Response}));

    ### Discard the root element if it is IntlRateResponse
    $response_tree = $response_tree->{IntlRateResponse}
        if (exists($response_tree->{IntlRateResponse}));

    #use Data::Dumper; debug3(Dumper($response_tree));

    # Handle errors
    ### Get all errors
    my $errors = [];
    push(@$errors, $response_tree->{Error})
        if (exists($response_tree->{Error}));
    if (ref $response_tree->{Package} eq 'HASH') {
        if (exists($response_tree->{Package}{Error})) {
            push(@$errors, $response_tree->{Package}{Error});
            $errors->[$#{$errors}]{PackageID} = $response_tree->{Package}{ID};
        }
    }
    elsif (ref $response_tree->{Package} eq 'ARRAY') {
        foreach my $pkg (@{ $response_tree->{Package} }) {
            if (exists($pkg->{Error})) {
                push(@$errors, $pkg->{Error});
                $errors->[$#{$errors}]{PackageID} = $pkg->{ID};
            }
        }
    }
    if (@$errors > 0) {
        ### Loop through the errors, gathering the details and
        ### create a simple error message string
        my (@errorDetails, $errorMsg);
        foreach my $errorHash (@$errors) {
            ### Get some of the error details
            my $code    = $errorHash->{Number};
            my $error   = $errorHash->{Description};
            my $source  = $errorHash->{Source};
            my $pkg_src = $errorHash->{PackageID};

            push(
                @errorDetails,
                {   error_code   => $code,
                    error_msg    => $error,
                    package_id   => $pkg_src,
                    error_source => $source
                }
            );
            if (!defined($errorMsg) && $error) {
                $errorMsg = "$source: $error ($code)";
            }
        }    # foreach error

        $self->user_error($errorMsg);
        $self->error_details(@errorDetails);

        return $self->is_success(0);
    }    # if errors

    # This is a "large" debug.
    debug3('response = ' . $self->response->content);

    #

    my $charges;
    my @services_results = ();

    # TODO: Get the pricing routines to work for multi-packages (not just
    # the default_package()
    #
    # Domestic *does* tell you the price of all services if you ask for 
    # service "ALL". If you ask for a specific service, it still might send 
    # more then one price. For example, if you ask for "Flat Rate Box" 
    # service, it will send you two prices, one for 
    # 'Priority Mail Flat Rate Box (11.25" x 8.75" x 6")' and the other for
    # 'Priority Mail Flat Rate Box (14" x 12" x 3.5")'
    if ($self->domestic()) {
        if (ref($response_tree->{Package}) eq 'ARRAY') {
            $self->user_error("Sorry, multiple packages not supported yet.");
            return $self->is_success(0);
        }
        
        $charges = $response_tree->{Package}->{Postage};

        #debug('response_tree = ' . Dumper($response_tree));
        if (defined($charges)) {
            $charges = [$charges] if (ref $charges ne 'ARRAY');
            foreach my $chg (@$charges) {
                next if (ref $chg ne 'HASH');
                my $service_hash = {
                    code       => undef,
                    nick       => service_to_nick($chg->{MailService}),
                    name       => $chg->{MailService},
                    deliv_days => undef,
                    deliv_date => undef,
                    charges    => $chg->{Rate},
                    charges_formatted =>
                        Business::Shipping::Util::currency({}, $chg->{Rate}),
                    deliv_date_formatted => undef,
                };
                push(@services_results, $service_hash);
            }
        }
    }

    # International with service 'all'
    elsif (defined($self->service()) && lc($self->service()) eq 'all') {

   # International *does* tell you the price of all services for each package
   # If caller asked for All services, then lets give them All services.  Will
   # pass back service name as-is.  Let caller try to distinguish it.

# Set charges to returned services, since charges needs to be set to something
        $charges = $response_tree->{Package}->{Service};

        if (defined($charges)) {
            $charges = [$charges] if (ref $charges ne 'ARRAY');
            foreach my $service (@$charges) {
                my $service_hash = {
                    code       => undef,
                    nick       => service_to_nick($service->{SvcDescription}),
                    name       => $service->{SvcDescription},
                    deliv_days => undef,
                    deliv_date => undef,
                    charges    => $service->{Postage},
                    charges_formatted => Business::Shipping::Util::currency(
                        {}, $service->{Postage},
                    ),
                    deliv_date_formatted => undef,
                };
                push(@services_results, $service_hash);
            }    # foreach service
        }    # if services defined
    }

    # International with one specific service.
    else {

    #
    # International *does* tell you the price of all services for each package
    #
        my $service_description;
        foreach my $service (@{ $response_tree->{Package}->{Service} }) {
            debug("Trying to find a matching service by service description ("
                    . $service->{SvcDescription}
                    . ")...");
            debug("Charges for $service->{SvcDescription} service = "
                    . $service->{Postage});

# BUG: you can't check if the service descriptions match, because many countries use
# different descriptions for the same service.  So we try to match by description
# *or* by mail_type.  (There are probably many services with the same mail_type, how
# do we handle those?  We could just get them based on index number (maybe all "zero"
# is the cheapest ground service, or...?

#
# TODO: Try searching all of them for a service that matches.  Perhaps we should
# have a "matching" variable for each service.  Like, "Air" for "Airmail Parcel Post",
# so that whichever service has "Air" in the description will be used first.
#

# USPS introduced new service types on May 14, 2007. Convert old service types to the new.

# A service translation would have to take 'letter' and 'flat rate' into account, it's probably
# better to leave the user to change their service.
#my %services_old_to_new = (
#    'Global Express Mail'       => 'Express Mail International',
#    'EMS'                       => 'Express Mail International',
#    'Global Priority Mail'
#    'Airmail( Parcel[- ]Post)?' => 'Priority Mail International',
#    'Economy( Parcel[- ]Post)?' => 'First Class Mail International',
#);
#
#while (my($old, $new) = each %services_old_to_new) {
#    if ($service =~ /$old/i) {
#        #print "Changing old service ($service) into new ($new)\n";
#        $service = $new;
#    }
#}

            if (    $self->service()
                and $self->service() =~ $service->{SvcDescription})
            {
                $charges             = $service->{'Postage'};
                $service_description = $service->{SvcDescription};
            }
        }
        if (!$charges) {

            # Couldn't find it by service description, try by mail_type...
            foreach my $service (@{ $response_tree->{Package}->{Service} }) {
                debug("Trying to find a matching service by mail_type...");
                if (    $self->mail_type()
                    and $self->mail_type() =~ $service->{MailType})
                {
                    $charges = $service->{Postage};
                }
            }

            # Still can't find the right service...
            if (!$charges) {
                my $error_msg
                    = "The requested service ("
                    . ($self->service() || 'none entered by user')
                    . ") did not match any services that were available for that country.";

                print STDERR $error_msg;
                $self->user_error($error_msg);
            }
        }

        if (defined($charges)) {
            my $service_hash = {
                code       => undef,
                nick       => service_to_nick($service_description),
                name       => undef,
                deliv_days => undef,
                deliv_date => undef,
                charges    => $charges,
                charges_formatted =>
                    Business::Shipping::Util::currency({}, $charges),
                deliv_date_formatted => undef,
            };
            push(@services_results, $service_hash);
        }
    }

    if (!$charges) {
        $self->user_error('charges are 0, error out');
        return $self->is_success(0);
    }
    debug('Setting charges to ' . $charges);

    my $results = [
        {   name => $self->shipper() || 'USPS_Online',
            rates => \@services_results,
        }
    ];

    $self->results($results);

    trace 'returning success';
    return $self->is_success(1);
}

sub service_to_nick {
    my ($service_description) = @_;
    return $service_description unless $service_description;
    my %services_codes = (
        'Express Mail'                     => 'EXPRESS',
        'Priority Mail'                    => 'PRIORITY',
        'Express Mail International (EMS)' => 'EXPRESS',
        'Priority Mail International'      => 'PRIORITY',
    );

    return $services_codes{$service_description} || $service_description;
}

=head2 _domestic_or_intl

Decide if we are domestic or international for this run.

=cut

sub _domestic_or_intl {
    my $self = shift;
    trace '()';

    #debug('to_country = ' . $self->shipment->to_country());
    if (    $self->shipment->to_country()
        and $self->shipment->to_country() !~ /(US)|(United States)/)
    {
        $self->domestic(0);
    }
    else {
        $self->domestic(1);
    }
    debug($self->domestic() ? 'Domestic' : 'International');
    return;
}

=head2 to_residential()

For compatibility with UPS modules.  Always returns 0.

=cut

sub to_residential { return 0; }

1;

__END__

=head1 AUTHOR

Dan Browning E<lt>F<db@kavod.com>E<gt>, Kavod Technologies, L<http://www.kavod.com>.

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself. See LICENSE for more info.

=cut
