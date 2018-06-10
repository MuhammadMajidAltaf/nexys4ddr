	.setcpu		"6502"

   .export init, _exit
   .export nmi_int, irq_int
   .import _main

   .export __STARTUP__ : absolute = 1     ; Mark as startup
   .import __RAM_START__, __RAM_SIZE__    ; Linker generated

   .import copydata, zerobss, initlib, donelib

   .include "zeropage.inc"

; ---------------------------------------------------------------------------
; Place the startup code in a special segment

.segment	"STARTUP"

; ---------------------------------------------------------------------------
; Entry point for a hardware reset. Referenced in lib/vectors.s

init:

; ---------------------------------------------------------------------------
; Setup processor mode

   SEI         ; Disable interrupts
   CLD         ; Clear decimal mode
   LDX #$FF    ; Reset stack pointer
   TXS

; ---------------------------------------------------------------------------
; Set cc65 argument stack pointer

   LDA #<(__RAM_START__ + __RAM_SIZE__)
   STA sp
   LDA #>(__RAM_START__ + __RAM_SIZE__)
   STA sp+1   

; ---------------------------------------------------------------------------
; Initialize memory storage

   JSR zerobss              ; Clear BSS segment
   JSR copydata             ; Initialize DATA segment
   JSR clearscreen          ; Fill the character screen with ' '.
   JSR initlib              ; Run constructors

; ---------------------------------------------------------------------------
; Call C-function main()

   JSR _main

; ---------------------------------------------------------------------------
; Back from main (this is also entry point for the C-function exit()):

_exit:
   SEI                      ; Disable interrupts
   JSR donelib              ; Run destructors
halt:
   JMP halt

clearscreen:
   LDY #$00                 ; Address of character memory
   LDX #$80
   STY ptr1                 ; Store address in zeropage pointer
   STX ptr1+1
   LDA #$20                 ; ASCII code for ' '
   LDX #$A0                 ; High byte of end pointer
   LDY #$00                 ; Loop counter
loop:                       ; Fill 256 bytes with ' '
   STA (ptr1),Y
   INY
   BNE loop
   INC ptr1+1               ; Increment high byte
   CPX ptr1+1               ; Have we reached the end?
   BNE loop                 ; If not, go back and continue.
   RTS

.segment	"CODE"

nmi_int:
   RTI

irq_int:
   RTI

