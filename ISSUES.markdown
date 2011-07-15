This document lists some issues and ideas related to packaging Padre.
Most if not all good ideas came from Mark@Cava.

Bugs
====
*  We may be getting an OSX issue with exiting perl causing a Padre Exit failure. These could be resolved by looking into SetExitOnFrameDelete in wxApp.

* Does the Padre window change in size each time it is opened?


Building Padre / Platforms
==========================
OSX:

*  We do need to stick with 32bit perl on OSX if we want the stable Wx packages (2.8.xx(12))
*  The development Wx (2.9) can use 64 bit uses carbon, but may be incomplete.

Linux:

*  Building on linux: Mark suggests we stick with building on CentOS because it will produce packages that work on the most distributions of linux, including RHEL5
*  We probably need to do 32 and 64 bit versions for linux
*  An option to streamline linux building is to package Wx in PAR Dist, and distribute that. Otherwise, padre-brew is going to be hard on linux because linux builds depend on the user having installed Wx and dependencies using their own package manager. If we have a stable build machine, we can manually set this up once.

Windows:

* Building on Windows may be easiest using Strawberry perl, and probably a 32 bit version is sufficient though a 64 could be built.

Padre Calling External Perls
============================
There are a number of cases where Padre does NOT call external perl, though it probably should.

One questionable one is migration.

One more obvious one is when calling Parse::ErrorString::Perl => Pod::Find::pod_where
 Here we should actively specify the directory containing our external perl, rather than relying on the bundled pod and calling internal perl?

