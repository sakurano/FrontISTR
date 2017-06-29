!-------------------------------------------------------------------------------
! Copyright (c) 2016 The University of Tokyo
! This software is released under the MIT License, see LICENSE.txt
!-------------------------------------------------------------------------------

module hecmw_precond_SAINV_nn
  use hecmw_util
  use m_hecmw_comm_f
  use hecmw_matrix_contact
  use hecmw_matrix_misc
  !$ use omp_lib

  private

  public:: hecmw_precond_nn_SAINV_setup
  public:: hecmw_precond_nn_SAINV_apply
  public:: hecmw_precond_nn_SAINV_clear

  integer(4),parameter :: krealp = 8

  integer(kind=kint) :: NPFIU, NPFIL
  integer(kind=kint) :: N
  integer(kind=kint) :: NDOF, NDOF2
  integer(kind=kint), pointer :: inumFI1L(:) => null()
  integer(kind=kint), pointer :: inumFI1U(:) => null()
  integer(kind=kint), pointer :: FI1L(:) => null()
  integer(kind=kint), pointer :: FI1U(:) => null()

  integer(kind=kint), pointer :: indexL(:) => null()
  integer(kind=kint), pointer :: indexU(:) => null()
  integer(kind=kint), pointer :: itemL(:)  => null()
  integer(kind=kint), pointer :: itemU(:)  => null()
  integer(kind=kint), pointer :: perm(:)   => null()
  integer(kind=kint), pointer :: iperm(:)  => null()
  real(kind=kreal), pointer :: D(:)  => null()
  real(kind=kreal), pointer :: AL(:) => null()
  real(kind=kreal), pointer :: AU(:) => null()

  real(kind=krealp), pointer :: SAINVU(:) => null()
  real(kind=krealp), pointer :: SAINVL(:) => null()
  real(kind=krealp), pointer :: SAINVD(:) => null()
  real(kind=kreal),  pointer :: T(:) => null()

contains

!C***
!C*** hecmw_precond_nn_sainv_setup
!C***
  subroutine hecmw_precond_nn_SAINV_setup(hecMAT)
    implicit none
    type(hecmwST_matrix) :: hecMAT

    integer(kind=kint ) :: NPU, NPL, NP
    integer(kind=kint ) :: rcm
    integer(kind=kint ) :: ierror, PRECOND

    real(kind=krealp) :: FILTER

    N = hecMAT%N
    NDOF = hecmat%NDOF
    NDOF2 = NDOF*NDOF
    PRECOND = hecmw_mat_get_precond(hecMAT)

    D => hecMAT%D
    AU=> hecMAT%AU
    AL=> hecMAT%AL
    indexL => hecMAT%indexL
    indexU => hecMAT%indexU
    itemL => hecMAT%itemL
    itemU => hecMAT%itemU

    if (PRECOND.eq.20) call FORM_ILU1_SAINV_nn(hecMAT)

    allocate (SAINVD(NDOF2*hecMAT%NP))
    allocate (SAINVL(NDOF2*NPFIU))
    allocate (T(NDOF*hecMAT%NP))
    SAINVD  = 0.0d0
    SAINVL  = 0.0d0
    T = 0.0d0

    FILTER= hecMAT%Rarray(5)

    Write(*,"(a,F15.8)")"### SAINV FILTER   :",FILTER

    call hecmw_sainv_nn(hecMAT)

    allocate (SAINVU(NDOF2*NPFIU))
    SAINVU  = 0.0d0

    call hecmw_sainv_make_u_nn(hecMAT)

  end subroutine hecmw_precond_nn_SAINV_setup

  subroutine hecmw_sainv_lu_nn()
    implicit none
    integer(kind=kint) :: i,j,js,je,in
    real(kind=kreal) :: X1, X2, X3, X(NDOF)

    do i=1, N
      write(*,*)NDOF
      SAINVD(9*i-5) = SAINVD(9*i-5)*SAINVD(9*i-4)
      SAINVD(9*i-2) = SAINVD(9*i-2)*SAINVD(9*i  )
      SAINVD(9*i-1) = SAINVD(9*i-1)*SAINVD(9*i  )
    enddo

    do i=1, N
      js = inumFI1L(i-1)+1
      je = inumFI1L(i)
      do j= js,je
        in= FI1L(j)
        X1= SAINVD(9*i-8)
        X2= SAINVD(9*i-4)
        X3= SAINVD(9*i  )
        SAINVL(9*j-8) = SAINVL(9*j-8)*X1
        SAINVL(9*j-7) = SAINVL(9*j-7)*X1
        SAINVL(9*j-6) = SAINVL(9*j-6)*X1
        SAINVL(9*j-5) = SAINVL(9*j-5)*X2
        SAINVL(9*j-4) = SAINVL(9*j-4)*X2
        SAINVL(9*j-3) = SAINVL(9*j-3)*X2
        SAINVL(9*j-2) = SAINVL(9*j-2)*X3
        SAINVL(9*j-1) = SAINVL(9*j-1)*X3
        SAINVL(9*j  ) = SAINVL(9*j  )*X3
      enddo
    enddo

  end subroutine hecmw_sainv_lu_nn

  subroutine hecmw_precond_nn_SAINV_apply(R, ZP)
    implicit none
    real(kind=kreal), intent(inout)  :: ZP(:)
    real(kind=kreal), intent(in)  :: R(:)
    integer(kind=kint) :: in, i, j, isL, ieL, isU, ieU, k, iold, rcm
    real(kind=kreal) :: SW1, SW2, SW3, X1, X2, X3

