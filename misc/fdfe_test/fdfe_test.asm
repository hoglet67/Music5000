   org &FD00

oswrch = &ffee

   ;; This is called before the VDU is initialized

.reset1
   ;; Clear the interrupt reset interrupt
   LDA &FCFF

   ;; Use the BREAK intercept vecter to run some code later
   ;; TODO: Should we save/chain the old vector?
   LDA #&4C
   STA &0287
   LDA #<reset2
   STA &0288
   LDA #>reset2
   STA &0289
   RTS

   ;; This is run after the VDU is initialized
.reset2
   ;; Clear the break intercept bector
   LDA #&00
   STA &0287

   ;; Test the break type
   LDA &028D
   BEQ exit

   ;; Save the current cursor location
   LDA &0319
   PHA
   LDA &0318
   PHA

   ;; Print the Owl (assumes mode 7)
   LDX #&00
.loop
   LDA owl_data,X
   BEQ done
   JSR oswrch
   INX
   BNE loop

   ;; Restore the old cursor location
.done
   LDA #&1F
   JSR oswrch
   PLA
   JSR oswrch
   PLA
   JSR oswrch

.exit
   RTS

.owl_data
   EQUB &1F, &1E, &01, &91, &E2, &A6, &E2, &A2
   EQUB &E6, &A6, &E2, &A2, &E6, &1F, &1E, &02
   EQUB &91, &A8, &B0, &A9, &A1, &B0, &B0, &A9
   EQUB &A1, &B8, &1F, &1E, &03, &93, &E2, &E6
   EQUB &E4, &E0, &E2, &E0, &E0, &A6, &E2, &1F
   EQUB &1E, &04, &92, &A8, &B9, &B9, &B9, &B9
   EQUB &20, &20, &20, &A8, &1F, &1E, &05, &96
   EQUB &20, &A2, &E6, &E6, &E6, &E4, &20, &20
   EQUB &E2, &1F, &1E, &06, &94, &20, &20, &20
   EQUB &A9, &B9, &A9, &B9, &B0, &A8, &1F, &1E
   EQUB &07, &95, &20, &A4, &A4, &A6, &A4, &A6
   EQUB &A4, &A2, &E6, &00


   ;; Install the Jim reset intercept vector
   org &FDFE

   EQUW reset1

   SAVE "fdfe_test.bin",&FD00,&FE00
