!> @file

!> @brief Create a netcdf type, which can be extended to meet
!!        our various I/O needs.
module netcdf_io_mod
use, intrinsic :: iso_fortran_env, only: int32, int64, real32, real64
use netcdf
use mpp_mod
use fms_io_utils_mod
use platform_mod
implicit none
private


!Module constants.
integer, parameter :: variable_missing = -1
integer, parameter :: dimension_missing = -1
integer, parameter, public :: no_unlimited_dimension = -1 !> No unlimited dimension in file.
character(len=1), parameter :: missing_path = ""
integer, parameter :: missing_ncid = -1
integer, parameter :: missing_rank = -1
integer, parameter, public :: define_mode = 0
integer, parameter, public :: data_mode = 1
integer, parameter, public :: max_num_restart_vars = 200
integer, parameter, public :: unlimited = nf90_unlimited !> Wrapper to specify unlimited dimension.
integer, parameter :: dimension_not_found = 0
integer, parameter, public :: max_num_compressed_dims = 10 !> Maximum number of compressed
                                                           !! dimensions allowed.


!> @brief Restart variable.
type :: RestartVariable_t
  character(len=256) :: varname !< Variable name.
  class(*), pointer :: data0d => null() !< Scalar data pointer.
  class(*), dimension(:), pointer :: data1d => null() !< 1d data pointer.
  class(*), dimension(:,:), pointer :: data2d => null() !< 2d data pointer.
  class(*), dimension(:,:,:), pointer :: data3d => null() !< 3d data pointer.
  class(*), dimension(:,:,:,:), pointer :: data4d => null() !< 4d data pointer.
  class(*), dimension(:,:,:,:,:), pointer :: data5d => null() !< 5d data pointer.
  logical :: was_read !< Flag to support legacy "query_initialized" feature, which
                      !! keeps track if a file was read.
endtype RestartVariable_t


!> @brief Compressed dimension.
type :: CompressedDimension_t
  character(len=256) :: dimname !< Dimension name.
  integer, dimension(:), allocatable :: npes_corner !< Array of starting
                                                    !! indices for each rank.
  integer, dimension(:), allocatable :: npes_nelems !< Number of elements
                                                    !! associated with each
                                                    !! rank.
  integer :: nelems !< Total size of the dimension.
endtype CompressedDimension_t


!> @brief Netcdf file type.
type, public :: FmsNetcdfFile_t
  character(len=256) :: path !< File path.
  logical :: is_readonly !< Flag telling if the file is readonly.
  integer :: ncid !< Netcdf file id.
  character(len=256) :: nc_format !< Netcdf file format.
  integer, dimension(:), allocatable :: pelist !< List of ranks who will
                                               !! communicate.
  integer :: io_root !< I/O root rank of the pelist.
  logical :: is_root !< Flag telling if the current rank is the
                     !! I/O root.
  logical :: is_restart !< Flag telling if the this file is a restart
                        !! file (that has internal pointers to data).
  logical :: mode_is_append !! true if file is open in "append" mode
  logical, allocatable :: is_open !< Allocated and set to true if opened.
  type(RestartVariable_t), dimension(:), allocatable :: restart_vars !< Array of registered
                                                                     !! restart variables.
  integer :: num_restart_vars !< Number of registered restart variables.
  type(CompressedDimension_t), dimension(:), allocatable :: compressed_dims !< "Compressed" dimension.
  integer :: num_compressed_dims !< Number of compressed dimensions.
  logical :: is_diskless !< Flag telling whether this is a diskless file.
  character (len=20) :: time_name
endtype FmsNetcdfFile_t


!> @brief Range type for a netcdf variable.
type, public :: Valid_t
  logical :: has_range !< Flag that's true if both min/max exist for a variable.
  logical :: has_min !< Flag that's true if min exists for a variable.
  logical :: has_max !< Flag that's true if max exists for a variable.
  logical :: has_fill !< Flag that's true a user defined fill value.
  logical :: has_missing !< Flag that's true a user defined missing value.
  real(kind=real64) :: fill_val !< Unpacked fill value for a variable.
  real(kind=real64) :: min_val !< Unpacked minimum value allowed for a variable.
  real(kind=real64) :: max_val !< Unpacked maximum value allowed for a variable.
  real(kind=real64) :: missing_val !< Unpacked missing value for a variable.
endtype Valid_t


public :: netcdf_file_open
public :: netcdf_file_close
public :: netcdf_add_dimension
public :: netcdf_add_variable
public :: netcdf_add_restart_variable
public :: global_att_exists
public :: variable_att_exists
public :: register_global_attribute
public :: register_variable_attribute
public :: get_global_attribute
public :: get_variable_attribute
public :: get_num_dimensions
public :: get_dimension_names
public :: dimension_exists
public :: is_dimension_unlimited
public :: get_dimension_size
public :: get_num_variables
public :: get_variable_names
public :: variable_exists
public :: get_variable_num_dimensions
public :: get_variable_dimension_names
public :: get_variable_size
public :: get_variable_unlimited_dimension_index
public :: netcdf_read_data
public :: netcdf_write_data
public :: compressed_write
public :: netcdf_save_restart
public :: netcdf_restore_state
public :: get_valid
public :: is_valid
public :: get_unlimited_dimension_name
public :: netcdf_file_open_wrap
public :: netcdf_file_close_wrap
public :: netcdf_add_variable_wrap
public :: netcdf_save_restart_wrap
public :: compressed_write_0d_wrap
public :: compressed_write_1d_wrap
public :: compressed_write_2d_wrap
public :: compressed_write_3d_wrap
public :: compressed_write_4d_wrap
public :: compressed_write_5d_wrap
public :: compressed_read_0d
public :: compressed_read_1d
public :: compressed_read_2d
public :: compressed_read_3d
public :: compressed_read_4d
public :: compressed_read_5d
public :: register_compressed_dimension
public :: netcdf_add_restart_variable_0d_wrap
public :: netcdf_add_restart_variable_1d_wrap
public :: netcdf_add_restart_variable_2d_wrap
public :: netcdf_add_restart_variable_3d_wrap
public :: netcdf_add_restart_variable_4d_wrap
public :: netcdf_add_restart_variable_5d_wrap
public :: compressed_start_and_count
public :: get_fill_value
public :: get_variable_sense
public :: get_variable_missing
public :: get_variable_units
public :: get_time_calendar
public :: is_registered_to_restart
public :: set_netcdf_mode
public :: check_netcdf_code
public :: check_if_open
public :: set_fileobj_time_name

interface netcdf_add_restart_variable
  module procedure netcdf_add_restart_variable_0d
  module procedure netcdf_add_restart_variable_1d
  module procedure netcdf_add_restart_variable_2d
  module procedure netcdf_add_restart_variable_3d
  module procedure netcdf_add_restart_variable_4d
  module procedure netcdf_add_restart_variable_5d
end interface netcdf_add_restart_variable


interface netcdf_read_data
  module procedure netcdf_read_data_0d
  module procedure netcdf_read_data_1d
  module procedure netcdf_read_data_2d
  module procedure netcdf_read_data_3d
  module procedure netcdf_read_data_4d
  module procedure netcdf_read_data_5d
end interface netcdf_read_data


interface netcdf_write_data
  module procedure netcdf_write_data_0d
  module procedure netcdf_write_data_1d
  module procedure netcdf_write_data_2d
  module procedure netcdf_write_data_3d
  module procedure netcdf_write_data_4d
  module procedure netcdf_write_data_5d
end interface netcdf_write_data


interface compressed_write
  module procedure compressed_write_0d
  module procedure compressed_write_1d
  module procedure compressed_write_2d
  module procedure compressed_write_3d
  module procedure compressed_write_4d
  module procedure compressed_write_5d
end interface compressed_write


interface register_global_attribute
  module procedure register_global_attribute_0d
  module procedure register_global_attribute_1d
end interface register_global_attribute


interface register_variable_attribute
  module procedure register_variable_attribute_0d
  module procedure register_variable_attribute_1d
end interface register_variable_attribute


interface get_global_attribute
  module procedure get_global_attribute_0d
  module procedure get_global_attribute_1d
end interface get_global_attribute


interface get_variable_attribute
  module procedure get_variable_attribute_0d
  module procedure get_variable_attribute_1d
end interface get_variable_attribute


contains


!> @brief Check for errors returned by netcdf.
!! @internal
subroutine check_netcdf_code(err)

  integer, intent(in) :: err !< Code returned by netcdf.

  character(len=80) :: buf

  if (err .ne. nf90_noerr) then
    buf = nf90_strerror(err)
    call error(trim(buf))
  endif
end subroutine check_netcdf_code


