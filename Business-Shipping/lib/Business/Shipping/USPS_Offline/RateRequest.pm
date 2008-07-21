# TODO: Implement USPS_Offline.  This is just a place-holder.
#
# Business::Shipping::USPS_Offline::RateRequest
#
# $Id$
#
# Copyright (C) 2003 Interchange Development Group
# Copyright (c) 2003, 2004 Kavod Technologies, Dan Browning.
#
# All rights reserved.
#
# Licensed under the GNU Public Licnese (GPL).  See LICENSE for more info.
#
# Based on the corresponding work in the Interchange project, which was written
# by Mike Heins <mike@perusion.com>. See http://www.icdevgroup.org for more info.

package Business::Shipping::USPS_Offline::RateRequest;

=head1 NAME

Business::Shipping::USPS_Offline::RateRequest

=head1 SYNOPSIS

 (in catalog.cfg)

    Database   usps             ship/usps.txt              TAB
    Database   air_pp           ship/air_pp.txt            TAB
    Database   surf_pp          ship/surf_pp.txt           TAB

 (in shipping.asc)

    air_pp: US Postal Air Parcel
        crit            weight
        min             0
        max             0
        cost            e No shipping needed!
        at_least        4
        adder           1
        aggregate       70
        table           air_pp

        min             0
        max             1000
        cost            s Postal

        min             70
        max             9999999
        cost            e Too heavy for Air Parcel

    surf_pp:    US Postal Surface Parcel
        crit            weight
        min             0
        max             0
        cost            e No shipping needed!
        at_least        4
        adder           1
        aggregate       70
        table           surf_pp

        min             0
        max             1000
        cost            s Postal

        min             70
        max             9999999
        cost            e Too heavy for Postal Parcel

=head1 DESCRIPTION

This is a stub, it needs a lot of work to be completed.

Looks up a service zone by country in the C<usps> table, then looks in
the appropriate rate table for a price by that zone.

Can aggregate shipments greater than 70 pounds by assuming you will ship
multiple 70-pound packages (plus one package with the remainder).

=cut

use version; our $VERSION = qv('2.2.0');

use strict;
use warnings;
use base ('Business::Shipping::RateRequest::Offline');
use Business::Shipping::Shipment;
use Business::Shipping::Package;
use Business::Shipping::Logging;
use Business::Shipping::Data;
use Business::Shipping::Util;
use Business::Shipping::Config;
use Data::Dumper;
use Class::MethodMaker 2.0 [new => [qw/ -hash new /]];

sub calculate {
    my ($mode, $weight, $row, $opt, $tagopt, $extra) = @_;

    $opt ||= { auto => 1 };

#::logDebug("Postal custom: mode=$mode weight=$weight row=$row opt=" . uneval($opt));

    $type = $opt->{table};
    $o->{geo} ||= 'country';

    if (!$type) {
        $extra = interpolate_html($extra) if $extra =~ /__|\[/;
        ($type) = split /\s+/, $extra;
    }

    unless ($type) {
        do_error("No table/type specified for %s shipping", 'Postal');
        return 0;
    }

    $country = $::Values->{ $o->{geo} };

#::logDebug("ready to calculate postal type=$type country=$country weight=$weight");

    if ($opt->{source_grams}) {
        $weight *= 0.00220462;
    }
    elsif ($opt->{source_kg}) {
        $weight *= 2.20462;
    }
    elsif ($opt->{source_oz}) {
        $weight /= 16;
    }

    if ($opt->{auto}) {
        if ($type eq 'surf_lp') {
            $opt->{oz} = 1;
        }
        elsif ($type eq 'air_lp') {
            $opt->{oz} = 1;
        }

        if ($type =~ /_([pl]p)$/) {
            $opt->{max_field} = "max_$1";
        }
        elsif ($type =~ /^(ems|gxg)$/) {
            $opt->{max_field} = "max_$1";
        }
    }

    if ($opt->{oz}) {
        $weight *= 16;
    }

    $weight = POSIX::ceil($weight);

    $opt->{min_weight} ||= 1;

    $weight = $opt->{min_weight} if $opt->{min_weight} > $weight;

    if (my $modulo = $opt->{aggregate}) {
        if ($weight > $modulo) {
            my $cost = 0;
            my $w    = $weight;
            while ($w > $modulo) {
                $w -= $modulo;
                $cost += tag_postal($type, $modulo, $country, $opt);
            }
            $cost += tag_postal($type, $w, $country, $opt);
            return $cost;
        }
    }

    $opt->{table} ||= $type;
    $opt->{zone_table} ||= 'usps';

    unless (defined $Vend::Database{ $opt->{zone_table} }) {
        logError("Postal lookup called, no database table named '%s'",
            $opt->{zone_table});
        return undef;
    }

    unless (defined $Vend::Database{ $opt->{table} }) {
        logError("Postal lookup called, no database table named '%s'",
            $opt->{table});
        return undef;
    }

    $country =~ s/\W+//;
    $country = uc $country;

    unless (length($country) == 2) {
        return do_error(
            'Country code %s improper format for postal shipping.', $country,
        );
    }

    my $crecord = tag_data($opt->{zone_table}, undef, $country, { hash => 1 })
        or return do_error('Country code %s has no zone for postal shipping.',
        $country,);

    $opt->{type_field} ||= $type;

    my $zone = $crecord->{ $opt->{type_field} };

    unless ($zone =~ /^\w+$/) {
        return do_error('Country code %s has no zone for type %s.',
            $country, $type,);
    }

    $zone = "zone$zone" unless $zone =~ /^zone/ or $opt->{verbatim_zone};

    my $maxits = $opt->{max_modulo} || 4;
    my $its = 1;
    my $cost;

    do {
        $cost = tag_data($opt->{table}, $zone, $weight);
    } until $cost or $its++ > $maxits;

    return do_error("Zero cost returned for mode %s, geo code %s.",
        $type, $country,)
        unless $cost;

    return $cost;
}

1;

__END__

=head1 AUTHOR

Dan Browning E<lt>F<db@kavod.com>E<gt>, Kavod Technologies, L<http://www.kavod.com>.

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2003-2004 Kavod Technologies, Dan Browning, Interchange 
Development Group. All rights reserved.

Licensed under the GNU Public Licnese (GPL).  See LICENSE for more info.

=cut
