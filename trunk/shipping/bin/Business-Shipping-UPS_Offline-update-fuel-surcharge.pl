#!/usr/bin/perl

=head1 NAME

Business-Shipping-UPS_Offline-update-fuel-surcharge.pl

=head1 VERSION

$Rev: 189 $

=head1 DESCRIPTION

Updates the fuel surcharge (stored in C<config/fuel_surcharge.txt>) from the UPS web site.  It is 
recommended that this be run every first Monday of the month in the early AM.  Here is an example 
line to add to your crontab:

 01 4 * * 1 Business-Shipping-UPS_Offline-update-fuel-surcharge.pl

That causes cron to run this update program at 4:01 AM every Monday.  Another good cronjob to have
is one that will update your Business::Shipping::DataFiles:

 01 4 * * 1 perl -MCPAN -e 'install Business::Shipping::DataFiles'

=head1 REQUIRED MODULES

LWP::UserAgent

=head1 METHODS

=cut

use strict;
use warnings;
use Business::Shipping;
use POSIX ( 'strftime' );
use LWP::UserAgent;

&check_for_updates;

=head2 check_for_updates()

Stores the "Good Through" rate in config/fuel_surcharge.txt, with the date it was updated.

=cut

sub check_for_updates
{
    my ( $self ) = @_;
    
    # Check last updated date, and see if the first monday of the next month has passed.
    
    my $fuel_surcharge_filename = Business::Shipping::Config::support_files 
        . '/config/fuel_surcharge.txt';
    
    my $fuel_surcharge_contents = readfile( $fuel_surcharge_filename );
    
    my ( undef, $line2 ) = split( "\n", $fuel_surcharge_contents );
    my ( undef, $g_good_through_date ) = split( ': ', $line2 );
    
    # Determine today's date, and see if it is past the $good_through_date.  
    
    my $today = strftime "%Y%m%d", localtime( time );
    
    my $get_new_update;
    
    if ( $today <= $g_good_through_date ) {
        print "Update not necessary\n";
        exit;
    }
    else {
        print "Update is necessary.  Requesting new rates from the UPS website...\n";
    }
    
    my $ua = LWP::UserAgent->new;
    $ua->timeout( 10 );
    $ua->env_proxy();
    my $request_param = 'http://www.ups.com/content/us/en/resources/find/cost/fuel_surcharge.html';
    my $response = $ua->get( $request_param );
    die "Could not update fuel surchage: could not access ups fuel_surcharge page" unless $response->is_success;
    
    my $content = $response->content;
    
    #<strong>Current Fuel Surcharge Rate:</strong><br><br><strong>Ground<br></strong>
    #Through&nbsp;January 2, 2005: 0.00%.<br>Effective&nbsp;January 3, 2005: 2.00%.<br>
    #<br><strong>Air and International<br></strong>Through&nbsp;January 2, 2005: 13.00%.<br>
    #Effective&nbsp;January 3, 2005: 9.50%.<br>    
    
    # First get the Ground value.
    $content =~ m|Ground<br></strong>Through\&nbsp\;(\w+) (\d+), (\d+): (\d+)|;
    my ( $g_month, $g_day, $g_year, $g_rate ) = ( $1, $2, $3, $4 );

    # Then get the Air and International value.
    $content =~ m|Air and International<br></strong>Through\&nbsp\;(\w+) (\d+), (\d+): (\d+)|;
    my ( $a_month, $a_day, $a_year, $a_rate ) = ( $1, $2, $3, $4 );

    print "INFO: $g_month, $g_day, $g_year, $g_rate\n$a_month, $a_day, $a_year, $a_rate\n\n";
    
    die "Could not determine the date and rate from the UPS fuel surcharge page" 
        unless $g_month and $g_day and $g_year and defined $g_rate
           and $a_month and $a_day and $a_year and defined $a_rate;
    
    # convert month names ('December') to the number
    
    my @month_names = qw( 
        January February March April May June July 
        August October September November December 
    );
    
    my $count = 1;
    for ( @month_names ) {
        if ( $g_month eq $_ ) {
            $g_month = $count;
        }
        if ( $a_month eq $_ ) {
            $a_month = $count;
        }
        $count++;
    }
    
    die "Could not convert month name ($g_month and $a_month) into the month number." 
        if $g_month !~ /\d+/ or $a_month !~ /\d+/;
    
    # Add leading zeros to month and day:
    
    $g_month = "0$g_month" if length $g_month == 1;
    $a_month = "0$a_month" if length $a_month == 1;
    $g_day   = "0$g_day"   if length $g_day   == 1;
    $a_day   = "0$a_day"   if length $a_day   == 1;
    
    my $new_rate_file = 
          "Ground Fuel Surcharge: $g_rate\n"
        . "Ground Good Through Date: $g_year$g_month$g_day\n"
        . "Air and International Fuel Surcharge: $a_rate\n"
        . "Air and International Good Through Date: $a_year$a_month$a_day\n";
    
    print "Going to write new values:\n";
    print "==========================\n$new_rate_file==========================\n";
    
    writefile( $fuel_surcharge_filename, $new_rate_file ) or die "Could not write to $fuel_surcharge_filename";

    return;
}

=head2 * readfile( $file )

Note: this is not an object-oriented method.

=cut

sub readfile
{
    my ( $file ) = @_;
    
    return undef unless open( READIN, "< $file" );
    
    # TODO: Use English;
    
    undef $/;
    
    my $contents = <READIN>;
    close( READIN );
    
    return $contents;
}

=head2 * writefile( $filename, $filecontents )

Note: this is not an object-oriented method.

=cut

sub writefile
{
    my ( $filename, $contents ) = @_;
    
    return unless open( OUT, "> $filename" );
    
    # TODO: Use English;
    
    undef $/;
    
    print OUT $contents;
    
    return $contents;
}

1;

__END__

=head1 AUTHOR

Dan Browning E<lt>F<db@kavod.com>E<gt>, Kavod Technologies, L<http://www.kavod.com>.

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself. See LICENSE for more info.

=cut
