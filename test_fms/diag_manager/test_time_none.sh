#!/bin/sh

#***********************************************************************
#*                   GNU Lesser General Public License
#*
#* This file is part of the GFDL Flexible Modeling System (FMS).
#*
#* FMS is free software: you can redistribute it and/or modify it under
#* the terms of the GNU Lesser General Public License as published by
#* the Free Software Foundation, either version 3 of the License, or (at
#* your option) any later version.
#*
#* FMS is distributed in the hope that it will be useful, but WITHOUT
#* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#* FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
#* for more details.
#*
#* You should have received a copy of the GNU Lesser General Public
#* License along with FMS.  If not, see <http://www.gnu.org/licenses/>.
#***********************************************************************

# Copyright (c) 2019-2020 Ed Hartnett, Seth Underwood

# Set common test settings.
. ../test-lib.sh

if [ -z "${skipflag}" ]; then
# create and enter directory for in/output files
output_dir

#TODO replace with yaml diag_table and set diag_manager_nml::use_modern_diag=.true.
cat <<_EOF > diag_table
test_none
2 1 1 0 0 0

"test_none",      6,  "hours", 1, "hours", "time"
"test_none_regional",      6,  "hours", 1, "hours", "time"

"ocn_mod", "var0", "var0_none", "test_none", "all", .false., "none", 2
"ocn_mod", "var1", "var1_none", "test_none", "all", .false., "none", 2
"ocn_mod", "var2", "var2_none", "test_none", "all", .false., "none", 2
"ocn_mod", "var3", "var3_none", "test_none", "all", .false., "none", 2

"ocn_mod", "var3", "var3_Z", "test_none", "all", .false., "-1 -1 -1 -1 2. 3.", 2

"ocn_mod", "var3", "var3_none", "test_none_regional", "all", .false., "78. 81. 78. 81. 2. 3.", 2 #chosen by MKL
_EOF

cat <<_EOF > diag_table.yaml
title: test_none
base_date: 2 1 1 0 0 0
diag_files:
- file_name: test_none
  freq: 6 hours
  time_units: hours
  unlimdim: time
  varlist:
  - module: ocn_mod
    var_name: var0
    output_name: var0_none
    reduction: none
    kind: r4
  - module: ocn_mod
    var_name: var1
    output_name: var1_none
    reduction: none
    kind: r4
  - module: ocn_mod
    var_name: var2
    output_name: var2_none
    reduction: none
    kind: r4
  - module: ocn_mod
    var_name: var3
    output_name: var3_none
    reduction: none
    kind: r4
  - module: ocn_mod
    var_name: var3
    output_name: var3_Z
    reduction: none
    zbounds: 2. 3.
    kind: r4
- file_name: test_none_regional
  freq: 6 hours
  time_units: hours
  unlimdim: time
  sub_region:
  - grid_type: latlon
    corner1: 78. 78.
    corner2: 78. 78.
    corner3: 81. 81.
    corner4: 81. 81.
  varlist:
  - module: ocn_mod
    var_name: var3
    output_name: var3_none
    reduction: none
    zbounds: 2. 3.
    kind: r4
_EOF

my_test_count=1
printf "&diag_manager_nml \n use_modern_diag=.true. \n / \n&test_reduction_methods_nml \n test_case = 0 \n/" | cat > input.nml
test_expect_success "Running diag_manager with "none" reduction method (test $my_test_count)" '
  mpirun -n 6 ../test_reduction_methods
'
test_expect_success "Checking answers for the "none" reduction method (test $my_test_count)" '
  mpirun -n 1 ../check_time_none
'

my_test_count=`expr $my_test_count + 1`
printf "&diag_manager_nml \n use_modern_diag=.true. \n / \n &test_reduction_methods_nml \n test_case = 0 \n mask_case = 1 \n \n/" | cat > input.nml
test_expect_success "Running diag_manager with "none" reduction method, logical mask (test $my_test_count)" '
  mpirun -n 6 ../test_reduction_methods
