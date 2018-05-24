!
! Copyright (C) 2002-2013 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!----------------------------------------------------------------------
subroutine gen_at_dj ( ik, natw, is_hubbard, hubbard_l, dwfcat )
   !----------------------------------------------------------------------
   !
   ! This routine calculates the atomic wfc generated by the derivative
   ! (with respect to the q vector) of the bessel function. This vector
   ! is needed in computing the Hubbard contribution to the stress tensor.
   !
   USE kinds,      ONLY : DP
   USE io_global,  ONLY : stdout
   USE constants,  ONLY : tpi
   USE atom,       ONLY : msh
   USE ions_base,  ONLY : nat, ntyp => nsp, ityp, tau
   USE cell_base,  ONLY : omega, at, bg, tpiba
   USE klist,      ONLY : xk, ngk, igk_k
   USE gvect,      ONLY : mill, eigts1, eigts2, eigts3, g
   USE wvfct,      ONLY : npwx
   USE us,         ONLY : tab_at, dq
   USE uspp_param, ONLY : upf
   !
   USE us_gpum,    ONLY : using_tab_at
   !
   implicit none
   !
   !  I/O variables
   !
   integer, intent (in) :: ik, natw, hubbard_l(ntyp)
   logical, intent (in) :: is_hubbard(ntyp)
   complex (DP), intent(out) :: dwfcat(npwx,natw)
   !
   ! local variables
   !
   integer :: l, na, nt, nb, iatw, iig, ig, i0, i1, i2 ,i3, m, lm, &
              nwfcm, lmax_wfc, npw
   real (DP) :: qt, arg, px, ux, vx, wx
   complex (DP) :: phase, pref
   real (DP), allocatable :: gk(:,:), q(:), ylm(:,:), djl(:,:,:)
   complex (DP), allocatable :: sk(:)
   ! 
   npw = ngk(ik)
   nwfcm = MAXVAL ( upf(1:ntyp)%nwfc )
   lmax_wfc = MAXVAL ( hubbard_l(:) )
   allocate ( ylm (npw,(lmax_wfc+1)**2) , djl (npw,nwfcm,ntyp) )
   allocate ( gk(3,npw), q (npw) )

   do ig = 1, npw
      iig = igk_k(ig,ik)
      gk (1,ig) = xk(1, ik) + g(1,iig)
      gk (2,ig) = xk(2, ik) + g(2,iig)
      gk (3,ig) = xk(3, ik) + g(3,iig)
      q (ig) = gk(1, ig)**2 +  gk(2, ig)**2 + gk(3, ig)**2
   enddo

   !
   !  ylm = spherical harmonics
   !
   call ylmr2 ((lmax_wfc+1)**2, npw, gk, q, ylm)

   q(:) = dsqrt ( q(:) )

   call using_tab_at(0)
   do nt=1,ntyp
      do nb=1,upf(nt)%nwfc
         if (upf(nt)%oc(nb) >= 0.d0) then
            do ig = 1, npw
               qt=q(ig)*tpiba
               px = qt / dq - int (qt / dq)
               ux = 1.d0 - px
               vx = 2.d0 - px
               wx = 3.d0 - px
               i0 = qt / dq + 1
               i1 = i0 + 1
               i2 = i0 + 2
               i3 = i0 + 3
               djl(ig,nb,nt) = &
                     ( tab_at (i0, nb, nt) * (-vx*wx-ux*wx-ux*vx)/6.d0 + &
                       tab_at (i1, nb, nt) * (+vx*wx-px*wx-px*vx)/2.d0 - &
                       tab_at (i2, nb, nt) * (+ux*wx-px*wx-px*ux)/2.d0 + &
                       tab_at (i3, nb, nt) * (+ux*vx-px*vx-px*ux)/6.d0 )/dq
            enddo
         end if
      end do
   end do
   deallocate ( q, gk )

   allocate ( sk(npw) )

   iatw = 0
   do na=1,nat
      nt=ityp(na)
      if ( .not. is_hubbard(nt) ) cycle
      arg = ( xk(1,ik) * tau(1,na) + &
              xk(2,ik) * tau(2,na) + &
              xk(3,ik) * tau(3,na) ) * tpi
      phase=CMPLX(cos(arg),-sin(arg),kind=DP)
      do ig =1,npw
         iig = igk_k(ig,ik)
         sk(ig) = eigts1(mill(1,iig),na) *      &
                  eigts2(mill(2,iig),na) *      &
                  eigts3(mill(3,iig),na) * phase
      end do
      do nb = 1,upf(nt)%nwfc
         l  = upf(nt)%lchi(nb)
         if ( upf(nt)%oc(nb) > 0.d0 .and. l == hubbard_l(nt) ) then
            pref = (0.d0,1.d0)**l
            do m = 1,2*l+1
               lm = l*l+m
               iatw = iatw+1
               do ig=1,npw
                  dwfcat(ig,iatw)= djl(ig,nb,nt)*sk(ig)*ylm(ig,lm)*pref
               end do
            end do
         end if
      enddo
   enddo

   if (iatw.ne.natw) then
      WRITE( stdout,*) 'iatw =',iatw,'natw =',natw
      call errore('gen_at_dj','unexpected error',1)
   end if

   deallocate ( sk )
   deallocate ( djl, ylm )

   return
end subroutine gen_at_dj
