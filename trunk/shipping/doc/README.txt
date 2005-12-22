NAME
    Business::Shipping - Rates and tracking for UPS and USPS

VERSION
    Version 2.03

SYNOPSIS
  Rate request example
     use Business::Shipping;
 
     my $rate_request = Business::Shipping->rate_request(
         shipper   => 'UPS_Offline',
         service   => 'Ground Residential',
         from_zip  => '98683',
         to_zip    => '98270',
         weight    =>  5.00,
     );    
 
     $rate_request->execute() or die $rate_request->user_error();
 
     print $rate_request->rate();

FEATURES
    Business::Shipping currently supports three shippers:

  UPS_Offline: United Parcel Service
    * Shipment rate estimation using offline tables. New tables are released
    whenever UPS updates them, and a script is available for automatically
    updating the fuel surcharge every month.

  UPS_Online: United Parcel Service using UPS OnLine Tools (disabled)
    * Disabled as of version 1.90, see doc/UPS_Online_disabled.txt.
    * Shipment rate estimation
    * Shipment tracking.
    * Rate Shopping.
        Gets rates for all the services in one request:

         my $rr_shop = Business::Shipping->rate_request( 
             service      => 'shop',    
             shipper      => 'UPS_Online',
             from_zip     => '98682',
             to_zip       => '98270',
             weight       => 5.00,
             user_id      => '',
             password     => '',
             access_key   => '',
         );
 
         $rr_shop->execute() or die $rr_shop->user_error();
 
         foreach my $shipper ( @$results ) {
             print "Shipper: $shipper->{name}\n\n";
             foreach my $rate ( @{ $shipper->{ rates } } ) {
                 print "  Service:  $rate->{name}\n";
                 print "  Charges:  $rate->{charges_formatted}\n";
                 print "  Delivery: $rate->{deliv_date_formatted}\n" 
                     if $rate->{ deliv_date_formatted };
                 print "\n";
             }
         }

    * C.O.D. (Cash On Delivery)
        Add these options to your rate request for C.O.D.:

        cod: enable C.O.D.

        cod_funds_code: The code that indicates the type of funds that will
        be used for the COD payment. Required if CODCode is 1, 2, or 3.
        Valid Values: 0 = All Funds Allowed. 8 = cashier's check or money
        order, no cash allowed.

        cod_value: The COD value for the package. Required if COD option is
        present. Valid values: 0.01 - 50000.00

        cod_code: The code associated with the type of COD. Values: 1 =
        Regular COD, 2 = Express COD, 3 = Tagless COD

        For example:

                cod            => 1,
                cod_value      => 400.00,
                cod_funds_code => 0,

  USPS_Online: United States Postal Service
    * Shipment rate estimation using USPS Online WebTools.
    * Shipment tracking

INSTALLATION
     perl -MCPAN -e 'install Bundle::Business::Shipping'

    See doc/INSTALL.

REQUIRED MODULES
    The following modules are required for offline UPS rate estimation. See
    doc/INSTALL.

     Business::Shipping::DataFiles (any)
     Class::MethodMaker::Engine (any)
     Config::IniFiles (any)
     Log::Log4perl (any)

OPTIONAL MODULES
    The following modules are used by online rate estimation and tracking.
    See doc/INSTALL.

     Cache::FileCache (any)
     Clone (any)
     Crypt::SSLeay (any)
     LWP::UserAgent (any)
     XML::DOM (any)
     XML::Simple (2.05)
 