!$OMP PARALLEL DEFAULT(NONE) &
!$OMP&PRIVATE(i,X1,X2,X3,SW1,SW2,SW3,j,in,isL,ieL,isU,ieU) &
!$OMP&SHARED(N,SAINVD,SAINVL,SAINVU,inumFI1U,FI1U,inumFI1L,FI1L,R,T,ZP)
!$OMP DO
      !C-- FORWARD
      do i= 1, N
        SW1= 0.0d0
        SW2= 0.0d0
        SW3= 0.0d0

        isL= inumFI1L(i-1)+1
        ieL= inumFI1L(i)
        do j= isL, ieL
          in= FI1L(j)
          X1= R(3*in-2)
          X2= R(3*in-1)
          X3= R(3*in  )
          SW1= SW1 + SAINVL(9*j-8)*X1 + SAINVL(9*j-7)*X2 + SAINVL(9*j-6)*X3
          SW2= SW2 + SAINVL(9*j-5)*X1 + SAINVL(9*j-4)*X2 + SAINVL(9*j-3)*X3
          SW3= SW3 + SAINVL(9*j-2)*X1 + SAINVL(9*j-1)*X2 + SAINVL(9*j  )*X3
        enddo

        X1= R(3*i-2)
        X2= R(3*i-1)
        X3= R(3*i  )

        T(3*i-2)= (X1 + SW1)*SAINVD(9*i-8)
        T(3*i-1)= (X2 + SAINVD(9*i-7)*X1 + SW2)*SAINVD(9*i-4)
        T(3*i  )= (X3 + SAINVD(9*i-6)*X1 + SAINVD(9*i-3)*X2 + SW3)*SAINVD(9*i  )
      enddo
!$OMP END DO
!$OMP DO
      !C-- BACKWARD
      do i= 1, N
        SW1= 0.0d0
        SW2= 0.0d0
        SW3= 0.0d0

        isU= inumFI1U(i-1) + 1
        ieU= inumFI1U(i)
        do j= isU, ieU
          in= FI1U(j)
          X1= T(3*in-2)
          X2= T(3*in-1)
          X3= T(3*in  )
          SW1= SW1 + SAINVU(9*j-8)*X1 + SAINVU(9*j-7)*X2 + SAINVU(9*j-6)*X3
          SW2= SW2 + SAINVU(9*j-5)*X1 + SAINVU(9*j-4)*X2 + SAINVU(9*j-3)*X3
          SW3= SW3 + SAINVU(9*j-2)*X1 + SAINVU(9*j-1)*X2 + SAINVU(9*j  )*X3
        enddo

        X1= T(3*i-2)
        X2= T(3*i-1)
        X3= T(3*i  )

        ZP(3*i-2)= X1 + SW1 + SAINVD(9*i-7)*X2 + SAINVD(9*i-6)*X3
        ZP(3*i-1)= X2 + SW2 + SAINVD(9*i-3)*X3
        ZP(3*i  )= X3 + SW3
      enddo
!$OMP END DO
!$OMP END PARALLEL

  end subroutine hecmw_precond_nn_SAINV_apply


!C***
!C*** hecmw_rif_nn
!C***
    subroutine hecmw_sainv_nn(hecMAT)
    implicit none
    type (hecmwST_matrix)     :: hecMAT

    integer(kind=kint) :: i, j, jS, jE, in, itr, iitr, ind(9), PRECOND
    real(kind=krealp) :: YV1, YV2, YV3, X1, X2, X3, dd, dd1, dd2, dd3, dtemp(3)
    real(kind=krealp) :: FILTER, SIGMA_DIAG
    real(kind=krealp), allocatable :: zz(:), vv(:)

    FILTER= hecMAT%Rarray(5)

    allocate (vv(NDOF*hecMAT%NP))
    allocate (zz(NDOF*hecMAT%NP))
    dO itr=1,N

    !------------------------------ iitr = 1 ----------------------------------------

    zz(:) = 0.0d0
    vv(:) = 0.0d0

    !{v}=[A]{zi}

    zz(3*itr-2)= SAINVD(9*itr-8)
    zz(3*itr-1)= SAINVD(9*itr-5)
    zz(3*itr  )= SAINVD(9*itr-2)

    zz(3*itr-2)= 1.0d0! * SIGMA_DIAG

    jS= inumFI1L(itr-1) + 1
    jE= inumFI1L(itr  )
    do j= jS, jE
      in  = FI1L(j)
      zz(3*in-2)= SAINVL(9*j-8)
      zz(3*in-1)= SAINVL(9*j-7)
      zz(3*in  )= SAINVL(9*J-6)
    enddo

    do i= 1, itr
      X1= zz(3*i-2)
      X2= zz(3*i-1)
      X3= zz(3*i  )
      vv(3*i-2) = vv(3*i-2) + D(9*i-8)*X1 + D(9*i-7)*X2 + D(9*i-6)*X3
      vv(3*i-1) = vv(3*i-1) + D(9*i-5)*X1 + D(9*i-4)*X2 + D(9*i-3)*X3
      vv(3*i  ) = vv(3*i  ) + D(9*i-2)*X1 + D(9*i-1)*X2 + D(9*i  )*X3

      jS= indexL(i-1) + 1
      jE= indexL(i  )
      do j=jS,jE
        in = itemL(j)
        vv(3*in-2)= vv(3*in-2) + AL(9*j-8)*X1 + AL(9*j-5)*X2 + AL(9*j-2)*X3
        vv(3*in-1)= vv(3*in-1) + AL(9*j-7)*X1 + AL(9*j-4)*X2 + AL(9*j-1)*X3
        vv(3*in  )= vv(3*in  ) + AL(9*j-6)*X1 + AL(9*j-3)*X2 + AL(9*j  )*X3
      enddo

      jS= indexU(i-1) + 1
      jE= indexU(i  )
      do j= jS, jE
        in = itemU(j)
        vv(3*in-2)= vv(3*in-2) + AU(9*j-8)*X1 + AU(9*j-5)*X2 + AU(9*j-2)*X3
        vv(3*in-1)= vv(3*in-1) + AU(9*j-7)*X1 + AU(9*j-4)*X2 + AU(9*j-1)*X3
        vv(3*in  )= vv(3*in  ) + AU(9*j-6)*X1 + AU(9*j-3)*X2 + AU(9*j  )*X3
      enddo
    enddo

    !{d}={v^t}{z_j}

    !dtemp(1) = SAINVD(9*itr-8)
    !dtemp(2) = SAINVD(9*itr-4)

