!
! Copyright (C) 2001-2014 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!-----------------------------------------------------------------------
SUBROUTINE slater( length, rs, ex, vx )
  !---------------------------------------------------------------------
  !        Slater exchange with alpha=2/3
  !
  USE kinds,      ONLY: DP
! #if defined(__LIBXC)
!   USE xc_f90_types_m
!   USE xc_f90_lib_m
! #endif
  !
  IMPLICIT NONE
  !
  INTEGER,  INTENT(IN)  :: length
  REAL(DP), INTENT(IN),  DIMENSION(length) :: rs
  REAL(DP), INTENT(OUT), DIMENSION(length) :: ex, vx
! #if defined(__LIBXC)
!   REAL(DP), DIMENSION(length) :: rho
!   REAL(DP), PARAMETER :: pi34 = 0.6203504908994d0 ! pi34=(3/4pi)^(1/3)
!   INTEGER  :: func_id = 1  ! Slater Exchange
!   INTEGER  :: size
!   TYPE(xc_f90_pointer_t) :: xc_func
!   TYPE(xc_f90_pointer_t) :: xc_info
!   !
!   size = length
!   !
!   rho = (pi34/rs)**3
!   call xc_f90_func_init( xc_func, xc_info, func_id, XC_UNPOLARIZED )
!   call xc_f90_lda_exc_vxc( xc_func, size, rho(1) ,ex(1), vx(1) )
!   call xc_f90_func_end( xc_func )  
! #else
  REAL(DP), PARAMETER   :: f = -0.687247939924714d0, alpha = 2.0d0/3.0d0
  !                        f = -9/8*(3/2pi)^(2/3)
  ex = f * alpha / rs
  vx = 4.d0 / 3.d0 * f * alpha / rs
! #endif
  !
  RETURN
  !
END SUBROUTINE slater
!
!
!-----------------------------------------------------------------------
SUBROUTINE slater1( length, rs, ex, vx )
  !---------------------------------------------------------------------
  !        Slater exchange with alpha=1, corresponding to -1.374/r_s Ry
  !        used to recover old results
  !
  USE kinds,      ONLY: DP
  !
  IMPLICIT NONE
  !
  INTEGER,  INTENT(IN)  :: length
  REAL(DP), INTENT(IN),  DIMENSION(length) :: rs
  REAL(DP), INTENT(OUT), DIMENSION(length) :: ex, vx
  REAL(DP), PARAMETER   :: f = -0.687247939924714d0, alpha = 1.0d0
  !
  ex = f * alpha / rs
  vx = 4.d0 / 3.d0 * f * alpha / rs
  !
  RETURN
  !
END SUBROUTINE slater1
!
!
!-----------------------------------------------------------------------
SUBROUTINE slater_rxc( length, rs, ex, vx )
  !---------------------------------------------------------------------
  !        Slater exchange with alpha=2/3 and Relativistic exchange
  !
  USE kinds,      ONLY: DP
  USE constants,  ONLY: pi, c_au
  !
  IMPLICIT NONE
  !
  INTEGER,  INTENT(IN)  :: length
  REAL(DP), INTENT(IN),  DIMENSION(length) :: rs
  REAL(DP), INTENT(OUT), DIMENSION(length) :: ex, vx
  !
  REAL(DP), PARAMETER   :: zero=0.d0, one=1.d0, pfive=0.5d0, &
                           opf=1.5d0 !, C014=0.014D0
  REAL(DP) :: trd, ftrd, tftm, a0, alp, z, fz, fzp, vxp, xp, &
              beta, sb, alb, c014
  INTEGER  :: i
  !
  trd = one/3.d0
  ftrd = 4.d0*trd
  tftm = 2**ftrd-2.d0
  A0 = (4.d0/(9.d0*PI))**trd
  C014= 1.0_DP/a0/c_au
  !
  !      X-alpha PARAMETER:
  alp= 2.d0 * trd
  !
  z  = zero
  fz = zero
  fzp= zero
  !
  DO i = 1, length
     !
     vxp = -3.d0*alp/( 2.d0*PI*A0*rs(i) )
     xp  = 3.d0*vxp/4.d0
     beta= C014 / rs(i)
     sb  = SQRT(1.d0+beta*beta)
     alb = LOG(beta+sb)
     vxp = vxp * ( -pfive + opf * alb / (beta*sb) )
     xp  = xp * ( one-opf*((beta*sb-alb)/beta**2)**2 )
     !  vxf = 2**trd*vxp
     !  exf = 2**trd*xp
     vx(i)  = vxp
     ex(i)  = xp
     !
  ENDDO
  !
