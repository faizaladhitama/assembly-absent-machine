.include "8515def.inc"
 
.equ col1 = PINA0
.equ col2 = PINA1
.equ col3 = PINA2
.equ col4 = PINA3
 
.def keyval = r16
.def temp = r17
.def flags = r18
.def keypad_out = r19
.def EW = r20 ; for PORTC
.def PB = r21 ; for PORTB
.def A  = r22
.def row  = r23
.def total_key = r24

.equ keyport = PORTA
.equ pressed = 0


;keypad aktif saat button di lepas
;menggunakan polling untuk mengecek tiap kolom dari masing-masing baris
;apabila ada perubahan bit (button tertekan) maka program akan otomatis
;mengeloop button tersebut sampai dilepas dikarenakan menggunakan perubahan
;dari high ke low

;timer dibutuhkan untuk mengecek selama 3 detik apakah bit dari button berubah
;atau tidak
;di label "LOOP" diberikan timer overflow untuk mengecek button mengalami perubahan
;atau tidak
;ketika button tertekan maka hasil dari asciinya akan disimpan di register A
;di cek menggunakan tst apakah ada perubahan di register A atau tidak selama n detik
;atau m kali timer overflow

;jika tidak ada perubahan maka LCD akan menampilkan tulisan "Input ulang ?"
;jika ada perubahan loop akan berjalan 

MAIN:
	ldi temp,HIGH(RAMEND)
	out SPH,temp
	ldi temp,LOW(RAMEND)
	out SPL,temp
	ldi temp,$ff
	ldi ZH,0x00
	ldi ZL,0x60
	out DDRB,temp ; Set port B as output
	out DDRC,temp ; Set port C as output
	rcall INIT_LCD
	rcall key_init
	rcall CLEAR_LCD
	SEI
	rjmp LOOP

LOOP:
	rcall get_key
	mov total_key,A
	sub total_key,keyval
	rcall GET_ASCII
	tst A
	brne ASCII_TO_LCD
	clr temp
	clr A
	rjmp LOOP

ASCII_TO_LCD:
	rcall WRITE_TEXT
	clr temp
	clr A
	rjmp LOOP

key_init:
	ldi keyval,0xF0		;Make Cols as i/p
	out DDRA, keyval	;and Rows as o/p
	ldi keyval,0x0F		;Enable pullups
	out keyport, keyval	;on columns
	ret
 
get_key:
	ldi keyval,0x00		;Scanning Row1
	ldi temp,0x7F		;Make Row1 low
	out keyport,temp	;Send to keyport
	rcall read_col		;Read Columns
 
	sbrc flags,pressed	;If key pressed
	rjmp done		;Exit the routine
 
	ldi keyval,0x04		;Scanning Row2
	ldi temp,0xBF		;Make Row2 Low
	out keyport,temp	;Send to keyport
	rcall read_col		;Read Columns
 
	sbrc flags,pressed	;If key pressed
	rjmp done		;Exit from routine
 
	ldi keyval,0x08		;Scanning Row3
	ldi temp,0xDF		;Make Row3 Low
	out keyport,temp	;Send to keyport
	rcall read_col		;Read columns
 
	sbrc flags,pressed	;If key pressed
	rjmp done		;Exit the routine
 
	ldi keyval,0x0C		;Scanning Row4
	ldi temp,0xEF		;Make Row4 Low
	out keyport,temp	;send to keyport
	rcall read_col		;Read columns
 
done:
	ret
 
read_col:
	cbr flags, (1<<pressed)	;Clear status flag
 
	sbic PINA, col1		;Check COL1
	rjmp nextcol		;Go to COL2 if not low
 
hold:
	sbis PINA, col1		;Wait for key release
	rjmp hold
	sbr flags, (1<<pressed)	;Set status flag
	in A,PINA
	ret			;key 1 pressed
nextcol:
	sbic PINA,col2		;Check COL2
	rjmp nextcol1		;Goto COL3 if not low
 
hold1:
	sbis PINA, col2		;Wait for key release
	rjmp hold1
	inc keyval		;Key 2 pressed
	sbr flags,(1<<pressed)	;Set status flag
	ret
