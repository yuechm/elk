
! Copyright (C) 2002-2011 J. K. Dewhurst, S. Sharma and C. Ambrosch-Draxl.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.

! main routine for the Elk code
program main
use modmain
use modmpi
use modvars
implicit none
! local variables
logical exist
integer itask
! initialise MPI execution environment
call mpi_init(ierror)
! duplicate mpi_comm_world
call mpi_comm_dup(mpi_comm_world,mpi_comm_kpt,ierror)
! determine the number of MPI processes
call mpi_comm_size(mpi_comm_kpt,np_mpi,ierror)
! determine the local MPI process number
call mpi_comm_rank(mpi_comm_kpt,lp_mpi,ierror)
! determine if the local process is the master
if (lp_mpi.eq.0) then
  mp_mpi=.true.
  write(*,*)
  write(*,'("Elk code version ",I1.1,".",I1.1,".",I2.2," started")') version
  if (np_mpi.gt.1) then
    write(*,*)
    write(*,'("Using MPI, number of processes : ",I8)') np_mpi
  end if
else
  mp_mpi=.false.
end if
! read input files
call readinput
! delete the VARIABLES.OUT file
call delvars
! write version number to VARIABLES.OUT
call writevars('version',nv=3,iva=version)
! check if Elk is already running in this directory
if (mp_mpi) then
  inquire(file='RUNNING',exist=exist)
  if (exist) then
    write(*,*)
    write(*,'("Info(main): several copies of Elk may be running in this path")')
    write(*,'("(this could be intentional, or result from a previous crash,")')
    write(*,'(" or arise from an incorrect MPI compilation)")')
  else
    open(50,file='RUNNING')
    close(50)
  end if
end if
! perform the tasks
do itask=1,ntasks
  task=tasks(itask)
  if (mp_mpi) then
    write(*,*)
    write(*,'("Info(main): current task : ",I6)') task
  end if
! synchronise MPI processes
  call mpi_barrier(mpi_comm_kpt,ierror)
! check if task can be run with MPI
  if (lp_mpi.gt.0) then
    select case(task)
    case(0,1,2,3,5,28,120,135,136,170,180,185,188,240,300,320,330,440)
      continue
    case default
      write(*,'("Info(main): MPI process ",I6," idle for task ",I6)') lp_mpi, &
       task
      cycle
    end select
  end if
! write task to VARIABLES.OUT
  call writevars('task',iv=task)
  select case(task)
  case(-1)
    write(*,'("Elk version ",I1.1,".",I1.1,".",I2.2)') version
  case(0,1)
    call gndstate
  case(2,3)
    call geomopt
  case(5)
    call hartfock
  case(10)
    call dos
  case(14)
    call writesf
  case(15,16)
    call writelsj
  case(20,21)
    call bandstr
  case(25)
    call effmass
  case(28,29)
    call mae
  case(31,32,33)
    call rhoplot
  case(41,42,43)
    call potplot
  case(51,52,53)
    call elfplot
  case(61,62,63,162)
    call wfplot
  case(65)
    call wfcrplot
  case(72,73,82,83,142,143,152,153)
    call vecplot
  case(91,92,93)
    call dbxcplot
  case(100,101)
    call fermisurf
  case(102)
    call fermisurfbxsf
  case(105)
    call nesting
  case(110)
    call mossbauer
  case(115)
    call writeefg
  case(120)
    call writepmat
  case(121)
    call dielectric
  case(122)
    call moke
  case(125)
    call nonlinopt
  case(130)
    call writeexpmat
  case(135)
    call writewfpw
  case(140)
    call elnes
  case(170)
    call writeemd
  case(175)
    call compton
  case(180)
    call epsinv_rpa
  case(185)
    call writehmlbse
  case(186)
    call writeevbse
  case(187)
    call dielectric_bse
  case(190)
    call geomplot
  case(195)
    call sfacrho
  case(196)
    call sfacmag
  case(200,201,202)
    call phononsc
  case(205)
    call phonon
  case(210)
    call phdos
  case(220)
    call phdisp
  case(230)
    call writephn
  case(240)
    call ephcouple
  case(245)
    call phlwidth
  case(250)
    call alpha2f
  case(260)
    call eliashberg
  case(270)
    call scdft
  case(300)
    call rdmft
  case(188,320)
    call tddftlr
  case(330)
    call tddftsplr
  case(350,351,352)
    call spiralsc
  case(400)
    call writetmdu
  case(440)
    call writestress
  case(450)
    call genafieldt
  case(460)
    call tddft
  case(500)
    call testcheck
  case default
    write(*,*)
    write(*,'("Error(main): task not defined : ",I8)') task
    write(*,*)
    stop
  end select
end do
if (mp_mpi) then
  open(50,file='RUNNING')
  close(50,status='DELETE')
  write(*,*)
  write(*,'("Elk code stopped")')
end if
! terminate MPI execution environment
call mpi_finalize(ierror)
stop
end program

