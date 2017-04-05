/*
 * adc.c
 */

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

#include <i2cfunc.h>

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

FILE* outfile;


/******************************************************************************
* Global Function Definitions                                                 *
******************************************************************************/


void dumpdata(void)
{
	unsigned short int *DDR_regaddr;
	unsigned char* test;
	int ln;
	int x;
	unsigned char tv;

  unsigned short int* valp;
  unsigned short int val;
  unsigned char rgb24[4];
  unsigned char v1, v2;
  rgb24[3]=0;
	

	
	DDR_regaddr = ddrMem + OFFSET_DDR;
	valp=(unsigned short int*)&sharedMem_int[OFFSET_SHAREDRAM+1];
	for (x=0; x<2000; x++)
	{
		val=*valp;
		val=val & 0xff; // we're just interested in 8 bits

		fprintf(outfile, "%d\n", val);
		valp++;
		valp++;
	}
	printf("\n");

	
}


int main (void)
{
    unsigned int ret;
    int i;
    void *DDR_paramaddr;
    void *DDR_ackaddr;
    int fin;
    char fname_new[255];
    
    tpruss_intc_initdata pruss_intc_initdata = PRUSS_INTC_INITDATA;
   
    printf("\nINFO: Starting %s example.\r\n", "ADC");
    /* Initialize the PRU */
    prussdrv_init ();		

    /* Open PRU Interrupt */
    ret = prussdrv_open(PRU_EVTOUT_1);
    if (ret)
    {
        printf("prussdrv_open open failed\n");
        return (ret);
    }
    
    /* Get the interrupt initialized */
    prussdrv_pruintc_init(&pruss_intc_initdata);
    
    // Open file
    outfile=fopen("data.csv", "w");

    /* Initialize example */
    printf("\tINFO: Initializing example.\r\n");
    LOCAL_exampleInit(PRU_NUM);
    
    /* Execute example on PRU */
    printf("\tINFO: Executing example.\r\n");
    
    DDR_paramaddr = ddrMem + OFFSET_DDR - 8;
    DDR_ackaddr = ddrMem + OFFSET_DDR - 4;
    
    sharedMem_int[OFFSET_SHAREDRAM]=0; // set to zero means no command
    // Execute program
    prussdrv_exec_program (PRU_NUM, "./prucode_adc.bin");
		printf("Executing. \n");
		sleep(1);
		sharedMem_int[OFFSET_SHAREDRAM]=(unsigned int)2; // set to 2 means perform capture
		
		// give some time for the PRU code to execute
		sleep(1);
		printf("Waiting for ack (curr=%d). \n", sharedMem_int[OFFSET_SHAREDRAM]);
		fin=0;
		do
		{
			if ( sharedMem_int[OFFSET_SHAREDRAM] == 1 )
			{
				// we have received the ack!
				dumpdata(); // Store to file
				sharedMem_int[OFFSET_SHAREDRAM] = 0;
				fin=1;
				printf("Ack\n");
			}
		} while(!fin);

		
		
    //prussdrv_pru_wait_event (PRU_EVTOUT_1);
    printf("Done\n");
    	//prussdrv_pru_clear_event (PRU1_ARM_INTERRUPT);

 		   	

		fclose(outfile);

    
    
    /* Disable PRU and close memory mapping*/
    prussdrv_pru_disable(PRU_NUM); 
    prussdrv_exit ();
    munmap(ddrMem, 0x0FFFFFFF);
    close(mem_fd);

    return(0);
}

/*****************************************************************************
* Local Function Definitions                                                 *
*****************************************************************************/

static int LOCAL_exampleInit (  )
{
    void *DDR_regaddr1, *DDR_regaddr2, *DDR_regaddr3;	
    
    prussdrv_map_prumem(PRUSS1_SHARED_DATARAM, &sharedMem);
    sharedMem_int = (unsigned int*) sharedMem;

    /* open the device */
    mem_fd = open("/dev/mem", O_RDWR);
    if (mem_fd < 0) {
        printf("Failed to open /dev/mem (%s)\n", strerror(errno));
        return -1;
    }	

    /* map the DDR memory */
    ddrMem = mmap(0, 0x0FFFFFFF, PROT_WRITE | PROT_READ, MAP_SHARED, mem_fd, DDR_BASEADDR);
    if (ddrMem == NULL) {
        printf("Failed to map the device (%s)\n", strerror(errno));
        close(mem_fd);
        return -1;
    }
    

    return(0);
}

