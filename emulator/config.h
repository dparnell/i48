/*
 *  This file is part of x48, an emulator of the HP-48sx Calculator.
 *  Copyright (C) 1994  Eddie C. Dost  (ecd@dressler.de)
 * 
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 * 
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 * 
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

/*
 * There are five supported architectures so far:
 *
 * Linux, Sunos 4.1.x, Solaris 2.x, Irix, HP/UX
 *
 * Please uncomment the relevant stuff for your machine, then type
 * 'xmkmf', then 'make'
 */

/*
 * Which OS are you on?
 */
#if defined(LinuxArchitecture)
# define UNIX_DEF -DLINUX
#elif  defined(SunArchitecture)
# define UNIX_DEF -DSOLARIS
#elif  defined(SGIArchitecture)
# define UNIX_DEF -DIRIX
#elif  defined(HPArchitecture)
# define UNIX_DEF -DHPUX
#elif  defined(DarwinArchitecture)
# define UNIX_DEF -DAPPLE
#endif

/*
 * If you have class (hp48 assembler), uncomment the following line
 */
/* #define HAVE_CLASS */

/*
 * If you don't have the XShm extension, comment the following line
 */
#define HAVE_XSHM

/*
 * If you don't want to use the readline library,
 * comment the following line
 *
 * (you should not have to do this ...)
 */
/* #define HAVE_READLINE */

/*
 * Which Optimization Flags:
 */
#if defined(linux)
   CDEBUGFLAGS_DEF = -O6 -Wall
//#  define CDEBUGFLAGS_DEF -O6 -Wall
#endif

/*
 * Which Flags to pass to the Linker:
 */
/* #define LDOPTIONS_DEF */


/************************************************************************
 *									*
 * DON'T CHANGE THESE DEFINITIONS !!!					*
 *									*
 ************************************************************************/

  VERSION_MAJOR = 0
  VERSION_MINOR = 4
     PATCHLEVEL = 3

#define HAVE_READLINE