GETTING STARTED
    Be careful to read, understand, and comply with the terms of use for the
    provider that you will use.

  UPS_Offline: For United Parcel Service (UPS) offline rate requests
    No signup required. "Business::Shipping::DataFiles" has all of rate
    tables, which are usually updated only once per year.

    We recommend that you run the following script to update your fuel
    surcharge every first monday of the month.

     bin/Business-Shipping-UPS_Offline-update-fuel-surcharge.pl

  UPS_Online: For United Parcel Service (UPS) Online XML: Free signup
    * Read the legal terms and conditions:
    <http://www.ups.com/content/us/en/resources/service/terms/index.html>
    * <https://www.ups.com/servlet/registration>
    * After receiving a User Id and Password from UPS, login, then select
    "Get Access Key", then "Get XML Access Key".
    * Read more about UPS Online Tools at <http://www.ec.ups.com>

  USPS_Online: For United States Postal Service (USPS): Free signup
    * <http://www.uspswebtools.com/registration/>
    * (More info at <http://www.uspswebtools.com>)
    * The online signup will result in a testing-only account (only a small
    sample of queries will work).
    * To activate the "production" use of your USPS account, you must follow
    the USPS documentation. As of Sept 16 2004, that means contacting the
    USPS Internet Customer Care Center by e-mail ("icustomercare@usps.com")
    or phone: 1-800-344-7779.

ERROR/DEBUG HANDLING
    Log4perl is used for logging error, debug, etc. messages. For simple
    manipulation of the current log level, use the
    Business::Shipping->log_level( $log_level ) class method (below). For
    more advanced logging/debugging options, see config/log4perl.conf.

Preloading Modules
    To preload all modules, call Business::Shipping with this syntax:

     use Business::Shipping { preload => 'All' };

    To preload the modules for just one shipper:

     use Business::Shipping { preload => 'USPS_Online' };
 
    Without preloading, some modules will be loaded at runtime. Normally,
    runtime loading is the best mode of operation. However, there are some
    circumstances when preloading is advantagous. For example:

    * For mod_perl, to load the modules only once at startup instead of at
    startup and then additional modules later on. (Thanks to Chris Ochs
    <chris@paymentonline.com> for contributing to this information).
    * For compatibilty with some security modules (e.g. Safe).
    * To move the delay that would normally occur with the first request
    into startup time. That way, it takes longer to start up, but the first
    user will not experience any delay.

METHODS
  $obj->init()
    Generic attribute setter.

  $obj->user_error()
    Log and store errors that should be visibile to the user.

  $obj->validate()
    Confirms that the object is valid. Checks that required attributes are
    set.

  $self->get_grouped_attrs( $attribute_name )
  $obj->rate_request()
    This method is used to request shipping rate information from online
    providers or offline tables. A hash is accepted as input. The acceptable
    values are determined by the shipper class, but the following are common
    to all:

    * shipper
        The name of the shipper to use. Must correspond to a module by the
        name of: "Business::Shipping::SHIPPER". For example, "UPS_Online".

    * service
        A valid service name for the provider. See the corresponding module
        documentation for a list of services compatible with the shipper.

    * from_zip
        The origin zipcode.

    * from_state
        The origin state in two-letter code format or full-name format.
        Required for UPS_Offline.

    * to_zip
        The destination zipcode.

    * to_country
        The destination country. Required for international shipments only.

    * weight
        Weight of the shipment, in pounds, as a decimal number.

    There are some additional common values:

    * user_id
        A user_id, if required by the provider. USPS_Online and UPS_Online
        require this, while UPS_Offline does not.

    * password
        A password, if required by the provider. USPS_Online and UPS_Online
        require this, while UPS_Offline does not.

  Business::Shipping->log_level()
    Simple alternative to editing the config/log4perl.conf file. Sets the
    log level for all Business::Shipping objects.

    Takes a scalar that can be 'debug', 'info', 'warn', 'error', or 'fatal'.

SEE ALSO
    Important modules that are related to Business::Shipping:

    * Business::Shipping::DataFiles - Required for offline cost estimation
    * Business::Shipping::DataTools - Tools that generate DataFiles
    (optional)

    Other Perl modules that are simliar to Business::Shipping:

    * Business::Shipping::UPS_XML - Online cost estimation module that has
    very few prerequisites. Supports shipments that originate in USA and
    Canada.
    * Business::UPS - Online cost estimation module that uses the UPS web
    form instead of the UPS Online Tools. For shipments that originate in
    the USA only.
    * Net::UPS - Implementation of UPS Online Tools API in Perl
    * http://www.halofree.com/lib/public/code/Ship/UPS.pm
    * http://www.halofree.com/lib/public/code/Ship/USPS.pm

Use of this software
    It is appreciated when users mention their use of Business::Shipping to
    the author and/or in their web site/application.

    * Interchange e-commerce system ( <http://www.icdevgroup.org> ). See
    "UserTag/business-shipping.tag".
    * Many E-Commerce websites, such as Phatmotorsports.com.
    * PaymentOnline.com software.
    * The "Shopping Cart" Wobject for the WebGUI project, by Andy Grundman
    <http://www.plainblack.com/shopping_cart_wobject>
    * Mentioned in YAPC 2004 Presentation: "Writing web applications with
    perl ..."

WEBSITE
    <http://www.kavod.com/Business-Shipping/>

    CPAN web site: <http://search.cpan.org/~dbrowning/Business-Shipping/>

    Backpan (old releases):
    <http://backpan.cpan.org/authors/id/D/DB/DBROWNING/>

SUPPORT
    This module is supported by the author. Please report any bugs or
    feature requests to "bug-business-shipping@rt.cpan.org", or through the
    web interface at <http://rt.cpan.org>. The author will be notified, and
    then you'll automatically be notified of progress on your bug as the
    author makes changes.

KNOWN BUGS
    See the "doc/Todo" file for a comprehensive list of known bugs.

CREDITS
    Many people have contributed to this module, please see the
    "doc/Credits" file.

AUTHOR
    Daniel Browning <db@kavod.com>, Kavod Technologies,
    <http://www.kavod.com>.

COPYRIGHT AND LICENCE
    Copyright (c) 2003-2005 Daniel Browning <db@kavod.com>. All rights
    reserved. This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself. See "doc/License" for
    more info.

