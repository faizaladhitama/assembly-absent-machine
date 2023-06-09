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
.def row = r23
.def total_key = r24
.def proses = r25

.equ keyport = PORTA
.equ pressed = 0
.equ next_proses = 1

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


;0x60 = Simpan banyak char dalam input (mata kuliah)
;0x61 = Simpan enter yang terjadi (mata kuliah)
;0x62 = Simpan enter yang terjadi (absensi)

MAIN:
	ldi temp,HIGH(RAMEND)
	out SPH,temp
	ldi temp,LOW(RAMEND)
	out SPL,temp
	ldi temp,$ff
	rcall INIT_CHECKER
	rcall INIT_CHAR_DATA
	ldi proses,0x00
	st X,proses
	out DDRB,temp ; Set port B as output
	out DDRC,temp ; Set port C as output
	rcall INIT_LCD
	rcall key_init
	rcall CLEAR_LCD
	rcall INIT_COURSE
	SEI

LOAD_BYTE:
	lpm ; Load byte from program memory into r0
	tst r0 ; Check if we've reached the end of the message
	breq CLEAR ; If so, quit
	mov A, r0 ; Put the character onto Port B
	rcall WRITE_TEXT
	adiw ZL,1 ; Increase Z registers
	rjmp LOAD_BYTE

LOAD_BYTE_2:
	lpm ; Load byte from program memory into r0
	tst r0 ; Check if we've reached the end of the message
	breq FOREVER ; If so, quit
	mov A, r0 ; Put the character onto Port B
	rcall WRITE_TEXT
	adiw ZL,1 ; Increase Z registers
	rjmp LOAD_BYTE_2

FOREVER:
	rjmp FOREVER

INIT_CHECKER:
	;check digit yang ke input
	ldi XH,0x00
	ldi XL,0x60
	ldi temp,0x00
	ST X,temp

	;check char yang ke input (mata kuliah)
	ldi XH,0x00
	ldi XL,0x61
	ldi temp,0x00
	ST X,temp
	
	;check berapa kali enter (mata kuliah)
	ldi XH,0x00
	ldi XL,0x62
	ldi temp,0x00
	ST X,temp
	
	;check char yang ke input (absen)
	ldi XH,0x00
	ldi XL,0x63
	ldi temp,0x00
	ST X,temp
	;check berapa kali enter (absen)
	ldi XH,0x00
	ldi XL,0x64
	ldi temp,0x00
	ST X,temp
	ret

INIT_SAVE_ABSENSI:
	ldi XH,0x00
	ldi XL,0x6C
	ret
 	 
INIT_ABSEN :
	ldi flags,0x00
	mov r15,flags
	rcall INIT_CHAR_DATA
	ST X,flags
	ldi ZH,HIGH(2*No_Absen)
	ldi ZL,LOW(2*No_Absen)
	ret

INIT_CHAR_DATA:
	ldi XH,0x00
	ldi XL,0x60
	ret

INIT_CHAR_SAVED:
	ldi XH,0x00
	ldi XL,0x66
	ret

INIT_COURSE :
	ldi ZH,HIGH(2*Course_ID)
	ldi ZL,LOW(2*Course_ID)
	ret

INIT_SUCCESS:
	ldi ZH,HIGH(2*Success)
	ldi ZL,LOW(2*Success)
	ret

INIT_FORMAT_SALAH:
	ldi ZH,HIGH(2*Format_Salah)
	ldi ZL,LOW(2*Format_Salah)
	ret

CLEAR:
	rcall PINDAH_BARIS
	clr A
	clr temp
	rjmp LOOP

CLEAR_SAVED_CHAR:
	ldi XL,0x60
	ld temp,X
	mov r9,temp
	ldi XL,0x61
	ld flags,X
	add temp,flags
	rcall CLEAR_SAVED_DIGIT
	ret	

CLEAR_SAVED_DIGIT:
	ldi XL,0x65
	add XL,temp
	ldi temp,0x00
	ST X,temp
	ldi XL,0x60
	ld temp,X
	subi temp,0x01
	tst temp
	brne CLEAR_2_DIGIT
	ret

CLEAR_2_DIGIT:
	ldi XL,0x65
	add XL,temp
	ldi temp,0x00
	ST X,temp
	ret

SAVE_TO_MEMORY:
	ld temp,X
	cpi temp,0x02
	breq CEK_TWO_DIGITS
	ret

CEK_TWO_DIGITS:
	rcall INIT_CHAR_DATA
	ld temp,X
	cpi temp,0x02
	breq IF_TWO_DIGITS
	ret

IF_TWO_DIGITS:
	ldi XL,0x61
	ld flags,X
	ldi XL,0x62
	ld temp,X
	add flags,temp
	rcall INIT_CHAR_SAVED
	add XL,flags
	ld temp,X
	rcall first_digit
	ret

SUCCESS_MESSAGE:
	ldi XH,0x00
	ldi XL,0x62
	ld temp,X
	ldi flags,0x01
	add temp,flags
	ST X,temp
	ldi XH,0x00
	ldi XL,0x61
	ld temp,X
	subi temp,0x01
	ST X,temp
	clr A
	clr temp
	rcall INIT_SUCCESS
	rjmp LOAD_BYTE_2