nextcol1:
	sbic PINA,col3		;Check COL3
	rjmp nextcol2		;Goto COL4 if no pressed
 
hold2:
	sbis PINA, col3		;Wait for key release
	rjmp hold2
	inc keyval		;Key 3 pressed
	inc keyval
	sbr flags, (1<<pressed)	;Set status flag
	ret
nextcol2:
	sbic PINA,col4		;Check COL4
	rjmp exit		;Exit if not low
 
hold3:
	sbis PINA, col4		;Wait for key release
	rjmp hold3
	inc keyval		;Key 4 Pressed
	inc keyval
	inc keyval
	sbr flags, (1<<pressed)	;Set status flag
	ret
exit:
	clr keyval		;reset keyval
	cbr flags, (1<<pressed)	;No Key Pressed
	ret

INIT_LCD:
	cbi PORTC,1	; CLR RS
	ldi PB,0x3C	; MOV DATA,0x38 --> 8bit, 2line, 5x7
	out PORTB,PB
	sbi PORTC,0	; SETB EN
	cbi PORTC,0	; CLR EN
	;rcall WAIT_LCD

	cbi PORTC,1	; CLR RS
	ldi PB,$0F	; MOV DATA,0x0F --> disp ON, cursor ON, blink ON
	out PORTB,PB
	sbi PORTC,0	; SETB EN
	cbi PORTC,0	; CLR EN
	;rcall WAIT_LCD
	
	cbi PORTC,1	; CLR RS
	ldi PB,$06	; MOV DATA,0x06 --> increase cursor, display sroll OFF
	out PORTB,PB
	sbi PORTC,0	; SETB EN
	cbi PORTC,0	; CLR EN
	;rcall WAIT_LCD

	rcall CLEAR_LCD ; CLEAR LCD
	ret

CLEAR_LCD:
	cbi PORTC,1 ; CLR RS
	ldi PB,$01 ; MOV DATA,0x01
	out PORTB,PB
	sbi PORTC,0 ; SETB EN
	cbi PORTC,0 ; CLR EN
	;rcall WAIT_LCD
	ret

WRITE_TEXT:
	sbi PORTC,1 ; SETB RS
	out PORTB, A
	sbi PORTC,0 ; SETB EN
	cbi PORTC,0 ; CLR EN
	ret

GET_ASCII: ; scanned binary is stored in R24
	cpi total_key, 0xE3 ; check if it's 1
	breq ONE
	cpi total_key, 0xF3 ; check if it's 2
	breq TWO
	cpi total_key, 0xF2
	breq THREE
	cpi total_key, 0xD7
	breq FOUR
	cpi total_key, 0xF7
	breq FIVE
	cpi total_key, 0xF6
	breq SIX
	cpi total_key, 0xBB
	breq SEVEN
	cpi total_key, 0xFB
	breq EIGHT
	cpi total_key, 0xFA
	breq NINE
	cpi total_key, 0xFF
	breq ZERO
	cpi total_key, 0xF5
	breq ENTER
	cpi total_key, 0xF1
	breq CLEARKEY
	rjmp NEXT

	
ONE:
	LDI A, 0x31
	rjmp NEXT
TWO:
	LDI A, 0x32
	rjmp NEXT
THREE:
	LDI A, 0x33
	rjmp NEXT
FOUR:
	LDI A, 0x34
	rjmp NEXT
FIVE:
	LDI A, 0x35
	rjmp NEXT
SIX:
	LDI A, 0x36
	rjmp NEXT
SEVEN:
	LDI A, 0x37
	rjmp NEXT
EIGHT:
	LDI A, 0x38
	rjmp NEXT
NINE:
	LDI A, 0x39
	rjmp NEXT
ZERO:
	LDI A, 0x30
	rjmp NEXT
UPKEY:
	LDI A, 0x55
	rjmp NEXT
DOWNKEY:
	LDI A, 0x44
	rjmp NEXT
RIGHTKEY:
	LDI A, 0x52
	rjmp NEXT
LEFTKEY:
	LDI A, 0x4C
	rjmp NEXT
ENTER:
	LDI A, 0x45
	rjmp NEXT
CLEARKEY:
	LDI A, 0x43
	rjmp NEXT
NEXT:
	ret