!$OMP PARALLEL DEFAULT(NONE) &
!$OMP&PRIVATE(i,j,jS,jE,in,X1,X2,X3) &
!$OMP&FIRSTPRIVATE(vv) &
!$OMP&SHARED(N,itr,SAINVD,SAINVL,inumFI1L,FI1L)
!$OMP DO
    do i=itr,N
      SAINVD(9*i-8) = vv(3*i-2)
      SAINVD(9*i-4) = vv(3*i-2)*SAINVD(9*i-7)   + vv(3*i-1)
      SAINVD(9*i  ) = vv(3*i-2)*SAINVD(9*i-6)   + vv(3*i-1)*SAINVD(9*i-3)  + vv(3*i)
      jS= inumFI1L(i-1) + 1
      jE= inumFI1L(i  )
      do j= jS, jE
        in  = FI1L(j)
        X1= vv(3*in-2)
        X2= vv(3*in-1)
        X3= vv(3*in  )
        SAINVD(9*i-8)= SAINVD(9*i-8) + X1*SAINVL(9*j-8) + X2*SAINVL(9*j-7) + X3*SAINVL(9*j-6)
        SAINVD(9*i-4)= SAINVD(9*i-4) + X1*SAINVL(9*j-5) + X2*SAINVL(9*j-4) + X3*SAINVL(9*j-3)
        SAINVD(9*i  )= SAINVD(9*i  ) + X1*SAINVL(9*j-2) + X2*SAINVL(9*j-1) + X3*SAINVL(9*j  )
      enddo
    enddo