END SUBROUTINE slater_rxc
!
!
!
SUBROUTINE slaterKZK( length, rs, ex, vx, vol )
  !---------------------------------------------------------------------
  !        Slater exchange with alpha=2/3, Kwee, Zhang and Krakauer KE
  !        correction
  !
  USE kinds,      ONLY: DP
  !
  IMPLICIT NONE
  !
  INTEGER,  INTENT(IN)  :: length
  REAL(DP), INTENT(IN),  DIMENSION(length) :: rs
  REAL(DP), INTENT(OUT), DIMENSION(length) :: ex, vx
  !
  REAL(DP) :: dL, vol, ga, pi, a0
  REAL(DP), PARAMETER ::  a1 = -2.2037d0, &
              a2 = 0.4710d0, a3 = -0.015d0, ry2h = 0.5d0
  REAL(DP), PARAMETER :: f = -0.687247939924714d0, alpha = 2.0d0/3.0d0
  !                      f = -9/8*(3/2pi)^(2/3)
  !
  pi = 4.d0 * ATAN(1.d0)
  a0 = f * alpha * 2.d0
  !
  dL = vol**(1.d0/3.d0)
  ga = 0.5d0 * dL *(3.d0 /pi)**(1.d0/3.d0)
  !
  WHERE ( rs < ga )
     ex = a0 / rs + a1 * rs / dL**2.d0 + a2 * rs**2.d0 / dL**3.d0
     vx = (4.d0 * a0 / rs + 2.d0 * a1 * rs / dL**2.d0 + &
              a2 * rs**2.d0 / dL**3.d0 ) / 3.d0
  ELSEWHERE
     ex = a0 / ga + a1 * ga / dL**2.d0 + a2 * ga**2.d0 / dL**3.d0 ! solids
     vx = ex
     ! ex = a3 * dL**5.d0 / rs**6.d0                           ! molecules
     ! vx = 3.d0 * ex  
  END WHERE
  !
  ex = ry2h * ex    ! Ry to Hartree
  vx = ry2h * vx
  !
  RETURN
  !
END SUBROUTINE slaterKZK
!
!
!  ... LSDA 
!
!-----------------------------------------------------------------------
SUBROUTINE slater_spin( length, rho, zeta, ex, vx )
  !-----------------------------------------------------------------------
  !     Slater exchange with alpha=2/3, spin-polarized case
  !
  USE kinds, ONLY : DP
  !
  IMPLICIT NONE
  !
  INTEGER,  INTENT(IN) :: length
  REAL(DP), INTENT(IN),  DIMENSION(length)   :: rho, zeta
  REAL(DP), INTENT(OUT), DIMENSION(length)   :: ex
  REAL(DP), INTENT(OUT), DIMENSION(length,2) :: vx
  !
  REAL(DP) :: f, alpha, third, p43
  PARAMETER (f = - 1.10783814957303361d0, alpha = 2.0d0 / 3.0d0)
  ! f = -9/8*(3/pi)^(1/3)
  PARAMETER (third = 1.d0 / 3.d0, p43 = 4.d0 / 3.d0)
  REAL(DP), DIMENSION(length) :: exup, exdw, rho13
  !
  rho13 = ( (1.d0 + zeta)*rho )**third
  exup = f * alpha * rho13
  vx(:,1) = p43 * f * alpha * rho13
  rho13 = ( (1.d0 - zeta)*rho )**third
  exdw = f * alpha * rho13
  vx(:,2) = p43 * f * alpha * rho13
  ex = 0.5d0 * ( (1.d0 + zeta)*exup + (1.d0 - zeta)*exdw)
  !
  RETURN
  !