!> @brief Switch to the correct netcdf mode.
!! @internal
subroutine set_netcdf_mode(ncid, mode)

  integer, intent(in) :: ncid !< Netcdf file id.
  integer, intent(in) :: mode !< Netcdf file mode.

  integer :: err

  if (mode .eq. define_mode) then
    err = nf90_redef(ncid)
    if (err .eq. nf90_eindefine .or. err .eq. nf90_eperm) then
      return
    endif
  elseif (mode .eq. data_mode) then
    err = nf90_enddef(ncid)
    if (err .eq. nf90_enotindefine .or. err .eq. nf90_eperm) then
      return
    endif
  else
    call error("mode must be either define_mode or data_mode.")
  endif
  call check_netcdf_code(err)
end subroutine set_netcdf_mode


!> @brief Get the id of a dimension from its name.
!! @return Dimension id, or dimension_missing if it doesn't exist.
!! @internal
function get_dimension_id(ncid, dimension_name, allow_failure) &
  result(dimid)

  integer, intent(in) :: ncid !< Netcdf file id.
  character(len=*), intent(in) :: dimension_name !< Dimension name.
  logical, intent(in), optional :: allow_failure !< Flag that prevents
                                                 !! crash if dimension
                                                 !! does not exist.
  integer :: dimid

  integer :: err

  err = nf90_inq_dimid(ncid, trim(dimension_name), dimid)
  if (present(allow_failure)) then
    if (allow_failure .and. err .eq. nf90_ebaddim) then
      dimid = dimension_missing
      return
    endif
  endif
  call check_netcdf_code(err)
end function get_dimension_id


!> @brief Get the id of a variable from its name.
!! @return Variable id, or variable_missing if it doesn't exist.
!! @internal
function get_variable_id(ncid, variable_name, allow_failure) &
  result(varid)

  integer, intent(in) :: ncid !< Netcdf file object.
  character(len=*), intent(in) :: variable_name !< Variable name.
  logical, intent(in), optional :: allow_failure !< Flag that prevents
                                                 !! crash if variable does
                                                 !! not exist.
  integer :: varid

  integer :: err

  err = nf90_inq_varid(ncid, trim(variable_name), varid)
  if (present(allow_failure)) then
    if (allow_failure .and. err .eq. nf90_enotvar) then
      varid = variable_missing
      return
    endif
  endif
  call check_netcdf_code(err)
end function get_variable_id


!> @brief Determine if an attribute exists.
!! @return Flag telling if the attribute exists.
!! @internal
function attribute_exists(ncid, varid, attribute_name) &
  result(att_exists)

  integer, intent(in) :: ncid !< Netcdf file id.
  integer, intent(in) :: varid !< Variable id.
  character(len=*), intent(in) :: attribute_name !< Attribute name.
  logical :: att_exists

  integer :: err

  err = nf90_inquire_attribute(ncid, varid, trim(attribute_name))
  if (err .eq. nf90_enotatt) then
    att_exists = .false.
  else
    call check_netcdf_code(err)
    att_exists = .true.
  endif
end function attribute_exists


!> @brief Get the type of a netcdf attribute.
!! @return The netcdf type of the attribute.
!! @internal
function get_attribute_type(ncid, varid, attname) &
  result(xtype)

  integer, intent(in) :: ncid !< Netcdf file id.
  integer, intent(in) :: varid !< Variable id.
  character(len=*), intent(in) :: attname !< Attribute name.
  integer :: xtype

  integer :: err

  err = nf90_inquire_attribute(ncid, varid, attname, xtype=xtype)
  call check_netcdf_code(err)
end function get_attribute_type


!> @brief Get the type of a netcdf variable.
!! @return The netcdf type of the variable.
!! @internal
function get_variable_type(ncid, varid) &
  result(xtype)

  integer, intent(in) :: ncid !< Netcdf file id.
  integer, intent(in) :: varid !< Variable id.
  integer :: xtype

  integer :: err

  err = nf90_inquire_variable(ncid, varid, xtype=xtype)
  call check_netcdf_code(err)
end function get_variable_type