!BOI
! !TITLE: {\huge{\sc The Elk Code Manual}}\\ \Large{\sc Version 2.3.22}\\ \vskip 20pt \includegraphics[height=1cm]{elk_silhouette.pdf}
! !AUTHORS: {\sc J. K. Dewhurst, S. Sharma} \\ {\sc L. Nordstr\"{o}m, F. Cricchio, F. Bultmark, O. Gr\aa n\"{a}s} \\ {\sc E. K. U. Gross}
! !AFFILIATION:
! !INTRODUCTION: Introduction
!   Welcome to the Elk Code! Elk is an all-electron full-potential linearised
!   augmented-plane-wave (FP-LAPW) code for determining the properties of
!   crystalline solids. It was developed originally at the
!   Karl-Franzens-Universit\"{a}t Graz as part of the EXCITING EU Research and
!   Training Network project\footnote{EXCITING code developed under the Research
!   and Training Network EXCITING funded by the EU, contract No.
!   HPRN-CT-2002-00317}. The guiding philosophy during the implementation of the
!   code was to keep it as simple as possible for both users and developers
!   without compromising on its capabilities. All the routines are released
!   under either the GNU General Public License (GPL) or the GNU Lesser General
!   Public License (LGPL) in the hope that they may inspire other scientists to
!   implement new developments in the field of density functional theory and
!   beyond.
!
!   \section{Acknowledgments}
!   Lots of people contributed to the Elk code with ideas, checking and testing,
!   writing code or documentation and general encouragement. They include
!   Claudia Ambrosch-Draxl, Clas Persson, Christian Brouder, Rickard Armiento,
!   Andrew Chizmeshya, Per Anderson, Igor Nekrasov, Sushil Auluck, Frank Wagner,
!   Fateh Kalarasse, J\"{u}rgen Spitaler, Stefano Pittalis, Nektarios
!   Lathiotakis, Tobias Burnus, Stephan Sagmeister, Christian Meisenbichler,
!   S\'{e}bastien Leb\`{e}gue, Yigang Zhang, Fritz K\"{o}rmann, Alexey Baranov,
!   Anton Kozhevnikov, Shigeru Suehara, Frank Essenberger, Antonio Sanna, Tyrel
!   McQueen, Tim Baldsiefen, Marty Blaber, Anton Filanovich, Torbj\"{o}rn
!   Bj\"{o}rkman, Martin Stankovski, Jerzy Goraus, Markus Meinert, Daniel Rohr,
!   Vladimir Nazarov, Kevin Krieger, Pink Floyd, Arkardy Davydov, Florian Eich,
!   Aldo Romero Castro, Koichi Kitahara, James Glasbrenner, Konrad Bussmann,
!   Igor Mazin and Matthieu Verstraete. Special mention of David Singh's very
!   useful book on the LAPW method\footnote{D. J. Singh, {\it Planewaves,
!   Pseudopotentials and the LAPW Method} (Kluwer Academic Publishers, Boston,
!   1994).} must also be made. Finally we would like to acknowledge the generous
!   support of Karl-Franzens-Universit\"{a}t Graz, as well as the EU Marie-Curie
!   Research Training Networks initiative.
!
!   \vspace{24pt}
!   Kay Dewhurst\newline
!   Sangeeta Sharma\newline
!   Lars Nordstr\"{o}m\newline
!   Francesco Cricchio\newline
!   Fredrik Bultmark\newline
!   Oscar Gr\aa n\"{a}s\newline
!   Hardy Gross
!
!   \vspace{12pt}
!   Halle and Uppsala, May 2014
!   \newpage
!
!   \section{Units}
!   Unless explicitly stated otherwise, Elk uses atomic units. In this system
!   $\hbar=1$, the electron mass $m=1$, the Bohr radius $a_0=1$ and the electron
!   charge $e=1$ (note that the electron charge is positive, so that the atomic
!   numbers $Z$ are negative). Thus, the atomic unit of length is
!   0.52917721092(17) \AA, and the atomic unit of energy is the Hartree which
!   equals 27.21138505(60) eV. The unit of the external magnetic fields is
!   defined such that one unit of magnetic field in {\tt elk.in} equals
!   1715.2554659 Tesla.
!
!   \section{Compiling and running Elk}
!   \subsection{Compiling the code}
!   Unpack the code from the archive file. Run the command
!   \begin{verbatim}
!     setup
!   \end{verbatim}
!   in the {\tt elk} directory and select the appropriate system and compiler.
!   We highly recommend that you edit the file {\tt make.inc} and tune the
!   compiler options for your computer system. In particular, use of
!   machine-optimised BLAS/LAPACK libraries can result in significant increase
!   in performance, but make sure they are of version $3.x$. Following this, run
!   \begin{verbatim}
!     make
!   \end{verbatim}
!   This will hopefully compile the entire code and all the libraries into one
!   executable, {\tt elk}, located in the {\tt elk/src} directory. It will also
!   compile two useful auxiliary programs, namely {\tt spacegroup} for producing
!   crystal geometries from spacegroup data and {\tt eos} for fitting equations
!   of state to energy-volume data. If you want to compile everything all over
!   again, then run {\tt make clean} from the {\tt elk} directory, followed by
!   {\tt make}.
!   \subsubsection{Parallelism in Elk}
!   Three forms of parallelism are implemented in Elk, and all can be used in
!   combination with each other, with efficiency depending on the particular
!   task, crystal structure and computer system. You may need to contact your
!   system administrator for assistance with running Elk in parallel.
!   \begin{enumerate}
!   \item
!    OpenMP works for symmetric multiprocessors, i.e. computers that have many
!    cores with the same unified memory accessible to each. It is enabled by
!    setting the appropriate command-line options (e.g. {\tt -openmp} for the
!    Intel compiler) before compiling, and also at runtime by the environment
!    variable
!    \begin{verbatim}
!     export OMP_NUM_THREADS=x
!    \end{verbatim}
!    where x is the number of cores available on a particular node. Elk also
!    makes use of nested OpenMP parallelism, meaning that there are nested
!    parallel loops in parts of the code, the iterative diagonaliser being one
!    such example. These nested loops can be run in parallel by setting
!    \begin{verbatim}
!     export OMP_NESTED=true
!    \end{verbatim}
!    Be aware that using this option can actually degrade performance if too
!    many threads are created. To avoid such oversubscription, you may need to
!    adjust related OpenMP variables including {\tt OMP\_THREAD\_LIMIT},
!    {\tt OMP\_MAX\_ACTIVE\_LEVELS} and {\tt OMP\_DYNAMIC} (there may also be
!    additional compiler-specific environment variables that can be set).
!    Finally, some vendor-supplied BLAS/LAPACK libraries use OpenMP internally,
!    for example MKL from Intel and ACML from AMD; refer to their documentation
!    for usage.
!    \item
!    The message passing interface (MPI) is particularly suitable for running
!    Elk across multiple nodes of a cluster, with scaling to hundreds of
!    processors possible. To enable MPI, comment out the lines indicated in
!    {\tt elk/make.inc}. Then run {\tt make clean} followed by {\tt make}. If
!    $y$ is the number of nodes and $x$ is the number of cores per node, then at
!    runtime envoke
!    \begin{verbatim}
!     mpirun -np z ./elk
!    \end{verbatim}
!    where $z=x y$ is the total number of cores available on the machine.
!    Highest efficiency is obtained by using hybrid parallelism with OpenMP on
!    each node and MPI across nodes. This can be done by compiling the code
!    using the MPI Fortran compiler in combination with the OpenMP command-line
!    option. At runtime set {\tt export OMP\_NUM\_THREADS=x} and start the MPI
!    run with {\em one process per node} as follows
!    \begin{verbatim}
!     mpirun -pernode -np y ./elk
!    \end{verbatim}
!    The number of MPI processes is reported in the file {\tt INFO.OUT} which
!    serves as a check that MPI is running correctly. Note that version 2 of the
!    MPI libraries is required to run Elk.
!   \item
!    Phonon calculations use a simple form of parallelism by just examining the
!    run directory for dynamical matrix files. These files are of the form
!    \begin{verbatim}
!     DYN_Qqqqq_qqqq_qqqq_Sss_Aaa_Pp.OUT
!    \end{verbatim}
!    and contain a single row of a particular dynamical matrix. Elk simply finds
!    which {\tt DYN} files do not exist, chooses one and runs it. This way many
!    independent runs of Elk can be started in the same directory on a networked
!    file system (NFS), and will run until all the dynamical matrices files are
!    completed. Should a particular run crash, then delete the associated empty
!    {\tt DYN} file and rerun Elk.
!   \end{enumerate}
!
!   \subsection{Linking with the Libxc functional library}
!   Libxc is the ETSF library of exchange-correlation functionals. Elk can use
!   the complete set of LDA and GGA functionals available in Libxc as well as
!   the potential-only metaGGA's. In order to enable this, first download and
!   compile Libxc version 2.2.$x$. This should have produced the files
!   {\tt libxc.a} and {\tt libxcf90.a}. Copy these files to the {\tt elk/src}
!   directory and then uncomment the lines indicated for Libxc in the file
!   {\tt elk/make.inc}. Once this is done, run {\tt make clean} followed by
!   {\tt make}. To select a particular functional of Libxc, use the block
!   \begin{verbatim}
!     xctype
!      100 nx nc
!   \end{verbatim}
!   where {\tt nx} and {\tt nc} are, respectively, the numbers of the exchange
!   and correlation functionals in the Libxc library. See the file
!   {\tt elk/src/libxc\_funcs.f90} for a list of the functionals and their
!   associated numbers.
!
!   \subsection{Running the code}
!   As a rule, all input files for the code are in lower case and end with the
!   extension {\tt .in}. All output files are uppercase and have the extension
!   {\tt .OUT}. For most cases, the user will only need to modify the file
!   {\tt elk.in}. In this file input parameters are arranged in blocks.
!   Each block consists of a block name on one line and the block variables on
!   subsequent lines. Almost all blocks are optional: the code uses reasonable
!   default values in cases where they are absent. Blocks can appear in any
!   order, if a block is repeated then the second instance is used. Comment
!   lines can be included in the input file and begin with the {\tt !}
!   character.
!
!   \subsubsection{Species files}
!   The only other input files are those describing the atomic species which go
!   into the crystal. These files are found in the {\tt species} directory and
!   are named with the element symbol and the extension {\tt .in}, for example
!   {\tt Sb.in}. They contain parameters like the atomic charge, mass,
!   muffin-tin radius, occupied atomic states and the type of linearisation
!   required. Here as an example is the copper species file {\tt Cu.in}:
!   \begin{verbatim}
!    'Cu'                                      : spsymb
!    'copper'                                  : spname
!   -29.0000                                   : spzn
!    115837.2716                               : spmass
!    0.371391E-06    2.0000   34.8965   500    : sprmin, rmt, sprmax, nrmt
!    10                                        : spnst
!    1   0   1   2.00000    T                  : spn, spl, spk, spocc, spcore
!    2   0   1   2.00000    T
!    2   1   1   2.00000    T
!    2   1   2   4.00000    T
!    3   0   1   2.00000    T
!    3   1   1   2.00000    F
!    3   1   2   4.00000    F
!    3   2   2   4.00000    F
!    3   2   3   6.00000    F
!    4   0   1   1.00000    F
!    1                                         : apword
!    0.1500   0  F                             : apwe0, apwdm, apwve
!    1                                         : nlx
!    2   2                                     : lx, apword
!    0.1500   0  T                             : apwe0, apwdm, apwve
!    0.1500   1  T
!    4                                         : nlorb
!    0   2                                     : lorbl, lorbord
!    0.1500   0  F                             : lorbe0, lorbdm, lorbve
!    0.1500   1  F
!    1   2
!    0.1500   0  F
!    0.1500   1  F
!    2   2
!    0.1500   0  F
!    0.1500   1  F
!    1   3
!    0.1500   0  F
!    0.1500   1  F
!   -2.8652   0  T
!   \end{verbatim}
!   The input parameters are defined as follows:
!   \vskip 6pt
!   {\tt spsymb} \\
!   The symbol of the element.
!   \vskip 6pt
!   {\tt spname} \\
!   The name of the element.
!   \vskip 6pt
!   {\tt spzn} \\
!   Nuclear charge: should be negative since the electron charge is taken to be
!   postive in the code; it can also be fractional for purposes of doping.
!   \vskip 6pt
!   {\tt spmass} \\
!   Nuclear mass in atomic units.
!   \vskip 6pt
!   {\tt sprmin}, {\tt rmt}, {\tt sprmax}, {\tt nrmt} \\
!   Respectively, the minimum radius on logarithmic radial mesh; muffin-tin
!   radius; effective infinity for atomic radial mesh; and number of radial mesh
!   points to muffin-tin radius.
!   \vskip 6pt
!   {\tt spnst} \\
!   Number of atomic states.
!   \vskip 6pt
!   {\tt spn}, {\tt spl}, {\tt spk}, {\tt spocc}, {\tt spcore} \\
!   Respectively, the principal quantum number of the radial Dirac equation;
!   quantum number $l$; quantum number $k$ ($l$ or $l+1$); occupancy of atomic
!   state (can be fractional); {\tt .T.} if state is in the core and therefore
!   treated with the Dirac equation in the spherical part of the muffin-tin
!   Kohn-Sham potential.
!   \vskip 6pt
!   {\tt apword} \\
!   Default APW function order, i.e. the number of radial functions and
!   therefore the order of the radial derivative matching at the muffin-tin
!   surface.
!   \vskip 6pt
!   {\tt apwe0}, {\tt apwdm}, {\tt apwve} \\
!   Respectively, the default APW linearisation energy; the order of the energy
!   derivative of the APW radial function $\partial^m u(r)/\partial E^m$; and
!   {\tt .T.} if the linearisation energy is allowed to vary.
!   \vskip 6pt
!   {\tt nlx} \\
!   The number of exceptions to the default APW configuration. These should be
!   listed on subsequent lines for particular angular momenta. In this example,
!   the fixed energy APW with angular momentum $d$ ({\tt lx} $=2$) is replaced
!   with a LAPW, which has variable linearisation energy.
!   \vskip 6pt
!   {\tt nlorb} \\
!   Number of local orbitals.
!   \vskip 6pt
!   {\tt lorbl}, {\tt lorbord} \\
!   Respectively, the angular momentum $l$ of the local-orbital; and the order
!   of the radial derivative which goes to zero at the muffin-tin surface.
!   \vskip 6pt
!   {\tt lorbe0}, {\tt lorbdm}, {\tt lorbve} \\
!   Respectively, the default local-orbital linearisation energy; the order of
!   the energy derivative of the local-orbital radial function; and {\tt .T.} if
!   the linearisation energy is allowed to vary.
!
!   \subsubsection{Examples}
!   The best way to learn to use Elk is to run the examples included with the
!   package. These can be found in the {\tt examples} directory and use many of
!   the code's capabilities. The following section which describes all the input
!   parameters will be of invaluable assistance.
!
!   \section{Input blocks}
!   This section lists all the input blocks available. It is arranged with the
!   name of the block followed by a table which lists each parameter name, what
!   the parameter does, its type and default value. A horizontal line in the
!   table indicates a new line in {\tt elk.in}. Below the table is a brief
!   overview of the block's function.
!
!   \block{atoms}{
!   {\tt nspecies} & number of species & integer & 0 \\
!   \hline
!   {\tt spfname(i)} & species filename for species $i$ & string & - \\
!   \hline
!   {\tt natoms(i)} & number of atoms for species $i$ & integer & - \\
!   \hline
!   {\tt atposl(j,i)} & atomic position in lattice coordinates for atom $j$
!    & real(3) & - \\
!   {\tt bfcmt(j,i)} & muffin-tin external magnetic field in Cartesian
!    coordinates for atom $j$ & real(3) & -}
!   Defines the atomic species as well as their positions in the unit cell and
!   the external magnetic field applied throughout the muffin-tin. These fields
!   are used to break spin symmetry and should be considered infinitesimal as
!   they do not contribute directly to the total energy. Collinear calculations
!   are more efficient if the field is applied in the $z$-direction. One could,
!   for example, set up an anti-ferromagnetic crystal by pointing the field on
!   one atom in the positive $z$-direction and in the opposite direction on
!   another atom. If {\tt molecule} is {\tt .true.} then the atomic positions
!   are assumed to be in Cartesian coordinates. See also {\tt sppath},
!   {\tt bfieldc} and {\tt molecule}.
!
!   \block{autokpt}{
!   {\tt autokpt} & {\tt .true.} if the $k$-point set is to be determined
!    automatically & logical & {\tt .false.}}
!   See {\tt radkpt} for details.
!
!   \block{autolinengy}{
!   {\tt autolinengy} & {\tt .true.} if the fixed linearisation energies are
!    to be determined automatically & logical & {\tt .false.}}
!   See {\tt dlefe} for details.
!
!   \block{autoswidth}{
!   {\tt autoswidth} & {\tt .true.} if the smearing parameter {\tt swidth}
!    should be determined automatically & logical & {\tt .false.}}
!   Calculates the smearing width from the $k$-point density, $V_{\rm BZ}/n_k$;
!   the valence band width, $W$; and an effective mass parameter, $m^{*}$;
!   according to
!   $$ \sigma=\frac{\sqrt{2W}}{m^{*}}\left(\frac{3}{4\pi}
!    \frac{V_{\rm BZ}}{n_k}\right)^{1/3}. $$
!   The variable {\tt mstar} then replaces {\tt swidth} as the control parameter
!   of the smearing width. A large value of $m^{*}$ gives a narrower smearing
!   function. Since {\tt swidth} is adjusted according to the fineness of the
!   ${\bf k}$-mesh, the smearing parameter can then be eliminated. It is not
!   recommended that {\tt autoswidth} be used in conjunction with the
!   Fermi-Dirac smearing function, since the electronic temperature will then be
!   a function of the $k$-point mesh. See T. Bj\"orkman and O. Gr\aa n\"as,
!   {\it Int. J. Quant. Chem.} DOI: 10.1002/qua.22476 (2010) for details. See
!   also {\tt stype} and {\tt swidth}.
!
!   \block{avec}{
!   {\tt avec(1)} & first lattice vector & real(3) & $(1.0,0.0,0.0)$ \\
!   \hline
!   {\tt avec(2)} & second lattice vector & real(3) & $(0.0,1.0,0.0)$ \\
!   \hline
!   {\tt avec(3)} & third lattice vector & real(3) & $(0.0,0.0,1.0)$}
!   Lattice vectors of the crystal in atomic units (Bohr).
!
!   \block{beta0}{
!   {\tt beta0} & adaptive mixing parameter & real & $0.05$}
!   This determines how much of the potential from the previous self-consistent
!   loop is mixed with the potential from the current loop. It should be made
!   smaller if the calculation is unstable. See {\tt betamax} and also the
!   routine {\tt mixadapt}.
!
!   \block{betamax}{
!   {\tt betamax} & maximum adaptive mixing parameter & real & $0.5$}
!   Maximum allowed mixing parameter used in routine {\tt mixadapt}.
!
!   \block{bfieldc}{
!   {\tt bfieldc} & global external magnetic field in Cartesian coordinates &
!    real(3) & $(0.0,0.0,0.0)$}
!   This is a constant magnetic field applied throughout the entire unit cell
!   and enters the second-variational Hamiltonian as
!   $$ \frac{g_e}{4c}\,\vec{\sigma}\cdot{\bf B}_{\rm ext}, $$
!   where $g_e$ is the electron $g$-factor. This field is normally used to break
!   spin symmetry for spin-polarised calculations and considered to be
!   infinitesimal with no direct contribution to the total energy. In cases
!   where the magnetic field is finite (for example when computing magnetic
!   response) the external ${\bf B}$-field energy reported in {\tt INFO.OUT}
!   should be added to the total by hand. This field is applied throughout the
!   entire unit cell. To apply magnetic fields in particular muffin-tins use the
!   {\tt bfcmt} vectors in the {\tt atoms} block. Collinear calculations are
!   more efficient if the field is applied in the $z$-direction.
!
!   \block{broydpm}{
!   {\tt broydpm} & Broyden mixing parameters $\alpha$ and $w_0$ & real &
!    $(0.25,0.01)$}
!   See {\tt mixtype} and {\tt mixsdb}.
!
!   \block{c\_tb09}{
!   {\tt c\_tb09} & Tran-Blaha constant $c$ & real & -}
!   Sets the constant $c$ in the Tran-Blaha '09 functional. Normally this is
!   calculated from the density, but there may be situations where this needs to
!   be adjusted by hand. See {\it Phys. Rev. Lett.} {\bf 102}, 226401 (2009).
!
!   \block{chgexs}{
!   {\tt chgexs} & excess electronic charge & real & $0.0$}
!   This controls the amount of charge in the unit cell beyond that required to
!   maintain neutrality. It can be set positive or negative depending on whether
!   electron or hole doping is required.
!
!   \block{cmagz}{
!   {\tt cmagz} & .true. if $z$-axis collinear magnetism is to be enforced &
!    logical & {\tt .false.}}
!   This variable can be set to .true. in cases where the magnetism is
!   predominantly collinear in the $z$-direction, for example a ferromagnet with
!   spin-orbit coupling. This will make the calculation considerably faster at
!   the slight expense of precision.
!
!   \block{deltaem}{
!   {\tt deltaem} & the size of the ${\bf k}$-vector displacement used when
!    calculating numerical derivatives for the effective mass tensor & real &
!    $0.025$}
!   See {\tt ndspem} and {\tt vklem}.
!
!   \block{deltaph}{
!   {\tt deltaph} & size of the atomic displacement used for calculating
!    dynamical matrices & real & $0.02$}
!   Phonon calculations are performed by constructing a supercell corresponding
!   to a particular ${\bf q}$-vector and making a small periodic displacement of
!   the atoms. The magnitude of this displacement is given by {\tt deltaph}.
!   This should not be made too large, as anharmonic terms could then become
!   significant, neither should it be too small as this can introduce numerical
!   error.
!
!   \block{deltast}{
!   {\tt deltast} & size of the change in lattice vectors used for calculating
!    the stress tensor & real & $0.01$}
!   The stress tensor is computed by changing the lattice vector matrix $A$ by
!   $$ A\rightarrow (1+\delta t\,e_i)A, $$
!   where $dt$ is an infinitesimal equal in practice to {\tt deltast} and $e_i$
!   is the $i^{\rm th}$ strain tensor. Numerical finite differences are used to
!   compute the stress tensor as the derivative of the total energy $dE_i/dt$.
!
!   \block{dft+u}{
!   {\tt dftu} & type of DFT+$U$ calculation & integer & 0 \\
!   {\tt inpdftu} & type of input for DFT+U calculation & integer & 1 \\
!   \hline
!   {\tt is} & species number & integer & - \\
!   {\tt l} & angular momentum value & integer & -1 \\
!   {\tt u} & the desired $U$ value & real & $0.0$ \\
!   {\tt j} & the desired $J$ value & real & $0.0$}
!   This block contains the parameters required for an DFT+$U$ calculation, with
!   the list of parameters for each species terminated with a blank line. The
!   type of double counting required is set with the parameter {\tt dftu}.
!   Currently implemented are:
!   \vskip 6pt
!   \begin{tabularx}{\textwidth}[h]{lX}
!    0 & No DFT+$U$ calculation \\
!    1 & Fully localised limit (FLL) \\
!    2 & Around mean field (AFM) \\
!    3 & An interpolation between FLL and AFM \\
!   \end{tabularx}
!   \vskip 6pt
!   The type of input parameters is set with the parameter {\tt inpdftu}.
!   The current possibilities are:
!   \vskip 6pt
!   \begin{tabularx}{\textwidth}[h]{lX}
!    1 & U and J \\
!    2 & Slater parameters \\
!    3 & Racah parameters \\
!    4 & Yukawa screening length \\
!    5 & U and determination of corresponding Yukawa screening length
!   \end{tabularx}
!   \vskip 6pt
!   See (amongst others) {\it Phys. Rev. B} {\bf 67}, 153106 (2003),
!   {\it Phys. Rev. B} {\bf 52}, R5467 (1995), {\it Phys. Rev. B} {\bf 60},
!   10763 (1999), and {\it Phys. Rev. B} {\bf 80}, 035121 (2009).
!
!   \block{dlefe}{
!   {\tt dlefe} & difference between the fixed linearisation energy and the
!    Fermi energy & real & $-0.1$}
!   When {\tt autolinengy} is {\tt .true.} then the fixed linearisation energies
!   are set to the Fermi energy plus {\tt dlefe}.
!
!   \block{dosmsum}{
!   {\tt dosmsum} & {\tt .true.} if the partial DOS is to be summed over $m$ &
!    logical & {\tt .false.}}
!   By default, the partial density of states is resolved over $(l,m)$ quantum
!   numbers. If {\tt dosmsum} is set to {\tt .true.} then the partial DOS is
!   summed over $m$, and thus depends only on $l$.
!
!   \block{dosssum}{
!   {\tt dosssum} & {\tt .true.} if the partial DOS is to be summed over spin &
!    logical & {\tt .false.}}
!   By default, the partial density of states for spin-polarised systems is spin
!   resolved.
!
!   \block{epsband}{
!   {\tt epsband} & convergence tolerance for determining band energies & real &
!    $1\times 10^{-12}$}
!   APW and local-orbital linearisation energies are determined from the band
!   energies. This is done by first searching upwards in energy until the radial
!   wavefunction at the muffin-tin radius is zero. This is the energy at the top
!   of the band, denoted $E_{\rm t}$. A downward search is now performed from
!   $E_{\rm t}$ until the slope of the radial wavefunction at the muffin-tin
!   radius is zero. This energy, $E_{\rm b}$, is at the bottom of the band. The
!   band energy is taken as $(E_{\rm t}+E_{\rm b})/2$. If either $E_{\rm t}$ or
!   $E_{\rm b}$ is not found, then the band energy is set to the default value.
!
!   \block{epschg}{
!   {\tt epschg} & maximum allowed error in the calculated total charge beyond
!    which a warning message will be issued & real & $1\times 10^{-3}$}
!
!   \block{epsengy}{
!   {\tt epsengy} & convergence criterion for the total energy & real &
!    $1\times 10^{-4}$}
!   See {\tt epspot}.
!
!   \block{epsforce}{
!   {\tt epsforce} & convergence tolerance for the forces during a geometry
!    optimisation run & real & $2\times 10^{-3}$}
!   If the mean absolute value of the atomic forces is less than {\tt epsforce}
!   then the geometry optimisation run is ended. See also {\tt tasks} and
!   {\tt latvopt}.
!
!   \block{epslat}{
!   {\tt epslat } & vectors with lengths less than this are considered zero &
!    real & $10^{-6}$}
!   Sets the tolerance for determining if a vector or its components are zero.
!   This is to account for any numerical error in real or reciprocal space
!   vectors.
!
!   \block{epsocc}{
!   {\tt epsocc} & smallest occupancy for which a state will contribute to the
!    density & real & $1\times 10^{-8}$}
!
!   \block{epspot}{
!   {\tt epspot} & convergence criterion for the Kohn-Sham potential and field &
!    real & $1\times 10^{-6}$}
!   If the RMS change in the Kohn-Sham potential and magnetic field is smaller
!   than {\tt epspot} and the absolute change in the total energy is less than
!   {\tt epsengy}, then the self-consistent loop is considered converged
!   and exited. For geometry optimisation runs this results in the forces being
!   calculated, the atomic positions updated and the loop restarted. See also
!   {\tt epsengy} and {\tt maxscl}.
!
!   \block{epsstress}{
!   {\tt epsstress} & convergence tolerance for the stress tensor during a
!    geometry optimisation run with lattice vector relaxation & real &
!    $5\times 10^{-4}$}
!   See also {\tt epsforce} and {\tt latvopt}.
!
!   \block{emaxelnes}{
!   {\tt emaxelnes} & maximum allowed initial-state eigenvalue for ELNES
!    calculations & real & $-1.2$}
!
!   \block{emaxrf}{
!   {\tt emaxrf} & energy cut-off used when calculating Kohn-Sham response
!    functions & real & $10^6$}
!   A typical Kohn-Sham response function is of the form
!   \begin{align*}
!    \chi_s({\bf r},{\bf r}',\omega)
!    \equiv\frac{\delta\rho({\bf r},\omega)}{\delta v_s({\bf r}',\omega)}
!    =\frac{1}{N_k}\sum_{i{\bf k},j{\bf k}'}(f_{i{\bf k}}-f_{j{\bf k}'})
!    \frac{\langle i{\bf k}|\hat{\rho}({\bf r})|j{\bf k}'\rangle
!    \langle j{\bf k}'|\hat{\rho}({\bf r}')|i{\bf k}\rangle}
!    {w+(\varepsilon_{i{\bf k}}-\varepsilon_{j{\bf k}'})+i\eta},
!   \end{align*}
!   where $\hat{\rho}$ is the density operator; $N_k$ is the number of
!   $k$-points; $\varepsilon_{i{\bf k}}$ and $f_{i{\bf k}}$ are the eigenvalues
!   and occupation numbers, respectively. The variable {\tt emaxrf} is an energy
!   window which limits the summation over states in the formula above so that
!   $|\varepsilon_{i{\bf k}}-\varepsilon_{\rm Fermi}|<{\tt emaxrf}$. Reducing
!   this can result in a faster calculation at the expense of accuracy.
!
!   \block{fracinr}{
!   {\tt fracinr} & fraction of the muffin-tin radius up to which {\tt lmaxinr}
!    is used as the angular momentum cut-off & real & $0.1$}
!   See {\tt lmaxinr}.
!
!   \block{fsmtype}{
!   {\tt fsmtype} & 0 for no fixed spin moment (FSM), 1 for total FSM, 2 for
!    local muffin-tin FSM, and 3 for both total and local FSM & integer & 0}
!   Set to 1, 2 or 3 for fixed spin moment calculations. To fix only the
!   direction and not the magnitude set to $-1$, $-2$ or $-3$. See also
!   {\tt momfix}, {\tt mommtfix}, {\tt taufsm} and {\tt spinpol}.
!
!   \block{ftmtype}{
!   {\tt ftmtype} & 1 to enable a fixed tensor moment (FTM) calculation,
!    0 otherwise & integer & 0}
!   If {\tt ftmtype} is $-1$ then the symmetry corresponding to the tensor
!   moment is broken but no FTM calculation is performed. See {\it Phys. Rev.
!   Lett.} {\bf 103}, 107202 (2009) and also {\tt tmomfix}.
!
!   \block{fxclrc}{
!   {\tt fxclrc} & parameters for the dynamical long-range contribution (LRC) to
!    the TDDFT exchange-correlation kernel & real(2) & $(0.0,0.0)$}
!   These are the parameters $\alpha$ and $\beta$ for the kernel proposed in
!   {\it Phys. Rev. B} {\bf 72}, 125203 (2005), namely
!   $$ f_{xc}({\bf G},{\bf G}',{\bf q},\omega)=-\frac{\alpha+\beta\omega^2}{q^2}
!    \delta_{{\bf G},{\bf G}'}\delta_{{\bf G},{\bf 0}}. $$
!
!   \block{fxtype}{
!   {\tt fxctype} & integer defining the type of exchange-correlation kernel
!    $f_{\rm xc}$ & integer & -1}
!   The acceptable values are:
!   \vskip 6pt
!   \begin{tabularx}{\textwidth}[h]{lX}
!   $-1$ & $f_{\rm xc}$ defined by {\tt xctype} \\
!   0,1 & RPA ($f_{\rm xc}=0$) \\
!   200 & Long-range contribution (LRC) kernel, S. Botti {\it et al.},
!    {\it Phys. Rev. B} {\bf 72}, 125203 (2005); see {\tt fxclrc} \\
!   210 & `Bootstrap' kernel, S. Sharma, J. K. Dewhurst, A. Sanna and
!    E. K. U. Gross, {\it Phys. Rev. Lett.} {\bf 107}, 186401 (2011) \\
!   \end{tabularx}
!
!   \block{gmaxrf}{
!   {\tt gmaxrf} & maximum length of $|{\bf G}|$ for computing response
!    functions & real & $3.0$}
!
!   \block{gmaxvr}{
!   {\tt gmaxvr} & maximum length of $|{\bf G}|$ for expanding the interstitial
!    density and potential & real & $12.0$}
!   This variable has a lower bound which is enforced by the code as follows:
!   $$ {\rm gmaxvr}\rightarrow\max\,({\rm gmaxvr},2\times{\rm gkmax}
!    +{\rm epslat}) $$
!   See {\tt rgkmax} and {\tt trimvg}.
!
!   \block{hdbse}{
!   {\tt hdbse} & {\tt .true.} if the direct term is to be included in the BSE
!    Hamiltonian & logical & {\tt .true.}}
!
!   \block{highq}{
!   {\tt highq} & {\tt .true.} if a high-quality parameter set should be used &
!    logical & {\tt .false.}}
!   Setting this to {\tt .true.} results in some default parameters being
!   changed to ensure good convergence in most situations. See the subroutine
!   {\tt readinput} for the list of changed parameters and their values. These
!   changes can be overruled by subsequent blocks in the input file.
!
!   \block{hmaxvr}{
!   {\tt hmaxvr} & maximum length of ${\bf H}$-vectors & real & $6.0$}
!   The ${\bf H}$-vectors are used for calculating X-ray and magnetic structure
!   factors. They are also used in linear response phonon calculations for
!   expanding the density and potential in plane waves. See also {\tt gmaxvr},
!   {\tt vhmat}, {\tt reduceh}, {\tt wsfac} and {\tt hkmax}.
!
!   \block{hxbse}{
!   {\tt hxbse} & {\tt .true.} if the exchange term is to be included in the BSE
!    Hamiltonian & {\tt .true.}}
!
!   \block{hybrid}{
!   {\tt hybrid} & {\tt .true} if a hybrid functional is to be used when running
!    a Hartree-Fock calculation & logical & {\tt .false}}
!   See also {\tt hybridc} and {\tt xctype}.
!
!   \block{hybridc}{
!   {\tt hybridc} & hybrid functional mixing coefficient & real & $1.0$}
!
!   \block{intraband}{
!   {\tt intraband} & {\tt .true.} if the intraband (Drude-like) contribution is
!    to be added to the dieletric tensor & logical & {\tt .false.}}
!
!   \block{isgkmax}{
!   {\tt isgkmax} & species for which the muffin-tin radius will be used for
!    calculating {\tt gkmax} & integer & $-1$}
!   By default ($-1$) the average muffin-tin radius is used for determining
!   {\tt gkmax} from {\tt rgkmax}. This can be changed by setting {\tt isgkmax}
!   either to the desired species number; or to $-2$ if
!   ${\tt gkmax}={\tt rgkmax}/2$; or to $-3$ in which case the smallest
!   radius is used.
!
!   \block{kstlist}{
!   {\tt kstlist(i)} & $i$th $k$-point and state pair & integer(2) & $(1,1)$}
!   This is a user-defined list of $k$-point and state index pairs which are
!   those used for plotting wavefunctions and writing ${\bf L}$, ${\bf S}$ and
!   ${\bf J}$ expectation values. Only the first pair is used by the
!   aforementioned tasks. The list should be terminated by a blank line.
!
!   \block{latvopt}{
!   {\tt latvopt} & type of lattice vector optimisation to be performed during
!    structural relaxation & integer & 0}
!   Unconstrained optimisation of the lattice vectors will be performed with
!   ${\tt task}=2,3$ when ${\tt latvopt}=1$. When ${\tt latvopt}=2$ the lattice
!   vectors will be optimised while keeping the unit cell volume fixed. In
!   either case, the crystal symmetry is retained during optimisation. By
!   default (${\tt latvopt}=0$) no lattice vector optimisation is performed
!   during structural relaxation. See also {\tt tau0latv}.
!
!   \block{lmaxapw}{
!   {\tt lmaxapw} & angular momentum cut-off for the APW functions & integer &
!    $8$}
!
!   \block{lmaxdos}{
!   {\tt lmaxdos} & angular momentum cut-off for the partial DOS plot &
!    integer & $3$}
!
!   \block{lmaxinr}{
!   {\tt lmaxinr} & angular momentum cut-off for the muffin-tin density and
!    potential on the inner part of the muffin-tin & integer & 2}
!   Close to the nucleus, the density and potential is almost spherical and
!   therefore the spherical harmonic expansion can be truncated a low angular
!   momentum. See also {\tt fracinr}.
!
!   \block{lmaxmat}{
!   {\tt lmaxmat} & angular momentum cut-off for the outer-most loop in the
!    hamiltonian and overlap matrix set up & integer & 6}
!
!   \block{lmaxvr}{
!   {\tt lmaxvr} & angular momentum cut-off for the muffin-tin density and
!    potential & integer & 7}
!
!   \block{lmirep}{
!   {\tt lmirep} & {\tt .true.} if the $Y_{lm}$ basis is to be transformed
!    into the basis of irreducible representations of the site symmetries for
!    DOS plotting & logical & {\tt .true.}}
!   When lmirep is set to .true., the spherical harmonic basis is transformed
!   into one in which the site symmetries are block diagonal. Band characters
!   determined from the density matrix expressed in this basis correspond to
!   irreducible representations, and allow the partial DOS to be resolved into
!   physically relevant contributions, for example $e_g$ and $t_{2g}$.
!
!   \block{lorbcnd}{
!   {\tt lorbcnd} & {\tt .true.} if conduction state local-orbitals are to be
!    automatically added to the basis & logical & {\tt .false.}}
!   Adding these higher energy local-orbitals can improve calculations which
!   rely on accurate unoccupied states, such as the response function. See also
!   {\tt lorbordc}.
!
!   \block{lorbordc}{
!   {\tt lorbordc} & the order of the conduction state local-orbitals &
!    integer & 3}
!   See {\tt lorbcnd}.
!
!   \block{lradstp}{
!   {\tt lradstp} & radial step length for determining coarse radial mesh &
!    integer & 4}
!   Some muffin-tin functions (such as the density) are calculated on a coarse
!   radial mesh and then interpolated onto a fine mesh. This is done for the
!   sake of efficiency. {\tt lradstp} defines the step size in going from the
!   fine to the coarse radial mesh. If it is too large, loss of precision may
!   occur.
!
!   \block{maxitoep}{
!   {\tt maxitoep} & maximum number of iterations when solving the exact
!    exchange integral equations & integer & 200}
!   See {\tt tau0oep}.
!
!   \block{maxscl}{
!   {\tt maxscl } & maximum number of self-consistent loops allowed & integer &
!    200}
!   This determines after how many loops the self-consistent cycle will
!   terminate if the convergence criterion is not met. If {\tt maxscl} is $1$
!   then the density and potential file, {\tt STATE.OUT}, will {\bf not} be
!   written to disk at the end of the loop. See {\tt epspot}.
!
!   \block{mixtype}{
!   {\tt mixtype } & type of mixing required for the potential & integer & 1}
!   Currently implemented are:
!   \vskip 6pt
!   \begin{tabularx}{\textwidth}[h]{lX}
!   1 & Adaptive linear mixing \\
!   2 & Pulay mixing, {\it Chem. Phys. Lett.} {\bf 73}, 393 (1980) \\
!   3 & Broyden mixing, {\it J. Phys. A: Math. Gen.} {\bf 17}, L317 (1984)
!   \end{tabularx}
!
!   \block{mixsdb}{
!   {\tt mixsdb} & subspace dimension for Broyden mixing & integer & 5}
!   This is the number of mixing vectors which define the subspace in which the
!   Hessian matrix is calculated. See {\tt mixtype} and {\tt broydpm}.
!
!   \block{mixsdp}{
!   {\tt mixsdp} & subspace dimension for Pulay mixing & integer & 3}
!   See {\tt mixsdb} and {\tt mixtype}.
!
!   \block{molecule}{
!   {\tt molecule} & {\tt .true.} if the system is an isolated molecule &
!    logical & {\tt .false.}}
!   If {\tt molecule} is {\tt .true.}, then the atomic positions, ${\bf a}$,
!   given in the {\tt atoms} block are assumed to be in Cartesian coordinates.
!
!   \block{momfix}{
!   {\tt momfix} & the desired total moment for a FSM calculation &
!    real(3) & $(0.0,0.0,0.0)$}
!   Note that all three components must be specified (even for collinear
!   calculations). See {\tt fsmtype}, {\tt taufsm} and {\tt spinpol}.
!
!   \block{mommtfix}{
!   {\tt is} & species number & integer & 0 \\
!   {\tt ia} & atom number & integer & 0 \\
!   {\tt mommtfix} & the desired muffin-tin moment for a FSM calculation &
!    real(3) & $(0.0,0.0,0.0)$}
!   The local muffin-tin moments are specified for a subset of atoms, with the
!   list terminated with a blank line. Note that all three components must be
!   specified (even for collinear calculations). See {\tt fsmtype}, {\tt taufsm}
!   and {\tt spinpol}.
!
!   \block{mstar}{
!   {\tt mstar} & Value of the effective mass parameter used for adaptive
!    determination of {\tt swidth} & real & $10.0$}
!   See {\tt autoswidth}.
!
!   \block{mustar}{
!   {\tt mustar} & Coulomb pseudopotential, $\mu^*$, used in the
!    McMillan-Allen-Dynes equation & real & $0.15$}
!   This is used when calculating the superconducting critical temperature with
!   the formula {\it Phys. Rev. B 12, 905 (1975)}
!   $$ T_c=\frac{\omega_{\rm log}}{1.2 k_B}\exp\left[\frac{-1.04(1+\lambda)}
!    {\lambda-\mu^*(1+0.62\lambda)}\right], $$
!   where $\omega_{\rm log}$ is the logarithmic average frequency and $\lambda$
!   is the electron-phonon coupling constant.
!
!   \block{ncbse}{
!   {\tt ncbse} & number of conduction states to be used for BSE calculations &
!    integer & 3}
!   See also {\tt nvbse}.
!
!   \block{ncgga}{
!   {\tt ncgga} & set to {\tt .true.} for non-collinear GGA calculations which
!    are difficult to converge & logical & {\tt .false.}}
!   Setting this variable to {\tt .true.} results in the second-order
!   gradients of the spin-density in the intersitial being averaged. This can
!   improve convergence for non-collinear GGA calculations, but necessarily
!   makes the exchange-correlation potential non-variational.
!
!   \block{ndspem}{
!   {\tt ndspem} & the number of {\bf k}-vector displacements in each direction
!    around {\tt vklem} when computing the numerical derivatives for the
!    effective mass tensor & integer & 1}
!   See {\tt deltaem} and {\tt vklem}.
!
!   \block{nempty}{
!   {\tt nempty} & the number of empty states per atom and spin & real & $4.0$ }
!   Defines the number of eigenstates beyond that required for charge
!   neutrality. When running metals it is not known {\it a priori} how many
!   states will be below the Fermi energy for each $k$-point. Setting
!   {\tt nempty} greater than zero allows the additional states to act as a
!   buffer in such cases. Furthermore, magnetic calculations use the
!   first-variational eigenstates as a basis for setting up the
!   second-variational Hamiltonian, and thus {\tt nempty} will determine the
!   size of this basis set. Convergence with respect to this quantity should be
!   checked.
!
!   \block{ngridk}{
!   {\tt ngridk } & the $k$-point mesh sizes & integer(3) & $(1,1,1)$}
!   The ${\bf k}$-vectors are generated using
!   $$ {\bf k}=(\frac{i_1+v_1}{n_1},\frac{i_2+v_2}{n_2},\frac{i_3+v_3}{n_3}), $$
!   where $i_j$ runs from 0 to $n_j-1$ and $0\le v_j<1$ for $j=1,2,3$. The
!   vector ${\bf v}$ is given by the variable {\tt vkloff}. See also
!   {\tt reducek}.
!
!   \block{ngridq}{
!   {\tt ngridq } & the phonon $q$-point mesh sizes & integer(3) & $(1,1,1)$}
!   Same as {\tt ngridk}, except that this mesh is for the phonon $q$-points.
!   See also {\tt reduceq}.
!
!   \block{nosource}{
!   {\tt nosource} & when set to {\tt .true.}, source fields are projected out
!    of the exchange-correlation magnetic field & logical & {\tt .false.}}
!   Experimental feature.
!
!   \block{notes}{
!   {\tt notes(i)} & the $i$th line of the notes & string & -}
!   This block allows users to add their own notes to the file {\tt INFO.OUT}.
!   The block should be terminated with a blank line, and no line should exceed
!   80 characters.
!
!   \block{npmae}{
!   {\tt npmae } & number or distribution of directions for MAE calculations &
!    integer & $-1$}
!   Automatic determination of the magnetic anisotropy energy (MAE) requires
!   that the total energy is determined for a set of directions of the total
!   magnetic moment. This variable controls the number or distribution of these
!   directions. The convention is:
!   \vskip 6pt
!   \begin{tabularx}{\textwidth}[h]{lX}
!   $-4,-3,-2,-1$ & Cardinal directions given by the primitive translation
!    vectors $n_1{\bf A}_1+n_2{\bf A}_2+n_3{\bf A}_3$, where
!    $1\le n_i\le|{\tt npmae}|$ \\
!   2 & Cartesian $x$ and $z$ directions \\
!   3 & Cartesian $x$, $y$ and $z$ directions \\
!   $4,5,\ldots$ & Even distribution of {\tt npmae} directions
!   \end{tabularx}
!
!   \block{ntemp}{
!   {\tt ntemp} & number of temperature steps & integer & 20}
!   This is the number of temperature steps to be used in the Eliashberg gap
!   and thermodynamic properties calculations.
!
!   \block{nvbse}{
!   {\tt nvbse} & number of valence states to be used for BSE calculations &
!    integer & 2}
!   See also {\tt ncbse}.
!
!   \block{nwrite}{
!   {\tt nwrite} & number of self-consistent loops after which {\tt STATE.OUT}
!    is to be written & integer & 0}
!   Normally, the density and potentials are written to the file {\tt STATE.OUT}
!   only after completion of the self-consistent loop. By setting {\tt nwrite}
!   to a positive integer the file will instead be written every {\tt nwrite}
!   loops.
!
!   \block{optcomp}{
!   {\tt optcomp} & the components of the first- or second-order optical tensor
!    to be calculated & integer(3) & $(1,1,1)$}
!   This selects which components of the optical tensor you would like to plot.
!   Only the first two are used for the first-order tensor. Several components
!   can be listed one after the other with a blank line terminating the list.
!
!   \block{phwrite}{
!   {\tt nphwrt} & number of $q$-points for which phonon modes are to be found &
!    integer & 1 \\
!   \hline
!   {\tt vqlwrt(i)} & the $i$th $q$-point in lattice coordinates & real(3) &
!    $(0.0,0.0,0.0)$}
!   This is used in conjunction with {\tt task}=230. The code will write the
!   phonon frequencies and eigenvectors to the file {\tt PHONON.OUT} for all the
!   $q$-points in the list. The $q$-points can be anywhere in the Brillouin zone
!   and do not have to lie on the mesh defined by {\tt ngridq}. Obviously, all
!   the dynamical matrices have to be computed first using {\tt task}=200.
!
!   \block{plot1d}{
!   {\tt nvp1d} & number of vertices & integer & 2 \\
!   {\tt npp1d} & number of plotting points & integer & 200 \\
!   \hline
!   {\tt vvlp1d(i)} & lattice coordinates for vertex $i$ & real(3) &
!    $(0.0,0.0,0.0)\rightarrow(1.0,1.0,1.0)$}
!   Defines the path in either real or reciprocal space along which the 1D plot
!   is to be produced. The user should provide {\tt nvp1d} vertices in lattice
!   coordinates.
!
!   \block{plot2d}{
!   {\tt vclp2d(1)} & first corner (origin) & real(3) & $(0.0,0.0,0.0)$ \\
!   \hline
!   {\tt vclp2d(2)} & second corner & real(3) & $(1.0,0.0,0.0)$ \\
!   \hline
!   {\tt vclp2d(3)} & third corner & real(3) & $(0.0,1.0,0.0)$ \\
!   \hline
!   {\tt np2d} & number of plotting points in both directions & integer(2) &
!    $(40,40)$}
!   Defines the corners of a parallelogram and the grid size used for producing
!   2D plots.
!
!   \block{plot3d}{
!   {\tt vclp3d(1)} & first corner (origin) & real(3) & $(0.0,0.0,0.0)$ \\
!   \hline
!   {\tt vclp3d(2)} & second corner & real(3) & $(1.0,0.0,0.0)$ \\
!   \hline
!   {\tt vclp3d(3)} & third corner & real(3) & $(0.0,1.0,0.0)$ \\
!   \hline
!   {\tt vclp3d(4)} & fourth corner & real(3) & $(0.0,0.0,1.0)$ \\
!   \hline
!   {\tt np3d} & number of plotting points each direction & integer(3) &
!    $(20,20,20)$}
!   Defines the corners of a box and the grid size used for producing 3D plots.
!
!   \block{primcell}{
!   {\tt primcell} & {\tt .true.} if the primitive unit cell should be found
!    & logical & {\tt .false.}}
!   Allows the primitive unit cell to be determined automatically from the
!   conventional cell. This is done by searching for lattice vectors among all
!   those which connect atomic sites, and using the three shortest which produce
!   a unit cell with non-zero volume.
!
!   \block{radkpt}{
!   {\tt radkpt } & radius of sphere used to determine $k$-point density &
!    real & $40.0$}
!   Used for the automatic determination of the $k$-point mesh. If {\tt autokpt}
!   is set to {\tt .true.} then the mesh sizes will be determined by
!   $n_i=R_k|{\bf B}_i|+1$, where ${\bf B}_i$ are the primitive reciprocal
!   lattice vectors.
!
!   \block{readadu}{
!   {\tt readadu} & set to {\tt .true.} if the interpolation constant for
!    DFT+$U$ should be read from file rather than calculated & logical &
!    {\tt .false.}}
!   When {\tt dftu}=3, the DFT+$U$ energy and potential are interpolated
!   between FLL and AFM. The interpolation constant, $\alpha$, is normally
!   calculated from the density matrix, but can also be read in from the file
!   {\tt ALPHADU.OUT}. This allows the user to fix $\alpha$, but is also
!   necessary when calculating forces, since the contribution of the potential
!   of the variation of $\alpha$ with respect to the density matrix is not
!   computed. See {\tt dft+u}.
!
!   \block{reducebf}{
!   {\tt reducebf} & reduction factor for the external magnetic fields & real &
!    $1.0$}
!   After each self-consistent loop, the external magnetic fields are multiplied
!   with {\tt reducebf}. This allows for a large external magnetic field at the
!   start of the self-consistent loop to break spin symmetry, while at the end
!   of the loop the field will be effectively zero, i.e. infinitesimal. See
!   {\tt bfieldc} and {\tt atoms}.
!
!   \block{reduceh}{
!   {\tt reduceh} & set to {\tt .true.} if the reciprocal ${\bf H}$-vectors
!    should be reduced by the symmorphic crystal symmetries & logical & .true.}
!   See {\tt hmaxvr} and {\tt vmat}.
!
!   \block{reducek}{
!   {\tt reducek} & type of reduction of the $k$-point set & integer & 1}
!   Types of reduction are defined by the symmetry group used:
!   \vskip 6pt
!   \begin{tabularx}{\textwidth}[h]{lX}
!   0 & no reduction \\
!   1 & reduce with full crystal symmetry group (including non-symmorphic
!    symmetries) \\
!   2 & reduce with symmorphic symmetries only
!   \end{tabularx}
!   \vskip 6pt
!   See also {\tt ngridk} and {\tt vkloff}.
!
!   \block{reduceq}{
!   {\tt reduceq} & type of reduction of the $q$-point set & integer & 1}
!   See {\tt reducek} and {\tt ngridq}.
!
!   \block{rgkmax}{
!   {\tt rgkmax} & $R^{\rm MT}_{\rm min}\times\max\{|{\bf G}+{\bf k}|\}$ &
!    real & $7.0$}
!   This sets the maximum length for the ${\bf G}+{\bf k}$ vectors, defined as
!   {\tt rgkmax} divided by the average muffin-tin radius. See {\tt isgkmax}.
!
!   \block{rotavec}{
!   {\tt axang} & axis-angle representation of lattice vector rotation &
!    real(4) & $(0.0,0.0,0.0,0.0)$}
!   This determines the rotation matrix which is applied to the lattice vectors
!   prior to any calculation. The first three components specify the axis and
!   the last component is the angle in degrees. The `right-hand rule' convention
!   is followed.
!
!   \block{scale}{
!   {\tt scale } & lattice vector scaling factor & real & $1.0$}
!   Scaling factor for all three lattice vectors. Applied in conjunction with
!   {\tt scale1}, {\tt scale2} and {\tt scale3}.
!
!   \block{scale1/2/3}{
!   {\tt scale1/2/3 } & separate scaling factors for each lattice vector &
!    real & $1.0$}
!
!   \block{scissor}{
!   {\tt scissor} & the scissor correction & real & $0.0$}
!   This is the scissor shift applied to states above the Fermi energy
!   {\it Phys. Rev. B} {\bf 43}, 4187 (1991). Affects optics calculations only.
!
!   \block{scrpath}{
!   {\tt scrpath} & scratch space path & string & null}
!   This is the scratch space path where the eigenvector files {\tt EVALFV.OUT}
!   and {\tt EVALSV.OUT} will be written. If the run directory is accessed via a
!   network then {\tt scrpath} can be set to a directory on the local disk, for
!   example {\tt /tmp/}. Note that the forward slash {\tt /} at the end of the
!   path must be included.
!
!   \block{socscf}{
!   {\tt socscf} & scaling factor for the spin-orbit coupling term in the
!    Hamiltonian & real & $1.0$}
!   This can be used to enhance the effect of spin-orbit coupling in order to
!   accurately determine the magnetic anisotropy energy (MAE).
!
!   \block{spincore}{
!   {\tt spincore} & set to {\tt .true.} if the core should be spin-polarised
!    & logical & {\tt .false.}}
!
!   \block{spinorb}{
!   {\tt spinorb} & set to {\tt .true.} if a spin-orbit coupling is required
!    & logical & {\tt .false.}}
!   If {\tt spinorb} is {\tt .true.}, then a $\boldsymbol\sigma\cdot{\bf L}$
!   term is added to the second-variational Hamiltonian. See {\tt spinpol}.
!
!   \block{spinpol}{
!   {\tt spinpol} & set to {\tt .true.} if a spin-polarised calculation is
!    required & logical & {\tt .false.}}
!   If {\tt spinpol} is {\tt .true.}, then the spin-polarised Hamiltonian is
!   solved as a second-variational step using two-component spinors in the
!   Kohn-Sham magnetic field. The first variational scalar wavefunctions are
!   used as a basis for setting this Hamiltonian.
!
!   \block{spinsprl}{
!   {\tt spinsprl} & set to {\tt .true.} if a spin-spiral calculation is
!   required & logical & {\tt .false.}}
!   Experimental feature for the calculation of spin-spiral states. See
!   {\tt vqlss} for details.
!
!   \block{sppath}{
!   {\tt sppath} & path where the species files can be found & string & null}
!   Note that the forward slash {\tt /} at the end of the path must be included.
!
!   \block{ssdph}{
!   {\tt ssdph} & set to {\tt .true.} if a complex de-phasing factor is to be
!    used in spin-spiral calculations & logical & {\tt .true.}}
!   If this is {\tt .true.} then spin-spiral wavefunctions in each muffin-tin at
!   position ${\bf r}_{\alpha}$ are de-phased by the matrix
!   $$ \begin{pmatrix} e^{-i{\bf q}\cdot{\bf r}_{\alpha}/2} & 0 \\
!    0 & e^{i{\bf q}\cdot{\bf r}_{\alpha}/2} \end{pmatrix}. $$
!   In simple situations, this has the advantage of producing magnon dynamical
!   matrices which are already in diagonal form. This option should be used with
!   care, and a full understanding of the spin-spiral configuration is required.
!   See {\tt spinsprl}.
!
!   \block{stype}{
!   {\tt stype} & integer defining the type of smearing to be used & integer &
!    $3$}
!   A smooth approximation to the Dirac delta function is needed to compute the
!   occupancies of the Kohn-Sham states. The variable {\tt swidth} determines
!   the width of the approximate delta function. Currently implemented are
!   \vskip 6pt
!   \begin{tabularx}{\textwidth}[h]{lX}
!   0 & Gaussian \\
!   1 & Methfessel-Paxton order 1, Phys. Rev. B {\bf 40}, 3616 (1989) \\
!   2 & Methfessel-Paxton order 2 \\
!   3 & Fermi-Dirac
!   \end{tabularx}
!   \vskip 6pt
!   See also {\tt autoswidth} and {\tt swidth}.
!
!   \block{swidth}{
!   {\tt swidth} & width of the smooth approximation to the Dirac delta
!    function & real & $0.001$}
!   See {\tt stype} for details.
!
!   \newpage
!   \block{tasks}{
!   {\tt task(i) } & the $i$th task & integer & $-1$}
!   A list of tasks for the code to perform sequentially. The list should be
!   terminated with a blank line. Each task has an associated integer as
!   follows:
!   \vskip 6pt
!   \begin{tabularx}{\textwidth}[h]{lX}
!   -1 & Write out the version number of the code. \\
!   0 & Ground state run starting from the atomic densities. \\
!   1 & Resumption of ground-state run using density in {\tt STATE.OUT}. \\
!   2 & Geometry optimisation run starting from the atomic densities, with
!    atomic positions written to {\tt GEOMETRY.OUT}. \\
!   3 & Resumption of geometry optimisation run using density in {\tt STATE.OUT}
!    but with positions from {\tt elk.in}. \\
!   5 & Ground state Hartree-Fock run. \\
!   10 & Total, partial and interstitial density of states (DOS). \\
!   14 & Plots the smooth Dirac delta and Heaviside step functions used by the
!        code to calculate occupancies. \\
!   15 & Output ${\bf L}$, ${\bf S}$ and ${\bf J}$ total expectation values. \\
!   16 & Output ${\bf L}$, ${\bf S}$ and ${\bf J}$ expectation values for each
!        $k$-point and state in {\tt kstlist}. \\
!   20 & Band structure plot. \\
!   21 & Band structure plot which includes angular momentum characters for
!    every atom. \\
!   25 & Compute the effective mass tensor at the $k$-point given by
!    {\tt vklem}. \\
!   31, 32, 33 & 1/2/3D charge density plot. \\
!   41, 42, 43 & 1/2/3D exchange-correlation and Coulomb potential plots. \\
!   51, 52, 53 & 1/2/3D electron localisation function (ELF) plot. \\
!   61, 62, 63 & 1/2/3D wavefunction plot:
!    $\left|\Psi_{i{\bf k}}({\bf r})\right|^2$. \\
!   65 & Write the core wavefunctions to file for plotting. \\
!   72, 73 & 2/3D plot of magnetisation vector field, ${\bf m}({\bf r})$. \\
!   82, 83 & 2/3D plot of exchange-correlation magnetic vector field,
!    ${\bf B}_{\rm xc}({\bf r})$. \\
!   91, 92, 93 & 1/2/3D plot of $\nabla\cdot{\bf B}_{\rm xc}({\bf r})$. \\
!   100 & 3D Fermi surface plot using the scalar product
!    $p({\bf k})=\Pi_i(\epsilon_{i{\bf k}}-\epsilon_{\rm F})$. \\
!   101 & 3D Fermi surface plot using separate bands (minus the Fermi
!    energy). \\
!   102 & 3D Fermi surface which can be plotted with XCrysDen. \\
!   105 & 3D nesting function plot. \\
!   110 & Calculation of M\"{o}ssbauer contact charge densities and magnetic
!    fields at the nuclear sites. \\
!   115 & Calculation of the electric field gradient (EFG) at the nuclear
!    sites. \\
!   120 & Output of the momentum matrix elements
!    $\langle\Psi_{i{\bf k}}|-i\nabla|\Psi_{j{\bf k}}\rangle$. \\
!   121 & Linear optical dielectric response tensor calculated within the random
!    phase approximation (RPA) and in the $q\rightarrow 0$ limit, with no
!    microscopic contributions. \\
!   122 & Magneto optical Kerr effect (MOKE) angle. \\
!   125 & Non-linear optical second harmonic generation. \\
!   130 & Output matrix elements of the type
!    $\langle\Psi_{i{\bf k+q}}|\exp[i({\bf G+q})\cdot{\bf r}]|
!    \Psi_{j{\bf k}}\rangle$. \\
!   135 & Output all wavefunctions expanded in the plane wave basis up to a
!    cut-off defined by {\tt rgkmax}.
!   \end{tabularx}
!
!   \begin{tabularx}{\textwidth}[h]{lX}
!   140 & Energy loss near edge structure (ELNES). \\
!   142, 143 & 2/3D plot of the electric field
!    ${\bf E}({\bf r})\equiv\nabla V_{\rm C}({\bf r})$. \\
!   152, 153 & 2/3D plot of
!    ${\bf m}({\bf r})\times{\bf B}_{\rm xc}({\bf r})$. \\
!   162 & Scanning-tunneling microscopy (STM) image. \\
!   180 & Generate the RPA inverse dielectric function with local contributions
!    and write it to file. \\
!   185 & Write the Bethe-Salpeter equation (BSE) Hamiltonian to file. \\
!   186 & Diagonalise the BSE Hamiltonian and write the eigenvectors and
!         eigenvalues to file. \\
!   187 & Output the BSE dielectric response function. \\
!   190 & Write the atomic geometry to file for plotting with XCrySDen and
!    V\_Sim. \\
!   195 & Calculation of X-ray density structure factors. \\
!   196 & Calculation of magnetic structure factors. \\
!   200 & Calculation of phonon dynamical matrices on a $q$-point set defined by
!    {\tt ngridq} using the supercell method. \\
!   201 & Phonon dry run: just produce a set of empty DYN files. \\
!   205 & Calculation of phonon dynamical matrices using density functional
!    perturbation theory (DFPT). \\
!   210 & Phonon density of states. \\
!   220 & Phonon dispersion plot. \\
!   230 & Phonon frequencies and eigenvectors for an arbitrary $q$-point. \\
!   240 & Generate the ${\bf q}$-dependent phonon linewidths and electron-phonon
!    coupling constants and write them to file. \\
!   245 & Phonon linewidths plot. \\
!   250 & Eliashberg function $\alpha^2F(\omega)$, electron-phonon coupling
!    constant $\lambda$, and the McMillan-Allen-Dynes critical temperature
!    $T_c$. \\
!   300 & Reduced density matrix functional theory (RDMFT) calculation. \\
!   320 & Time-dependent density functional theory (TDDFT) calculation of the
!    dielectric response function including microscopic contributions. \\
!   330 & TDDFT calculation of the spin-polarised response function for
!    arbitrary ${\bf q}$-vectors. \\
!   400 & Calculation of tensor moments and corresponding DFT+$U$ Hartree-Fock
!    energy contributions.
!   \end{tabularx}
!
!   \block{tau0atp}{
!   {\tt tau0atp} & the step size to be used for atomic position optimisation &
!    real & $0.25$}
!   The position of atom $\alpha$ is updated on step $m$ of a geometry
!   optimisation run using
!   $$ {\bf r}_{\alpha}^{m+1}={\bf r}_{\alpha}^m+\tau_{\alpha}^m
!    \left({\bf F}_{\alpha}^m+{\bf F}_{\alpha}^{m-1}\right), $$
!   where $\tau_{\alpha}$ is set to {\tt tau0atp} for $m=0$, and incremented by
!   the same amount if the atom is moving in the same direction between steps.
!   If the direction changes then $\tau_{\alpha}$ is reset to {\tt tau0atp}.
!
!   \block{tau0latv}{
!   {\tt tau0latv} & the step size to be used for lattice vector optimisation &
!    real & $0.5$}
!   This parameter is used for lattice vector optimisation in a procedure
!   identical to that for atomic position optimisation. See {\tt tau0atp} and
!   {\tt latvopt}.
!
!   \block{tauoep}{
!   {\tt tauoep} & step length initial value and scaling factors for the OEP
!    iterative solver & real(3) & $(1.0, 0.2, 1.5)$}
!   The optimised effective potential is determined using an interative method.
!   [Phys. Rev. Lett. 98, 196405 (2007)]. At the first iteration the step length
!   is set to {\tt tauoep(1)}. During subsequent iterations, the step length is
!   scaled by {\tt tauoep(2)} or {\tt tauoep(3)}, when the residual is
!   increasing or decreasing, respectively. See also {\tt maxitoep}.
!
!   \block{taufsm}{
!   {\tt taufsm} & the step size to be used when finding the effective magnetic
!   field in fixed spin moment calculations & real & $0.01$}
!   An effective magnetic field, ${\bf B}_{\rm FSM}$, is required for fixing the
!   spin moment to a given value, ${\bf M}_{\rm FSM}$. This is found by adding a
!   vector to the field which is proportional to the difference between the
!   moment calculated in the $i$th self-consistent loop and the required moment:
!   $$ {\bf B}_{\rm FSM}^{i+1}={\bf B}_{\rm FSM}^i+\lambda\left({\bf M}^i
!    -{\bf M}_{\rm FSM}\right), $$
!   where $\lambda$ is proportional to {\tt taufsm}. See also {\tt fsmtype},
!   {\tt momfix} and {\tt spinpol}.
!
!   \block{tfibs}{
!   {\tt tfibs} & set to {\tt .true.} if the IBS correction to the force should
!    be calculated & logical & {\tt .true.}}
!   Because calculation of the incomplete basis set (IBS) correction to the
!   force is fairly time-consuming, it can be switched off by setting
!   {\tt tfibs} to {\tt .false.} This correction can then be included only when
!   necessary, i.e. when the atoms are close to equilibrium in a geometry
!   optimisation run.
!
!   \block{tforce}{
!   {\tt tforce} & set to {\tt .true.} if the force should be calculated at the
!    end of the self-consistent cycle & logical & {\tt .false.}}
!   This variable is automatically set to {\tt .true.} when performing geometry
!   optimisation.
!
!   \block{tmwrite}{
!   {\tt tmwrite} & set to {\tt .true.} if the tensor moments and the
!    corresponding decomposition of DFT+$U$ energy should be calculated
!    at every loop of the self-consistent cycle & logical & {\tt .false.}}
!   This variable is useful to check the convergence of the tensor moments in
!   DFT+$U$ caculations. Alternatively, with {\tt task} equal to 400, one can
!   calculate the tensor moments and corresponding DFT+$U$ energy contributions
!   from a given density matrix and set of Slater parameters at the end of the
!   self-consistent cycle.
!
!   \block{trimvg}{
!   {\tt trimvg} & set to {\tt .true.} if the Fourier components of the
!    Kohn-Sham potential for $|G|>{\tt gmaxvr}/2$ are to be set to zero &
!    logical & {\tt .false.}}
!   This fixes stability problems which can occur for large {\tt rgkmax}. Should
!   be used only in conjunction with large {\tt gmaxvr}.
!
!   \block{tefvit}{
!   {\tt tefvit} & set to {\tt .true.} if the first-variational eigenvalue
!    equation should be solved iteratively & logical & {\tt .false.}}
!
!   \block{tefvr}{
!   {\tt tefvr} & set to {\tt .true.} if a real symmetric eigenvalue solver
!    should be used for crystals which have inversion symmetry & logical &
!    {\tt .true.}}
!   For crystals with inversion symmetry, the first-variational Hamiltonian and
!   overlap matrices can be made real by using appropriate transformations. In
!   this case, a real symmetric (instead of complex Hermitian) eigenvalue solver
!   can be used. This makes the calculation about three times faster.
!
!   \block{tmomfix}{
!   {\tt ntmfix} & number of tensor moments (TM) to be fixed & integer & 0 \\
!   \hline
!   {\tt is(i)} & species number for entry $i$ & integer & - \\
!   {\tt ia(i)} & atom number & integer & - \\
!   {\tt (l, n)(i)} & $l$ and $n$ indices of TM & integer & - \\
!   \hline
!   {\tt (k, p, x, y)(i)} or & & & \\
!    {\tt (k, p, r, t)(i)} & indices for the 2-index or 3-index TM,
!    respectively & integer & - \\
!   \hline
!   {\tt z(i)} & complex TM value & complex & - \\
!   \hline
!   {\tt p(i)} & parity of spatial rotation & integer & - \\
!   {\tt aspl(i)} & Euler angles of spatial rotation & real(3) & - \\
!   {\tt aspn(i)} & Euler angles of spin rotation & real(3) & - }
!   This block sets up the fixed tensor moment (FTM). There should be as many
!   TM entries as {\tt ntmfix}. See {\it Phys. Rev. Lett.} {\bf 103}, 107202
!   (2009) for the tensor moment indexing convention. This is a highly
!   complicated feature of the code, and should only be attempted with a full
!   understanding of tensor moments.
!
!   \block{tshift}{
!   {\tt tshift} & set to {\tt .true.} if the crystal can be shifted so that the
!    atom closest to the origin is exactly at the origin &
!    logical & {\tt .true.}}
!
!   \block{vhmat}{
!   {\tt vhmat(1)} & matrix row 1 & real(3) & $(1.0,0.0,0.0)$ \\
!   \hline
!   {\tt vhmat(2)} & matrix row 2 & real(3) & $(0.0,1.0,0.0)$ \\
!   \hline
!   {\tt vhmat(3)} & matrix row 3 & real(3) & $(0.0,0.0,1.0)$}
!   This is the transformation matrix $M$ applied to every vector $\bf H$ in the
!   structure factor output files {\tt SFACRHO.OUT} and {\tt SFACMAG.OUT}. It is
!   stored in the usual row-column setting and applied directly as
!   ${\bf H}'=M{\bf H}$ to every vector but {\em only} when writing the output
!   files. See also {\tt hmaxvr} and {\tt reduceh}.
!
!   \block{vklem}{
!   {\tt vklem} & the $k$-point in lattice coordinates at which to compute the
!    effective mass tensors & real(3) & $(0.0,0.0,0.0)$}
!   See {\tt deltaem} and {\tt ndspem}.
!
!   \block{vkloff}{
!   {\tt vkloff } & the $k$-point offset vector in lattice coordinates &
!    real(3) & $(0.0,0.0,0.0)$}
!   See {\tt ngridk}.
!
!   \block{vqlss}{
!   {\tt vqlss} & the ${\bf q}$-vector of the spin-spiral state in lattice
!    coordinates & real(3) & $(0.0,0.0,0.0)$}
!   Spin-spirals arise from spinor states assumed to be of the form
!   $$ \Psi^{\bf q}_{\bf k}({\bf r})=
!    \left( \begin{array}{c}
!    U^{{\bf q}\uparrow}_{\bf k}({\bf r})e^{i({\bf k+q/2})\cdot{\bf r}} \\
!    U^{{\bf q}\downarrow}_{\bf k}({\bf r})e^{i({\bf k-q/2})\cdot{\bf r}} \\
!    \end{array} \right). $$
!   These are determined using a second-variational approach, and give rise to a
!   magnetisation density of the form
!   $$ {\bf m}^{\bf q}({\bf r})=(m_x({\bf r})\cos({\bf q \cdot r}),
!    m_y({\bf r})\sin({\bf q \cdot r}),m_z({\bf r})), $$
!   where $m_x$, $m_y$ and $m_z$ are lattice periodic. See also {\tt spinsprl}.
!
!   \block{wplot}{
!   {\tt nwplot} & number of frequency/energy points in the DOS or optics plot &
!    integer & $500$ \\
!   {\tt ngrkf} & fine $k$-point grid size used for integrating functions in the
!    Brillouin zone & integer & $100$ \\
!   {\tt nswplot} & level of smoothing applied to DOS/optics output & integer &
!    $1$ \\
!   \hline
!   {\tt wplot} & frequency/energy window for the DOS or optics plot & real(2) &
!    $(-0.5,0.5)$}
!   DOS and optics plots require integrals of the kind
!   $$ g(\omega_i)=\frac{\Omega}{(2\pi)^3}\int_{\rm BZ} f({\bf k})
!    \delta(\omega_i-e({\bf k}))d{\bf k}. $$
!   These are calculated by first interpolating the functions $e({\bf k})$ and
!   $f({\bf k})$ with the trilinear method on a much finer mesh whose size is
!   determined by {\tt ngrkf}. Then the $\omega$-dependent histogram of the
!   integrand is accumulated over the fine mesh. If the output function is noisy
!   then either {\tt ngrkf} should be increased or {\tt nwplot} decreased.
!   Alternatively, the output function can be artificially smoothed up to a
!   level given by {\tt nswplot}. This is the number of successive 3-point
!   averages to be applied to the function $g$.
!
!   \block{wsfac}{
!   {\tt wsfac} & energy window to be used when calculating density or magnetic
!    structure factors & real(2) & $(-10^6,10^6)$}
!   Only those states with eigenvalues within this window will contribute to the
!   density or magnetisation. See also {\tt hmaxvr} and {\tt vhmat}.
!
!   \block{xctype}{
!   {\tt xctype} & integers defining the type of exchange-correlation functional
!    to be used & integer(3) & $(3,0,0)$}
!   Normally only the first value is used to define the functional type. The
!   other value may be used for external libraries. Currently implemented are:
!   \vskip 6pt
!   \begin{tabularx}{\textwidth}[h]{lX}
!   $-n$ & Exact-exchange optimised effective potential (EXX-OEP) method with
!    correlation energy and potential given by functional number $n$ \\
!   1 & No exchange-correlation funtional ($E_{\rm xc}\equiv 0$) \\
!   2 & LDA, Perdew-Zunger/Ceperley-Alder, {\it Phys. Rev. B} {\bf 23}, 5048
!    (1981) \\
!   3 & LSDA, Perdew-Wang/Ceperley-Alder, {\it Phys. Rev. B} {\bf 45}, 13244
!    (1992) \\
!   4 & LDA, X-alpha approximation, J. C. Slater, {\it Phys. Rev.} {\bf 81}, 385
!    (1951) \\
!   5 & LSDA, von Barth-Hedin, {\it J. Phys. C} {\bf 5}, 1629 (1972) \\
!   20 & GGA, Perdew-Burke-Ernzerhof, {\it Phys. Rev. Lett.} {\bf 77}, 3865
!    (1996) \\
!   21 & GGA, Revised PBE, Zhang-Yang, {\it Phys. Rev. Lett.} {\bf 80}, 890
!    (1998) \\
!   22 & GGA, PBEsol, Phys. Rev. Lett. 100, 136406 (2008) \\
!   26 & GGA, Wu-Cohen exchange (WC06) with PBE correlation, {\it Phys. Rev. B}
!    {\bf 73}, 235116 (2006) \\
!   30 & GGA, Armiento-Mattsson (AM05) spin-unpolarised functional,
!    {\it Phys. Rev. B} {\bf 72}, 085108 (2005) \\
!   100 & Libxc functionals; the second and third values of {\tt xctype} define
!    the exchange and correlation functionals in the Libxc library,
!    respectively \\
!   \end{tabularx}
!
!   \section{Contributing to Elk}
!   Please bear in mind when writing code for the Elk project that it should be
!   an exercise in physics and not software engineering. All code should
!   therefore be kept as simple and concise as possible, and above all it should
!   be easy for anyone to locate and follow the Fortran representation of the
!   original mathematics. We would also appreciate the following conventions
!   being adhered to:
!   \begin{itemize}
!   \item Strict Fortran 90/95 should be used. Features which are marked as
!    obsolescent in F90/95 should be avoided. These include assigned format
!    specifiers, labeled do-loops, computed goto statements and statement
!    functions.
!   \item Modules should be used in place of common blocks for declaring
!    global variables. Use the existing modules to declare new global variables.
!   \item Any code should be written in lower-case free form style, starting
!    from column one. Try and keep the length of each line to fewer than 80
!    characters using the \& character for line continuation.
!   \item Every function or subroutine, no matter how small, should be in its
!    own file named {\tt routine.f90}, where {\tt routine} is the function or
!    subroutine name. It is recommended that the routines are named so as to
!    make their purpose apparent from the name alone.
!   \item Use of {\tt implicit none} is mandatory. Remember also to define the
!    {\tt intent} of any passed arguments.
!   \item Local allocatable arrays must be deallocated on exit of the routine to
!    prevent memory leakage. Use of automatic arrays should be limited to arrays
!    of small size.
!   \item Every function or subroutine must be documented with the Protex source
!    code documentation system. This should include a short \LaTeX\ description
!    of the algorithms and methods involved. Equations which need to be
!    referenced should be labeled with {\tt routine\_1}, {\tt routine\_2}, etc.
!    The authorship of each new piece of code or modification should be
!    indicated in the {\tt REVISION HISTORY} part of the header. See the Protex
!    documentation for details.
!   \item Ensure as much as possible that a routine will terminate the program
!    when given improper input instead of continuing with erroneous results.
!    Specifically, functions should have a well-defined domain for which they
!    return accurate results. Input outside that domain should result in an
!    error message and termination.
!   \item Report errors prior to termination with a short description, for
!    example:
!    \begin{verbatim}
!     write(*,*)
!     write(*,'("Error(readinput): natoms <= 0 : ",I8)') natoms(is)
!     write(*,'(" for species ",I4)') is
!     write(*,*)
!     stop
!    \end{verbatim}
!   \item Wherever possible, real numbers outputted as ASCII data should be
!    formatted with the {\tt G18.10} specifier.
!   \item Avoid redundant or repeated code: check to see if the routine you need
!    already exists, before writing a new one.
!   \item All reading in of ASCII data should be done in the subroutine
!    {\tt readinput}. For binary data, separate routines for reading and writing
!    should be used (for example {\tt writestate} and {\tt readstate}).
!   \item Input filenames should be in lowercase and have the extension
!    {\tt .in} . All output filenames should be in uppercase with the extension
!    {\tt .OUT} .
!   \item All internal units should be atomic. Input and output units should be
!    atomic by default and clearly stated otherwise. Rydbergs should not be used
!    under any circumstances.
!   \end{itemize}
!   \subsection{Licensing}
!    Routines which constitute the main part of the code are released under the
!    GNU General Public License (GPL). Library routines are released under the
!    less restrictive GNU Lesser General Public License (LGPL). Both licenses
!    are contained in the file {\tt COPYING}. Any contribution to the code must
!    be licensed at the authors' discretion under either the GPL or LGPL.
!    Author(s) of the code retain the copyrights. Copyright and (L)GPL
!    information must be included at the beginning of every file, and no code
!    will be accepted without this.
!
!EOI

