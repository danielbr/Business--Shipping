# Business::Shipping::Config - Configuration functions
# 
# $Id: Config.pm,v 1.9 2004/06/25 20:42:26 danb Exp $
# 
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See LICENSE for more info.
# 

package Business::Shipping::Config;

=head1 NAME

Business::Shipping::Config - Configuration functions

=head1 VERSION

$Revision: 1.9 $      $Date: 2004/06/25 20:42:26 $

=head1 DESCRIPTION

Business::Shipping::Config is currently just a simple API on top of the 
Config::IniFiles module.

=head1 METHODS

=over 4

=cut

$VERSION = do { my @r=(q$Revision: 1.9 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };
@EXPORT = qw/ cfg cfg_obj config_to_hash config_to_ary_of_hashes /;
use constant DEFAULT_SUPPORT_FILES_DIR => '/var/perl/Business-Shipping';
#use constant DEFAULT_SUPPORT_FILES_DIR => '~_~SUPPORT_FILES_DIR~_~';

use strict;
use warnings;
use base ( 'Exporter' );
use Config::IniFiles;
use Carp;

my $support_files_dir;
my $main_config_file;

# Try the current directory first.

if ( -f 'config/config.ini' ) {
    $support_files_dir = '.';
}

# Then try environment variables

$support_files_dir ||= $ENV{ BUSINESS_SHIPPING_SUPPORT_FILES };

# Then fall back on the default.

$support_files_dir ||= DEFAULT_SUPPORT_FILES_DIR;

$main_config_file = "$support_files_dir/config/config.ini";
tie my %cfg, 'Config::IniFiles', (      -file => $main_config_file );
my $cfg_obj = Config::IniFiles->new(    -file => $main_config_file );

sub cfg             { return \%cfg;                 }
sub cfg_obj         { return $cfg_obj;              }
sub support_files   { return $support_files_dir;    }

=item * config_to_hash( $ary, $del )

 $ary   Key/value pairs
 $del   Delimiter for the above array (tab is default)

Builds a hash from an array of lines containing key / value pairs, like so:

 key1    value1
 key2    value2
 key3    value3

=cut

sub config_to_hash
{
    my ( $ary, $delimiter ) = @_;
    return unless $ary;
    #
    # TODO: check ref( $ary ) eq 'ARRAY'
    #
    
    $delimiter ||= "\t";
    
    my $hash = {};
    foreach my $line ( @$ary ) {
        my ( $key, $val ) = split( $delimiter, $line );
        $hash->{ $key } = $val;
    }
    
    return $hash;    
}

=item * config_to_ary_of_hashes( 'configuration_parameter' )

Reads in the configuration hashref ( e.g. cfg()->{ primary }->{ secondary } ),
then returns an array of hashes.  For example:

This:

 [invalid_rate_requests]
 invalid_rate_requests_ups=<<EOF
 service=XDM    to_country=Canada    reason=Not available.
 service=XDM    to_country=Brazil
 EOF

When called with this:

 my @invalid_rate_requests_ups = config_to_ary_of_hashes( 
     cfg()->{ invalid_rate_requests }->{ invalid_rate_requests_ups }
 );

Returns this:

 [ 
     {
         to_country => 'Canada',
         service    => 'XDM'
     },
     {
         to_country => 'Brazil',
         service    => 'XDM'
     },
 ]

=cut

sub config_to_ary_of_hashes
{
    my ( $cfg ) = @_;
        
    my @ary;
    foreach my $line ( @$cfg ) {

        # Convert multiple tabs into one tab.
        # Remove the leading tab.
        # split on the tabs to get key=val pairs.
        # split on the '='.

        $line =~ s/\t+/\t/g;
        $line =~ s/^\t//;
        my @key_val_pairs = split( "\t", $line );
        next unless @key_val_pairs;

        # Each line becomes a hash.

        my $hash = {};
        foreach my $key_val_pair ( @key_val_pairs ) {
            my ( $key, $val ) = split( '=', $key_val_pair );
            next unless ( defined $key and defined $val );
            $hash->{ $key } = $val;
        }

        push @ary, $hash if ( %$hash );
    }

    return @ary;
}

1;

__END__

=back

=head1 AUTHOR

Dan Browning E<lt>F<db@kavod.com>E<gt>, Kavod Technologies, L<http://www.kavod.com>.

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself. See LICENSE for more info.

=cut