!> @brief Open a netcdf file.
!! @return .true. if open succeeds, or else .false.
function netcdf_file_open(fileobj, path, mode, nc_format, pelist, is_restart) &
  result(success)

  class(FmsNetcdfFile_t), intent(inout) :: fileobj !< File object.
  character(len=*), intent(in) :: path !< File path.
  character(len=*), intent(in) :: mode !< File mode.  Allowed values are:
                                       !! "read", "append", "write", or
                                       !! "overwrite".
  character(len=*), intent(in), optional :: nc_format !< Netcdf format that
                                                     !! new files are written
                                                     !! as.  Allowed values
                                                     !! are: "64bit", "classic",
                                                     !! or "netcdf4". Defaults to
                                                     !! "64bit".
  integer, dimension(:), intent(in), optional :: pelist !< List of ranks associated
                                                        !! with this file.  If not
                                                        !! provided, only the current
                                                        !! rank will be able to
                                                        !! act on the file.
  logical, intent(in), optional :: is_restart !< Flag telling if this file
                                              !! is a restart file.  Defaults
                                              !! to false.
  logical :: success

  integer :: nc_format_param
  integer :: err
  character(len=256) :: buf
  logical :: is_res

  if (allocated(fileobj%is_open)) then
    if (fileobj%is_open) then
      success = .true.
      return
    endif
  endif
  !Add ".res" to the file path if necessary.
  is_res = .false.
  if (present(is_restart)) then
    is_res = is_restart
  endif
  if (is_res) then
    call restart_filepath_mangle(buf, trim(path))
  else
    call string_copy(buf, trim(path))
  endif

  !Check if the file exists.
  success = .true.
  if (string_compare(mode, "read", .true.) .or. string_compare(mode, "append", .true.)) then
    success = file_exists(buf)
    if (.not. success) then
      return
    endif
  endif

  !Store properties in the derived type.
  call string_copy(fileobj%path, trim(buf))
  if (present(pelist)) then
    allocate(fileobj%pelist(size(pelist)))
    fileobj%pelist(:) = pelist(:)
  else
    allocate(fileobj%pelist(1))
    fileobj%pelist(1) = mpp_pe()
  endif
  fileobj%io_root = fileobj%pelist(1)
  fileobj%is_root = mpp_pe() .eq. fileobj%io_root

  !Open the file with netcdf if this rank is the I/O root.
  if (fileobj%is_root) then
    nc_format_param = nf90_64bit_offset
    call string_copy(fileobj%nc_format, "64bit")
    if (present(nc_format)) then
      if (string_compare(nc_format, "64bit", .true.)) then
        nc_format_param = nf90_64bit_offset
      elseif (string_compare(nc_format, "classic", .true.)) then
        nc_format_param = nf90_classic_model
      elseif (string_compare(nc_format, "netcdf4", .true.)) then
        nc_format_param = nf90_hdf5
      else
        call error("unrecognized netcdf file format "//trim(nc_format)//".")
      endif
      call string_copy(fileobj%nc_format, nc_format)
    endif
    if (string_compare(mode, "read", .true.)) then
      err = nf90_open(trim(fileobj%path), nf90_nowrite, fileobj%ncid)
    elseif (string_compare(mode, "append", .true.)) then
      err = nf90_open(trim(fileobj%path), nf90_write, fileobj%ncid)
    elseif (string_compare(mode, "write", .true.)) then
      err = nf90_create(trim(fileobj%path), ior(nf90_noclobber, nc_format_param), fileobj%ncid)
    elseif (string_compare(mode,"overwrite",.true.)) then
      err = nf90_create(trim(fileobj%path), ior(nf90_clobber, nc_format_param), fileobj%ncid)
    else
      call error("unrecognized file mode "//trim(mode)//".")
    endif
    call check_netcdf_code(err)
  else
    fileobj%ncid = missing_ncid
  endif

  fileobj%is_diskless = .false.

  !Allocate memory.
  fileobj%is_restart = is_res
  if (fileobj%is_restart) then
    allocate(fileobj%restart_vars(max_num_restart_vars))
    fileobj%num_restart_vars = 0
  endif
  fileobj%is_readonly = string_compare(mode, "read", .true.)
  fileobj%mode_is_append = string_compare(mode, "append", .true.)
  allocate(fileobj%compressed_dims(max_num_compressed_dims))
  fileobj%num_compressed_dims = 0
  ! Set the is_open flag to true for this file object.
  if (.not.allocated(fileobj%is_open)) allocate(fileobj%is_open)
  fileobj%is_open = .true.
end function netcdf_file_open


!> @brief Close a netcdf file.
subroutine netcdf_file_close(fileobj)

  class(FmsNetcdfFile_t),intent(inout) :: fileobj !< File object.

  integer :: err
  integer :: i

  if (fileobj%is_root) then
    err = nf90_close(fileobj%ncid)
    call check_netcdf_code(err)
  endif
  if (allocated(fileobj%is_open)) fileobj%is_open = .false.
  fileobj%path = missing_path
  fileobj%ncid = missing_ncid
  if (allocated(fileobj%pelist)) then
    deallocate(fileobj%pelist)
  endif
  fileobj%io_root = missing_rank
  fileobj%is_root = .false.
  if (allocated(fileobj%restart_vars)) then
    deallocate(fileobj%restart_vars)
  endif
  fileobj%is_restart = .false.
  fileobj%num_restart_vars = 0
  do i = 1, fileobj%num_compressed_dims
    if (allocated(fileobj%compressed_dims(i)%npes_corner)) then
      deallocate(fileobj%compressed_dims(i)%npes_corner)
    endif
    if (allocated(fileobj%compressed_dims(i)%npes_nelems)) then
      deallocate(fileobj%compressed_dims(i)%npes_nelems)
    endif
  enddo
  if (allocated(fileobj%compressed_dims)) then
    deallocate(fileobj%compressed_dims)
  endif
end subroutine netcdf_file_close


!> @brief Get the index of a compressed dimension in a file object.
!! @return Index of the compressed dimension.
!! @internal
function get_compressed_dimension_index(fileobj, dim_name) &
  result(dindex)

  class(FmsNetcdfFile_t), intent(in) :: fileobj !< File object.
  character(len=*), intent(in) :: dim_name !< Dimension name.

  integer :: dindex
  integer :: i

  dindex = dimension_not_found
  do i = 1, fileobj%num_compressed_dims
    if (string_compare(fileobj%compressed_dims(i)%dimname, dim_name)) then
      dindex = i
      return
    endif
  enddo
end function get_compressed_dimension_index


!> @brief Add a compressed dimension to a file object.
!! @internal
subroutine append_compressed_dimension(fileobj, dim_name, npes_corner, &
                                       npes_nelems)

  class(FmsNetcdfFile_t), intent(inout) :: fileobj !< File object.
  character(len=*), intent(in) :: dim_name !< Dimension name.
  integer, dimension(:), intent(in) :: npes_corner !< Array of starting
                                                   !! indices for each rank.
  integer, dimension(:), intent(in) :: npes_nelems !< Number of elements
                                                   !! associated with each
                                                   !! rank.

  integer :: n

  if (get_compressed_dimension_index(fileobj, dim_name) .ne. dimension_not_found) then
    call error("dimension "//trim(dim_name)//" already registered" &
               //" to file "//trim(fileobj%path)//".")
  endif
  fileobj%num_compressed_dims = fileobj%num_compressed_dims + 1
  n = fileobj%num_compressed_dims
  if (n .gt. max_num_compressed_dims) then
    call error("number of compressed dimensions exceeds limit.")
  endif
  call string_copy(fileobj%compressed_dims(n)%dimname, dim_name)
  if (size(npes_corner) .ne. size(fileobj%pelist) .or. &
      size(npes_nelems) .ne. size(fileobj%pelist)) then
    call error("incorrect size for input npes_corner or npes_nelems arrays.")
  endif
  allocate(fileobj%compressed_dims(n)%npes_corner(size(fileobj%pelist)))
  fileobj%compressed_dims(n)%npes_corner(:) = npes_corner(:)
  allocate(fileobj%compressed_dims(n)%npes_nelems(size(fileobj%pelist)))
  fileobj%compressed_dims(n)%npes_nelems(:) = npes_nelems(:)
  fileobj%compressed_dims(n)%nelems = sum(fileobj%compressed_dims(n)%npes_nelems)
end subroutine append_compressed_dimension


!> @brief Add a dimension to a file.
subroutine netcdf_add_dimension(fileobj, dimension_name, dimension_length, &
                                is_compressed)

  class(FmsNetcdfFile_t), intent(inout) :: fileobj !< File object.
  character(len=*), intent(in) :: dimension_name !< Dimension name.
  integer, intent(in) :: dimension_length !< Dimension length.
  logical, intent(in), optional :: is_compressed !< Changes the meaning of dim_len from
                                                 !! referring to the total size of the
                                                 !! dimension (when false) to the local
                                                 !! size for the current rank (when true).

  integer :: dim_len
  integer, dimension(:), allocatable :: npes_start
  integer, dimension(:), allocatable :: npes_count
  integer :: i
  integer :: err
  integer :: dimid

  dim_len = dimension_length
  if (present(is_compressed)) then
    if (is_compressed) then
      !Gather all local dimension lengths on the I/O root pe.
      allocate(npes_start(size(fileobj%pelist)))
      allocate(npes_count(size(fileobj%pelist)))
      do i = 1, size(fileobj%pelist)
        if (fileobj%pelist(i) .eq. mpp_pe()) then
          npes_count(i) = dim_len
        else
          call mpp_recv(npes_count(i), fileobj%pelist(i), block=.false.)
          call mpp_send(dim_len, fileobj%pelist(i))
        endif
      enddo
      call mpp_sync_self(check=event_recv)
      call mpp_sync_self(check=event_send)
      npes_start(1) = 1
      do i = 1, size(fileobj%pelist)-1
        npes_start(i+1) = npes_start(i) + npes_count(i)
      enddo
      call append_compressed_dimension(fileobj, dimension_name, npes_start, &
                                       npes_count)
      dim_len = sum(npes_count)
    endif
  endif
  if (fileobj%is_root .and. .not. fileobj%is_readonly) then
    call set_netcdf_mode(fileobj%ncid, define_mode)
    err = nf90_def_dim(fileobj%ncid, trim(dimension_name), dim_len, dimid)
    call check_netcdf_code(err)
  endif
end subroutine netcdf_add_dimension


!> @brief Add a compressed dimension.
subroutine register_compressed_dimension(fileobj, dimension_name, &
                                         npes_corner, npes_nelems)

  class(FmsNetcdfFile_t), intent(inout) :: fileobj !< File object.
  character(len=*), intent(in) :: dimension_name !< Dimension name.
  integer, dimension(:), intent(in) :: npes_corner !< Array of starting
                                                   !! indices for each rank.
  integer, dimension(:), intent(in) :: npes_nelems !< Number of elements
                                                   !! associated with each
                                                   !! rank.

  integer :: dsize
  integer :: fdim_size

  call append_compressed_dimension(fileobj, dimension_name, npes_corner, npes_nelems)
  dsize = sum(npes_nelems)
  if (fileobj%is_readonly) then
    call get_dimension_size(fileobj, dimension_name, fdim_size, broadcast=.true.)
    if (fdim_size .ne. dsize) then
      call error("dimension "//trim(dimension_name)//" does not match" &
                 //" the size of the associated compressed axis.")
    endif
  else
    call netcdf_add_dimension(fileobj, dimension_name, dsize)
  endif
end subroutine register_compressed_dimension


!> @brief Add a variable to a file.
subroutine netcdf_add_variable(fileobj, variable_name, variable_type, dimensions)

  class(FmsNetcdfFile_t), intent(in) :: fileobj !< File object.
  character(len=*), intent(in) :: variable_name !< Variable name.
  character(len=*), intent(in) :: variable_type !< Variable type.  Allowed
                                                !! values are: "char", "int", "int64",
                                                !! "float", or "double".
  character(len=*), dimension(:), intent(in), optional :: dimensions !< Dimension names.

  integer :: err
  integer, dimension(:), allocatable :: dimids
  integer :: vtype
  integer :: varid
  integer :: i

  if (fileobj%is_root) then
    call set_netcdf_mode(fileobj%ncid, define_mode)
    if (string_compare(variable_type, "int", .true.)) then
      vtype = nf90_int
    elseif (string_compare(variable_type, "int64", .true.)) then
      vtype = nf90_int64
    elseif (string_compare(variable_type, "float", .true.)) then
      vtype = nf90_float
    elseif (string_compare(variable_type, "double", .true.)) then
      vtype = nf90_double
    elseif (string_compare(variable_type, "char", .true.)) then
      vtype = nf90_char
      if (.not. present(dimensions)) then
        call error("string variables require a string length dimension.")
      endif
    else
      call error("unsupported type.")
    endif
    if (present(dimensions)) then
      allocate(dimids(size(dimensions)))
      do i = 1, size(dimids)
        dimids(i) = get_dimension_id(fileobj%ncid, trim(dimensions(i)))
      enddo
      err = nf90_def_var(fileobj%ncid, trim(variable_name), vtype, dimids, varid)
      deallocate(dimids)
    else
      err = nf90_def_var(fileobj%ncid, trim(variable_name), vtype, varid)
    endif
    call check_netcdf_code(err)
  endif
end subroutine netcdf_add_variable


!> @brief Given a compressed variable, get the index of the compressed
!!        dimension.
!! @return Index of the compressed dimension or dimension_not_found.
function get_variable_compressed_dimension_index(fileobj, variable_name, broadcast) &
  result(compressed_dimension_index)

  class(FmsNetcdfFile_t), intent(in) :: fileobj !< File object.
  character(len=*), intent(in) :: variable_name !< Variable name.
  logical, intent(in), optional :: broadcast !< Flag controlling whether or
                                             !! not the data will be
                                             !! broadcasted to non
                                             !! "I/O root" ranks.
                                             !! The broadcast will be done
                                             !! by default.
  integer, dimension(2) :: compressed_dimension_index

  integer :: ndims
  character(len=nf90_max_name), dimension(:), allocatable :: dim_names
  integer :: i
  integer :: j

  compressed_dimension_index = dimension_not_found
  if (fileobj%is_root) then
    ndims = get_variable_num_dimensions(fileobj, variable_name, broadcast=.false.)
    if (ndims .gt. 0) then
      allocate(dim_names(ndims))
      call get_variable_dimension_names(fileobj, variable_name, dim_names, broadcast=.false.)
      do i = 1, size(dim_names)
        j = get_compressed_dimension_index(fileobj,dim_names(i))
        if (j .ne. dimension_not_found) then
          compressed_dimension_index(1) = i
          compressed_dimension_index(2) = j
          exit
        endif
      enddo
      deallocate(dim_names)
    endif
  endif
  if (present(broadcast)) then
    if (.not. broadcast) then
      return
    endif
  endif
  call mpp_broadcast(compressed_dimension_index(1), fileobj%io_root, pelist=fileobj%pelist)
end function get_variable_compressed_dimension_index


!> @brief Add a restart variable to a FmsNetcdfFile_t type.
!! @internal
subroutine add_restart_var_to_array(fileobj, variable_name)

  class(FmsNetcdfFile_t), intent(inout) :: fileobj !< Netcdf file object.
  character(len=*), intent(in) :: variable_name !< Variable name.

  integer :: i

  if (.not. fileobj%is_restart) then
    call error("file "//trim(fileobj%path)//" is not a restart file.")
  endif
  do i = 1, fileobj%num_restart_vars
    if (string_compare(fileobj%restart_vars(i)%varname, variable_name, .true.)) then
      call error("variable "//trim(variable_name)//" has already" &
                 //" been added to restart file "//trim(fileobj%path)//".")
    endif
  enddo
  fileobj%num_restart_vars = fileobj%num_restart_vars + 1
  if (fileobj%num_restart_vars .gt. max_num_restart_vars) then
    call error("Number of restart variables exceeds limit.")
  endif
  call string_copy(fileobj%restart_vars(fileobj%num_restart_vars)%varname, &
                   variable_name)
end subroutine add_restart_var_to_array


!> @brief Loop through registered restart variables and write them to
!!        a netcdf file.
subroutine netcdf_save_restart(fileobj, unlim_dim_level)

  class(FmsNetcdfFile_t), intent(in) :: fileobj !< File object.
  integer, intent(in), optional :: unlim_dim_level !< Unlimited dimension
                                                     !! level.

  integer :: i

  if (.not. fileobj%is_restart) then
    call error("file "//trim(fileobj%path)//" is not a restart file.")
  endif
  do i = 1, fileobj%num_restart_vars
    if (associated(fileobj%restart_vars(i)%data0d)) then
      call compressed_write(fileobj, fileobj%restart_vars(i)%varname, &
                            fileobj%restart_vars(i)%data0d, &
                            unlim_dim_level=unlim_dim_level)
    elseif (associated(fileobj%restart_vars(i)%data1d)) then
      call compressed_write(fileobj, fileobj%restart_vars(i)%varname, &
                            fileobj%restart_vars(i)%data1d, &
                            unlim_dim_level=unlim_dim_level)
    elseif (associated(fileobj%restart_vars(i)%data2d)) then
      call compressed_write(fileobj, fileobj%restart_vars(i)%varname, &
                            fileobj%restart_vars(i)%data2d, &
                            unlim_dim_level=unlim_dim_level)
    elseif (associated(fileobj%restart_vars(i)%data3d)) then
      call compressed_write(fileobj, fileobj%restart_vars(i)%varname, &
                            fileobj%restart_vars(i)%data3d, &
                            unlim_dim_level=unlim_dim_level)
    elseif (associated(fileobj%restart_vars(i)%data4d)) then
      call compressed_write(fileobj, fileobj%restart_vars(i)%varname, &
                            fileobj%restart_vars(i)%data4d, &
                            unlim_dim_level=unlim_dim_level)
    else
      call error("this branch should not be reached.")
    endif
  enddo
end subroutine netcdf_save_restart


!> @brief Loop through registered restart variables and read them from
!!        a netcdf file.
subroutine netcdf_restore_state(fileobj, unlim_dim_level)

  type(FmsNetcdfFile_t), intent(in) :: fileobj !< File object.
  integer, intent(in), optional :: unlim_dim_level !< Unlimited dimension
                                                   !! level.

  integer :: i

  if (.not. fileobj%is_restart) then
    call error("file "//trim(fileobj%path)//" is not a restart file.")
  endif
  do i = 1, fileobj%num_restart_vars
    if (associated(fileobj%restart_vars(i)%data0d)) then
      call netcdf_read_data(fileobj, fileobj%restart_vars(i)%varname, &
                            fileobj%restart_vars(i)%data0d, &
                            unlim_dim_level=unlim_dim_level, &
                            broadcast=.true.)
    elseif (associated(fileobj%restart_vars(i)%data1d)) then
      call netcdf_read_data(fileobj, fileobj%restart_vars(i)%varname, &
                            fileobj%restart_vars(i)%data1d, &
                            unlim_dim_level=unlim_dim_level, &
                            broadcast=.true.)
    elseif (associated(fileobj%restart_vars(i)%data2d)) then
      call netcdf_read_data(fileobj, fileobj%restart_vars(i)%varname, &
                            fileobj%restart_vars(i)%data2d, &
                            unlim_dim_level=unlim_dim_level, &
                            broadcast=.true.)
    elseif (associated(fileobj%restart_vars(i)%data3d)) then
      call netcdf_read_data(fileobj, fileobj%restart_vars(i)%varname, &
                            fileobj%restart_vars(i)%data3d, &
                            unlim_dim_level=unlim_dim_level, &
                            broadcast=.true.)
    elseif (associated(fileobj%restart_vars(i)%data4d)) then
      call netcdf_read_data(fileobj, fileobj%restart_vars(i)%varname, &
                            fileobj%restart_vars(i)%data4d, &
                            unlim_dim_level=unlim_dim_level, &
                            broadcast=.true.)
    else
      call error("this branch should not be reached.")
    endif
  enddo
end subroutine netcdf_restore_state


!> @brief Determine if a global attribute exists.
!! @return Flag telling if a global attribute exists.
function global_att_exists(fileobj, attribute_name, broadcast) &
  result(att_exists)

  class(FmsNetcdfFile_t), intent(in) :: fileobj !< File object.
  character(len=*), intent(in) :: attribute_name !< Attribute name.
  logical, intent(in), optional :: broadcast !< Flag controlling whether or
                                             !! not the data will be
                                             !! broadcasted to non
                                             !! "I/O root" ranks.
                                             !! The broadcast will be done
                                             !! by default.
  logical :: att_exists

  if (fileobj%is_root) then
    att_exists = attribute_exists(fileobj%ncid, nf90_global, trim(attribute_name))
  endif
  if (present(broadcast)) then
    if (.not. broadcast) then
      return
    endif
  endif
  call mpp_broadcast(att_exists, fileobj%io_root, pelist=fileobj%pelist)
end function global_att_exists


!> @brief Determine if a variable's attribute exists.
!! @return Flag telling if the variable's attribute exists.
function variable_att_exists(fileobj, variable_name, attribute_name, &
                             broadcast) &
  result(att_exists)

  class(FmsNetcdfFile_t), intent(in) :: fileobj !< File object.
  character(len=*), intent(in) :: variable_name !< Variable name.
  character(len=*), intent(in) :: attribute_name !< Attribute name.
  logical, intent(in), optional :: broadcast !< Flag controlling whether or
                                             !! not the data will be
                                             !! broadcasted to non
                                             !! "I/O root" ranks.
                                             !! The broadcast will be done
                                             !! by default.
  logical :: att_exists

  integer :: varid

  att_exists = .false.
  if (fileobj%is_root) then
    varid = get_variable_id(fileobj%ncid, trim(variable_name))
    att_exists = attribute_exists(fileobj%ncid, varid, trim(attribute_name))
  endif
  if (present(broadcast)) then
    if (.not. broadcast) then
      return
    endif
  endif
  call mpp_broadcast(att_exists, fileobj%io_root, pelist=fileobj%pelist)
end function variable_att_exists


!> @brief Determine the number of dimensions in a file.
!! @return The number of dimensions in the file.
function get_num_dimensions(fileobj, broadcast) &
  result(ndims)

  class(FmsNetcdfFile_t), intent(in) :: fileobj !< File object.
  logical, intent(in), optional :: broadcast !< Flag controlling whether or
                                             !! not the data will be
                                             !! broadcasted to non
                                             !! "I/O root" ranks.
                                             !! The broadcast will be done
                                             !! by default.
  integer :: ndims

  integer :: err

  if (fileobj%is_root) then
    err = nf90_inquire(fileobj%ncid, nDimensions=ndims)
    call check_netcdf_code(err)
  endif
  if (present(broadcast)) then
    if (.not. broadcast) then
      return
    endif
  endif
  call mpp_broadcast(ndims, fileobj%io_root, pelist=fileobj%pelist)
end function get_num_dimensions


!> @brief Get the names of the dimensions in a file.
subroutine get_dimension_names(fileobj, names, broadcast)

  class(FmsNetcdfFile_t), intent(in) :: fileobj !< File object.
  character(len=*), dimension(:), intent(inout) :: names !< Names of the
                                                         !! dimensions.
  logical, intent(in), optional :: broadcast !< Flag controlling whether or
                                             !! not the data will be
                                             !! broadcasted to non
                                             !! "I/O root" ranks.
                                             !! The broadcast will be done
                                             !! by default.

  integer :: ndims
  integer :: i
  integer :: err

  if (fileobj%is_root) then
    ndims = get_num_dimensions(fileobj, broadcast=.false.)
    if (ndims .gt. 0) then
      if (size(names) .ne. ndims) then
        call error("incorrect size of names array.")
      endif
    else
      call error("there are no dimensions in this file.")
    endif
    names(:) = ""
    do i = 1, ndims
      err = nf90_inquire_dimension(fileobj%ncid, i, name=names(i))
      call check_netcdf_code(err)
    enddo
  endif
  if (present(broadcast)) then
    if (.not. broadcast) then
      return
    endif
  endif
  call mpp_broadcast(ndims, fileobj%io_root, pelist=fileobj%pelist)
  if (.not. fileobj%is_root) then
    if (ndims .gt. 0) then
      if (size(names) .ne. ndims) then
        call error("incorrect size of names array.")
      endif
    else
      call error("there are no dimensions in this file.")
    endif
    names(:) = ""
  endif
  call mpp_broadcast(names, len(names(ndims)), fileobj%io_root, &
                     pelist=fileobj%pelist)
end subroutine get_dimension_names


!> @brief Determine if a dimension exists.
!! @return Flag telling if the dimension exists.
function dimension_exists(fileobj, dimension_name, broadcast) &
  result(dim_exists)

  class(FmsNetcdfFile_t), intent(in) :: fileobj !< File object.
  character(len=*), intent(in) :: dimension_name !< Dimension name.
  logical, intent(in), optional :: broadcast !< Flag controlling whether or
                                             !! not the data will be
                                             !! broadcasted to non
                                             !! "I/O root" ranks.
                                             !! The broadcast will be done
                                             !! by default.
  logical :: dim_exists

  integer :: dimid

  if (fileobj%is_root) then
    dimid = get_dimension_id(fileobj%ncid, trim(dimension_name), &
                             allow_failure=.true.)
    if (dimid .eq. dimension_missing) then
      dim_exists = .false.
    else
      dim_exists = .true.
    endif
  endif
  if (present(broadcast)) then
    if (.not. broadcast) then
      return
    endif
  endif
  call mpp_broadcast(dim_exists, fileobj%io_root, pelist=fileobj%pelist)
end function dimension_exists


!> @brief Determine where or not the dimension is unlimited.
!! @return True if the dimension is unlimited, or else false.
function is_dimension_unlimited(fileobj, dimension_name, broadcast) &
  result(is_unlimited)

  class(FmsNetcdfFile_t), intent(in) :: fileobj !< File object.
  character(len=*), intent(in) :: dimension_name !< Dimension name.
  logical, intent(in), optional :: broadcast !< Flag controlling whether or
                                             !! not the data will be
                                             !! broadcasted to non
                                             !! "I/O root" ranks.
                                             !! The broadcast will be done
                                             !! by default.
  logical :: is_unlimited

  integer :: dimid
  integer :: err
  integer :: ulim_dimid

  if (fileobj%is_root) then
    dimid = get_dimension_id(fileobj%ncid, trim(dimension_name))
    err = nf90_inquire(fileobj%ncid, unlimitedDimId=ulim_dimid)
    call check_netcdf_code(err)
    is_unlimited = dimid .eq. ulim_dimid
  endif
  if (present(broadcast)) then
    if (.not. broadcast) then
      return
    endif
  endif
  call mpp_broadcast(is_unlimited, fileobj%io_root, pelist=fileobj%pelist)
end function is_dimension_unlimited


!> @brief Get the name of the unlimited dimension.
subroutine get_unlimited_dimension_name(fileobj, dimension_name, broadcast)

  class(FmsNetcdfFile_t), intent(in) :: fileobj !< File object.
  character(len=*), intent(out) :: dimension_name !< Dimension name.
  logical, intent(in), optional :: broadcast !< Flag controlling whether or
                                             !! not the data will be
                                             !! broadcasted to non
                                             !! "I/O root" ranks.
                                             !! The broadcast will be done
                                             !! by default.

  integer :: err
  integer :: dimid
  character(len=nf90_max_name), dimension(1) :: buffer

  dimension_name = ""
  if (fileobj%is_root) then
    err = nf90_inquire(fileobj%ncid, unlimitedDimId=dimid)
    call check_netcdf_code(err)
    err = nf90_inquire_dimension(fileobj%ncid, dimid, dimension_name)
    call check_netcdf_code(err)
    call string_copy(buffer(1), dimension_name)
  endif
  if (present(broadcast)) then
    if (.not. broadcast) then
      return
    endif
  endif
  call mpp_broadcast(buffer, nf90_max_name, fileobj%io_root, &
                     pelist=fileobj%pelist)
  call string_copy(dimension_name, buffer(1))
end subroutine get_unlimited_dimension_name


!> @brief Get the length of a dimension.
subroutine get_dimension_size(fileobj, dimension_name, dim_size, broadcast)

  class(FmsNetcdfFile_t), intent(in) :: fileobj !< File object.
  character(len=*), intent(in) :: dimension_name !< Dimension name.
  integer, intent(inout) :: dim_size !< Dimension size.
  logical, intent(in), optional :: broadcast !< Flag controlling whether or
                                             !! not the data will be
                                             !! broadcasted to non
                                             !! "I/O root" ranks.
                                             !! The broadcast will be done
                                             !! by default.

  integer :: dimid
  integer :: err

  if (fileobj%is_root) then
    dimid = get_dimension_id(fileobj%ncid, trim(dimension_name))
    err = nf90_inquire_dimension(fileobj%ncid, dimid, len=dim_size)
    call check_netcdf_code(err)
  endif
  if (present(broadcast)) then
    if (.not. broadcast) then
      return
    endif
  endif
  call mpp_broadcast(dim_size, fileobj%io_root, pelist=fileobj%pelist)
end subroutine get_dimension_size


!> @brief Determine the number of variables in a file.
!! @return The number of variables in the file.
function get_num_variables(fileobj, broadcast) &
  result(nvars)

  class(FmsNetcdfFile_t), intent(in) :: fileobj !< File object.
  logical, intent(in), optional :: broadcast !< Flag controlling whether or
                                             !! not the data will be
                                             !! broadcasted to non
                                             !! "I/O root" ranks.
                                             !! The broadcast will be done
                                             !! by default.
  integer :: nvars

  integer :: err

  if (fileobj%is_root) then
    err = nf90_inquire(fileobj%ncid, nVariables=nvars)
    call check_netcdf_code(err)
  endif
  if (present(broadcast)) then
    if (.not. broadcast) then
      return
    endif
  endif
  call mpp_broadcast(nvars, fileobj%io_root, pelist=fileobj%pelist)
end function get_num_variables


!> @brief Get the names of the variables in a file.
subroutine get_variable_names(fileobj, names, broadcast)

  class(FmsNetcdfFile_t), intent(in) :: fileobj !< File object.
  character(len=*), dimension(:), intent(inout) :: names !< Names of the
                                                         !! variables.
  logical, intent(in), optional :: broadcast !< Flag controlling whether or
                                             !! not the data will be
                                             !! broadcasted to non
                                             !! "I/O root" ranks.
                                             !! The broadcast will be done
                                             !! by default.

  integer :: nvars
  integer :: i
  integer :: err

  if (fileobj%is_root) then
    nvars = get_num_variables(fileobj, broadcast=.false.)
    if (nvars .gt. 0) then
      if (size(names) .ne. nvars) then
        call error("names array has incorrect size.")
      endif
    else
      call error("there are no variables in this file.")
    endif
    names(:) = ""
    do i = 1, nvars
      err = nf90_inquire_variable(fileobj%ncid, i, name=names(i))
      call check_netcdf_code(err)
    enddo
  endif
  if (present(broadcast)) then
    if (.not. broadcast) then
      return
    endif
  endif
  call mpp_broadcast(nvars, fileobj%io_root, pelist=fileobj%pelist)
  if (.not. fileobj%is_root) then
    if (nvars .gt. 0) then
      if (size(names) .ne. nvars) then
        call error("names array has incorrect size.")
      endif
    else
      call error("there are no variables in this file.")
    endif
    names(:) = ""
  endif
  call mpp_broadcast(names, len(names(nvars)), fileobj%io_root, &
                     pelist=fileobj%pelist)
end subroutine get_variable_names


!> @brief Determine if a variable exists.
!! @return Flag telling if the variable exists.
function variable_exists(fileobj, variable_name, broadcast) &
  result(var_exists)

  class(FmsNetcdfFile_t), intent(in) :: fileobj !< File object.
  character(len=*), intent(in) :: variable_name !< Variable name.
  logical, intent(in), optional :: broadcast !< Flag controlling whether or
                                             !! not the data will be
                                             !! broadcasted to non
                                             !! "I/O root" ranks.
                                             !! The broadcast will be done
                                             !! by default.
  logical :: var_exists

  integer :: varid

  if (fileobj%is_root) then
    varid = get_variable_id(fileobj%ncid, trim(variable_name), &
                            allow_failure=.true.)
    var_exists = varid .ne. variable_missing
  endif
  if (present(broadcast)) then
    if (.not. broadcast) then
      return
    endif
  endif
  call mpp_broadcast(var_exists, fileobj%io_root, pelist=fileobj%pelist)
end function variable_exists


!> @brief Get the number of dimensions a variable depends on.
!! @return Number of dimensions that the variable depends on.
function get_variable_num_dimensions(fileobj, variable_name, broadcast) &
  result(ndims)

  class(FmsNetcdfFile_t), intent(in) :: fileobj !< File object.
  character(len=*), intent(in) :: variable_name !< Variable name.
  logical, intent(in), optional :: broadcast !< Flag controlling whether or
                                             !! not the data will be
                                             !! broadcasted to non
                                             !! "I/O root" ranks.
                                             !! The broadcast will be done
                                             !! by default.
  integer :: ndims

  integer :: varid
  integer :: err

  if (fileobj%is_root) then
    varid = get_variable_id(fileobj%ncid, trim(variable_name))
    err = nf90_inquire_variable(fileobj%ncid, varid, ndims=ndims)
    call check_netcdf_code(err)
  endif
  if (present(broadcast)) then
    if (.not. broadcast) then
      return
    endif
  endif
  call mpp_broadcast(ndims, fileobj%io_root, pelist=fileobj%pelist)
end function get_variable_num_dimensions


!> @brief Get the name of a variable's dimensions.
subroutine get_variable_dimension_names(fileobj, variable_name, dim_names, &
                                        broadcast)

  class(FmsNetcdfFile_t), intent(in) :: fileobj !< File object.
  character(len=*), intent(in) :: variable_name !< Variable name.
  character(len=*), dimension(:), intent(inout) :: dim_names !< Array of
                                                             !! dimension
                                                             !! names.
  logical, intent(in), optional :: broadcast !< Flag controlling whether or
                                             !! not the data will be
                                             !! broadcasted to non
                                             !! "I/O root" ranks.
                                             !! The broadcast will be done
                                             !! by default.

  integer :: varid
  integer :: err
  integer :: ndims
  integer,dimension(nf90_max_var_dims) :: dimids
  integer :: i

  if (fileobj%is_root) then
    varid = get_variable_id(fileobj%ncid, trim(variable_name))
    err = nf90_inquire_variable(fileobj%ncid, varid, ndims=ndims, &
                                dimids=dimids)
    call check_netcdf_code(err)
    if (ndims .gt. 0) then
      if (size(dim_names) .ne. ndims) then
        call error("incorrect size of dim_names array.")
      endif
    else
      call error("this variable is a scalar.")
    endif
    dim_names(:) = ""
    do i = 1, ndims
      err = nf90_inquire_dimension(fileobj%ncid, dimids(i), name=dim_names(i))
      call check_netcdf_code(err)
    enddo
  endif
  if (present(broadcast)) then
    if (.not. broadcast) then
      return
    endif
  endif
  call mpp_broadcast(ndims, fileobj%io_root, pelist=fileobj%pelist)
  if (.not. fileobj%is_root) then
    if (ndims .gt. 0) then
      if (size(dim_names) .ne. ndims) then
        call error("incorrect size of dim_names array.")
      endif
    else
      call error("this variable is a scalar.")
    endif
    dim_names(:) = ""
  endif
  call mpp_broadcast(dim_names, len(dim_names(ndims)), fileobj%io_root, &
                     pelist=fileobj%pelist)
end subroutine get_variable_dimension_names


!> @brief Get the size of a variable's dimensions.
subroutine get_variable_size(fileobj, variable_name, dim_sizes, broadcast)

  class(FmsNetcdfFile_t), intent(in) :: fileobj !< File object.
  character(len=*), intent(in) :: variable_name !< Variable name.
  integer, dimension(:), intent(inout) :: dim_sizes !< Array of dimension
                                                    !! sizes.
  logical, intent(in), optional :: broadcast !< Flag controlling whether or
                                             !! not the data will be
                                             !! broadcasted to non
                                             !! "I/O root" ranks.
                                             !! The broadcast will be done
                                             !! by default.

  integer :: varid
  integer :: err
  integer :: ndims
  integer,dimension(nf90_max_var_dims) :: dimids
  integer :: i

  if (fileobj%is_root) then
    varid = get_variable_id(fileobj%ncid, trim(variable_name))
    err = nf90_inquire_variable(fileobj%ncid, varid, ndims=ndims, dimids=dimids)
    call check_netcdf_code(err)
    if (ndims .gt. 0) then
      if (size(dim_sizes) .ne. ndims) then
        call error("incorrect size of dim_sizes array.")
      endif
    else
      call error("this variable is a scalar.")
    endif
    do i = 1, ndims
      err = nf90_inquire_dimension(fileobj%ncid, dimids(i), len=dim_sizes(i))
      call check_netcdf_code(err)
    enddo
  endif
  if (present(broadcast)) then
    if (.not. broadcast) then
      return
    endif
  endif
  call mpp_broadcast(ndims, fileobj%io_root, pelist=fileobj%pelist)
  if (.not. fileobj%is_root) then
    if (ndims .gt. 0) then
      if (size(dim_sizes) .ne. ndims) then
        call error("incorrect size of dim_names array.")
      endif
    else
      call error("this variable is a scalar.")
    endif
  endif
  call mpp_broadcast(dim_sizes, ndims, fileobj%io_root, pelist=fileobj%pelist)
end subroutine get_variable_size


!> @brief Get the index of a variable's unlimited dimensions.
!! @return The index of the unlimited dimension, or else
!!         no_unlimited_dimension.
function get_variable_unlimited_dimension_index(fileobj, variable_name, &
                                                broadcast) &
  result(unlim_dim_index)

  class(FmsNetcdfFile_t), intent(in) :: fileobj !< File object.
  character(len=*), intent(in) :: variable_name !< Variable name.
  logical, intent(in), optional :: broadcast !< Flag controlling whether or
                                             !! not the data will be
                                             !! broadcasted to non
                                             !! "I/O root" ranks.
                                             !! The broadcast will be done
                                             !! by default.
  integer :: unlim_dim_index

  integer :: ndims
  character(len=nf90_max_name), dimension(:), allocatable :: dim_names
  integer :: i

  unlim_dim_index = no_unlimited_dimension
  if (fileobj%is_root) then
    ndims = get_variable_num_dimensions(fileobj, variable_name, broadcast=.false.)
    allocate(dim_names(ndims))
    call get_variable_dimension_names(fileobj, variable_name, dim_names, &
                                      broadcast=.false.)
    do i = 1, size(dim_names)
      if (is_dimension_unlimited(fileobj, dim_names(i), .false.)) then
        unlim_dim_index = i
        exit
      endif
    enddo
    deallocate(dim_names)
  endif
  if (present(broadcast)) then
    if (.not. broadcast) then
      return
    endif
  endif
  call mpp_broadcast(unlim_dim_index, fileobj%io_root, pelist=fileobj%pelist)
end function get_variable_unlimited_dimension_index


!> @brief Store the valid range for a variable.
!! @return A ValidType_t object containing data about the valid
!!         range data for this variable can take.
function get_valid(fileobj, variable_name) &
  result(valid)

  class(FmsNetcdfFile_t), intent(in) :: fileobj !< File object.
  character(len=*), intent(in) :: variable_name !< Variable name.
  type(Valid_t) :: valid

  integer :: varid
  real(kind=real64) :: scale_factor
  real(kind=real64) :: add_offset
  real(kind=real64), dimension(2) :: buffer
  integer :: xtype

  if (fileobj%is_root) then
    varid = get_variable_id(fileobj%ncid, variable_name)
    valid%has_max = .false.
    valid%has_min = .false.
    valid%has_fill = .false.
    valid%has_missing = .false.
    valid%has_range = .false.

    !This routine makes use of netcdf's automatic type conversion to
    !store all range information in double precision.
    if (attribute_exists(fileobj%ncid, varid, "scale_factor")) then
      call get_variable_attribute(fileobj, variable_name, "scale_factor", scale_factor)
    else
      scale_factor = 1._real64
    endif
    if (attribute_exists(fileobj%ncid, varid, "add_offset")) then
      call get_variable_attribute(fileobj, variable_name, "add_offset", add_offset)
    else
      add_offset = 0._real64
    endif

    !valid%max_val and valid%min_val are defined by the "valid_range", "valid_min", and
    !"valid_max" variable attributes if they are present in the file. If either the maximum value
    !or minimum value is defined, valid%has_range is set to .true. (i.e. open ended ranges
    !are valid and should be tested within the is_valid function).
    if (attribute_exists(fileobj%ncid, varid, "valid_range")) then
      call get_variable_attribute(fileobj, variable_name, "valid_range", buffer)
      valid%max_val = buffer(2)*scale_factor + add_offset
      valid%has_max = .true.
      valid%min_val = buffer(1)*scale_factor + add_offset
      valid%has_min = .true.
    else
      if (attribute_exists(fileobj%ncid, varid, "valid_max")) then
        call get_variable_attribute(fileobj, variable_name, "valid_max", buffer(1))
        valid%max_val = buffer(1)*scale_factor + add_offset
        valid%has_max = .true.
      endif
      if (attribute_exists(fileobj%ncid, varid, "valid_min")) then
        call get_variable_attribute(fileobj, variable_name, "valid_min", buffer(1))
        valid%min_val = buffer(1)*scale_factor + add_offset
        valid%has_min = .true.
      endif
    endif
    valid%has_range = valid%has_min .or. valid%has_max

    !Get the missing value from the file if it exists.
    if (attribute_exists(fileobj%ncid, varid, "missing_value")) then
      call get_variable_attribute(fileobj, variable_name, "missing_value", buffer(1))
      valid%missing_val = buffer(1)*scale_factor + add_offset
      valid%has_missing = .true.
    endif

    !Get the fill value from the file if it exists.
    !If the _FillValue attribute is present and the maximum or minimum value is not defined,
    !then the maximum or minimum value will be determined by the _FillValue according to the NUG convention.
    !The NUG convention states that a positive fill value will be the exclusive upper
    !bound (i.e. valid values are less than the fill value), while a
    !non-positive fill value will be the exclusive lower bound (i.e. valis
    !values are greater than the fill value). As before, valid%has_range is true
    !if either a maximum or minimum value is set.
    if (attribute_exists(fileobj%ncid, varid, "_FillValue")) then
      call get_variable_attribute(fileobj, variable_name, "_FillValue", buffer(1))
      valid%fill_val = buffer(1)*scale_factor + add_offset
      valid%has_fill = .true.
      xtype = get_variable_type(fileobj%ncid, varid)
      if (.not. valid%has_range) then
        if (xtype .eq. nf90_short .or. xtype .eq. nf90_int) then
          if (buffer(1) .gt. 0) then
            valid%max_val = (buffer(1) - 1._real64)*scale_factor + add_offset
            valid%has_max = .true.
          else
            valid%min_val = (buffer(1) + 1._real64)*scale_factor + add_offset
            valid%has_min = .true.
          endif
        elseif (xtype .eq. nf90_float .or. xtype .eq. nf90_double) then
          if (buffer(1) .gt. 0) then
            valid%max_val = (nearest(nearest(buffer(1), -1._real64), -1._real64)) &
                            *scale_factor + add_offset
            valid%has_max = .true.
          else
            valid%min_val = (nearest(nearest(buffer(1), 1._real64), 1._real64)) &
                            *scale_factor + add_offset
            valid%has_min = .true.
          endif
        else
          call error("unsupported type.")
        endif
        valid%has_range = .true.
      endif
    endif

  endif

  call mpp_broadcast(valid%has_min, fileobj%io_root, pelist=fileobj%pelist)
  if (valid%has_min) then
    call mpp_broadcast(valid%min_val, fileobj%io_root, pelist=fileobj%pelist)
  endif
  call mpp_broadcast(valid%has_max, fileobj%io_root, pelist=fileobj%pelist)
  if (valid%has_max) then
    call mpp_broadcast(valid%max_val, fileobj%io_root, pelist=fileobj%pelist)
  endif
  call mpp_broadcast(valid%has_range, fileobj%io_root, pelist=fileobj%pelist)

  call mpp_broadcast(valid%has_fill, fileobj%io_root, pelist=fileobj%pelist)
  if (valid%has_fill) then
     call mpp_broadcast(valid%fill_val, fileobj%io_root, pelist=fileobj%pelist)
  endif

  call mpp_broadcast(valid%has_missing, fileobj%io_root, pelist=fileobj%pelist)
  if (valid%has_missing) then
     call mpp_broadcast(valid%missing_val, fileobj%io_root, pelist=fileobj%pelist)
  endif

end function get_valid


!> @brief Determine if a piece of data is "valid" (in the correct range.)
!! @return A flag telling if the data element is "valid."
elemental function is_valid(datum, validobj) &
  result(valid_data)

  class(*), intent(in) :: datum !< Unpacked data element.
  type(Valid_t), intent(in) :: validobj !< Valid object.
  logical :: valid_data

  real(kind=real64) :: rdatum

  select type (datum)
    type is (integer(kind=int32))
      rdatum = real(datum, kind=real64)
    type is (real(kind=real32))
      rdatum = real(datum, kind=real64)
    type is (real(kind=real64))
      rdatum = real(datum, kind=real64)
 !  class default
 !    call error("unsupported type.")
  end select

  valid_data = .true.
  ! If the variable has a range (open or closed), valid values must be in that
  ! range.
  if (validobj%has_range) then
    if (validobj%has_min .and. .not. validobj%has_max) then
      valid_data = rdatum .ge. validobj%min_val
    elseif (validobj%has_max .and. .not. validobj%has_min) then
      valid_data = rdatum .le. validobj%max_val
    else
      valid_data = .not. (rdatum .lt. validobj%min_val .or. rdatum .gt. validobj%max_val)
    endif
  endif
  ! If the variable has a fill value or missing value, valid values must not be
  ! equal to either.
  if (validobj%has_fill .or. validobj%has_missing) then
    if (validobj%has_fill .and. .not. validobj%has_missing) then
      valid_data = rdatum .ne. validobj%fill_val
    elseif (validobj%has_missing .and. .not. validobj%has_fill) then
      valid_data = rdatum .ne. validobj%missing_val
    else
      valid_data = .not. (rdatum .eq. validobj%missing_val .or. rdatum .eq. validobj%fill_val)
    endif
  endif
end function is_valid


!> @brief Gathers a compressed arrays size and offset for each pe.
subroutine compressed_start_and_count(fileobj, nelems, npes_start, npes_count)

  class(FmsNetcdfFile_t), intent(in) :: fileobj !< File object.
  integer, intent(in) :: nelems !< Number of elements on the current pe.
  integer, dimension(:), allocatable, intent(out) :: npes_start !< Offset for each pe.
  integer, dimension(:), allocatable, intent(out) :: npes_count !< Number of elements for
                                                                !! each pe.

  integer :: i

  allocate(npes_start(size(fileobj%pelist)))
  allocate(npes_count(size(fileobj%pelist)))
  do i = 1, size(fileobj%pelist)
    if (fileobj%pelist(i) .eq. mpp_pe()) then
      npes_count(i) = nelems
    else
      call mpp_recv(npes_count(i), fileobj%pelist(i), block=.false.)
      call mpp_send(nelems, fileobj%pelist(i))
    endif
  enddo
  call mpp_sync_self(check=EVENT_RECV)
  call mpp_sync_self(check=EVENT_SEND)
  npes_start(1) = 1
  do i = 1, size(fileobj%pelist)-1
    npes_start(i+1) = npes_start(i) + npes_count(i)
  enddo
end subroutine compressed_start_and_count


include "include/netcdf_add_restart_variable.inc"
include "include/netcdf_read_data.inc"
include "include/netcdf_write_data.inc"
include "include/register_global_attribute.inc"
include "include/register_variable_attribute.inc"
include "include/get_global_attribute.inc"
include "include/get_variable_attribute.inc"
include "include/compressed_write.inc"
include "include/compressed_read.inc"


!> @brief Wrapper to distinguish interfaces.
function netcdf_file_open_wrap(fileobj, path, mode, nc_format, pelist, is_restart) &
  result(success)

  type(FmsNetcdfFile_t), intent(inout) :: fileobj !< File object.
  character(len=*), intent(in) :: path !< File path.
  character(len=*), intent(in) :: mode !< File mode.  Allowed values are:
                                       !! "read", "append", "write", or
                                       !! "overwrite".
  character(len=*), intent(in), optional :: nc_format !< Netcdf format that
                                                     !! new files are written
                                                     !! as.  Allowed values
                                                     !! are: "64bit", "classic",
                                                     !! or "netcdf4". Defaults to
                                                     !! "64bit".
  integer, dimension(:), intent(in), optional :: pelist !< List of ranks associated
                                                        !! with this file.  If not
                                                        !! provided, only the current
                                                        !! rank will be able to
                                                        !! act on the file.
  logical, intent(in), optional :: is_restart !< Flag telling if this file
                                              !! is a restart file.  Defaults
                                              !! to false.
  logical :: success

  success = netcdf_file_open(fileobj, path, mode, nc_format, pelist, is_restart)
end function netcdf_file_open_wrap


!> @brief Wrapper to distinguish interfaces.
subroutine netcdf_file_close_wrap(fileobj)

  type(FmsNetcdfFile_t), intent(inout) :: fileobj !< File object.

  call netcdf_file_close(fileobj)
end subroutine netcdf_file_close_wrap


!> @brief Wrapper to distinguish interfaces.
subroutine netcdf_add_variable_wrap(fileobj, variable_name, variable_type, dimensions)

  type(FmsNetcdfFile_t), intent(in) :: fileobj !< File object.
  character(len=*), intent(in) :: variable_name !< Variable name.
  character(len=*), intent(in) :: variable_type !< Variable type.  Allowed
                                                !! values are: "int", "int64",
                                                !! "float", or "double".
  character(len=*), dimension(:), intent(in), optional :: dimensions !< Dimension names.

  call netcdf_add_variable(fileobj, variable_name, variable_type, dimensions)
end subroutine netcdf_add_variable_wrap


!> @brief Wrapper to distinguish interfaces.
subroutine netcdf_save_restart_wrap(fileobj, unlim_dim_level)

  type(FmsNetcdfFile_t), intent(in) :: fileobj !< File object.
  integer, intent(in), optional :: unlim_dim_level !< Unlimited dimension
                                                     !! level.

  call netcdf_save_restart(fileobj, unlim_dim_level)
end subroutine netcdf_save_restart_wrap


!> @brief Returns a variable's fill value if it exists in the file.
!! @return Flag telling if a fill value exists.
function get_fill_value(fileobj, variable_name, fill_value, broadcast) &
  result(fill_exists)

  class(FmsNetcdfFile_t), intent(in) :: fileobj !< File object.
  character(len=*), intent(in) :: variable_name !< Variable name.
  class(*), intent(out) :: fill_value !< Fill value.
  logical, intent(in), optional :: broadcast !< Flag controlling whether or
                                             !! not the data will be
                                             !! broadcasted to non
                                             !! "I/O root" ranks.
                                             !! The broadcast will be done
                                             !! by default.
  logical :: fill_exists

  character(len=32), dimension(2) :: attribute_names
  logical :: bcast
  integer :: i

  fill_exists = .false.
  call string_copy(attribute_names(1), "_FillValue")
  call string_copy(attribute_names(2), "missing_value")
  if (present(broadcast)) then
    bcast = broadcast
  else
    bcast = .true.
  endif
  do i = 1, size(attribute_names)
    fill_exists = variable_att_exists(fileobj, variable_name, attribute_names(i), &
                                      broadcast=bcast)
    if (fill_exists) then
      call get_variable_attribute(fileobj, variable_name, attribute_names(i), &
                                  fill_value, broadcast=bcast)
      exit
    endif
  enddo
end function get_fill_value


function get_variable_sense(fileobj, variable_name) &
  result (variable_sense)

  class(FmsNetcdfFile_t), intent(in) :: fileobj
  character(len=*), intent(in) :: variable_name
  integer :: variable_sense

  character(len=256) :: buf

  variable_sense = 0
  if (variable_att_exists(fileobj, variable_name, "positive")) then
    call get_variable_attribute(fileobj, variable_name, "positive", buf)
    if (string_compare(buf, "down")) then
      variable_sense = -1
    elseif (string_compare(buf, "up")) then
      variable_sense = 1
    endif
  endif
end function get_variable_sense


function get_variable_missing(fileobj, variable_name) &
  result(variable_missing)

  type(FmsNetcdfFile_t), intent(in) :: fileobj
  character(len=*), intent(in) :: variable_name
  real(kind=real64) :: variable_missing

  if (variable_att_exists(fileobj, variable_name, "_FillValue")) then
    call get_variable_attribute(fileobj, variable_name, "_FillValue", variable_missing)
  elseif (variable_att_exists(fileobj, variable_name, "missing_value")) then
    call get_variable_attribute(fileobj, variable_name, "missing_value", variable_missing)
  elseif (variable_att_exists(fileobj, variable_name, "missing")) then
    call get_variable_attribute(fileobj, variable_name, "missing", variable_missing)
  else
    variable_missing = MPP_FILL_DOUBLE
  endif
end function get_variable_missing


subroutine get_variable_units(fileobj, variable_name, units)

  class(FmsNetcdfFile_t), intent(in) :: fileobj
  character(len=*), intent(in) :: variable_name
  character(len=*), intent(out) :: units

  if (variable_att_exists(fileobj, variable_name, "units")) then
    call get_variable_attribute(fileobj, variable_name, "units", units)
  else
    units = "nounits"
  endif
end subroutine get_variable_units


subroutine get_time_calendar(fileobj, time_name, calendar_type)

  class(FmsNetcdfFile_t), intent(in) :: fileobj
  character(len=*), intent(in) :: time_name
  character(len=*), intent(out) :: calendar_type

  if (variable_att_exists(fileobj, time_name, "calendar")) then
    call get_variable_attribute(fileobj, time_name, "calendar", calendar_type)
  elseif (variable_att_exists(fileobj, time_name, "calendar_type")) then
    call get_variable_attribute(fileobj, time_name, "calendar_type", calendar_type)
  else
    calendar_type = "unspecified"
  endif
end subroutine get_time_calendar


!> @brief Determine if a variable has been registered to a restart file..
!! @return Flag telling if the variable has been registered to a restart file.
function is_registered_to_restart(fileobj, variable_name) &
  result(is_registered)

  class(FmsNetcdfFile_t), intent(in) :: fileobj !< File object.
  character(len=*), intent(in) :: variable_name !< Variable name.
  logical :: is_registered

  integer :: i

  if (.not. fileobj%is_restart) then
    call error("file "//trim(fileobj%path)//" is not a restart file.")
  endif
  is_registered = .false.
  do i = 1, fileobj%num_restart_vars
    if (string_compare(fileobj%restart_vars(i)%varname, variable_name, .true.)) then
      is_registered = .true.
      exit
    endif
  enddo
end function is_registered_to_restart


function check_if_open(fileobj, fname) result(is_open)
  logical :: is_open !< True if the file in the file object is opened
  class(FmsNetcdfFile_t), intent(in) :: fileobj !< File object.
  character(len=*), intent(in), optional :: fname !< Optional filename for checking

  !Check if the is_open variable in the object has been allocated
  if (allocated(fileobj%is_open)) then
    is_open = fileobj%is_open !Return the value of the fileobj%is_open
  else
    is_open = .false. !If fileobj%is_open is not allocated, that the file has not been opened
  endif

  if (present(fname)) then
    !If the filename does not match the name in path,
    !then this is considered not open
     if (is_open .AND. trim(fname) .ne. trim(fileobj%path)) is_open = .false.
  endif
end function check_if_open

subroutine set_fileobj_time_name (fileobj,time_name)
  class(FmsNetcdfFile_t), intent(inout) :: fileobj
  character(*),intent(in) :: time_name
  integer :: len_of_name
  len_of_name = len(trim(time_name))
  fileobj%time_name = '                    '
  fileobj%time_name = time_name(1:len_of_name)
!  if (.not. allocated(fileobj%time_name)) then
!     allocate(character(len=len_of_name) :: fileobj%time_name)
!     fileobj%time_name = time_name(1:len_of_name)
!  else
!     call error ("set_fileobj_time_name :: The time_name has already been set")
!  endif
end subroutine set_fileobj_time_name

end module netcdf_io_mod
