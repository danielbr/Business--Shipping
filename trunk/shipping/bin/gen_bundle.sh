#!/bin/sh

#
# How to generate the Bundle::Business::Shipping
#

perl -MCPAN -e <<EOF
autobundle   Data::Dumper LWP::UserAgent Crypt::SSLeay XML::Simple XML::DOM Error \
             Cache::FileCache Class::MethodMaker Bundle::DBD::CSV Archive::Zip \
             Config::IniFiles