END SUBROUTINE slater_spin
!
!
!-----------------------------------------------------------------------
SUBROUTINE slater_rxc_spin( length, rho, zeta, ex, vx )
  !-----------------------------------------------------------------------
  !     Slater exchange with alpha=2/3, relativistic exchange case
  !
  USE kinds, ONLY : DP
  USE constants, ONLY : pi
  !
  IMPLICIT NONE
  !
  INTEGER,  INTENT(IN) :: length
  REAL(DP), INTENT(IN),  DIMENSION(length)   :: rho, zeta
  REAL(DP), INTENT(OUT), DIMENSION(length)   :: ex 
  REAL(DP), INTENT(OUT), DIMENSION(length,2) :: vx
  !
  INTEGER :: i
  REAL(DP), PARAMETER :: zero=0.D0, one=1.D0, pfive=.5D0, &
                         opf=1.5D0, C014=0.014D0
  REAL(DP) :: rs, trd, ftrd, tftm, a0, alp,z, fz, fzp, vxp, xp, &
              beta, sb, alb, vxf, exf

  !------------------------------
  trd = one/3.d0
  ftrd = 4.d0*trd
  tftm = 2**ftrd-2.d0
  A0 = (4.d0/(9.d0*PI))**trd
  !
  !      X-alpha PARAMETER:
  alp = 2.d0 * trd
  !------------------------------
  !
  DO i=1,length
     !
     z = zeta(i)
     IF ( rho(i) <=  zero ) THEN
        ex(i)   = zero
        vx(i,:) = zero
        CYCLE
     ELSE
        fz = ((1.d0+z)**ftrd+(1.d0-Z)**ftrd-2.d0)/tftm
        fzp = ftrd*((1.d0+Z)**trd-(1.d0-Z)**trd)/tftm
     ENDIF
     RS = (3.d0 / (4.d0*PI*rho(i)) )**trd
     vxp = -3.d0*alp/(2.d0*PI*A0*RS)
     XP = 3.d0*vxp/4.d0
     !
     beta = C014/RS
     SB = SQRT(1.d0+beta*beta)
     alb = LOG(beta+SB)
     vxp = vxp * (-pfive + opf * alb / (beta*SB))
     xp = xp * (one-opf*((beta*SB-alb)/beta**2)**2)
  
     vxf = 2.d0**trd*vxp
     exf = 2.d0**trd*xp
     vx(i,1)  = vxp + fz*(vxf-vxp) + (1.d0-z)*fzp*(exf-xp)
     vx(i,2)  = vxp + fz*(vxf-vxp) - (1.d0+z)*fzp*(exf-xp)
     ex(i)    = xp  + fz*(exf-xp)
     !
  ENDDO
  !      
END SUBROUTINE slater_rxc_spin
!
!
!-----------------------------------------------------------------------
SUBROUTINE slater1_spin( length, rho, zeta, ex, vx )
  !-----------------------------------------------------------------------
  !     Slater exchange with alpha=2/3, spin-polarized case
  !
  USE kinds, ONLY: DP
  !
  IMPLICIT NONE
  !
  INTEGER,  INTENT(IN) :: length
  REAL(DP), INTENT(IN),  DIMENSION(length)   :: rho, zeta
  REAL(DP), INTENT(OUT), DIMENSION(length)   :: ex
  REAL(DP), INTENT(OUT), DIMENSION(length,2) :: vx
  REAL(DP), PARAMETER :: f = - 1.10783814957303361d0, alpha = 1.0d0, &
                         third = 1.d0 / 3.d0, p43 = 4.d0 / 3.d0
                         ! f = -9/8*(3/pi)^(1/3)
  REAL(DP), DIMENSION(length) :: exup, exdw, rho13
  !
  rho13 = ( (1.d0 + zeta) * rho) **third
  exup = f * alpha * rho13
  vx(:,1) = p43 * f * alpha * rho13
  rho13 = ( (1.d0 - zeta) * rho) **third
  exdw = f * alpha * rho13
  vx(:,2) = p43 * f * alpha * rho13
  ex = 0.5d0 * ( (1.d0 + zeta) * exup + (1.d0 - zeta) * exdw)
  !
  !
  RETURN
  !
END SUBROUTINE slater1_spin
