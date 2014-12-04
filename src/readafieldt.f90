
! Copyright (C) 2014 K. Krieger, J. K. Dewhurst, S. Sharma and E. K. U. Gross.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.

subroutine readafieldt
use modmain
use modtddft
implicit none
! local variables
integer its,iostat
open(50,file='AFIELDT.OUT',action='READ',form='FORMATTED',status='OLD', &
 iostat=iostat)
if (iostat.ne.0) then
  write(*,*)
  write(*,'("Error(readafieldt): error opening AFIELDT.OUT")')
  write(*,*)
  stop
end if
read(50,*) ntimes
if (ntimes.le.0) then
  write(*,*)
  write(*,'("Error(readafieldt): ntimes <= 0 : ",I8)') ntimes
  write(*,*)
  stop
end if
if (allocated(times)) deallocate(times)
allocate(times(ntimes))
if (allocated(afieldt)) deallocate(afieldt)
allocate(afieldt(3,ntimes))
do its=1,ntimes
  read(50,*) times(its),afieldt(:,its)
end do
return
end subroutine

