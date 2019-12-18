#!/bin/sh

# This is part of the GFDL FMS package. This is a shell script to
# execute tests in the test_fms/field_manager directory.

# Ed Hartnett 11/29/19

# Set common test settings.
. ../test_common.sh

# Source function that sets up and runs tests
. /$top_srcdir/test_fms/run_test.sh

# Copy files for test.
cp $top_srcdir/test_fms/interpolator/input_base.nml input.nml
cp $top_srcdir/test_fms/interpolator/diag_table_base diag_table

# Test is skipped in bats file.
run_test test_interpolator 2 skip


