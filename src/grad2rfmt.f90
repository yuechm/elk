
! Copyright (C) 2009 J. K. Dewhurst, S. Sharma and E. K. U. Gross.
! This file is distributed under the terms of the GNU Lesser General Public
! License. See the file COPYING for license details.

subroutine grad2rfmt(nr,nri,r,rfmt,g2rfmt)
use modmain
implicit none
! arguments
integer, intent(in) :: nr,nri
real(8), intent(in) :: r(nr)
real(8), intent(in) :: rfmt(lmmaxvr,nr)
real(8), intent(out) :: g2rfmt(lmmaxvr,nr)
! local variables
integer nr0,ir0,ir,l,m,lm
real(8) t1
! automatic arrays
real(8) ri(nr),ri2(nr),cf(3,nr)
! tabulate 1/r and 1/r^2
do ir=1,nr
  ri(ir)=1.d0/r(ir)
  ri2(ir)=ri(ir)**2
end do
lm=0
do l=0,lmaxvr
  if (l.le.lmaxinr) then
    nr0=nr
    ir0=1
  else
    nr0=nr-nri
    ir0=nri+1
  end if
  t1=-dble(l*(l+1))
  do m=-l,l
    lm=lm+1
! use a cubic spline to compute radial derivatives
    call spline(nr0,r(ir0),lmmaxvr,rfmt(lm,ir0),cf(1,ir0))
! apply Laplacian
    do ir=ir0,nr
      g2rfmt(lm,ir)=2.d0*(ri(ir)*cf(1,ir)+cf(2,ir))+ri2(ir)*t1*rfmt(lm,ir)
    end do
  end do
end do
return
end subroutine

