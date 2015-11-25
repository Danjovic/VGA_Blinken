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



;**********************************************************************
; __   __        _      _    _        
; \ \ / /_ _ _ _(_)__ _| |__| |___ ___
;  \ V / _` | '_| / _` | '_ \ / -_|_-<
;   \_/\__,_|_| |_\__,_|_.__/_\___/__/
;                                     
;**********************************************************************

 udata

Conta       res 1
Temp        res 1


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
	movlw .240        ; first half of vilible lines
	decfsz Conta,f
	goto VBackPorch_Loop

First_half:
	movwf Conta      ; 240 lines
VFirst_Visible_Loop:
	call Visible_line
	movlw .240        ; second half of vilible lines
	decfsz Conta,f
	goto VFirst_Visible_Loop

Second_half:
	movwf Conta      ; 240 lines
VSecond_Visible_Loop:
	call Visible_line
	movlw .9       ; last 10 blank lines minus one
	decfsz Conta,f
	goto VSecond_Visible_Loop

VFront_Porch
	movwf Conta      ; 8 lines bottom plus 2 frontporch 
VFrontPorch_Loop:  ; minus one to equalize timing
	call Blank_line
	movlw .2        ;  dummy
	decfsz Conta,f
	goto VFrontPorch_Loop

                     
	nop              ; dummy for equalize timing
	call Blank_line  ;  last is called outside a loop 
	movlw .2         

	goto VGA_Frame ;


        ;**********************************************************************
; INFO:
; VGA Horizontal Lines. It takes 8 cycles for performing the loop
; including the last return. only 151 cycles remain
; PINs from PORTC
;**********************************************************************


;**********************************************************************
; Generate one visible line (Color Bar)
;**********************************************************************

Visible_line: 
    ; Begin is similar to Blank Line
    ; drop Vsync      ;cy acumulado
    movlw _VGA_HSYNC  ;1  
    movwf PORT_RGB;C       ;1   
    movlw .5           ;1  1  (19 cycles until next write to PORTC)
    movwf Temp        ;1  2
Vis1:
    decfsz Temp,f      ;1
    goto   Vis1        ;2  (3*5 -1)14 -> 16
    movlw _VGA_SHELF  ;1  17
    nop               ;1  18
    nop               ;1  19
    movwf PORT_RGB;C       ;1
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

; Backporch 15+1 cycles. extra cycle is to adjust timing
    movlw .4          ;1
    movwf Temp        ;1
BPrch1:
    decfsz Temp,f     ;1
    goto BPrch1       ;2 (3*4-1) 11
    nop               ;1
    movlw _WHITE      ;1    - color for the next stripe
    movwf PORT_RGB;C       ;1

; White Stripe 16 cycles
    movlw .4          ;1
    movwf Temp        ;1
WhStrp1:
    decfsz Temp,f       ;1
    goto WhStrp1      ;2 (3*4-1) 11
    nop               ;1
    movlw _YELLOW     ;1    - color for the next stripe
    movwf PORT_RGB;C       ;1

; Yellow Stripe 16 cycles
    movlw .4          ;1
    movwf Temp        ;1
YeStrp1:
    decfsz Temp,f       ;1
    goto YeStrp1      ;2 (3*4-1) 11
    nop               ;1
    movlw _CYAN       ;1    - color for the next stripe
    movwf PORT_RGB;C       ;1

; Cyan Stripe 16 cycles
    movlw .4          ;1
    movwf Temp        ;1
CyStrp1:
    decfsz Temp,f       ;1
    goto CyStrp1      ;2 (3*4-1) 11
    nop               ;1
    movlw _GREEN      ;1    - color for the next stripe
    movwf PORT_RGB;C       ;1

; Green Stripe 16 cycles
    movlw .4          ;1
    movwf Temp        ;1
GrStrp1:
    decfsz Temp,f       ;1
    goto GrStrp1      ;2 (3*4-1) 11
    nop               ;1
    movlw _MAGENTA    ;1    - color for the next stripe
    movwf PORT_RGB;C       ;1

; Magenta Stripe 16 cycles
    movlw .4          ;1
    movwf Temp        ;1
MgStrp1:
    decfsz Temp,f       ;1
    goto MgStrp1      ;2 (3*4-1) 11
    nop               ;1
    movlw _RED        ;1    - color for the next stripe
    movwf PORT_RGB;C       ;1

; Red Stripe 16 cycles
    movlw .4          ;1
    movwf Temp        ;1
RdStrp1:
    decfsz Temp,f       ;1
    goto RdStrp1      ;2 (3*4-1) 11
    nop               ;1
    movlw _BLUE       ;1    - color for the next stripe
    movwf PORT_RGB;C       ;1

; Blue Stripe 16 cycles
    movlw .4          ;1
    movwf Temp        ;1
BlStrp1:
    decfsz Temp,f       ;1
    goto BlStrp1      ;2 (3*4-1) 11
    nop               ;1
    movlw _VGA_SHELF  ;1    - color for the next stripe
    movwf PORT_RGB;C       ;1      shelf is Black
	nop               ;1    Last cycle, to equalize timing

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
    movlw _VGA_HSYNC  ;1  
    movwf PORT_RGB;C       ;1   
    movlw .5           ;1  1  (19 cycles until next write to PORTC)
    movwf Temp        ;1  2
BL1:
    decfsz Temp,f       ;1  
    goto   BL1        ;2  (3*5 -1)14 -> 16
    movlw _VGA_SHELF  ;1  17
    nop               ;1  18
    nop               ;1  19
    movwf PORT_RGB;C       ;1  
    ; 22 cycles up to here. 129 to the end
    movlw .42         ;1  42 is the answer!
    movwf Temp        ;1
BL2:
    decfsz Temp,f     ;1
    goto BL2          ;2 (3*42-1) 125
    nop               ;1
    nop               ;1

	return ; already taken into acconunt


; 
END