!$OMP END DO
!$OMP END PARALLEL

    !Update D
    dd = 1.0d0/SAINVD(9*itr-8)

    SAINVD(9*itr-4) =SAINVD(9*itr-4)*dd
    SAINVD(9*itr  ) =SAINVD(9*itr  )*dd

    do i =itr+1,N
      SAINVD(9*i-8) = SAINVD(9*i-8)*dd
      SAINVD(9*i-4) = SAINVD(9*i-4)*dd
      SAINVD(9*i  ) = SAINVD(9*i  )*dd
    enddo

    !Update Z

    dd2=SAINVD(9*itr-4)
    if(dabs(dd2) > FILTER)then
      SAINVD(9*itr-7)= SAINVD(9*itr-7) - dd2*zz(3*itr-2)
      jS= inumFI1L(itr-1) + 1
      jE= inumFI1L(itr  )
      do j= jS, jE
        in  = FI1L(j)
        SAINVL(9*j-5) = SAINVL(9*j-5)-dd2*zz(3*in-2)
        SAINVL(9*j-4) = SAINVL(9*j-4)-dd2*zz(3*in-1)
        SAINVL(9*j-3) = SAINVL(9*j-3)-dd2*zz(3*in  )
      enddo
    endif

    dd3=SAINVD(9*itr  )
    if(dabs(dd3) > FILTER)then
      SAINVD(9*itr-6)= SAINVD(9*itr-6) - dd3*zz(3*itr-2)
      jS= inumFI1L(itr-1) + 1
      jE= inumFI1L(itr  )
      do j= jS, jE
        in  = FI1L(j)
        SAINVL(9*j-2) = SAINVL(9*j-2)-dd3*zz(3*in-2)
        SAINVL(9*j-1) = SAINVL(9*j-1)-dd3*zz(3*in-1)
        SAINVL(9*j  ) = SAINVL(9*j  )-dd3*zz(3*in  )
      enddo
    endif

    do i= itr +1,N
      jS= inumFI1L(i-1) + 1
      jE= inumFI1L(i  )
      dd1=SAINVD(9*i-8)
      if(dabs(dd1) > FILTER)then
        do j= jS, jE
          in  = FI1L(j)
          if (in > itr) exit
          SAINVL(9*j-8) = SAINVL(9*j-8)-dd1*zz(3*in-2)
          SAINVL(9*j-7) = SAINVL(9*j-7)-dd1*zz(3*in-1)
          SAINVL(9*j-6) = SAINVL(9*j-6)-dd1*zz(3*in  )
        enddo
      endif
      dd2=SAINVD(9*i-4)
      if(dabs(dd2) > FILTER)then
        do j= jS, jE
          in  = FI1L(j)
          if (in > itr) exit
          SAINVL(9*j-5) = SAINVL(9*j-5)-dd2*zz(3*in-2)
          SAINVL(9*j-4) = SAINVL(9*j-4)-dd2*zz(3*in-1)
          SAINVL(9*j-3) = SAINVL(9*j-3)-dd2*zz(3*in  )
        enddo
      endif
      dd3=SAINVD(9*i  )
      if(dabs(dd3) > FILTER)then
        do j= jS, jE
          in  = FI1L(j)
          if (in > itr) exit
          SAINVL(9*j-2) = SAINVL(9*j-2)-dd3*zz(3*in-2)
          SAINVL(9*j-1) = SAINVL(9*j-1)-dd3*zz(3*in-1)
          SAINVL(9*j  ) = SAINVL(9*j  )-dd3*zz(3*in  )
        enddo
      endif
    enddo

    !------------------------------ iitr = 1 ----------------------------------------

    zz(:) = 0.0d0
    vv(:) = 0.0d0

    !{v}=[A]{zi}

    zz(3*itr-2)= SAINVD(9*itr-7)
    zz(3*itr-1)= SAINVD(9*itr-4)
    zz(3*itr  )= SAINVD(9*itr-1)

    zz(3*itr-1)= 1.0d0

    jS= inumFI1L(itr-1) + 1
    jE= inumFI1L(itr  )
    do j= jS, jE
      in  = FI1L(j)
      zz(3*in-2)= SAINVL(9*j-5)
      zz(3*in-1)= SAINVL(9*j-4)
      zz(3*in  )= SAINVL(9*J-3)
    enddo

    do i= 1, itr
      X1= zz(3*i-2)
      X2= zz(3*i-1)
      X3= zz(3*i  )
      vv(3*i-2) = vv(3*i-2) + D(9*i-8)*X1 + D(9*i-7)*X2 + D(9*i-6)*X3
      vv(3*i-1) = vv(3*i-1) + D(9*i-5)*X1 + D(9*i-4)*X2 + D(9*i-3)*X3
      vv(3*i  ) = vv(3*i  ) + D(9*i-2)*X1 + D(9*i-1)*X2 + D(9*i  )*X3

      jS= indexL(i-1) + 1
      jE= indexL(i  )
      do j=jS,jE
        in = itemL(j)
        vv(3*in-2)= vv(3*in-2) + AL(9*j-8)*X1 + AL(9*j-5)*X2 + AL(9*j-2)*X3
        vv(3*in-1)= vv(3*in-1) + AL(9*j-7)*X1 + AL(9*j-4)*X2 + AL(9*j-1)*X3
        vv(3*in  )= vv(3*in  ) + AL(9*j-6)*X1 + AL(9*j-3)*X2 + AL(9*j  )*X3
      enddo

      jS= indexU(i-1) + 1
      jE= indexU(i  )
      do j= jS, jE
        in = itemU(j)
        vv(3*in-2)= vv(3*in-2) + AU(9*j-8)*X1 + AU(9*j-5)*X2 + AU(9*j-2)*X3
        vv(3*in-1)= vv(3*in-1) + AU(9*j-7)*X1 + AU(9*j-4)*X2 + AU(9*j-1)*X3
        vv(3*in  )= vv(3*in  ) + AU(9*j-6)*X1 + AU(9*j-3)*X2 + AU(9*j  )*X3
      enddo
    enddo

    !{d}={v^t}{z_j}
    dtemp(1) = SAINVD(9*itr-8)

!$OMP PARALLEL DEFAULT(NONE) &
!$OMP&PRIVATE(i,j,jS,jE,in,X1,X2,X3) &
!$OMP&FIRSTPRIVATE(vv) &
!$OMP&SHARED(N,itr,SAINVD,SAINVL,inumFI1L,FI1L)
!$OMP DO
    do i=itr,N
      SAINVD(9*i-8) = vv(3*i-2)
      SAINVD(9*i-4) = vv(3*i-2)*SAINVD(9*i-7)   + vv(3*i-1)
      SAINVD(9*i  ) = vv(3*i-2)*SAINVD(9*i-6)   + vv(3*i-1)*SAINVD(9*i-3)  + vv(3*i)
      jS= inumFI1L(i-1) + 1
      jE= inumFI1L(i  )
      do j= jS, jE
        in  = FI1L(j)
        X1= vv(3*in-2)
        X2= vv(3*in-1)
        X3= vv(3*in  )
        SAINVD(9*i-8)= SAINVD(9*i-8) + X1*SAINVL(9*j-8) + X2*SAINVL(9*j-7) + X3*SAINVL(9*j-6)
        SAINVD(9*i-4)= SAINVD(9*i-4) + X1*SAINVL(9*j-5) + X2*SAINVL(9*j-4) + X3*SAINVL(9*j-3)
        SAINVD(9*i  )= SAINVD(9*i  ) + X1*SAINVL(9*j-2) + X2*SAINVL(9*j-1) + X3*SAINVL(9*j  )
      enddo
    enddo
