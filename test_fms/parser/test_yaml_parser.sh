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

# This is part of the GFDL FMS package. This is a shell script to
# execute tests in the test_fms/parser directory.

# Set common test settings.
. ../test_common.sh

touch input.nml

run_test test_yaml_parser 1 $parser_skip
run_test parser_demo 1 $parser_skip
run_test parser_demo2 1 $parser_skip

printf "&check_crashes_nml \n missing_file = .true. \n/" | cat > input.nml
run_test check_crashes 1 $parser_skip && echo "It worked?"
if [ $? -eq 0 ]; then
  echo "The test should have failed"
  exit 3
fi

printf "&check_crashes_nml \n bad_conversion = .true. \n/" | cat > input.nml
run_test check_crashes 1 $parser_skip && echo "It worked?"
if [ $? -eq 0 ]; then
  echo "The test should have failed"
  exit 3
fi

printf "&check_crashes_nml \n missing_key = .true. \n/" | cat > input.nml
run_test check_crashes 1 $parser_skip && echo "It worked?"
if [ $? -eq 0 ]; then
  echo "The test should have failed"
  exit 3
fi

printf "&check_crashes_nml \n get_block_ids_bad_id = .true. \n/" | cat > input.nml
run_test check_crashes 1 $parser_skip && echo "It worked?"
if [ $? -eq 0 ]; then
  echo "The test should have failed"
  exit 3
fi

printf "&check_crashes_nml \n get_num_blocks_bad_id = .true. \n/" | cat > input.nml
run_test check_crashes 1 $parser_skip && echo "It worked?"
if [ $? -eq 0 ]; then
  echo "The test should have failed"
  exit 3
fi

printf "&check_crashes_nml \n get_nkeys_bad_id = .true. \n/" | cat > input.nml
run_test check_crashes 1 $parser_skip && echo "It worked?"
if [ $? -eq 0 ]; then
  echo "The test should have failed"
  exit 3
fi

printf "&check_crashes_nml \n get_key_ids_bad_id = .true. \n/" | cat > input.nml
run_test check_crashes 1 $parser_skip && echo "It worked?"
if [ $? -eq 0 ]; then
  echo "The test should have failed"
  exit 3
fi

printf "&check_crashes_nml \n get_key_name_bad_id = .true. \n/" | cat > input.nml
run_test check_crashes 1 $parser_skip && echo "It worked?"
if [ $? -eq 0 ]; then
  echo "The test should have failed"
  exit 3
fi

printf "&check_crashes_nml \n get_key_value_bad_id = .true. \n/" | cat > input.nml
run_test check_crashes 1 $parser_skip && echo "It worked?"
if [ $? -eq 0 ]; then
  echo "The test should have failed"
  exit 3
fi

printf "&check_crashes_nml \n get_value_from_key_bad_id = .true. \n/" | cat > input.nml
run_test check_crashes 1 $parser_skip && echo "It worked?"
if [ $? -eq 0 ]; then
  echo "The test should have failed"
  exit 3
fi

printf "&check_crashes_nml \n get_key_name_bad_key_id = .true. \n/" | cat > input.nml
run_test check_crashes 1 $parser_skip && echo "It worked?"
if [ $? -eq 0 ]; then
  echo "The test should have failed"
  exit 3
fi

printf "&check_crashes_nml \n get_key_value_bad_key_id = .true. \n/" | cat > input.nml
run_test check_crashes 1 $parser_skip && echo "It worked?"
if [ $? -eq 0 ]; then
  echo "The test should have failed"
  exit 3
fi

###
printf "&check_crashes_nml \n get_key_ids_bad_block_id = .true. \n/" | cat > input.nml
run_test check_crashes 1 $parser_skip && echo "It worked?"
if [ $? -eq 0 ]; then
  echo "The test should have failed"
  exit 3
fi

printf "&check_crashes_nml \n get_nkeys_bad_block_id = .true. \n/" | cat > input.nml
run_test check_crashes 1 $parser_skip && echo "It worked?"
if [ $? -eq 0 ]; then
  echo "The test should have failed"
  exit 3
fi

printf "&check_crashes_nml \n get_block_ids_bad_block_id = .true. \n/" | cat > input.nml
run_test check_crashes 1 $parser_skip && echo "It worked?"
if [ $? -eq 0 ]; then
  echo "The test should have failed"
  exit 3
fi

printf "&check_crashes_nml \n get_num_blocks_bad_block_id = .true. \n/" | cat > input.nml
run_test check_crashes 1 $parser_skip && echo "It worked?"
if [ $? -eq 0 ]; then
  echo "The test should have failed"
  exit 3
fi

printf "&check_crashes_nml \n get_value_from_key_bad_block_id = .true. \n/" | cat > input.nml
run_test check_crashes 1 $parser_skip && echo "It worked?"
if [ $? -eq 0 ]; then
  echo "The test should have failed"
  exit 3
fi

printf "&check_crashes_nml \n wrong_buffer_size_key_id = .true. \n/" | cat > input.nml
run_test check_crashes 1 && echo "It worked?"
if [ $? -eq 0 ]; then
  echo "The test should have failed"
  exit 3
fi

printf "&check_crashes_nml \n wrong_buffer_size_block_id = .true. \n/" | cat > input.nml
run_test check_crashes 1 && echo "It worked?"
if [ $? -eq 0 ]; then
  echo "The test should have failed"
  exit 3
fi
