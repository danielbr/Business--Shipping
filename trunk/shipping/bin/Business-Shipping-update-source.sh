#!/bin/sh

#
#
# TODO: If Business-Shipping-CVS doesn't exist, do a checkout.
#
#
# Link to this file:
#
#
# cd ~/src
# cvs -q -z3 -d:pserver:anonymous@cvs.sourceforge.net:/cvsroot/shipping login
# cvs -q -z3 -d:pserver:anonymous@cvs.sourceforge.net:/cvsroot/shipping co -d Business-Shipping-CVS shipping
# mkdir -p ~/bin; ln -s ~/src/Business-Shipping-CVS/bin/Business-Shipping-update-source.sh ~/bin
#
# Required if you want to update the Interchange usertag too
#
# You can set them up in your ~/.bash_profile file.
#
#export B_S_USER=interch
#export B_S_GROUP=interch
#export B_S_GLOBAL_TAG_DIR=/usr/lib/interchange/code/UserTag
#export B_S_PERL=/usr/local/myperl/bin/perl

#
# Standard locations
#
export SOURCE_PATH=${HOME}/src
cd $SOURCE_PATH/Business-Shipping-CVS
cvs -q -z3 up -dP

$B_S_PERL Makefile.PL && make && make test && make install

#
# Update Interchange UserTag
# TODO: require specific input to perform this step.
#
cp -f UserTag/business-shipping.tag $B_S_GLOBAL_TAG_DIR/
cp -f UserTag/incident.tag $B_S_GLOBAL_TAG_DIR/
chown ${B_S_USER}.${B_S_GROUP} $B_S_GLOBAL_TAG_DIR/business-shipping.tag
chown ${B_S_USER}.${B_S_GROUP} $B_S_GLOBAL_TAG_DIR/incident.tag
echo
echo
echo Please restart Interchange for the new usertag to take effect

