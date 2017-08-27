
; "Springs are going to the party"
; - 256 bytes intro by Frog for CC'2017
;
; http://frog.enlight.ru
; frog@enlight.ru
;

                include "vectrex.i"

frames_c	equ	$C880
base_x		equ	$C882

springs         equ	$C890    ; index in sine table for each spring

sine            equ    $fc6d        ; sine table from BIOS (access via reg y)
;***************************************************************************
                org     0

                db      "g GCE 1982", $80 	; 'g' is copyright sign
                dw      $f600            	; music from the rom ($F600 - no music) 
                db      $FC, $30, 33, -$46	; height, width, rel y, rel x
title:          db      "SPRINGS - 256 BYTES", $80	; app title, ending with $80
                db      0                 	; end of header

                jsr    $f92e

; copy initial springs positions to RAM
                ldu    #springstmp
                ldx    #springs
                lda    #(3*3)
                jsr    Move_Mem_a            ; A - byte count, U - source, X - destination


                clr    frames_c

;                inc     Vec_Music_Flag

loop:


                jsr     DP_to_C8
                ldu     #$fe38

                jsr     Init_Music_chk          ; Initialize the music

                jsr     Wait_Recal        	; recalibrate CRT, reset beam to 0,0.  D, X - trashed

                jsr     Do_Sound

                tst     Vec_Music_Flag          ; Loop if music is still playing
                bne     stillplaying
                inc     Vec_Music_Flag            ; restart music
;                ldu     #$fe38
 ;               jsr     Init_Music_chk          ; Initialize the music
                
stillplaying:

              ;  jsr     DP_to_D0                ; wtf? I need this bytes!

; intro title

                ldu    #title
                ldd    #(-127*256+(-54))    ; Y,X
                jsr    Print_Str_d

; draw floor
                lda     #$ff              	; scale (max possible)
                sta     <VIA_t1_cnt_lo

                ldd     #(-60*256+(-54)) 	; Y,X
                jsr     Moveto_d

                ldd     #(0*256+(127)) 		; Y,X
                jsr     Draw_Line_d

                clr    base_x

                ldu    #0                    ; curves counter

                ldx    #springs              ; reset after each series of curves

;                jsr	Intensity_5F

nextcurve:

; start drawing curve

	       jsr	Reset0Ref			; recalibrate crt (x,y = 0)
	       lda	#$CE 				; /Blank low, /ZERO high
                sta	<VIA_cntl           ; enable beam, disable zeroing



; calculate Y position and height for curve

                ldb    ,x                 ; load pos in sine for cur cuve froom springs to y 
                cmpb    #32            ; check if end of sine.  was:15
                bne    skipreset
                clrb    
skipreset:

; move only each nth frame
                lda    frames_c
                bita #$03
                bne    skipinc
                incb                    ; next sine point
skipinc:

                stb    ,x+
; b - index in sine
                clra
   
                addd    #sine 		; index to addr
; b - offset in sine

                tfr    d,y

                lda    ,y                

                lsra
                lsra

    		pshs a

                suba    #60                ; ground level 

                ldb    frames_c
                addb    base_x                

                jsr     Moveto_d            ; A = y coord, B = x coord (D trashed)


; Draw_Curve begin
; params: y - coeff. to make curves look different

                ldd     #$1881
                stb     <VIA_port_b        	; disable MUX, disable ~RAMP
                sta     <VIA_aux_cntl      	; AUX: shift mode 4. PB7 not timer controlled. PB7 is ~RAMP

    		puls a

                lsra

                sta     <VIA_port_a        	; end Y to DAC  (kinda "scale")

                decb                      	; b now $80
                stb     <VIA_port_b        	; enable MUX

                clrb						; X start = 0
                inc     <VIA_port_b        	; MUX off, only X on DAC now
                stb     <VIA_port_a        	; X to DAC

                incb
                stb     <VIA_port_b        	; MUX disable, ~RAMP enable. Start integration

                ldb    #$ff
                stb     <VIA_shift_reg     	; pattern

; draw spring                
                ldd    #$300e                ; a = spring width ($80 = -127...+127), b = $0f (number of turns)
                lda    ,u			; to make springs different

               
nextturn:
                sta     <VIA_port_a        	; put X to DAC
                eora    #1                   ; 127 -> -127
                nega

; delay to make springs more wide
                ldy    #4
delaywidth:     leay    -1,y
                bne    delaywidth

                decb                            ; next turn
                bne	nextturn



; restore hardware after drawing curve
                ldd    #$9881                ; b -  81, a - 98

;                ldb     #$81              	; ramp off, MUX off
                stb     <VIA_port_b

 ;               lda     #$98
                sta     <VIA_aux_cntl      	; restore usual AUX setting (enable PB7 timer, SHIFT mode 4)


               ; ldb     #30   				; end dot brightness (20-30 is ok for release)
                lsrb                        ; 81 => 40  (saved 1 byte :)

repeat_dot:     decb
                bne     repeat_dot


                clr     <VIA_shift_reg  	; Blank beam in VIA shift register

               lda    base_x
               adda    #80        ; x gap between curves
               sta    base_x



               
                cmpx    #springs+3        ; check if all curves processed
                bne    skip
                ldx    #springs

skip:


                leau    1,u
                cmpu    #3                    ; number of curves

	       bne    nextcurve


                dec    frames_c

                jmp     loop

; (moved to springs, access via reg x)
; current index in sine table for each curve
springstmp:
                db    15,  20,  25         ; yes, it could be heavely optimized - 3 items don't require tables, memcpy etc..