BALIK_KE_INPUT_AWAL:
	ldi XH,0x00
	ldi XL,0x62
	ld temp,X
	ldi flags,0x01
	add temp,flags
	ST X,temp
	ldi XH,0x00
	ldi XL,0x61
	ld temp,X
	subi temp,0x01
	ST X,temp
	clr A
	clr temp
	ldi proses,0x00
	rcall INIT_COURSE
	rjmp LOAD_BYTE

ASCII_TO_LCD:
	cpi A, 0x43
	breq CLEAR_INPUT
	cpi A, 0x45
	breq ENTER_INPUT
	rcall WRITE_TEXT
	subi A,48
	add r15,A
	add r14,A
	rcall INCREMENT_X_CHAR
	rcall INIT_CHAR_DATA
	ldi temp,0x00
	mov r15,temp
	rjmp UPDATE

CLEAR_INPUT:
	rcall CLEAR_LCD
	rcall INIT_COURSE
	rcall CLEAR_SAVED_CHAR
	ldi XL,0x60
	ld temp,X
	ldi temp,0x00
	ST X,temp
	clr temp
	clr A
	rjmp LOAD_BYTE

	
INPUT_NOL:
	rcall CLEAR_LCD
	clr temp
	clr A
	rcall INIT_FORMAT_SALAH
	rjmp LOAD_BYTE_2

ENTER_INPUT:
	rcall CLEAR_LCD
	mov temp,r14
	cpi temp,0x00
	breq INPUT_NOL
	ld temp,X
	ldi flags,0x01
	add temp,flags
	ST X,temp
	rcall CEK_TWO_DIGITS
	rcall INCREMENT_X_ENTER
	rcall INIT_ABSEN
	ldi temp,0x01
	add proses,temp
	cpi proses,0x02
	breq BALIK_KE_INPUT_AWAL
	clr temp
	clr A
	rjmp LOAD_BYTE


LOOP:
	rcall get_key
	mov total_key,A
	sub total_key,keyval
	rcall GET_ASCII
	tst A
	brne CEK_CHAR
	rjmp UPDATE

INCREMENT_X_CHAR:
	ldi XH,0x00
	ldi XL, 0x60
	ld temp,X
	ldi flags,1
	add temp,flags
	mov r7,temp
	ldi XH,0x00
	ldi XL,0x61
	ld flags,X
	add temp,flags
	ldi XH,0x00
	ldi XL, 0x62
	ld flags,X
	add temp,flags
	mov r8,temp
	ldi XH,0x00
	ldi XL, 0x65
	add XL,temp
	ST X,r15
	ldi XL,0x60
	mov temp,r7
	ST X,temp
	ret

INCREMENT_X_ENTER:
	mov r15,temp
	ldi XH,0x00
	ldi XL, 0x61
	ld temp,X
	ldi flags,1
	add temp,flags
	mov r4,temp
	ldi XL, 0x62
	ld flags,X
	add temp,flags
	ldi XH,0x00
	ldi XL, 0x65
	add XL,temp
	ST X,r15
	mov temp,r4
	ldi XL,0x61
	ST X,temp
	ret

CEK_CHAR:
	ld flags, X
	cpi flags, 0x02
	breq UPDATE
	rjmp ASCII_TO_LCD

UPDATE:
	clr temp
	clr A
	rjmp LOOP

FIRST_DIGIT:
	ldi flags,0x01
	cpi temp,1
	breq TEN
	cpi temp,2
	breq TWENTY
	cpi temp,3
	breq THIRTY
	cpi temp,4
	breq FOURTY
	ret

TEN:
	adiw XL,1
	ld temp,X
	ldi flags,10
	add temp,flags
	ret
TWENTY:
	adiw XL,1
	ld temp,X
	ldi temp,20
	add temp,flags
	ret
THIRTY:
	adiw XL,1
	ld temp,X
	ldi temp,30
	add temp,flags
	ret
FOURTY:
	adiw XL,1
	ld temp,X
	ldi temp,40
	add temp,flags
	ret	

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
	ret

BALIK_ATAS:
	cbi PORTA,1
	cbi PORTA,2
	ldi temp,0x80
	out PORTB,temp
	sbi PORTA,0
	cbi PORTA,0
	ret

PINDAH_BARIS:
	cbi PORTC,1
	cbi PORTC,2
	ldi temp,0xC0
	out PORTB,temp
	sbi PORTC,0
	cbi PORTC,0
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
	cpi total_key, 0x7F
	breq NULL
	rjmp NEXT

NULL:
	LDI A,0x00
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

ENTER:
	ldi XL,0x60
	ld temp,X
	subi temp,1
	ST X,temp
	LDI A, 0x45
	rjmp NEXT

CLEARKEY:
	rcall CLEAR_SAVED_CHAR
	ld flags,X
	ldi flags,0x00
	ldi XH,0x00
	ldi XL,0x60
	ST X,flags
	LDI A, 0x43
	rjmp NEXT
NEXT:
	ret

Course_ID:
.db "Course ID :"
.db 0

No_Absen:
.db "No Absensi :"
.db 0

Format_Salah:
.db "Tidak boleh menginput 0"
.db 0

Success:
.db "Input Success"
.db 0
