NAME
    Business::Shipping - Rates and tracking for UPS and USPS

VERSION
    Version 1.53

SYNOPSIS
  Rate request example
        use Business::Shipping;
    
        my $rate_request = Business::Shipping->rate_request(
            shipper   => 'Offline::UPS',
            service   => 'GNDRES',
            from_zip  => '98682',
            to_zip    => '98270',
            weight    =>  5.00,
        );    
    
        $rate_request->submit() or die $rate_request->user_error();
    
        print $rate_request->total_charges();

FEATURES
  United Parcel Service (UPS)
    * Shipment rate estimation using UPS Online WebTools.
    * Shipment rate estimation using offline tables.
    * Shipment tracking.

  United States Postal Service (USPS)
    * Shipment rate estimation using USPS Online WebTools.
    * Shipment tracking.

INSTALLATION
     perl -MCPAN -e 'install Bundle::Business::Shipping'
 
    See the INSTALL file for more details.

REQUIRED MODULES
     Bundle::DBD::CSV (any)
     Business::Shipping::DataFiles (any)
     Cache::FileCache (any)
     Class::MethodMaker::Engine (any)
     Clone (any)
     Config::IniFiles (any)
     Crypt::SSLeay (any)
     Getopt::Mixed (any)
     Log::Log4perl (any)
     LWP::UserAgent (any)
     Math::BaseCnv (any)
     Scalar::Util (1.10)
     XML::DOM (any)
     XML::Simple (2.05)

ERROR/DEBUG HANDLING
    Log4perl is used for logging error, debug, etc. messages. See
    config/log4perl.conf. For simple manipulation of the current log level,
    use the Business::Shipping->log_level( $log_level ) class method
    (below).

GETTING STARTED
    Be careful to read, understand, and comply with the terms of use for the
    provider that you will use.

  UPS_Offline: For United Postal Service (UPS) offline rate requests
    No signup required. Business::Shipping::DataFiles has all of rate
    tables.

  UPS_Online: For United Postal Service (UPS) Online XML: Free signup
    * https://www.ups.com/servlet/registration?loc=en_US_EC
    * (More info at http://www.ec.ups.com)
    * Once you get a User Id and Password from UPS, you will need to login
    and select "Get Access Key", then "Get XML Access Key".
    * Legal Terms and Conditions:
    <http://www.ups.com/content/us/en/resources/service/terms/index.html>

  USPS_Online: For United States Postal Service (USPS): Free signup
    * <http://www.uspswebtools.com/registration/>
    * (More info at <http://www.uspswebtools.com>)
    * The online signup will result in a testing-only account (only a small
    sample of queries will work).
    * To activate the "production" use of your USPS account, you must follow
    the USPS documentation. Currently, that means contacting the Internet
    Customer Care Center by e-mail ("icustomercare@usps.com") or phone:
    1-800-344-7779.

Uses of this software
    It is appreciated when users mention their use of Business::Shipping to
    the author and/or on their website or in their application.

    * Interchange e-commerce system ( <http://www.icdevgroup.org> ). See
    "UserTag/business-shipping.tag".
    * The paymentonline.com mod_perl/template toolkit system.
    * The "Shopping Cart" Wobject for the WebGUI project, by Andy Grundman
    <andy@kahncentral.net>.
    <http://www.plainblack.com/wobjects?wid=1143&func=viewSubmission&sid=654
    >
    <http://www.plainblack.com/uploads/1143/654/webgui-shopping-cart-1.0.tar
    .gz>
    * Mentioned in YAPC 2004 Presentation: "Writing web applications with
    perl ..." <http://www.beamartyr.net/YAPC-2004/text25.html>
    * Phatmotorsports.com

WEBSITE
    <http://www.kavod.com/Business-Shipping>

    The website carries the most recent version, as well as instructions for
    accessing the anonymous CVS repository.

    <http://sf.net/projects/shipping>

    Sourceforge.net provides hosting for the project.

Preloading Modules
    To preload all modules, call Business::Shipping with this syntax:

     use Business::Shipping { preload => 'All' };

    To preload the modules for just one certain shipper:

     use Business::Shipping { preload => 'USPS_Online' };
 
    Without preloading, some modules will be loaded at runtime. Normally,
    runtime loading is the best mode of operation. However, there are some
    circumstances when preloading is advantagous. For example:

    * For mod_perl, to load the modules only once at startup instead of at
    startup and then additional modules later on. (Thanks to Chris Ochs
    <chris@paymentonline.com> for contributing to this information).
    * For compatibilty with some security modules (e.g. Safe). Note that we
    have not tested Safe, but this would be a prerequisite for someone to do
    so.
    * To move the delay that would normally occur with the first request
    into startup time. That way, it takes longer to start up, but the first
    user will not notice any delay.

METHODS
  $obj->init( %args )
    Generic attribute setter.

  $obj->user_error( "Error message" )
    Log and store errors that should be visibile to the user.

  $obj->validate()
    Confirms that the object is valid. Checks that required attributes are
    set.

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
        Required for Offline::UPS.

    * to_zip
        The destination zipcode.

    * to_country
        The destination country. Required for international shipments only.

    * weight
        Weight of the shipment, in pounds, as a decimal number.

    There are some additional common values:

    * user_id
        A user_id, if required by the provider. Online::USPS and Online::UPS
        require this, while Offline::UPS does not.

    * password
        A password, if required by the provider. Online::USPS and
        Online::UPS require this, while Offline::UPS does not.

  Business::Shipping->log_level( $log_level )
    Sets the log level for all Business::Shipping objects.

    $log_level can be 'debug', 'info', 'warn', 'error', or 'fatal'.

  Business::Shipping->_new_subclass( "Subclass::Name", %opt )
    Private Method.

    Generates an object of a given subclass dynamically. Will dynamically
    'use' the corresponding module, unless runtime module loading has been
    disabled via the 'preload' option.

SEE ALSO
    Important modules that are related to Business::Shipping:

    * Business::Shipping::DataFiles - Required for offline cost estimation
    * Business::Shipping::DataTools - Tools that generating DataFiles
    (optional)

    Other CPAN modules that are simliar to Business::Shipping:

    * Business::Shipping::UPS_XML - Online cost estimation module that has
    very few prerequisites.
    * Business::UPS - Online cost estimation module that uses the UPS web
    form instead of the UPS Online Tools.

SUPPORT
    This module is supported by the author. Please report any bugs or
    feature requests to "bug-business-shipping@rt.cpan.org", or through the
    web interface at <http://rt.cpan.org>. The author will be notified, and
    then you'll automatically be notified of progress on your bug as the
    author makes changes.

KNOWN BUGS
    See the TODO file for a comprehensive list of known bugs.

    * USPS_Online and no internet connection.
        You will get the following error when there is no connection to the
        internet when using USPS_Online:

         Business::Shipping::USPS_Online::RateRequest::_handle_response: ()
         File does not exist:  at .../USPS_Online/RateRequest.pm ...

CREDITS
    See CREDITS file.

AUTHOR
    Dan Browning <db@kavod.com>, Kavod Technologies, <http://www.kavod.com>.

COPYRIGHT AND LICENCE
    Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights
    reserved. This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself. See LICENSE for more
    info.

