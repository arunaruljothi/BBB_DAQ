/******************************************************************************
* Include Files                                                               *
******************************************************************************/

// Standard header files
#include <stdio.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>
#include <string.h>


// Driver header file
#include "prussdrv.h"
#include <pruss_intc_mapping.h>
#include "adc.h"


/******************************************************************************
* Local Macro Declarations                                                    *
******************************************************************************/

#define PRU_NUM 	 1

#define DDR_BASEADDR     0x80000000
#define OFFSET_DDR	 0x00001008

#define OFFSET_SHAREDRAM 0
#define PRUSS1_SHARED_DATARAM    4


/******************************************************************************
* Local Function Declarations                                                 *
******************************************************************************/

static int LOCAL_exampleInit ( );


/******************************************************************************
* Global Variable Definitions                                                 *
******************************************************************************/

static int mem_fd;
static void *ddrMem, *sharedMem;

static int chunk;

static unsigned int *sharedMem_int;

int main (void)
{
  prussdrv_init ();
  
  prussdrv_pru_disable(PRU_NUM);
  prussdrv_exit ();
  munmap(ddrMem, 0x0FFFFFFF);
  close(mem_fd);

  return(0);
}
