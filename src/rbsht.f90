
! Copyright (C) 2013 J. K. Dewhurst, S. Sharma and E. K. U. Gross.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.

subroutine rbsht(nr,nri,lrstp1,rfmt1,lrstp2,rfmt2)
use modmain
implicit none
! arguments
integer, intent(in) :: nr,nri
integer, intent(in) :: lrstp1
real(8), intent(in) :: rfmt1(lmmaxvr,lrstp1,nr)
integer, intent(in) :: lrstp2
real(8), intent(out) :: rfmt2(lmmaxvr,lrstp2,nr)
! local variables
integer ld1,ld2,nr0,ir0
ld1=lmmaxvr*lrstp1
ld2=lmmaxvr*lrstp2
! transform the inner part of the muffin-tin
call dgemm('N','N',lmmaxinr,nri,lmmaxinr,1.d0,rbshtinr,lmmaxinr,rfmt1,ld1, &
 0.d0,rfmt2,ld2)
! transform the outer part of the muffin-tin
nr0=nr-nri
if (nr0.eq.0) return
ir0=nri+1
call dgemm('N','N',lmmaxvr,nr0,lmmaxvr,1.d0,rbshtvr,lmmaxvr,rfmt1(:,1,ir0), &
 ld1,0.d0,rfmt2(:,1,ir0),ld2)
return
end subroutine

