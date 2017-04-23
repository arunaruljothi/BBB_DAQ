// delay tester

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
#define RECORDS 200000

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
		MOV r14, 500 // byteswap delay
UDEL1:
		SUB r14, r14, 1
		QBNE UDEL1, r14, 0 // loop if weve not finished
.endm

.macro DEL
DEL:
		MOV r1, 50000 // generic delay
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

		MOV r4, 500000

LOOPDEL:
		SET r30.t11 // set high
		DEL
		CLR r30.t11 // set low
		DEL
		SUB r4, r4, 1
		QBEQ LOOPDEL, r4, 0

EXIT:
    // Send notification to Host for program completion
    MOV       r31.b0, PRU1_ARM_INTERRUPT+16

    // Halt the processor
    HALT

ERR:
	LED_ON
	JMP ERR
