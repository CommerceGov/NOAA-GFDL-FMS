#!/bin/sh

# This is part of the GFDL FMS package. This is a shell script to
# execute tests in the test_fms/drifters directory.

# Ed Hartnett 11/29/19

# Set common test settings.
. ../test_common.sh

# Source function that sets up and runs tests
. ../run_test.sh 

# Copy file for test.
cp $top_srcdir/test_fms/exchange/input_base.nml input.nml

# This test is skipped in the bats file.
#cp -r $top_srcdir/test_fms/exchange/INPUT INPUT
run_test test_xgrid 2 skip
