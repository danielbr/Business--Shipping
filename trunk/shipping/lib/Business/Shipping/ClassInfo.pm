# Business::Shipping::ClassInfo - Used by ClassAttribs
# 
# $Id$
# 
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See LICENSE for more info.
# 

package Business::Shipping::ClassInfo;

=head1 NAME

Business::Shipping::ClassInfo - Used by ClassAttribs

=head1 VERSION

$Revision: 1.5 $      $Date$

=head1 METHODS

=over 4

=cut

$VERSION = do { my @r=(q$Revision: 1.5 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use strict;
use warnings;
use Scalar::Util 'blessed';
use Business::Shipping::Util;
use Business::Shipping::Logging;

use Class::MethodMaker 2.0 
    [ 
      new    => [ { -init => 'this_init' }, 'new' ],
    ];

sub this_init
{
    $_[ 0 ]->{ classes } = {};
    return;
}

sub get_classes_str { return "\n    " . join( "\n    ", $_[ 0 ]->get_classes_ary ); }
sub get_classes_ary { return ( sort keys %{ $_[ 0 ]->classes } ); }
=item * classes

Returns $self->{ classes }, which is:

 $self->{ classes } = {
             'Business::Shipping' => { 
                               object => 'Business::Shipping=HASHREF(0x9999)',
                               name   => 'Business::Shipping'
                               },
 }

Where possible, object is an actual object from the $self object (or one of its
Has_a objects).

=cut

sub classes { return $_[ 0 ]->{ classes }; }

sub add_classes_objects
{
    my ( $self, %classes_objects ) = @_;
    #trace '()';
    
    foreach my $class ( keys %classes_objects ) {
        
        if ( $self->classes->{ $class } and defined $self->classes->{ $class }->{ object } ) {
            debug3( "$class already defined and has object , skipping." );
            next;
        }
        my $object = $classes_objects{ $class };
        if ( ! $object ) {
            debug3( "This class ( $class ) did not have an object associated with it. Skipping" );
            next;
        }
        debug3( "Adding class: $class " );
        debug3( "   w/ Object: $object" );
        $self->new_unless_defined( $class );
        
        $self->classes->{ $class }->{ object } = $object;
    }
    
    debug3 "Done.  Now, classes are: " . $self->get_classes_str;
    
    #trace 'returning';
    
    return;
}

sub new_unless_defined
{
    my ( $self, $class_name ) = @_;
    #trace '()';
    
    if ( not defined $self->{ classes }->{ $class_name } ) {
        $self->{ classes }->{ $class_name } = {};
        #
        # Might as well duplicate the name for convenience
        #
        $self->{ classes }->{ $class_name }->{ name } = $class_name;
    }
    
    return;
}

sub find_and_add_Has_a_objects
{
    my ( $self ) = @_;
    trace3 '()';
    
    use Data::Dumper;
    debug3( "classes = " . Dumper( $self->{ classes } ) );
    
    
    my %classes_objects = $self->get_my_classes_objects;
    
    $self->recursive_find_Has_a( %classes_objects );
    
    return;
}

=item * get_classes_objects_for_classes

=cut

sub get_classes_objects_for_classes
{
    my ( $self, @class_names ) = @_;
    trace3 'called';
    
    #debug3 ( "arg1 = $_[1], arg2 = $_[2]" );
    
    my %class_tree_with_objs;
    
    foreach my $class_name ( @class_names ) {
        my $obj = get_object( $class_name );
        $class_tree_with_objs{ $class_name } = $obj;
    }
    
    return %class_tree_with_objs;
}


sub get_my_classes_objects
{
    my ( $self ) = @_;
    
    my %classes_objects;
    
    foreach my $class ( %{ $self->{ classes } } ) {
        $classes_objects{ $class } = $self->{ classes }->{ object };
    }
    
    return %classes_objects;
}
    
sub recursive_find_Has_a
{
    my ( $self, %classes_objects ) = @_;
    #trace "( " . uneval ( %classes_objects ) . " )";
    
    foreach my $class ( keys %classes_objects ) {
        
        if ( $class =~ /^HASH/ or ref $class eq 'HASH' ) {
            debug3( "class was HASH, not a name... skipping " );
            next;
        }
        debug3( "Working on $class" ); 
        #debug3( "working on $class that has object $classes_objects{$class}" );
        my $object = $classes_objects{ $class } 
            || $self->{ classes }->{ $class }->{ object };
        
        # Array support.  For example, supports Class::MethodMaker "array" type.
        
        if ( defined $object and ref $object eq 'ARRAY' ) {
            debug3( "Object is an array ref, using the first element of the "
                  . "array as the object instead." );
            $object = $object->[ 0 ];
        }
        
        if ( not defined $object ) {
            debug3( "$class: object not defined" );
            $object = $self->get_object( $class );
            if ( not defined $object ) {
                debug3( "Could not get object for $class." );
                next;
            }
        }
        
        debug3( "Checking for Has_a... in object $object" );
        my @Has_a_classes;
        my %Has_a_classes_objects;
        my %parent_classes_objects;
        
        if ( $object->can( 'Has_a' ) ) {
            
            #
            # TODO: Switch to eval method: %Has_a = eval "$obj->Has_a";
            #
            my %slots_classes = convert_special_scalar_to_hash( $object->Has_a );
            @Has_a_classes = sort values %slots_classes;
            debug3( "Has_a found.  All Classes are: " . join( ', ', @Has_a_classes ) );
            
            my ( $slot1 ) = keys %slots_classes;
            my ( $class1 ) = $slots_classes{ $slot1 };
            debug3( "    -- The first slot/class combo:  $slot1 => $class1 "  );
            
            
            #
            # Get the actual object that Has_a refers to.
            #
            foreach my $slot ( keys %slots_classes ) {
                my $new_class_name = $slots_classes{ $slot };
                my $new_class_object = $object->$slot;
                debug3( "current object: $object" );
                debug3( "new_class_name: $new_class_name" );
                #debug3( "new_class_obj:  $new_class_object" );
                
                $Has_a_classes_objects{ $new_class_name } = $new_class_object
                    if defined $new_class_object;
                
                #
                #   - For each Has_a Object found, search that tree too, perhaps it has parents 
                #     that we haven't added yet.  For example:
                #     - Shipment::UPS     Has_a     Package::UPS
                #     - Normally, we just add Package::UPS::Group() ('packaging').
                #     - What we should do is also add Package::Group() ('weight').
                #
                my @tree_class_names = $self->get_tree_class_names( $new_class_name );
                %parent_classes_objects = $self->get_classes_objects_for_classes( @tree_class_names );
                
                #debug3( "Checking slot $slot.  Found new_class_name = $new_class_name, with new class_object = $new_class_object" );
            }
        }
        
        $self->add_classes_objects( %Has_a_classes_objects );
        $self->add_classes_objects( %parent_classes_objects );
        
        $self->recursive_find_Has_a( %Has_a_classes_objects );
    }
    
}

sub convert_special_scalar_to_hash
{
    my ( $special_scalar ) = @_;
    
    my @Has_a_lines = split( ', ', $special_scalar );
    my %Has_a;
    foreach my $Has_a_line ( @Has_a_lines ) {
        my ( $scalar_name, $class_name ) = split( '=>', $Has_a_line );
        $Has_a{ $scalar_name } = $class_name;
    }
    
    return %Has_a;
}

sub add_via_class_name
{
    my ( $self, @classes ) = @_;
    
    foreach my $class ( @classes ) {
        my $object = get_object( $class );
        next if not defined $object;
        
        #
        # Tries not to overwrite if stg is already there.
        #
        $self->new_unless_defined( $class );
        $self->{ classes }->{ $class }->{ name } ||= $class;
        $self->{ classes }->{ $class }->{ object } ||= $object;
    }
    
    return;
}


sub get_object
{
    my ( $class ) = @_;
    trace3 "( $class )";
    #
    # Skip any objects that have construction problems.
    #
    
    $@ = '';
    my $obj;
    
    eval {
        eval "use $class";
        $obj = $class->new;
    };
    if ( $@ ) { 
        my ( undef, undef, undef, $caller ) = caller(1);
        #
        # Errors are expected, since we are testing the *entire* class heirarchy
        # Lets just ignore the errors.
        #
        #log_error( "\tError when calling $class->new: $@.  Caller was $caller\n" );
        return;
    }
    
    return $obj;
}

sub find_group
{
    my ( $self, $group ) = @_;
    trace3 "( $group )";
    
    if ( ! $group ) {
        log_error( "find_group() did not have a group and class_name!" );
        return;
    }
    my @Group;
    my @classes = keys %{ $self->{ classes } };
    debug3( "classes = " . join( "\n", @classes ) );
    foreach my $class ( @classes ) {
        my $object = $self->{ classes }->{ $class }->{ object };
        if ( defined $object and ref $object eq 'ARRAY' ) {
            $object = $object->[ 0 ];
        }
        if ( not defined $object ) {
            debug3( "$class did not have an object defined for it" );
            next;
        }
        
        
        if ( $object->can( $group ) ) {
            my $Group_in_string_format = $object->$group;
            
            if ( $Group_in_string_format ) {
                #
                # We check that the group is not empty, because sometimes they 
                # are, like when a custom function is used (e.g. Package::USPS).
                #
                debug3( "$class->$group was called on $object" );
                debug3( "$class->$group returned $Group_in_string_format" );
                push @Group, handle_group( $Group_in_string_format );
            }
        }
        else {
            debug3( "$class cannot exec $group" );
        }
    }
    
    @Group = Business::Shipping::Util::unique( @Group );
    my $str = "find_group( $group ) returning " . join( ',', @Group ) . "\n";
    debug3 $str;
    
    return @Group;
}
            
sub handle_group
{
    my ( $group ) = @_;
    
    #
    # TODO: use eval "" ?
    #
    my @group = split( ', ', $group );
    
    return @group;
}

sub add_missing_objects
{
    my ( $self ) = @_;
    
    foreach my $class ( $self->get_classes_ary ) {
        if ( not defined $self->classes->{ $class }->{ object } ) {
            my $object = eval "$class->new;";
            if ( defined $object ) {
                $self->classes->{ $class }->{ object } = $object;
                debug "$class: constructed object successfully..";
            }
            else {
                debug "$class: tried to get object, but failed. Deleting class.";
                delete $self->classes->{ $class };
            }
        }
    }
     
    return;
}

=item * get_tree_class_names( $class_name )

=cut

sub get_tree_class_names
{
    my ( $self, $class_name ) = @_;
    
    my @tree_class_names = split '::', $class_name;
    my @full_tree_class_names;
    
    for ( my $i = 0; $i < @tree_class_names; $i++ ) {
        push @full_tree_class_names, join( '::', @tree_class_names[ 0 .. $i ] );
    }

    return @full_tree_class_names;
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
