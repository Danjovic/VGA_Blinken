;**********************************************************************
;         __   _____   _     ___ _ _      _                           *
;         \ \ / / __| /_\   | _ ) (_)_ _ | |_____ _ _                 *
;          \ V / (_ |/ _ \  | _ \ | | ' \| / / -_) ' \                *
;           \_/ \___/_/ \_\ |___/_|_|_||_|_\_\___|_||_|               *
;                                                                     *
;                                                                     *
;   This program generates a random coloured dot pattern on a VGA     *
;   monitor (640x480p@60Hz) with the purpose of turning obsolete CRT  *
;   monitors into decoration appliances.                              *
;   This project was conceived as an entrance for the Square Inch     *
;   Contest at Hackaday.io                                            *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Filename:	    main.asm                                          *
;    Version 0.1   November 24th 2015                                 *
;    - Basic release                                                  *
;    Version 0.9   November 28th 2015                                 *
;    - First Working Version                                          *
;                                                                     *
;    Author:  Daniel Jose Viana                                       *
;    Company:  http://danjovic.blogspot.com                           *
;              http://hackaday.io/danjovic                            *
;                                                                     *
;**********************************************************************
;         ASCII titles by http://patorjk.com/software/taag/           *
;**********************************************************************


;  ___ ___ ___ _  __ ___ __  ___  ___ 
; | _ \_ _/ __/ |/ /| __/ / ( _ )( _ )
; |  _/| | (__| / _ \ _/ _ \/ _ \/ _ \
; |_| |___\___|_\___/_|\___/\___/\___/
;                                     
;
	list	 p=16f688		; list directive to define processor
	#include <P16F688.inc>	; processor specific variable definitions
	__CONFIG    _CP_OFF & _CPD_OFF & _BOD_OFF & _PWRTE_ON & _WDT_OFF & _HS_OSC & _MCLRE_ON & _FCMEN_OFF & _IESO_OFF	


#define PORT_RGB PORTC
#define TRIS_RGB TRISC
#define _CMCON CMCON0

; Pins from PORT C 
_RD       EQU 4 ; Red Pin
_GR       EQU 5 ; Green Pin
_BL       EQU 0 ; Blue Pin
_HSYNC    EQU 1 ; Horizontal Sync
_VSYNC    EQU 2 ; Vertical Sync


;**********************************************************************
;  ___       __ _      _ _   _             
; |   \ ___ / _(_)_ _ (_) |_(_)___ _ _  ___
; | |) / -_)  _| | ' \| |  _| / _ \ ' \(_-<
; |___/\___|_| |_|_||_|_|\__|_\___/_||_/__/
;                                          
;**********************************************************************

; Macros
#define  _bank0  bcf STATUS,RP0
#define  _bank1  bsf STATUS,RP0


; VGA sync levels definition - Separate sync
_VGA_SHELF     EQU (  (1<<_HSYNC) | (1<<_VSYNC) ) ; R,G,B at black, Syncs at High (inactive)
_VGA_HSYNC     EQU (                (1<<_VSYNC) ) ; R,G,B at black, HSync Active (Low)
_VGA_VSHELF    EQU (  (1<<_HSYNC)               ) ; R,G,B at black, VSync Active (Low)
_VGA_VSYNC     EQU (  (0<<_HSYNC) | (0<<_VSYNC) ) ; R,G,B at black, HSync and VSync both Active (Low)



; Colors definition 
_WHITE       EQU ( _VGA_SHELF | (1<<_RD) |(1<<_GR) |(1<<_BL) )
_YELLOW      EQU ( _VGA_SHELF | (1<<_RD) |(1<<_GR)           )
_CYAN        EQU ( _VGA_SHELF |           (1<<_GR) |(1<<_BL) )
_GREEN       EQU ( _VGA_SHELF |           (1<<_GR)           )
_MAGENTA     EQU ( _VGA_SHELF | (1<<_RD) |          (1<<_BL) )
_RED         EQU ( _VGA_SHELF | (1<<_RD)                     )
_BLUE        EQU ( _VGA_SHELF |                     (1<<_BL) )
_BLACK       EQU ( _VGA_SHELF                                )

_TOP_BLACK_LINES    EQU .17  ; 20 - 3 from gap 0
_BOTTOM_BLACK_LINES EQU .21
_STRIP_HEIGHT       EQU .64
_GAP_HEIGHT         EQU .11

_XG_INTRVL          EQU .50  ; change colors once per second


;**********************************************************************
; __   __        _      _    _        
; \ \ / /_ _ _ _(_)__ _| |__| |___ ___
;  \ V / _` | '_| / _` | '_ \ / -_|_-<
;   \_/\__,_|_| |_\__,_|_.__/_\___/__/
;                                     
;**********************************************************************

 udata

Conta       res 1 ; counter for lines
Temp        res 1 ; temporary storage

;Time_to_upd res 1 ; flag for update randon numbers
TMRCNTR     res 1 ; 1/60th seconds timer Counter

L1Str1   res 1  ; Block Line 1, Stripe 1 colour
L1Str2   res 1  ; Block Line 1, Stripe 2 colour
L1Str3   res 1  ; Block Line 1, Stripe 3 colour
L1Str4   res 1  ; Block Line 1, Stripe 4 colour
L1Str5   res 1  ; Block Line 1, Stripe 5 colour
L1Str6   res 1  ; Block Line 1, Stripe 6 colour
L1Str7   res 1  ; Block Line 1, Stripe 7 colour
L1Str8   res 1  ; Block Line 1, Stripe 8 colour

RAND0_l1 res 1   ; 24bit random generater number, first stripe line
RAND1_l1 res 1
RAND2_l1 res 1
RAND0_l2 res 1   ; 24bit random generated numbers, 2nd stripe line
RAND1_l2 res 1
RAND2_l2 res 1
RAND0_l3 res 1   ; 24bit random generated numbers, 3rd stripe line
RAND1_l3 res 1
RAND2_l3 res 1
RAND0_l4 res 1   ; 24bit random generated numbers, 4th stripe line
RAND1_l4 res 1
RAND2_l4 res 1
RAND0_l5 res 1   ; 24bit random generated numbers, 5th stripe line
RAND1_l5 res 1
RAND2_l5 res 1
RAND0_l6 res 1   ; 24bit random generated numbers, 6th stripe line
RAND1_l6 res 1
RAND2_l6 res 1


w_temp	    res 1  ; variable used for context saving
status_temp res 1  ; variable used for context saving
pclath_temp res 1  ; variable used for context saving


;**********************************************************************
;  ___ _            _             
; / __| |_ __ _ _ _| |_ _  _ _ __ 
; \__ \  _/ _` | '_|  _| || | '_ \
; |___/\__\__,_|_|  \__|\_,_| .__/
;                           |_|   
;**********************************************************************


	ORG		0x000			; processor reset vector
   	goto		main			; go to beginning of program


	ORG		0x004			; interrupt vector location
	movwf		w_temp			; save off current W register contents
	movf		STATUS,w		; move status register into W register
	movwf		status_temp		; save off contents of STATUS register
	movf		PCLATH,w		; move pclath register into W register
	movwf		pclath_temp		; save off contents of PCLATH register

; isr code can go here or be located as a call subroutine elsewhere
 
	movf		pclath_temp,w		; retrieve copy of PCLATH register
	movwf		PCLATH			; restore pre-isr PCLATH register contents	
	movf		status_temp,w		; retrieve copy of STATUS register
	movwf		STATUS			; restore pre-isr STATUS register contents
	swapf		w_temp,f
	swapf		w_temp,w		; restore pre-isr W register contents
	retfie					; return from interrupt



;**********************************************************************
;  __  __      _        ___             _   _          
; |  \/  |__ _(_)_ _   | __|  _ _ _  __| |_(_)___ _ _  
; | |\/| / _` | | ' \  | _| || | ' \/ _|  _| / _ \ ' \ 
; |_|  |_\__,_|_|_||_| |_| \_,_|_||_\__|\__|_\___/_||_|
;                                                      
;**********************************************************************

 
main

; Configure IO Ports
	bcf STATUS,RP0           ;Select Bank 0
	clrf    PORT_RGB ;C      ;Set all pins on Port C

    movlw   b'00000111'        
    movwf   _CMCON           ; disable analog comparators 


	bsf STATUS,RP0           ;Select Bank 1

	clrf    TRISA            ;Set all PortA pins as outputs 
                             
    movlw ~(  1<<_HSYNC | 1<<_VSYNC | 1<<_RD | 1<<_BL | 1<<_GR ) 
	movwf   TRIS_RGB         ;Set all pins used for video generation as outputs

    
    movlw   b'10000000'
    movwf   VRCON              ;Turn off CVref to save power

	bcf STATUS,RP0           ;return to Bank 0


    movlw 0x12    ; Seed for Random number generator
    movwf RAND0_l1
    movlw 0x34
    movwf RAND0_l2
    movlw 0x56
    movwf RAND0_l3
    movwf 0x78
    movwf RAND0_l4
    movlw 0x9a
    movwf RAND0_l5
    movlw 0xbc
    movwf RAND0_l6



	movlw _XG_INTRVL  ; Initialise update interval
    movwf TMRCNTR      ;   
	
    movlw RAND0_l1    ;Initalise RANDOM numbers pointers
    movwf FSR         ;


  
;**********************************************************************
; __   _____   _     ___          _   _             
; \ \ / / __| /_\   | _ \___ _  _| |_(_)_ _  ___ ___
;  \ V / (_ |/ _ \  |   / _ \ || |  _| | ' \/ -_|_-<
;   \_/ \___/_/ \_\ |_|_\___/\_,_|\__|_|_||_\___/__/
;                                                   
;**********************************************************************

; ** Render a VGA Frame
DO_VGA:
	movlw 2 ; Initialize amount of Vsync Lines

VGA_Frame:
	movwf Conta 
Vsync_loop:
	call Vsync_line
	movlw .33         ; amount of lines for next loop. Was placed here to 
	decfsz Conta,f   ; equalize timing of all loops that make the frame
	goto Vsync_loop  ; each loop takes exactly 8 cycles + call time
                   ; at 20Mhz we have 159 cycles per VGA line (31.8us)
VBackPorch:
	movwf Conta      ; 25lines backporch plus 8 lines top border
VBackPorch_Loop:
	call Blank_line
	movlw _TOP_BLACK_LINES        ; top black lines
	decfsz Conta,f
	goto VBackPorch_Loop

; ************************** VISIBLE LINES **************************

; Top Black           17
; Gap                  3
; Strip Lines Line 1  64
; Gap                 11
; Strip Lines Line 2  64
; Gap                 11
; Strip Lines Line 3  64
; Gap                 11
; Strip Lines Line 4  64
; Gap                 11
; Strip Lines Line 5  64
; Gap                 11
; Strip Lines Line 6  64
; Bottom Black        21
;                   ------
;                    480 Total


;Top_Black:
        movwf Conta
        call Blank_line
        movlw .3         ; Gap 0 
        decfsz Conta,f
        goto $-3

;Gap 0
        movwf Conta
        call Gap_line
        movlw _STRIP_HEIGHT
        decfsz Conta,f
        goto $-3

;Stripe 1
        movwf Conta
        call Strip_line
        movlw _GAP_HEIGHT
        decfsz Conta,f
        goto $-3
;Gap 1
        movwf Conta
        call Gap_line
        movlw _STRIP_HEIGHT
        decfsz Conta,f
        goto $-3


;Stripe 2
        movwf Conta
        call Strip_line
        movlw _GAP_HEIGHT
        decfsz Conta,f
        goto $-3
;Gap 2
        movwf Conta
        call Gap_line
        movlw _STRIP_HEIGHT
        decfsz Conta,f
        goto $-3

;Stripe 3
        movwf Conta
        call Strip_line
        movlw _GAP_HEIGHT
        decfsz Conta,f
        goto $-3
;Gap 3
        movwf Conta
        call Gap_line
        movlw _STRIP_HEIGHT
        decfsz Conta,f
        goto $-3


;Stripe 4
        movwf Conta
        call Strip_line
        movlw _GAP_HEIGHT
        decfsz Conta,f
        goto $-3
;Gap 4
        movwf Conta
        call Gap_line
        movlw _STRIP_HEIGHT
        decfsz Conta,f
        goto $-3

;Stripe 5
        movwf Conta
        call Strip_line
        movlw _GAP_HEIGHT
        decfsz Conta,f
        goto $-3
;Gap 5
        movwf Conta
        call Gap_line
        movlw _STRIP_HEIGHT
        decfsz Conta,f
        goto $-3


;Stripe 6
        movwf Conta
        call Strip_line
        movlw _BOTTOM_BLACK_LINES
        decfsz Conta,f
        goto $-3
        

;Bottom Black
        movwf Conta
        call Blank_line
	movlw .9       ; last 10 blank lines minus one
        decfsz Conta,f
        goto $-3


; ************************** END OF VISIBLE LINES **************************

VFront_Porch
	movwf Conta      ; 8 lines bottom plus 2 frontporch 
VFrontPorch_Loop:  ; minus one to equalize timing
	call Blank_line
	movlw .2        ;  dummy
	decfsz Conta,f
	goto VFrontPorch_Loop

                     
	nop              ; dummy for equalize timing
	call VGA_Last_line  ;  last is called outside a loop 
	movlw .2         

	goto VGA_Frame ;



;**********************************************************************
; INFO:
; VGA Horizontal Lines. It takes 8 cycles for performing the loop
; including the last return. only 151 cycles remain
; PINs from PORTC
;**********************************************************************




;**********************************************************************
; Generate one Strip Line
;**********************************************************************

Strip_line:
    ; Begin is similar to Blank Line
    ; drop Vsync      ;cycles acumulated
    movlw _VGA_HSYNC  ;1  1
    movwf PORT_RGB;C  ;1  2
    movlw .5          ;1  3  (19 cycles until next write to PORTC)
    movwf Temp        ;1  4

    decfsz Temp,f     ;1
    goto   $-1       ;2  (3*5 -1) 14 -> 18
    movlw _VGA_SHELF  ;1  19
    nop               ;1  20
    nop               ;1  21
    movwf PORT_RGB;C  ;1  22
   ; 22 cycles up to here. 129 to the end

;**********************************************************************
; INFO:
; We have to consider that we should have to reduce the visible area 
; in order to fit the PIC clock timing. 
; From the standard we should still have 135 clock cycles until the
; front Porch. Thus we are lacking 6 clock cycles and we should 
; compensate in the left border
; From here to start of visible we have 9 clocks, plus 6 clocks for the
; left border, thus we have 15clocks for the backporch 
; and 126-6-6 = 114 cycles for visible content
;**********************************************************************

; Backporch 15+2 cycles after drop sync. extra cycles are to adjust timing
    movlw .4          ;1  1  
    movwf Temp        ;1  2  
    decfsz Temp,f     ;1  3
    goto $-1          ;2 (3*4-1) 11 -> 14
    nop               ;1   15
    nop               ;1   16  

    movf L1Str1,w    ;1   17 - color for the first stripe
    movwf PORT_RGB    ;1    

 

; First Stripe - 12 cycles on, 2 cycles off, 14 cycles total
    movlw .3          ;1   1
    movwf Temp        ;1   2
    decfsz Temp,f     ;1
    goto $-1          ;2 (3*3-1) 8 -> 10
    movlw _BLACK      ;1   11  - black color in the gap
    movwf PORT_RGB    ;1   12
    movf  L1Str2,w   ;1   1 - color for the next stripe
    movwf PORT_RGB    ;1   2

; Second Stripe - 12 cycles on, 2 cycles off, 14 cycles total
    movlw .3          ;1   1
    movwf Temp        ;1   2
    decfsz Temp,f     ;1
    goto $-1          ;2 (3*3-1) 8 -> 10
    movlw _BLACK      ;1   11  - black color in the gap
    movwf PORT_RGB    ;1   12
    movf  L1Str3,w   ;1   1 - color for the next stripe
    movwf PORT_RGB    ;1   2

; Third Stripe - 12 cycles on, 2 cycles off, 14 cycles total
    movlw .3          ;1   1
    movwf Temp        ;1   2
    decfsz Temp,f     ;1
    goto $-1          ;2 (3*3-1) 8 -> 10
    movlw _BLACK      ;1   11  - black color in the gap
    movwf PORT_RGB    ;1   12
    movf  L1Str4,w   ;1   1 - color for the next stripe
    movwf PORT_RGB    ;1   2

; 4th Stripe - 12 cycles on, 2 cycles off, 14 cycles total
    movlw .3          ;1   1
    movwf Temp        ;1   2
    decfsz Temp,f     ;1
    goto $-1          ;2 (3*3-1) 8 -> 10
    movlw _BLACK      ;1   11  - black color in the gap
    movwf PORT_RGB    ;1   12
    movf  L1Str5,w   ;1   1 - color for the next stripe
    movwf PORT_RGB    ;1   2

; 5th Stripe - 12 cycles on, 2 cycles off, 14 cycles total
    movlw .3          ;1   1
    movwf Temp        ;1   2
    decfsz Temp,f     ;1
    goto $-1          ;2 (3*3-1) 8 -> 10
    movlw _BLACK      ;1   11  - black color in the gap
    movwf PORT_RGB    ;1   12
    movf  L1Str6,w   ;1   1 - color for the next stripe
    movwf PORT_RGB    ;1   2

; 6th Stripe - 12 cycles on, 2 cycles off, 14 cycles total
    movlw .3          ;1   1
    movwf Temp        ;1   2
    decfsz Temp,f     ;1
    goto $-1          ;2 (3*3-1) 8 -> 10
    movlw _BLACK      ;1   11  - black color in the gap
    movwf PORT_RGB    ;1   12
    movf  L1Str7,w   ;1   1 - color for the next stripe
    movwf PORT_RGB    ;1   2

; 7th Stripe - 12 cycles on, 2 cycles off, 14 cycles total
    movlw .3          ;1   1
    movwf Temp        ;1   2
    decfsz Temp,f     ;1
    goto $-1          ;2 (3*3-1) 8 -> 10
    movlw _BLACK      ;1   11  - black color in the gap
    movwf PORT_RGB    ;1   12
    movf  L1Str8,w   ;1   1 - color for the next stripe
    movwf PORT_RGB    ;1   2

; 8th Stripe - 12 cycles on, 12 cycles total
    movlw .3          ;1   1
    movwf Temp        ;1   2
    decfsz Temp,f     ;1
    goto $-1          ;2 (3*3-1) 8 -> 10
    movlw _VGA_SHELF   ;1   11  - black color in the gap
    movwf PORT_RGB    ;1   12

    nop    
    nop               ;1    Last 2 cycles, to equalize timing

	return ; already taken into acconunt






;**********************************************************************
; Generate one Vertical Sync line
;**********************************************************************
; INFO:
; During a vertical sync line a HSync pulse is generated while the 
; VSync line is kept low
;**********************************************************************
Vsync_line:
    ; drop Vsync       ;cy acumulado
    movlw _VGA_VSYNC  ;1
    movwf PORT_RGB;C     ;1   
    movlw .5          ;1  1  (19 cycles until next write to PORTC)
    movwf Temp        ;1  2
VL1:
    decfsz Temp,f       ;1
    goto   VL1        ;2  (3*5 -1)14 -> 16
    movlw _VGA_VSHELF ;1  17
    nop               ;1  18
    nop               ;1  19
    movwf PORT_RGB;C       ;1  
    ; 22 cycles up to here. 129 to the end
    movlw .42         ;1  42 is the answer!
    movwf Temp        ;1
VL2:
    decfsz Temp,f       ;1
    goto VL2          ;2 (3*42-1) 125
    nop               ;1
    nop               ;1

	return ; already taken into acconunt


;**********************************************************************
; Generate a Blank Line (only one HSync pulse)
;**********************************************************************
Blank_line:
    ; drop Vsync      ;cy acumulado
    movlw _VGA_HSYNC  ;1  1
    movwf PORT_RGB;C  ;1  2
    movlw .5          ;1  3  (19 cycles until next write to PORT_RGB)
    movwf Temp        ;1  4
BL1:
    decfsz Temp,f     ;1
    goto   BL1        ;2  (3*5 -1)14 -> 18
    movlw _VGA_SHELF  ;1  19
    nop               ;1  20
    nop               ;1  21
    movwf PORT_RGB    ;1  22   (22-3=19)
    ; 22 cycles up to here. 129 to the end



    movlw .42         ;1  42 is the answer!
    movwf Temp        ;1
BL2:
    decfsz Temp,f     ;1
    goto BL2          ;2 (3*42-1) 125
    nop               ;1
    nop               ;1

	return ; already taken into acconunt


;**********************************************************************
; Generate a GAP Line - Also processes also distribute the color bits
; along the L1Strx variables
;**********************************************************************
Gap_line:
    ; drop Vsync      ;cy acumulado
    movlw _VGA_HSYNC  ;1  1
    movwf PORT_RGB;C  ;1  2
    movlw .5          ;1  3  (19 cycles until next write to PORT_RGB)
    movwf Temp        ;1  4

    decfsz Temp,f     ;1
    goto   $-1        ;2  (3*5 -1)14 -> 18
    movlw _VGA_SHELF  ;1  19
    nop               ;1  20
    nop               ;1  21
    movwf PORT_RGB    ;1  22   (22-3=19)
    ; 22 cycles up to here. 129 to the end

    movf Conta,w      ; 1     1   'Conta' is used on a loop that calls GAP_line
    xorlw 1           ; 1     2   'Conta' is a countdown)
    btfsc STATUS,Z    ; 1     3    are we on the last line (1)?
    goto FillClrTbl   ; 1/2   4/5    Yes, make fill color table     

    ; up to here 4 cycles, 122 to the end

    movlw .41         ;1      5
    movwf Temp        ;1      6
    decfsz Temp,f     ;1
    goto $-1          ;2 (3*41-1) 122 -> 128
    nop               ;1      129

    return ; already taken into acconunt
    
    
;**********************************************************************
;  Fill color stripe table with bits from RANDx word
;  takes 67 cycles to run
;*********************************************************************

    ; 5 cycles up to here, 124 cycles to the end
FillClrTbl:
    movlw _VGA_SHELF  ; 1  Stripe 1 Color  - 8 clock cycles
    btfsc INDF,0 ;     ; 1  RAND0_,0
    iorlw (1<<_RD)    ; 1
    btfsc INDF,1       ; 1  RAND0_,1
    iorlw (1<<_GR)    ; 1
    btfsc INDF,2       ; 1  RAND0_,2
    iorlw (1<<_BL)    ; 1
    movwf L1Str1      ; 1

    movlw _VGA_SHELF  ; Stripe 2 Color
    btfsc INDF,3
    iorlw (1<<_RD)
    btfsc INDF,4
    iorlw (1<<_GR)
    btfsc INDF,5
    iorlw (1<<_BL)
    movwf L1Str2

    movlw _VGA_SHELF  ; Stripe 3 Color
    btfsc INDF,6
    iorlw (1<<_RD)
    btfsc INDF,7
    iorlw (1<<_GR)
    incf FSR,f        ; 1 extra cycle
    btfsc INDF,0
    iorlw (1<<_BL)
    movwf L1Str3

    movlw _VGA_SHELF  ; Stripe 4 Color
    btfsc INDF,1
    iorlw (1<<_RD)
    btfsc INDF,2
    iorlw (1<<_GR)
    btfsc INDF,3
    iorlw (1<<_BL)
    movwf L1Str4

    movlw _VGA_SHELF  ; Stripe 5 Color
    btfsc INDF,4
    iorlw (1<<_RD)
    btfsc INDF,5
    iorlw (1<<_GR)
    btfsc INDF,6
    iorlw (1<<_BL)
    movwf L1Str5

    movlw _VGA_SHELF  ; Stripe 6 Color
    btfsc INDF,7
    iorlw (1<<_RD)
    incf FSR,f        ; 1 extra cycle
    btfsc INDF,0
    iorlw (1<<_GR)
    btfsc INDF,1
    iorlw (1<<_BL)
    movwf L1Str6

    movlw _VGA_SHELF  ; Stripe 7 Color
    btfsc INDF,2
    iorlw (1<<_RD)
    btfsc INDF,3
    iorlw (1<<_GR)
    btfsc INDF,4
    iorlw (1<<_BL)
    movwf L1Str7

    movlw _VGA_SHELF  ; Stripe 8 Color
    btfsc INDF,5
    iorlw (1<<_RD)
    btfsc INDF,6
    iorlw (1<<_GR)
    btfsc INDF,7
    iorlw (1<<_BL)
    movwf L1Str8

    incf FSR,f        ; 1 extra cycle



    ; 72 (5 + 67) cycles up to here, 57 cycles to the end.

    movlw .18         ;1      73
    movwf Temp        ;1      74
    decfsz Temp,f     ;1
    goto $-1          ;2 (3*18-1) 53 -> 127
    nop               ;1      128
    nop               ;1      129

    return ; already taken into acconunt






;**********************************************************************
; Generate a Blank Line and check for a given number of intervals
; to activate the generation of new random numbers
;**********************************************************************
; INFO: This function is called once in a frame (1/60s)
;**********************************************************************
VGA_Last_line:
    ; drop Vsync      ;cy acumulado
    movlw _VGA_HSYNC  ;1  1
    movwf PORT_RGB;C  ;1  2
    movlw .5          ;1  3  (19 cycles until next write to PORT_RGB)
    movwf Temp        ;1  4

    decfsz Temp,f     ;1
    goto   $-1        ;2  (3*5 -1) 14 -> 18
    movlw _VGA_SHELF  ;1  19
    nop               ;1  20
    nop               ;1  21
    movwf PORT_RGB    ;1  22   (22-3=19)
    ; 22 cycles up to here. 129 to the end


	decfsz TMRCNTR,f   ; 1   1 check for timeout 
	goto VGALLnoUpd    ; 1/2 2/3  no, finish the blank line

; Randomize 2 cycles up to here

   ;Pseudo Random number generator: Takes 12 cycles each
   
; Random Line 1
    bcf     STATUS,C    ; 1     1
    rrf     RAND2_l1,F  ; 1     2
    rrf     RAND1_l1,F  ; 1     3
    rrf     RAND0_l1,F  ; 1     4
    btfss   STATUS,C    ; 1     5
    goto $+6           ; 1/2   6/7
    MOVLW   0xD7        ; 1     7
    XORWF   RAND2_l1    ; 1     8
    XORWF   RAND1_l1    ; 1     9
    XORWF   RAND0_l1    ; 1    10
    goto $+6            ; 2    12

    nop                 ; 1    8
    nop                 ; 1    9
    nop                 ; 1   10
    nop                 ; 1   11
    nop                 ; 1   12

; Random Line 2
    bcf     STATUS,C    ; 1     1
    rrf     RAND2_l2,F  ; 1     2
    rrf     RAND1_l2,F  ; 1     3
    rrf     RAND0_l2,F  ; 1     4
    btfss   STATUS,C    ; 1     5
    goto $+6            ; 1/2   6/7
    MOVLW   0xD7        ; 1     7
    XORWF   RAND2_l2    ; 1     8
    XORWF   RAND1_l2    ; 1     9
    XORWF   RAND0_l2    ; 1    10
    goto $+6            ; 2    12

    nop                 ; 1    8
    nop                 ; 1    9
    nop                 ; 1   10
    nop                 ; 1   11
    nop                 ; 1   12   
 
; Random Line 3
    bcf     STATUS,C    ; 1     1
    rrf     RAND2_l3,F  ; 1     2
    rrf     RAND1_l3,F  ; 1     3
    rrf     RAND0_l3,F  ; 1     4
    btfss   STATUS,C    ; 1     5
    goto $+6            ; 1/2   6/7
    MOVLW   0xD7        ; 1     7
    XORWF   RAND2_l3    ; 1     8
    XORWF   RAND1_l3    ; 1     9
    XORWF   RAND0_l3    ; 1    10
    goto $+6            ; 2    12

    nop                 ; 1    8
    nop                 ; 1    9
    nop                 ; 1   10
    nop                 ; 1   11
    nop                 ; 1   12    
   
; Random Line 4
    bcf     STATUS,C    ; 1     1
    rrf     RAND2_l4,F  ; 1     2
    rrf     RAND1_l4,F  ; 1     3
    rrf     RAND0_l4,F  ; 1     4
    btfss   STATUS,C    ; 1     5
    goto $+6            ; 1/2   6/7
    MOVLW   0xD7        ; 1     7
    XORWF   RAND2_l4    ; 1     8
    XORWF   RAND1_l4    ; 1     9
    XORWF   RAND0_l4    ; 1    10
    goto $+6            ; 2    12

    nop                 ; 1    8
    nop                 ; 1    9
    nop                 ; 1   10
    nop                 ; 1   11
    nop                 ; 1   12

; Random Line 5
    bcf     STATUS,C    ; 1     1
    rrf     RAND2_l5,F  ; 1     2
    rrf     RAND1_l5,F  ; 1     3
    rrf     RAND0_l5,F  ; 1     4
    btfss   STATUS,C    ; 1     5
    goto $+6            ; 1/2   6/7
    MOVLW   0xD7        ; 1     7
    XORWF   RAND2_l5    ; 1     8
    XORWF   RAND1_l5    ; 1     9
    XORWF   RAND0_l5    ; 1    10
    goto $+6            ; 2    12

    nop                 ; 1    8
    nop                 ; 1    9
    nop                 ; 1   10
    nop                 ; 1   11
    nop                 ; 1   12   
 
; Random Line 6
    bcf     STATUS,C    ; 1     1
    rrf     RAND2_l6,F  ; 1     2
    rrf     RAND1_l6,F  ; 1     3
    rrf     RAND0_l6,F  ; 1     4
    btfss   STATUS,C    ; 1     5
    goto $+6            ; 1/2   6/7
    MOVLW   0xD7        ; 1     7
    XORWF   RAND2_l6    ; 1     8
    XORWF   RAND1_l6    ; 1     9
    XORWF   RAND0_l6    ; 1    10
    goto $+6            ; 2    12

    nop                 ; 1    8
    nop                 ; 1    9
    nop                 ; 1   10
    nop                 ; 1   11
    nop                 ; 1   12    
   
; 74 (2+12*6) cycles up to here, 55 to the end


    movf RAND0_l1,w     ; 1   76  reinit interval with random value
    andlw 0x0f          ; 1   77  between 0.36 and 0.63 seconds
    addlw .22           ; 1   78
    movwf TMRCNTR       ; 1   79
    nop                 ; 1   80
    nop                 ; 1   81
    movlw  .14          ; 1   82
	movwf Temp          ; 1   83
	goto VLastL2        ; 2   84
	

	
	
VGALLnoUpd:
    ; 4 cycles up to here, 125 to end
    nop               ;1  4
    movlw .40         ;1  5
    movwf Temp        ;1  6
VLastL2:
    decfsz Temp,f     ;1                                 coming from RANDOMIZE  
    goto $-1          ;2  (3*40-1) 119 -> 125            (3*14-1) 41 -> 125
    nop               ;1  126
	nop               ;1  127
    movlw RAND0_l1    ;1  128   Restore RANDOM numbers pointers
    movwf FSR         ;1  129

    return ; already taken into account




; 
END