# Business::Shipping::ClassAttribs - Class attribute functions
# 
# $Id$
# 
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See LICENSE for more info.
# 

package Business::Shipping::ClassAttribs;

=head1 NAME

Business::Shipping::ClassAttribs - Class attribute functions

=head1 VERSION

$Rev$      $Date$

=head1 DESCRIPTION

Determines certain class attributes using metadata that is built into the class
via static class methods.

=head1 METHODS

=over 4

=cut

$VERSION = do { my $r = q$Rev$; $r =~ /\d+/; $&; };
@EXPORT = qw( get_grouped_attrs );

use strict;
use warnings;
use base ( 'Exporter' );
use Business::Shipping::Logging;
use Business::Shipping::ClassInfo;
use Scalar::Util 'blessed';
    
=item * $object->get_grouped_attrs( $attribute_group_name, %options  )

Its recommended that you create an object of the desired class, then call it as 
above. 

Returns a list of attributes for a certain group.  For example, if several 
classes have the Group Attribute "Required()", then call them all, split the
comma-separated list, if any, then return an array of the attributes.

Options can be one of the following (they are optional -- they will be determined
automatically if you call the $self->... version of this method.)
    class_name => '...',
    -or-
    object => $obj,
    -or- 
    
class_name is for the old feature
    
 Three steps:
 1. Compile a list of all class names and corresponding objects.
 2. Check all of those objects for Has_a, then recursively find additional
    class names and objects, and add them to the list.
 3. Go over the list and look for $group elements.
    
=cut

#
# TODO: automatically notice when called as "$self->" or not, 
# and adjust accordingly.  If $self *AND* object => ... are specified,
# then object => ... overrules.
#
sub get_grouped_attrs
{
    my ( $self, $attribute_group_name, %options ) = @_;
    
    #
    # Allow %options to override $self as the object.
    #
    my $class_name = $options{ class_name } 
                    || obj_to_class_name( $options{ object } )
                    || obj_to_class_name( $self );

    if ( ! $class_name ) {
        error_log( "Could not get class_name." );
        return;
    }

    my $object = $options{ object } || $self || eval "use $class_name; return $class_name->new;";
    
    debug3( "Creating ClassInfo object" );
    
    my $class_info = Business::Shipping::ClassInfo->new();
    
    $class_info->{ classes }->{ $class_name } = {};
    $class_info->{ classes }->{ $class_name }->{ object } = $object;
    
    debug3( "Added class $class_name with object $object." );
    
    $class_info->recursive_find_Has_a( $class_name => $object ) unless $options{ no_Has_a_objects };
    
    #
    # 1. Create list.
    #    Note that it cannot override the one that we already added.
    #
    my @tree_class_names = $class_info->get_tree_class_names( $class_name );
    my %classes_objects = $class_info->get_classes_objects_for_classes( @tree_class_names );
    $class_info->add_classes_objects( %classes_objects );
    
    #debug3( "tree class names are: " . join( ',', @tree_class_names ) );
    #debug3( "classes_objects keys   = \n\t" . join( "\n\t", sort keys %classes_objects ) );
    #debug3( "classes_objects values = \n\t" . join( "\n\t", sort values %classes_objects ) );
    
    
    
    #
    # 2. Add Has_a objects
    #    Here, however, it *must* override any that it finds (so that the 
    #    authentic objects replace the auto-generated ones from above).
    #    

    $class_info->find_and_add_Has_a_objects unless $options{ no_Has_a_objects };
    
    #
    # For some reason, we are ending up with some classes that still do not have
    # objects assigned to them (e.g. Business::Shipping::Shipment when the group
    # is 'Unique').  Find those, and assign objects.
    # 
    $class_info->add_missing_objects;
    
    #
    # 3. Look for the desired grouped attributes.
    #
    my @groups = $class_info->find_group( $attribute_group_name );
    @groups = sort @groups;
    
    return @groups;
}

=item * obj_to_class_name( $obj )

=cut

sub obj_to_class_name
{
    my ( $obj ) = @_;
    
    if ( not defined $obj ) {
        #debug3( "Non-fatal error: no object passed." );
        return;
    }
    
    my $class_name = blessed $obj;
    
    return $class_name;   
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
