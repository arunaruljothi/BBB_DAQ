// pru code v0.1 (testoutput into c program)
//
// BBB Schematic  BBB port Assign   Bit
// -------------  -------- ------   ------------
// LCD_DATA0      P8.45    d0       PRU1_R31_0
// LCD_DATA1      P8.46    d1       PRU1_R31_1
// LCD_DATA2      P8.43    d2       PRU1_R31_2
// LCD_DATA3      P8.44    d3       PRU1_R31_3
// LCD_DATA4      P8.41    d4       PRU1_R31_4
// LCD_DATA5      P8.42    d5       PRU1_R31_5
// LCD_DATA6      P8.39    d6       PRU1_R31_6
// LCD_DATA7      P8.40    d7       PRU1_R31_7
// LCD_DATA7      P8.29    CNVST    PRU1_R30_9
// LCD_PCLK       P8.28    BUSY     PRU1_R31_10
// LCD_DE         P8.30    BYTESWP  PRU1_R30_11

.origin 0
.entrypoint START

#include "prucode_adc.hp"

#define GPIO1 0x4804c000
#define GPIO_CLEARDATAOUT 0x190
#define GPIO_SETDATAOUT 0x194

#define SHARED 0x10000

#define MASK0 0x000000ff

// Memory location of command:
#define CMD 0x00010000

// Memory location where to store the data to be acquired:
#define ACQRAM 0x00010004
// Length of acquisition:
#define RECORDS 20000000

// *** LED routines, so that LED USR0 can be used for some simple debugging
// *** Affects: r2, r3
.macro LED_OFF
		MOV r2, 1<<21
    MOV r3, GPIO1 | GPIO_CLEARDATAOUT
    SBBO r2, r3, 0, 4
.endm

.macro LED_ON
		MOV r2, 1<<21
    MOV r3, GPIO1 | GPIO_SETDATAOUT
    SBBO r2, r3, 0, 4
.endm

.macro UDEL
UDEL:
		MOV r14, 50 // byteswap delay
UDEL1:
		SUB r14, r14, 1
		QBNE UDEL1, r14, 0 // loop if weve not finished
.endm

.macro DEL
DEL:
		MOV r1, 500 // generic delay
DEL1:
		SUB r1, r1, 1
		QBNE DEL1, r1, 0 // loop if weve not finished
.endm

.macro MDEL
DEL:
		MOV r1, 5000000 // generic delay
DEL1:
		SUB r1, r1, 1
		QBNE DEL1, r1, 0 // loop if weve not finished
.endm




START:

    // Enable OCP master port
    LBCO      r0, CONST_PRUCFG, 4, 4
    CLR     r0, r0, 4         // Clear SYSCFG[STANDBY_INIT] to enable OCP master port
    SBCO      r0, CONST_PRUCFG, 4, 4

    // Configure the programmable pointer register for PRU0 by setting c28_pointer[15:0]
    // field to 0x0100.  This will make C28 point to 0x00010000 (PRU shared RAM).
    MOV     r0, 0x00000100
    MOV       r1, CTPPR_0
    ST32      r0, r1

    // Configure the programmable pointer register for PRU0 by setting c31_pointer[15:0]
    // field to 0x0010.  This will make C31 point to 0x80001000 (DDR memory).
    MOV     r0, 0x00100000
    MOV       r1, CTPPR_1
    ST32      r0, r1

    //Load values from external DDR Memory into Registers R0/R1/R2
    LBCO      r0, CONST_DDR, 0, 12

    //Store values from read from the DDR memory into PRU shared RAM
    //SBCO      r0, CONST_PRUSHAREDRAM, 0, 12

		LED_OFF


START1:
		MOV r6, ACQRAM // PRU shared RAM
		MOV r4, MASK0
		MOV r7, RECORDS // This will be the loop counter to read the entire set of data
		MOV r11, CMD
		// wait for command
CMDLOOP:
		DEL //delay before starting
		LBCO r12, CONST_PRUSHAREDRAM, 0, 4
		QBEQ CMDLOOP, r12, 0 // loop until we get an instruction
		QBEQ CMDLOOP, r12, 1 // loop until we get an instruction
		// ok, we have an instruction. Assume it means begin capture
		LED_ON

RUN:
		WBC r31.t10 // wait for input to be low
	  CLR r30.t9 // set out low
		WBS r31.t10 // wait for input to be hight
		SET r30.t9 // set out high
		SUB r7, r7, 1 // sub one from records
		QBNE RUN, r7, 0 // loop back to run


CLEANUP:
		LED_OFF
		MOV r1, 1
		SBCO r1, CONST_PRUSHAREDRAM, 0, 8 // Put contents of r1 into shared RAM
		JMP EXIT // finished, Quit

EXIT:
    // Send notification to Host for program completion
    MOV       r31.b0, PRU1_ARM_INTERRUPT+16
    // Halt the processor
    HALT

ERR:
	LED_ON
	HALT
	JMP ERR