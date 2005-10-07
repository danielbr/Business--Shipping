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

 
 http://www.ups.com/content/us/en/resources/find/cost/fuel_surcharge.html
    
=head1 REQUIRED MODULES

LWP::UserAgent

=head1 METHODS

=cut

use strict;
use warnings;
use Business::Shipping;
use Business::Shipping::Logging;
#use POSIX ( 'strftime' );
use LWP::UserAgent;

#Business::Shipping->log_level( 'debug' );

&check_for_updates;

=head2 check_for_updates()

Stores the "Good Through" rate in config/fuel_surcharge.txt, with the date it was updated.

=cut

sub check_for_updates
{
    my ( $self ) = @_;
    
    # Check last updated date, and see if the first monday of the next month has passed.
    
    my $fuel_surcharge_filename = Business::Shipping::Config::config_dir()
        . '/fuel_surcharge.txt';
    
    # UPS usually releases a new file three weeks after the effective date, but
    # we should check anyways, so just always do the update.
    # 
    # my $fuel_surcharge_contents = readfile( $fuel_surcharge_filename );
    # 
    #print( $fuel_surcharge_contents );
    # 
    # my ( undef, $line2 ) = split( "\n", $fuel_surcharge_contents );
    # my ( undef, $gt_good_through_date ) = split( ': ', $line2 );
    # Determine today's date, and see if it is past the $good_through_date.  
    # my $today = strftime "%Y%m%d", localtime( time );
    #if ( $today <= $gt_good_through_date ) {
    #    print "Update not necessary\n";
    #    exit;
    #}
    #else {
    #    print "Update is recommended.  Requesting new rates from the UPS website...\n";
    #}
    
    my $ua = LWP::UserAgent->new;
    $ua->timeout( 10 );
    $ua->env_proxy();
    my $request_param = 'http://www.ups.com/content/us/en/resources/find/cost/fuel_surcharge.html';
    my $response = $ua->get( $request_param );
    die "Could not update fuel surchage: could not access ups fuel_surcharge page" unless $response->is_success;
    
    my $content = $response->content;    
    my @lines = split( "\n", $content );
    my $rates = { ground => {}, air => {} };
    my %type_regex = ( 
        #'ground' => '^<STRONG>Ground<BR></STRONG>Through (\w+) (\d+), (\d+): (\d+\.?\d?\d?)%',
        'ground' => '^<STRONG>Ground<BR></STRONG>Through (\w+) (\d+), (\d+): (\d+\.?\d?\d?)%<BR>Effective (\w+) (\d+), (\d+): (\d+\.?\d?\d?)%',
        'air'    => '^<STRONG>Air and International<BR></STRONG>Through (\w+) (\d+), (\d+): (\d+\.?\d?\d?)%<BR>Effective (\w+) (\d+), (\d+): (\d+\.?\d?\d?)%',
    );
    
    #print "content = $content\n";
    # New HTML style (2005-09-16)
    # <STRONG>Current Fuel Surcharge Rate:</STRONG><br><br>
    # <STRONG>Ground<BR></STRONG>Through September 4, 2005: 2.75%<BR>Effective September 5, 2005: 3.00%<br><br>
    # <STRONG>Air and International<BR></STRONG>Through September 4, 2005: 9.50%<BR>Effective September 5, 2005: 9.50%<br><br>
    
    foreach my $line ( @lines ) {
        while ( my ( $service_type, $regex ) = each %type_regex ) {
            if ( $line =~ m|$regex| ) {
                #print "Match!  line = $line";
                my %through;
                my %effective;
                @through{   qw| month day year rate | } = ( $1, $2, $3, $4 );
                @effective{ qw| month day year rate | } = ( $5, $6, $7, $8 );
                $rates->{ $service_type }->{ through } = \%through;
                $rates->{ $service_type }->{ effective } = \%effective;
            }
        }
    }

    #print "INFO: $gt_month, $gt_day, $gt_year, $gt_rate\n$at_month, $at_day, $at_year, $at_rate\n\n";
    
    #print Dumper( $rates );
    
    # convert month names ('December') to the number
    my @month_names = qw( 
        January February March April May June July 
        August October September November December 
    );
    
    #print "ground through month = $rates->{ground}{through}{month}\n";
    foreach my $service_type ( 'ground', 'air' ) {
        foreach my $date_type ( 'through', 'effective' ) {
            
            # cur = current date and rate hash.
            my %cur = %{ $rates->{ $service_type }{ $date_type } };
            
            my $found_month;
            for my $c ( 0 .. $#month_names ) {
                if ( $cur{ month } eq $month_names[ $c ] ) {
                    #print "cur month ('$cur{month}') eq month_names[c] ('$month_names[$c]')\n";
                    $cur{ month } = $c + 1;  # Add one because we don't count months from 0 in real life.
                    $found_month = 1;
                    last;
                }
            }
            die "Could not convert month name ($cur{month}) into the month number." unless $found_month;
            
            # Add leading zeros to month and day:
            $cur{ month } = "0" . $cur{ month } if length $cur{ month } == 1;
            $cur{ day } = "0" . $cur{ day } if length $cur{ day } == 1;
            
            $rates->{ $service_type }{ $date_type } = \%cur;    
        }
    }
    #print Dumper( $rates );
    
    my $ground_through_date   = join( '', @{ $rates->{ ground }{ through } }{ qw| year month day | } );
    my $ground_through_rate   = $rates->{ ground }{ through }{ rate };
    my $ground_effective_date = join( '', @{ $rates->{ ground }{ effective } }{ qw| year month day | } );
    my $ground_effective_rate = $rates->{ ground }{ effective }{ rate };
    my $air_through_date   = join( '', @{ $rates->{ air }{ through } }{ qw| year month day | } );
    my $air_through_rate   = $rates->{ air }{ through }{ rate };
    my $air_effective_date = join( '', @{ $rates->{ air }{ effective } }{ qw| year month day | } );
    my $air_effective_rate = $rates->{ air }{ effective }{ rate };
    
    my $new_rate_file = 
          "Ground Fuel Surcharge: $ground_through_rate\n"
        . "Ground Good Through Date: $ground_through_date\n"
        . "Air and International Fuel Surcharge: $air_through_rate\n"
        . "Air and International Good Through Date: $air_through_date\n"
        . "Ground Effective Fuel Surcharge: $ground_effective_rate\n"
        . "Ground Effective Date: $ground_effective_date\n"
        . "Air and International Effective Fuel Surcharge: $air_effective_rate\n"
        . "Air and International Effective Date: $air_effective_date\n"
    ;
    
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
