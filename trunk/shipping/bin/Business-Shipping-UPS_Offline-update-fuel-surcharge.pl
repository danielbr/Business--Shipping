#!/usr/bin/perl

=head1 NAME

Business-Shipping-UPS_Offline-update-fuel-surcharge.pl

=head1 VERSION

$Rev: 189 $

=head1 DESCRIPTION

Updates the fuel surcharge (stored in C<config/fuel_surcharge.txt>) from the UPS web site.  It is 
recommended that this be run every first Monday of the month in the early AM.  Here is an example 
line to add to your crontab:

 01 1 * * * Business-Shipping-UPS_Offline-update-fuel-surcharge.pl

That causes cron to run this update program at 1:01 AM every Monday.

=head1 METHODS

=cut

use strict;
use warnings;
use Business::Shipping;
use POSIX ( 'strftime' );
use LWP::UserAgent;

&check_for_updates;

=head2 check_for_updates()

TODO: Put in a bin/... script, since it only needs to run once a month.

Changes to the surcharge will be effective the first Monday of each month.


    * [Enh] Determine the upcoming fuel surcharge changes from UPS website, then 
      check to see if that date has passed.  If so, automatically update the fuel 
      surcharge.
      
Stores the current rate in config/fuel_surcharge.txt, with the date it was updated.

TOdO: Add LWP::UserAgent to the required modules?

Fuel Surcharge: 11.25
Good Through Date: 20041101

=cut

sub check_for_updates
{
    my ( $self ) = @_;
    
    print "Checking for updates...\n";

    # Check last updated date, and see if the first monday of the next month has passed.
    
    my $fuel_surcharge_filename = Business::Shipping::Config::support_files 
        . '/config/fuel_surcharge.txt';
    
    my $fuel_surcharge_contents = readfile( $fuel_surcharge_filename );
    
    my ( undef, $line2 ) = split( "\n", $fuel_surcharge_contents );
    my ( undef, $good_through_date ) = split( ': ', $line2 );
    
    # Determine today's date, and see if it is past the $good_through_date.  
    
    my $today = strftime "%Y%m%d", localtime( time );
    
    my $get_new_update;
    
    if ( $today <= $good_through_date ) {
        print "Update not necessary\n";
        exit;
    }
    
    my $ua = LWP::UserAgent->new;
    $ua->timeout( 10 );
    $ua->env_proxy();
    my $request_param = 'http://www.ups.com/content/us/en/resources/find/cost/fuel_surcharge.html';
    my $response = $ua->get( $request_param );
    die "Could not update fuel surchage: could not access ups fuel_surcharge page" unless $response->is_success;
    
    my $content = $response->content;
    
    $content =~ m|Current Fuel Surcharge Rate:<br></strong>Through\&nbsp\;(\w+) (\d+), (\d+): (\d+)|;
    my ( $month, $day, $year, $rate ) = ( $1, $2, $3, $4 );

    die "Could not determine the date and rate from the UPS fuel surcharge page" 
        unless $month and $day and $year and $rate;
    
    # convert month names ('December') to the number
    
    my @month_names = qw( 
        January February March April May June July 
        August October September November December 
    );
    
    my $count = 1;
    for ( @month_names ) {
        if ( $month eq $_ ) {
            $month = $count;
        }
        $count++;
    }
    
    die "Could not convert month name ($month) into the month number." if $month !~ /\d+/;
    
    # Add leading zeros to month and day:
    
    $month = "0$month" if length $month == 1;
    $day   = "0$day"   if length $day   == 1;
    
    my $new_rate_file = "Fuel Surcharge: $rate\nGood Through Date: $year$month$day\n";
    
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