'
test_expect_success "Checking answers for the "none" reduction method, logical mask (test $my_test_count)" '
  mpirun -n 1 ../check_time_none
'

my_test_count=`expr $my_test_count + 1`
printf "&diag_manager_nml \n use_modern_diag=.true. \n / \n &test_reduction_methods_nml \n test_case = 0 \n mask_case = 2 \n \n/" | cat > input.nml
test_expect_success "Running diag_manager with "none" reduction method, real mask (test $my_test_count)" '
  mpirun -n 6 ../test_reduction_methods
'
test_expect_success "Checking answers for the "none" reduction method, real mask (test $my_test_count)" '
  mpirun -n 1 ../check_time_none
'

export OMP_NUM_THREADS=1
my_test_count=`expr $my_test_count + 1`
printf "&diag_manager_nml \n use_modern_diag=.true. \n / \n&test_reduction_methods_nml \n test_case = 1 \n \n/" | cat > input.nml
test_expect_success "Running diag_manager with "none" reduction method with openmp (test $my_test_count)" '
  mpirun -n 6 ../test_reduction_methods
'
test_expect_success "Checking answers for the "none" reduction method with openmp (test $my_test_count)" '
  mpirun -n 1 ../check_time_none
'

my_test_count=`expr $my_test_count + 1`
printf "&diag_manager_nml \n use_modern_diag=.true. \n / \n&test_reduction_methods_nml \n test_case = 1 \n mask_case = 1 \n \n/" | cat > input.nml
test_expect_success "Running diag_manager with "none" reduction method with openmp, logical mask (test $my_test_count)" '
  mpirun -n 6 ../test_reduction_methods
'
test_expect_success "Checking answers for the "none" reduction method with openmp, logical mask (test $my_test_count)" '
  mpirun -n 1 ../check_time_none
'

my_test_count=`expr $my_test_count + 1`
printf "&diag_manager_nml \n use_modern_diag=.true. \n / \n&test_reduction_methods_nml \n test_case = 1 \n mask_case = 2 \n \n/" | cat > input.nml
test_expect_success "Running diag_manager with "none" reduction method with openmp, real mask (test $my_test_count)" '
  mpirun -n 6 ../test_reduction_methods
'
test_expect_success "Checking answers for the "none" reduction method with openmp, real mask (test $my_test_count)" '
  mpirun -n 1 ../check_time_none
'
export OMP_NUM_THREADS=1

my_test_count=`expr $my_test_count + 1`
printf "&diag_manager_nml \n use_modern_diag=.true. \n / \n&test_reduction_methods_nml \n test_case = 2 \n \n/" | cat > input.nml
test_expect_success "Running diag_manager with "none" reduction method with halo output (test $my_test_count)" '
  mpirun -n 6 ../test_reduction_methods
'
test_expect_success "Checking answers for the "none" reduction method with halo output (test $my_test_count)" '
  mpirun -n 1 ../check_time_none
'

my_test_count=`expr $my_test_count + 1`
printf "&diag_manager_nml \n use_modern_diag=.true. \n / \n&test_reduction_methods_nml \n test_case = 2 \n mask_case = 1 \n \n/" | cat > input.nml
test_expect_success "Running diag_manager with "none" reduction method with halo output with logical mask (test $my_test_count)" '
  mpirun -n 6 ../test_reduction_methods
'
test_expect_success "Checking answers for the "none" reduction method with halo output with logical mask (test $my_test_count)" '
  mpirun -n 1 ../check_time_none
'

my_test_count=`expr $my_test_count + 1`
printf "&diag_manager_nml \n use_modern_diag=.true. \n / \n&test_reduction_methods_nml \n test_case = 2 \n mask_case = 2 \n \n/" | cat > input.nml
test_expect_success "Running diag_manager with "none" reduction method with halo output with real mask (test $my_test_count)" '
  mpirun -n 6 ../test_reduction_methods
'
test_expect_success "Checking answers for the "none" reduction method with halo output with real mask (test $my_test_count)" '
  mpirun -n 1 ../check_time_none
'
fi
test_done