!$OMP END DO
!$OMP END PARALLEL

    !Update D
    dd = 1.0d0/SAINVD(9*itr-4)

    SAINVD(9*itr-8) = dtemp(1)
    SAINVD(9*itr  ) =SAINVD(9*itr  )*dd

    do i =itr+1,N
      SAINVD(9*i-8) = SAINVD(9*i-8)*dd
      SAINVD(9*i-4) = SAINVD(9*i-4)*dd
      SAINVD(9*i  ) = SAINVD(9*i  )*dd
    enddo

    !Update Z
    dd3=SAINVD(9*itr  )
    if(dabs(dd3) > FILTER)then
      SAINVD(9*itr-6)= SAINVD(9*itr-6) - dd3*zz(3*itr-2)
      SAINVD(9*itr-3)= SAINVD(9*itr-3) - dd3*zz(3*itr-1)

      jS= inumFI1L(itr-1) + 1
      jE= inumFI1L(itr  )
      do j= jS, jE
        in  = FI1L(j)
        SAINVL(9*j-2) = SAINVL(9*j-2)-dd3*zz(3*in-2)
        SAINVL(9*j-1) = SAINVL(9*j-1)-dd3*zz(3*in-1)
        SAINVL(9*j  ) = SAINVL(9*j  )-dd3*zz(3*in  )
      enddo
    endif

    do i= itr +1,N
      jS= inumFI1L(i-1) + 1
      jE= inumFI1L(i  )
      dd1=SAINVD(9*i-8)
      if(dabs(dd1) > FILTER)then
        do j= jS, jE
          in  = FI1L(j)
          if (in > itr) exit
          SAINVL(9*j-8) = SAINVL(9*j-8)-dd1*zz(3*in-2)
          SAINVL(9*j-7) = SAINVL(9*j-7)-dd1*zz(3*in-1)
          SAINVL(9*j-6) = SAINVL(9*j-6)-dd1*zz(3*in  )
        enddo
      endif
      dd2=SAINVD(9*i-4)
      if(dabs(dd2) > FILTER)then
        do j= jS, jE
          in  = FI1L(j)
          if (in > itr) exit
          SAINVL(9*j-5) = SAINVL(9*j-5)-dd2*zz(3*in-2)
          SAINVL(9*j-4) = SAINVL(9*j-4)-dd2*zz(3*in-1)
          SAINVL(9*j-3) = SAINVL(9*j-3)-dd2*zz(3*in  )
        enddo
      endif
      dd3=SAINVD(9*i  )
      if(dabs(dd3) > FILTER)then
        do j= jS, jE
          in  = FI1L(j)
          if (in > itr) exit
          SAINVL(9*j-2) = SAINVL(9*j-2)-dd3*zz(3*in-2)
          SAINVL(9*j-1) = SAINVL(9*j-1)-dd3*zz(3*in-1)
          SAINVL(9*j  ) = SAINVL(9*j  )-dd3*zz(3*in  )
        enddo
      endif
    enddo


    !------------------------------ iitr = 1 ----------------------------------------

    zz(:) = 0.0d0
    vv(:) = 0.0d0

    !{v}=[A]{zi}

    zz(3*itr-2)= SAINVD(9*itr-6)
    zz(3*itr-1)= SAINVD(9*itr-3)
    zz(3*itr  )= SAINVD(9*itr  )

    zz(3*itr  )= 1.0d0

    jS= inumFI1L(itr-1) + 1
    jE= inumFI1L(itr  )
    do j= jS, jE
      in  = FI1L(j)
      zz(3*in-2)= SAINVL(9*j-2)
      zz(3*in-1)= SAINVL(9*j-1)
      zz(3*in  )= SAINVL(9*J  )
    enddo

    do i= 1, itr
      X1= zz(3*i-2)
      X2= zz(3*i-1)
      X3= zz(3*i  )
      vv(3*i-2) = vv(3*i-2) + D(9*i-8)*X1 + D(9*i-7)*X2 + D(9*i-6)*X3
      vv(3*i-1) = vv(3*i-1) + D(9*i-5)*X1 + D(9*i-4)*X2 + D(9*i-3)*X3
      vv(3*i  ) = vv(3*i  ) + D(9*i-2)*X1 + D(9*i-1)*X2 + D(9*i  )*X3

      jS= indexL(i-1) + 1
      jE= indexL(i  )
      do j=jS,jE
        in = itemL(j)
        vv(3*in-2)= vv(3*in-2) + AL(9*j-8)*X1 + AL(9*j-5)*X2 + AL(9*j-2)*X3
        vv(3*in-1)= vv(3*in-1) + AL(9*j-7)*X1 + AL(9*j-4)*X2 + AL(9*j-1)*X3
        vv(3*in  )= vv(3*in  ) + AL(9*j-6)*X1 + AL(9*j-3)*X2 + AL(9*j  )*X3
      enddo

      jS= indexU(i-1) + 1
      jE= indexU(i  )
      do j= jS, jE
        in = itemU(j)
        vv(3*in-2)= vv(3*in-2) + AU(9*j-8)*X1 + AU(9*j-5)*X2 + AU(9*j-2)*X3
        vv(3*in-1)= vv(3*in-1) + AU(9*j-7)*X1 + AU(9*j-4)*X2 + AU(9*j-1)*X3
        vv(3*in  )= vv(3*in  ) + AU(9*j-6)*X1 + AU(9*j-3)*X2 + AU(9*j  )*X3
      enddo
    enddo

    !{d}={v^t}{z_j}
    dtemp(1) = SAINVD(9*itr-8)
    dtemp(2) = SAINVD(9*itr-4)

!$OMP PARALLEL DEFAULT(NONE) &
!$OMP&PRIVATE(i,j,jS,jE,in,X1,X2,X3) &
!$OMP&FIRSTPRIVATE(vv) &
!$OMP&SHARED(N,itr,SAINVD,SAINVL,inumFI1L,FI1L)
!$OMP DO
    do i=itr,N
      SAINVD(9*i-8) = vv(3*i-2)
      SAINVD(9*i-4) = vv(3*i-2)*SAINVD(9*i-7)   + vv(3*i-1)
      SAINVD(9*i  ) = vv(3*i-2)*SAINVD(9*i-6)   + vv(3*i-1)*SAINVD(9*i-3)  + vv(3*i)
      jS= inumFI1L(i-1) + 1
      jE= inumFI1L(i  )
      do j= jS, jE
        in  = FI1L(j)
        X1= vv(3*in-2)
        X2= vv(3*in-1)
        X3= vv(3*in  )
        SAINVD(9*i-8)= SAINVD(9*i-8) + X1*SAINVL(9*j-8) + X2*SAINVL(9*j-7) + X3*SAINVL(9*j-6)
        SAINVD(9*i-4)= SAINVD(9*i-4) + X1*SAINVL(9*j-5) + X2*SAINVL(9*j-4) + X3*SAINVL(9*j-3)
        SAINVD(9*i  )= SAINVD(9*i  ) + X1*SAINVL(9*j-2) + X2*SAINVL(9*j-1) + X3*SAINVL(9*j  )
      enddo
    enddo
