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

/* $Log: serial.c,v $
 * Revision 1.11  1995/01/11  18:20:01  ecd
 * major update to support HP48 G/GX
 *
 * Revision 1.10  1994/12/07  20:20:50  ecd
 * complete change in handling of serial line,
 * lines can be turned off now
 *
 * Revision 1.10  1994/12/07  20:20:50  ecd
 * complete change in handling of serial line,
 * lines can be turned off now
 *
 * Revision 1.9  1994/11/28  02:00:51  ecd
 * added support for drawing the connections in the window title
 *
 * Revision 1.8  1994/11/02  14:44:28  ecd
 * support for HPUX added
 *
 * Revision 1.7  1994/10/06  16:30:05  ecd
 * new init for IRIX
 * added CREAD for serial line
 *
 * Revision 1.6  1994/10/05  08:49:59  ecd
 * changed printf() to print the correct /dev/ttyp?
 *
 * Revision 1.5  1994/09/30  12:37:09  ecd
 * check if serial device is opened by OPENIO
 *
 * Revision 1.4  1994/09/18  15:29:22  ecd
 * turned off unused rcsid message
 *
 * Revision 1.3  1994/09/13  16:57:00  ecd
 * changed to plain X11
 *
 * Revision 1.2  1994/08/31  18:23:21  ecd
 * changed IR and wire definitions.
 *
 * Revision 1.1  1994/08/26  11:09:02  ecd
 * Initial revision
 *
 * $Id: serial.c,v 1.11 1995/01/11 18:20:01 ecd Exp ecd $
 */


#include "global.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/time.h>
#if defined(HPUX) || defined(CSRG_BASED)
#  include <sys/ioctl.h>
#endif
#include <unistd.h>
#include <termios.h>
#ifdef SOLARIS
#  include <sys/stream.h>
#  include <sys/stropts.h>
#  include <sys/termios.h>
#endif

#include "hp48.h"
#include "device.h"
#include "hp48_emu.h"

extern int rece_instr;

/* #define DEBUG_SERIAL */

void
update_connection_display(void)
{
}

int
serial_init(void)
{
	/* Not implemented */
	return 1;
}

void
serial_baud(int baud)
{
	/* Not implemented */
}


void
transmit_char(void)
{
	/* Not implemented */
}

void
receive_char()
{
	/* Not implemented */
}
