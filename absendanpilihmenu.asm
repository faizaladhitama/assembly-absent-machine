.include "m8515def.inc"

.def temp =r16	; Define temporary variable
.def EW = r17	; for PORTA
.def PB = r18	; for PORTB
.def A  = r19
.equ space = 0x20
.equ lcd_displayOn = 0b00001100
.equ lcd_displayOff = 0b00001000
.def selected = r20

; PORTB as DATA
; PORTA.0 as EN
; PORTA.1 as RS
; PORTA.2 as RW

;.cseg
;.org $e50f
START:	
	ldi	temp,low(RAMEND) ; Set stack pointer to -
	out	SPL,temp		 ; -- last internal RAM location
	ldi	temp,high(RAMEND)
	out	SPH,temp

	rcall INIT_LCD
	rcall CLEAR_LCD

	ldi	temp,$ff
	out	DDRA,temp	; Set port A as output
	out	DDRB,temp	; Set port B as output

	ldi	ZH,high(2*message)	; Load high part of byte address into ZH
	ldi	ZL,low(2*message)	; Load low part of byte address into ZL

LOADBYTE:
	lpm				; Load byte from program memory into r0

	tst	r0			; Check if we've reached the end of the message
	breq blink		; If so, quit

	
	mov A, r0		; Put the character onto Port B
	cpi A, 0x2A
	breq enter
	rcall WRITE_TEXT
	adiw ZL,1		; Increase Z registers
	rjmp LOADBYTE



loop:
	rjmp loop

enter:
	cbi PORTA,1	; CLR RS dia pengen rsnya 0 instruction
	ldi PB,0b11000000	; baris 2 kolom 1 untuk enter 
	out PORTB,PB
	sbi PORTA,0	; SETB EN
	cbi PORTA,0	; CLR EN
	adiw ZL,1
	rjmp LOADBYTE
	

blink:
	ldi r20, 3

	blinking:
		cbi PORTA, 1
		ldi PB, lcd_displayOff
		out PORTB, PB
		sbi PORTA,0	; SETB EN
		cbi PORTA,0	; CLR EN
		rcall wait_lcd

		cbi PORTA, 1
		ldi PB, lcd_displayOn
		out PORTB, PB
		sbi PORTA,0	; SETB EN
		cbi PORTA,0	; CLR EN
		rcall wait_lcd

		dec r20
		brne blinking

	rcall CLEAR_LCD ; biar bisa balik lg ke blink
	rjmp pilih_menu
	rjmp QUIT


pilih_menu:
	cpi selected, 0x01
	breq QUIT
	ldi	ZH,high(2*menu)	; Load high part of byte address into ZH
	ldi	ZL,low(2*menu)	; Load low part of byte address into ZL
	ldi selected, 1
	rjmp LOADBYTE

QUIT:	rjmp QUIT

WAIT_LCD:
	ret
	ldi	r22, 16
CONT:	dec	r22
	brne	CONT
	ret

INIT_LCD:
	cbi PORTA,1	; CLR RS
	ldi PB,0x38	; MOV DATA,0x38 --> 8bit, 2line, 5x7
	out PORTB,PB
	sbi PORTA,0	; SETB EN
	cbi PORTA,0	; CLR EN
	rcall WAIT_LCD
	
	cbi PORTA,1	; CLR RS
	ldi PB,$0E	; MOV DATA,0x0E --> disp ON, cursor ON, blink OFF
	out PORTB,PB
	sbi PORTA,0	; SETB EN
	cbi PORTA,0	; CLR EN
	rcall WAIT_LCD
	
	cbi PORTA,1	; CLR RS
	ldi PB,$06	; MOV DATA,0x06 --> increase cursor, display sroll OFF
	out PORTB,PB
	sbi PORTA,0	; SETB EN
	cbi PORTA,0	; CLR EN
	rcall WAIT_LCD
	ret

CLEAR_LCD:
	cbi PORTA,1	; CLR RS
	ldi PB,$01	; MOV DATA,0x01
	out PORTB,PB
	sbi PORTA,0	; SETB EN
	cbi PORTA,0	; CLR EN
	rcall WAIT_LCD
	ret

WRITE_TEXT:
	sbi PORTA,1	; SETB RS
	out PORTB, A
	sbi PORTA,0	; SETB EN
	cbi PORTA,0	; CLR EN
	;rcall WAIT_LCD
	ret

message:
.db	"Absensi*Mahasiswa"
.db	0,0 ;buat quit biar ga loadbyte terus

menu:
.db "Pilih Menu*A. Input B. History"
.db 0,0