!$OMP END DO
!$OMP END PARALLEL

    !Update D
    dd = 1.0d0/SAINVD(9*itr  )

    SAINVD(9*itr-8) = dtemp(1)
    SAINVD(9*itr-4) = dtemp(2)

    do i =itr+1,N
      SAINVD(9*i-8) = SAINVD(9*i-8)*dd
      SAINVD(9*i-4) = SAINVD(9*i-4)*dd
      SAINVD(9*i  ) = SAINVD(9*i  )*dd
    enddo

    !Update Z
    do i= itr +1,N
      jS= inumFI1L(i-1) + 1
      jE= inumFI1L(i  )
      dd1=SAINVD(9*i-8)
      if(dabs(dd1) > FILTER)then
        do j= jS, jE
          in  = FI1L(j)
          if (in > itr) exit
          SAINVL(9*j-8) = SAINVL(9*j-8)-dd1*zz(3*in-2)
          SAINVL(9*j-7) = SAINVL(9*j-7)-dd1*zz(3*in-1)
          SAINVL(9*j-6) = SAINVL(9*j-6)-dd1*zz(3*in  )
        enddo
      endif
      dd2=SAINVD(9*i-4)
      if(dabs(dd2) > FILTER)then
        do j= jS, jE
          in  = FI1L(j)
          if (in > itr) exit
          SAINVL(9*j-5) = SAINVL(9*j-5)-dd2*zz(3*in-2)
          SAINVL(9*j-4) = SAINVL(9*j-4)-dd2*zz(3*in-1)
          SAINVL(9*j-3) = SAINVL(9*j-3)-dd2*zz(3*in  )
        enddo
      endif
      dd3=SAINVD(9*i  )
      if(dabs(dd3) > FILTER)then
        do j= jS, jE
          in  = FI1L(j)
          if (in > itr) exit
          SAINVL(9*j-2) = SAINVL(9*j-2)-dd3*zz(3*in-2)
          SAINVL(9*j-1) = SAINVL(9*j-1)-dd3*zz(3*in-1)
          SAINVL(9*j  ) = SAINVL(9*j  )-dd3*zz(3*in  )
        enddo
      endif
    enddo
    enddo
    deallocate(vv)
    deallocate(zz)

    do i =1,N
      SAINVD(9*i-8) = 1.0d0/SAINVD(9*i-8)
      SAINVD(9*i-4) = 1.0d0/SAINVD(9*i-4)
      SAINVD(9*i  ) = 1.0d0/SAINVD(9*i  )
      SAINVD(9*i-5) = SAINVD(9*i-7)
      SAINVD(9*i-2) = SAINVD(9*i-6)
      SAINVD(9*i-1) = SAINVD(9*i-3)
    enddo

  end subroutine hecmw_sainv_nn

  subroutine hecmw_sainv_make_u_nn(hecMAT)
    implicit none
    type (hecmwST_matrix)     :: hecMAT
    integer(kind=kint) i,j,k,kk,n,m,o,idof,jdof
    integer(kind=kint) is,ie,js,je

    n = 1
    do i= 1, hecMAT%NP
      is=inumFI1U(i-1) + 1
      ie=inumFI1U(i  )
      flag1:do k= is, ie
        m = FI1U(k)
        js=inumFI1L(m-1) + 1
        je=inumFI1L(m  )
        do j= js,je
          o = FI1L(j)
          if (o == i)then
            do idof = 1, NDOF
              do jdof = 1, NDOF
!              SAINVU(NDOF2*(n-1)+NDOF*(idof-1)+jdof)=SAINVL(NDOF2*(n-1)+NDOF*(jdof-1)+idof)
              end do 
            end do 
            SAINVU(9*n-8)=SAINVL(9*j-8)
            SAINVU(9*n-7)=SAINVL(9*j-5)
            SAINVU(9*n-6)=SAINVL(9*j-2)
            SAINVU(9*n-5)=SAINVL(9*j-7)
            SAINVU(9*n-4)=SAINVL(9*j-4)
            SAINVU(9*n-3)=SAINVL(9*j-1)
            SAINVU(9*n-2)=SAINVL(9*j-6)
            SAINVU(9*n-1)=SAINVL(9*j-3)
            SAINVU(9*n  )=SAINVL(9*j  )
            n = n + 1
            cycle flag1
          endif
        enddo
      enddo flag1
    enddo
  end subroutine hecmw_sainv_make_u_nn

!C***
!C*** FORM_ILU1_nn
!C*** form ILU(1) matrix
  subroutine FORM_ILU0_SAINV_nn(hecMAT)
    implicit none
    type(hecmwST_matrix) :: hecMAT

    allocate (inumFI1L(0:hecMAT%NP), inumFI1U(0:hecMAT%NP))
    allocate (FI1L (hecMAT%NPL), FI1U (hecMAT%NPU))

    inumFI1L = 0
    inumFI1U = 0
    FI1L = 0
    FI1U = 0

    inumFI1L = hecMAT%indexL
    inumFI1U = hecMAT%indexU
    FI1L = hecMAT%itemL
    FI1U = hecMAT%itemU

    NPFIU = hecMAT%NPU
    NPFIL = hecMAT%NPL

  end subroutine FORM_ILU0_SAINV_nn

