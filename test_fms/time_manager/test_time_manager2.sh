#!/bin/sh

# This is part of the GFDL FMS package. This is a shell script to
# execute tests in the test_fms/time_manager directory.

# Ed Hartnett 11/29/19

# Set common test settings.
. ../test_common.sh

# Source function that sets up and runs tests
. ../run_test.sh 

# Copy file for test.
cp $top_srcdir/test_fms/time_manager/input_base.nml input.nml

# Run the test. 
run_test test_time_manager 1 
