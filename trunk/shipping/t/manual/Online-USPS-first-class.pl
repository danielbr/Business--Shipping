#!/usr/bin/perl

use strict;
use warnings;
use Business::Shipping;

my $rr_first_class = Business::Shipping->rate_request(
    shipper     => 'USPS_Online',
    
    from_zip    => 98682,
    
    to_zip      => 98270,
    
    service     => 'First-Class',
    
    weight      => 0.75,
    
    user_id     => $ENV{ USPS_USER_ID  },
    password    => $ENV{ USPS_PASSWORD },
    #'mail_type'  => 'Postcards or Aerogrammes',
);




$rr_first_class->submit or die $rr_first_class->user_error;
print $rr_first_class->total_charges;
