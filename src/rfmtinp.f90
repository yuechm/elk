
! Copyright (C) 2003-2005 J. K. Dewhurst, S. Sharma and C. Ambrosch-Draxl.
! This file is distributed under the terms of the GNU Lesser General Public
! License. See the file COPYING for license details.

!BOP
! !ROUTINE: rfmtinp
! !INTERFACE:
real(8) function rfmtinp(lrstp,nr,nri,r,rfmt1,rfmt2)
! !USES:
use modmain
! !INPUT/OUTPUT PARAMETERS:
!   lrstp : radial step length (in,integer)
!   nr    : number of radial mesh points (in,integer)
!   nri   : number of radial mesh points on the inner part of the muffin-tin
!           (in,integer)
!   r     : radial mesh (in,real(nr))
!   rfmt1 : first real function inside muffin-tin (in,real(lmmaxvr,nr))
!   rfmt2 : second real function inside muffin-tin (in,real(lmmaxvr,nr))
! !DESCRIPTION:
!   Calculates the inner product of two real fuctions in the muffin-tin. So
!   given two real functions of the form
!   $$ f({\bf r})=\sum_{l=0}^{l_{\rm max}}\sum_{m=-l}^{l}f_{lm}(r)R_{lm}
!    (\hat{\bf r}) $$
!   where $R_{lm}$ are the real spherical harmonics, the function returns
!   $$ I=\int\sum_{l=0}^{l_{\rm max}}\sum_{m=-l}^{l}f_{lm}^1(r)f_{lm}^2(r)r^2
!    dr\;. $$
!   The radial integral is performed using a high accuracy cubic spline method.
!   See routines {\tt genrlm} and {\tt fderiv}.
!
! !REVISION HISTORY:
!   Created November 2003 (Sharma)
!EOP
!BOC
implicit none
! arguments
integer, intent(in) :: lrstp
integer, intent(in) :: nr,nri
real(8), intent(in) :: r(nr)
real(8), intent(in) :: rfmt1(lmmaxvr,nr)
real(8), intent(in) :: rfmt2(lmmaxvr,nr)
! local variables
integer ir,irc
! automatic arrays
real(8) rc(nr),fr(nr),gr(nr)
! external functions
real(8) ddot
external ddot
if (lrstp.le.0) then
  write(*,*)
  write(*,'("Error(rfmtinp): lrstp <= 0 : ",I8)') lrstp
  write(*,*)
  stop
end if
if (nr.le.0) then
  write(*,*)
  write(*,'("Error(rfmtinp): nr <= 0 : ",I8)') nr
  write(*,*)
  stop
end if
irc=0
! inner part of muffin-tin
do ir=1,nri,lrstp
  irc=irc+1
  rc(irc)=r(ir)
  fr(irc)=ddot(lmmaxinr,rfmt1(:,ir),1,rfmt2(:,ir),1)*r(ir)**2
end do
! outer part of muffin-tin
do ir=nri+lrstp,nr,lrstp
  irc=irc+1
  rc(irc)=r(ir)
  fr(irc)=ddot(lmmaxvr,rfmt1(:,ir),1,rfmt2(:,ir),1)*r(ir)**2
end do
call fderiv(-1,irc,rc,fr,gr)
rfmtinp=gr(irc)
return
end function
!EOC
