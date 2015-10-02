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

/* $Log: romio.c,v $
 * Revision 1.1  1995/01/11  18:11:25  ecd
 * Initial revision
 *
 *
 * $Id: romio.c,v 1.1 1995/01/11 18:11:25 ecd Exp ecd $
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/stat.h>

#include "global.h"
#include "romio.h"

unsigned int opt_gx = 0;
unsigned int rom_size = 0;

int
#ifdef __FunctionProto__
read_rom_file(char *name, unsigned char **mem, int *size)
#else
read_rom_file(name, mem, size)
char *name;
unsigned char **mem;
int *size;
#endif
{
  FILE *fp;
  unsigned char *tmp_mem;
  unsigned char byte;
  unsigned char four[4];
  int i, j;
  long file_size;
	
  *mem = NULL;
  *size = 0;
  if (NULL == (fp = fopen(name, "r")))
    {
      fprintf(stderr, "can\'t open %s\n", name);
      return 0;
    }

  fseek(fp, 0, SEEK_END);
  file_size = ftell(fp);
  fseek(fp, 0, SEEK_SET);
	
  if (fread(four, 1, 4, fp) != 4)
    {
      fprintf(stderr, "can\'t read first 4 bytes of %s\n", name);
      fclose(fp);
      return 0;
    }

  if (four[0] == 0x02 && four[1] == 0x03 &&
      four[2] == 0x06 && four[3] == 0x09)
    {
      *size = (int)file_size;
    }
  else if (four[0] == 0x32 && four[1] == 0x96 &&
      four[2] == 0x1b && four[3] == 0x80)
    {
      *size = 2 * (int)file_size;
    }
  else if ((four[1] = 0x49))
    {
      fprintf(stderr, "%s is an HP49 ROM\n", name);
      *size = 2 * (int)file_size;
    }
  else if (four[0])
    {
      printf("%d\n", (int)file_size);
      *size = (int)file_size;
    }
  else
    {
      fprintf(stderr, "%s is not a HP48 ROM\n", name);
      fclose(fp);
      return 0;
    }

  if (fseek(fp, 0, 0) < 0)
    {
      fprintf(stderr, "can\'t fseek to position 0 in %s\n", name);
      *size = 0;
      fclose(fp);
      return 0;
    }

  *mem = (unsigned char *)malloc(*size);

  if (file_size == *size)
    {
      /*
       * size is same as memory size, old version file
       */
      if (fread(*mem, 1, (size_t)*size, fp) != *size)
        {
          fprintf(stderr, "can\'t read %s\n", name);
          free(*mem);
          *mem = NULL;
          *size = 0;
          fclose(fp);
          return 0;
        }
    }
  else
    {
      /*
       * size is different, check size and decompress memory
       */

      if (file_size != *size / 2)
        {
          fprintf(stderr, "strange size %s, expected %d, found %ld\n",
                  name, *size / 2, (long int)file_size);
          free(*mem);
          *mem = NULL;
          *size = 0;
          fclose(fp);
          return 0;
        }

      if (NULL == (tmp_mem = (unsigned char *)malloc((size_t)file_size)))
        {
          for (i = 0, j = 0; i < *size / 2; i++)
            {
              if (1 != fread(&byte, 1, 1, fp))
                {
                  fprintf(stderr, "can\'t read %s\n", name);
                  free(*mem);
                  *mem = NULL;
                  *size = 0;
                  fclose(fp);
                  return 0;
                }
              (*mem)[j++] = byte & 0xf;
              (*mem)[j++] = (byte >> 4) & 0xf;
            }
        }
      else
        {
          if (fread(tmp_mem, 1, (size_t)*size / 2, fp) != *size / 2)
            {
              fprintf(stderr, "can\'t read %s\n", name);
              free(*mem);
              *mem = NULL;
              *size = 0;
              fclose(fp);
              free(tmp_mem);
              return 0;
            }

          for (i = 0, j = 0; i < *size / 2; i++)
            {
              (*mem)[j++] = tmp_mem[i] & 0xf;
              (*mem)[j++] = (tmp_mem[i] >> 4) & 0xf;
            }
    
          free(tmp_mem);
        }
    }

  fclose(fp);

  if ((*mem)[0x29] == 0x00)
    {
      if (*size == ROM_SIZE_GX)
        {
          opt_gx = 1;
        }
      else
      if (*size == 4 * ROM_SIZE_GX)
        {
          fprintf(stderr, "%s seems to be HP49 ROM, but size is 0x%x\n",
		  name, *size);
          opt_gx = 2;
        }
      else
      if (*size == 8 * ROM_SIZE_GX)
        {
          fprintf(stderr, "%s seems to be HP49 ROM, but size is 0x%x\n",
		  name, *size);
          opt_gx = 2;
        }
      else
        {
          fprintf(stderr, "%s seems to be G/GX ROM, but size is 0x%x\n",
		  name, *size);
          free(*mem);
          *mem = NULL;
          *size = 0;
          return 0;
        }
    }
  else
    {
      if (*size == ROM_SIZE_SX)
        {
          opt_gx = 0;
        }
      else
        {
          fprintf(stderr, "%s seems to be S/SX ROM, but size is 0x%x\n",
		  name, *size);
          free(*mem);
          *mem = NULL;
          *size = 0;
          return 0;
        }
    }

  if (verbose)
    printf("%s: read %s\n", progname, name);

  return 1;
}