!C***
!C*** FORM_ILU1_nn
!C*** form ILU(1) matrix
  subroutine FORM_ILU1_SAINV_nn(hecMAT)
    implicit none
    type(hecmwST_matrix) :: hecMAT

    integer(kind=kint),allocatable :: IWsL(:), IWsU(:), IW1(:), IW2(:)
    integer(kind=kint) :: NPLf1,NPUf1
    integer(kind=kint) :: i,jj,jj1,ij0,kk,ik,kk1,kk2,L,iSk,iEk,iSj,iEj
    integer(kind=kint) :: icou,icou0,icouU,icouU1,icouU2,icouU3,icouL,icouL1,icouL2,icouL3
    integer(kind=kint) :: j,k,iSL,iSU
    !C
    !C +--------------+
    !C | find fill-in |
    !C +--------------+
    !C===

    !C
    !C-- count fill-in
    allocate (IW1(hecMAT%NP) , IW2(hecMAT%NP))
    allocate (inumFI1L(0:hecMAT%NP), inumFI1U(0:hecMAT%NP))

    inumFI1L= 0
    inumFI1U= 0

    NPLf1= 0
    NPUf1= 0
    do i= 2, hecMAT%NP
    icou= 0
    IW1= 0
    IW1(i)= 1
    do L= indexL(i-1)+1, indexL(i)
      IW1(itemL(L))= 1
    enddo
    do L= indexU(i-1)+1, indexU(i)
      IW1(itemU(L))= 1
    enddo

      iSk= indexL(i-1) + 1
      iEk= indexL(i)
      do k= iSk, iEk
        kk= itemL(k)
        iSj= indexU(kk-1) + 1
        iEj= indexU(kk  )
        do j= iSj, iEj
          jj= itemU(j)
          if (IW1(jj).eq.0 .and. jj.lt.i) then
            inumFI1L(i)= inumFI1L(i)+1
            IW1(jj)= 1
          endif
          if (IW1(jj).eq.0 .and. jj.gt.i) then
            inumFI1U(i)= inumFI1U(i)+1
            IW1(jj)= 1
          endif
        enddo
      enddo
      NPLf1= NPLf1 + inumFI1L(i)
      NPUf1= NPUf1 + inumFI1U(i)
    enddo

    !C
    !C-- specify fill-in
    allocate (IWsL(0:hecMAT%NP), IWsU(0:hecMAT%NP))
    allocate (FI1L (hecMAT%NPL+NPLf1), FI1U (hecMAT%NPU+NPUf1))

    NPFIU = hecMAT%NPU+NPUf1
    NPFIL = hecMAT%NPL+NPLf1

    FI1L= 0
    FI1U= 0

    IWsL= 0
    IWsU= 0
    do i= 1, hecMAT%NP
      IWsL(i)= indexL(i)-indexL(i-1) + inumFI1L(i) + IWsL(i-1)
      IWsU(i)= indexU(i)-indexU(i-1) + inumFI1U(i) + IWsU(i-1)
    enddo

    do i= 2, hecMAT%NP
      icouL= 0
      icouU= 0
      inumFI1L(i)= inumFI1L(i-1) + inumFI1L(i)
      inumFI1U(i)= inumFI1U(i-1) + inumFI1U(i)
      icou= 0
      IW1= 0
      IW1(i)= 1
      do L= indexL(i-1)+1, indexL(i)
        IW1(itemL(L))= 1
      enddo
      do L= indexU(i-1)+1, indexU(i)
        IW1(itemU(L))= 1
      enddo

      iSk= indexL(i-1) + 1
      iEk= indexL(i)
      do k= iSk, iEk
        kk= itemL(k)
        iSj= indexU(kk-1) + 1
        iEj= indexU(kk  )
        do j= iSj, iEj
          jj= itemU(j)
          if (IW1(jj).eq.0 .and. jj.lt.i) then
            icouL           = icouL + 1
            FI1L(icouL+IWsL(i-1)+indexL(i)-indexL(i-1))= jj
            IW1(jj)          = 1
          endif
          if (IW1(jj).eq.0 .and. jj.gt.i) then
            icouU           = icouU + 1
            FI1U(icouU+IWsU(i-1)+indexU(i)-indexU(i-1))= jj
            IW1(jj)          = 1
          endif
        enddo
      enddo
    enddo

    iSL  = 0
    iSU  = 0
    do i= 1, hecMAT%NP
      icouL1= indexL(i) - indexL(i-1)
      icouL2= inumFI1L(i) - inumFI1L(i-1)
      icouL3= icouL1 + icouL2
      icouU1= indexU(i) - indexU(i-1)
      icouU2= inumFI1U(i) - inumFI1U(i-1)
      icouU3= icouU1 + icouU2
      !C
      !C-- LOWER part
      icou0= 0
      do k= indexL(i-1)+1, indexL(i)
        icou0 = icou0 + 1
        IW1(icou0)= itemL(k)
      enddo

      do k= inumFI1L(i-1)+1, inumFI1L(i)
        icou0 = icou0 + 1
        IW1(icou0)= FI1L(icou0+IWsL(i-1))
      enddo

      do k= 1, icouL3
        IW2(k)= k
      enddo
      call SAINV_SORT_nn (IW1, IW2, icouL3, hecMAT%NP)

      do k= 1, icouL3
        FI1L (k+isL)= IW1(k)
      enddo
      !C
      !C-- UPPER part
      icou0= 0
      do k= indexU(i-1)+1, indexU(i)
        icou0 = icou0 + 1
        IW1(icou0)= itemU(k)
      enddo

      do k= inumFI1U(i-1)+1, inumFI1U(i)
        icou0 = icou0 + 1
        IW1(icou0)= FI1U(icou0+IWsU(i-1))
      enddo

      do k= 1, icouU3
        IW2(k)= k
      enddo
      call SAINV_SORT_nn (IW1, IW2, icouU3, hecMAT%NP)

      do k= 1, icouU3
        FI1U (k+isU)= IW1(k)
      enddo

      iSL= iSL + icouL3
      iSU= iSU + icouU3
    enddo

    !C===
    do i= 1, hecMAT%NP
      inumFI1L(i)= IWsL(i)
      inumFI1U(i)= IWsU(i)
    enddo

    deallocate (IW1, IW2)
    deallocate (IWsL, IWsU)
    !C===
  end subroutine FORM_ILU1_SAINV_nn

 !C
  !C***
  !C*** fill_in_S33_SORT
  !C***
  !C
  subroutine SAINV_SORT_nn(STEM, INUM, N, NP)
    use hecmw_util
    implicit none
    integer(kind=kint) :: N, NP
    integer(kind=kint), dimension(NP) :: STEM
    integer(kind=kint), dimension(NP) :: INUM
    integer(kind=kint), dimension(:), allocatable :: ISTACK
    integer(kind=kint) :: M,NSTACK,jstack,l,ir,ip,i,j,k,ss,ii,temp,it

    allocate (ISTACK(-NP:+NP))

    M     = 100
    NSTACK= NP

    jstack= 0
    l     = 1
    ir    = N

    ip= 0
1   continue
    ip= ip + 1

    if (ir-l.lt.M) then
      do j= l+1, ir
        ss= STEM(j)
        ii= INUM(j)

        do i= j-1,1,-1
          if (STEM(i).le.ss) goto 2
          STEM(i+1)= STEM(i)
          INUM(i+1)= INUM(i)
        end do
        i= 0

2       continue
        STEM(i+1)= ss
        INUM(i+1)= ii
      end do

      if (jstack.eq.0) then
        deallocate (ISTACK)
        return
      endif

      ir = ISTACK(jstack)
      l = ISTACK(jstack-1)
      jstack= jstack - 2
    else

      k= (l+ir) / 2
      temp = STEM(k)
      STEM(k)  = STEM(l+1)
      STEM(l+1)= temp

      it = INUM(k)
      INUM(k)  = INUM(l+1)
      INUM(l+1)= it

      if (STEM(l+1).gt.STEM(ir)) then
        temp = STEM(l+1)
        STEM(l+1)= STEM(ir)
        STEM(ir )= temp
        it = INUM(l+1)
        INUM(l+1)= INUM(ir)
        INUM(ir )= it
      endif

      if (STEM(l).gt.STEM(ir)) then
        temp = STEM(l)
        STEM(l )= STEM(ir)
        STEM(ir)= temp
        it = INUM(l)
        INUM(l )= INUM(ir)
        INUM(ir)= it
      endif

      if (STEM(l+1).gt.STEM(l)) then
        temp = STEM(l+1)
        STEM(l+1)= STEM(l)
        STEM(l  )= temp
        it = INUM(l+1)
        INUM(l+1)= INUM(l)
        INUM(l  )= it
      endif

      i= l + 1
      j= ir

      ss= STEM(l)
      ii= INUM(l)

3     continue
      i= i + 1
      if (STEM(i).lt.ss) goto 3

4     continue
      j= j - 1
      if (STEM(j).gt.ss) goto 4

      if (j.lt.i)        goto 5

      temp   = STEM(i)
      STEM(i)= STEM(j)
      STEM(j)= temp

      it     = INUM(i)
      INUM(i)= INUM(j)
      INUM(j)= it

      goto 3

5     continue

      STEM(l)= STEM(j)
      STEM(j)= ss
      INUM(l)= INUM(j)
      INUM(j)= ii

      jstack= jstack + 2

      if (jstack.gt.NSTACK) then
        write (*,*) 'NSTACK overflow'
        stop
      endif

      if (ir-i+1.ge.j-1) then
        ISTACK(jstack  )= ir
        ISTACK(jstack-1)= i
        ir= j-1
      else
        ISTACK(jstack  )= j-1
        ISTACK(jstack-1)= l
        l= i
      endif

    endif

    goto 1

  end subroutine SAINV_SORT_nn

  subroutine hecmw_precond_nn_SAINV_clear()
    implicit none

    if (associated(SAINVD)) deallocate(SAINVD)
    if (associated(SAINVL)) deallocate(SAINVL)
    if (associated(SAINVU)) deallocate(SAINVU)
    if (associated(inumFI1L)) deallocate(inumFI1L)
    if (associated(inumFI1U)) deallocate(inumFI1U)
    if (associated(FI1L)) deallocate(FI1L)
    if (associated(FI1U)) deallocate(FI1U)
    nullify(inumFI1L)
    nullify(inumFI1U)
    nullify(FI1L)
    nullify(FI1U)
    nullify(D)
    nullify(AL)
    nullify(AU)
    nullify(indexL)
    nullify(indexU)
    nullify(itemL)
    nullify(itemU)

  end subroutine hecmw_precond_nn_SAINV_clear
end module hecmw_precond_SAINV_nn