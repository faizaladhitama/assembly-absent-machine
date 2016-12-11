.include "m8515def.inc"


.def temp =r16 ; Define temporary variable
.def EW = r17 ; for PORTA
.def PB = r18 ; for PORTB
.def A  = r19

.def sem =r18 
.def temp =r18 
.def xorReg=r19

.org $00
rjmp START
.org $01
rjmp ext_int0
.org $02
rjmp ext_int1


; PORTB as DATA
; PORTA.0 as EN
; PORTA.1 as RS
; PORTA.2 as RW

START:
ldi temp,low(RAMEND) ; Set stack pointer to -
out SPL,temp ; -- last internal RAM location
ldi temp,high(RAMEND)
out SPH,temp

ldi temp,$ff
out DDRA,temp ; Set port A as output
out DDRB,temp ; Set port B as output
out DDRC,temp ; Set port B as output

rcall CLEAR_LCD
rcall INIT_LCD

ldi ZH,high(2*message) ; Load high part of byte address into ZH
ldi ZL,low(2*message) ; Load low part of byte address into ZL

;Setting interupt
;out DDRD, r16
;out PORTD, r16

enableinterrupt:
ldi r17,0b00001010
out MCUCR,r17
ldi r17,0b11000000
out GICR,r17
sei

LOADBYTE:
lpm ; Load byte from program memory into r0
tst r0 ; Check if we've reached the end of the message
breq QUIT ; If so, quit

ldi r25, 0x20
cp r0, r25
breq ENTER_TEXT

mov A, r0 ; Put the character onto Port B
rcall WRITE_TEXT
ENTER_QUIT:
adiw ZL,1 ; Increase Z registers
rjmp LOADBYTE

ENTER_TEXT :

cbi PORTA,1 ; CLR RS
ldi PB,0xc0 ; MOV DATA,0x38 --> 8bit, 2line, 5x7
out PORTB,PB
sbi PORTA,0 ; SETB EN
cbi PORTA,0 ; CLR EN
rcall WAIT_LCD
	
rjmp ENTER_QUIT

QUIT: 
cbi PORTA,1 ; CLR RS
ldi PB,0x0C
out PORTB,PB
sbi PORTA,0 ; SETB EN
cbi PORTA,0 ; CLR EN
rcall WAIT_LCD
cbi PORTA,1 ; CLR RS
ldi PB,0x08
out PORTB,PB
sbi PORTA,0 ; SETB EN
cbi PORTA,0 ; CLR EN
rcall WAIT_LCD
rjmp QUIT

WAIT_LCD:
ldi r20, 1
ldi r21, 69
ldi r22, 69
CONT: 
dec r22
brne CONT
dec r21
brne CONT
dec r20
brne CONT
ret

WAIT:
ldi r23, 1
ldi r24, 69
ldi r25, 69
CONT1: 
dec r25
brne CONT1
dec r24
brne CONT1
dec r23
brne CONT1
ret

INIT_LCD:
cbi PORTA,1 ; CLR RS
ldi PB,0x38 ; MOV DATA,0x38 --> 8bit, 2line, 5x7
out PORTB,PB
sbi PORTA,0 ; SETB EN
cbi PORTA,0 ; CLR EN
rcall WAIT_LCD

cbi PORTA,1 ; CLR RS
ldi PB,$0E ; MOV DATA,0x0E --> disp ON, cursor ON, blink OFF
out PORTB,PB
sbi PORTA,0 ; SETB EN
cbi PORTA,0 ; CLR EN
rcall WAIT_LCD

;rcall CLEAR_LCD ; CLEAR LCD
cbi PORTA,1 ; CLR RS
ldi PB,$06 ; MOV DATA,0x06 --> increase cursor, display sroll OFF
out PORTB,PB
sbi PORTA,0 ; SETB EN
cbi PORTA,0 ; CLR EN
rcall WAIT_LCD

;rcall CLEAR_LCD ; CLEAR LCD
;cbi PORTA,1 ; CLR RS
;ldi PB,$88
;out PORTB,PB
;sbi PORTA,0 ; SETB EN
;cbi PORTA,0 ; CLR EN
;rcall WAIT_LCD
ret

CLEAR_LCD:
cbi PORTA,1 ; CLR RS
ldi PB,$01 ; MOV DATA,0x01
out PORTB,PB
sbi PORTA,0 ; SETB EN
cbi PORTA,0 ; CLR EN
rcall WAIT_LCD
ret

WRITE_TEXT:
sbi PORTA,1 ; SETB RS
out PORTB, A
sbi PORTA,0 ; SETB EN
cbi PORTA,0 ; CLR EN
rcall WAIT_LCD
ret


ext_int0:
;push r16
;in r16,sreg
;push r16
;LED1:
ldi sem,0x01 
out PORTC,sem ; Update LEDS
rcall WAIT
ldi sem,0x04 
out PORTC,sem ; Update LEDS
rcall WAIT
ldi sem,0x02 
out PORTC,sem ; Update LEDS
rcall WAIT
ldi sem,0x80 
out PORTC,sem ; Update LEDS
rcall WAIT
ldi sem,0x00 
out PORTC,sem ; Update LEDS
rcall WAIT
ldi sem,0x80 
out PORTC,sem ; Update LEDS
rcall WAIT
ldi sem,0x20 
out PORTC,sem ; Update LEDS
rcall WAIT
ldi sem,0x40 
out PORTC,sem ; Update LEDS
rcall WAIT
ldi sem,0x80 
out PORTC,sem ; Update LEDS
rcall WAIT
ldi sem,0x00 
out PORTC,sem ; Update LEDS
rcall WAIT
ldi sem,0x80 
out PORTC,sem ; Update LEDS
rcall WAIT
ldi sem,0x08 
out PORTC,sem ; Update LEDS
rcall WAIT
;ret
;pop r16
;out sreg,r16
;pop r16
reti


ext_int1:
;push r16
;in r16,sreg
;push r16

;LED2:
ldi sem,0x00 
out PORTC,sem ; Update LEDS
rcall WAIT
ldi sem,0x02 
out PORTC,sem ; Update LEDS
rcall WAIT
ldi sem,0x01 
out PORTC,sem ; Update LEDS
rcall WAIT
ldi sem,0x40 
out PORTC,sem ; Update LEDS
rcall WAIT
ldi sem,0x00 
out PORTC,sem ; Update LEDS
rcall WAIT
ldi sem,0x40 
out PORTC,sem ; Update LEDS
rcall WAIT
ldi sem,0x80 
out PORTC,sem ; Update LEDS
rcall WAIT
ldi sem,0x20 
out PORTC,sem ; Update LEDS
rcall WAIT
ldi sem,0x40 
out PORTC,sem ; Update LEDS
rcall WAIT
ldi sem,0x00 
out PORTC,sem ; Update LEDS
rcall WAIT
ldi sem,0x40 
out PORTC,sem ; Update LEDS
rcall WAIT
ldi sem,0x04 
out PORTC,sem ; Update LEDS
rcall WAIT
;
;pop r16
;out sreg,r16
;pop r16
reti


message:
.db "DIJUAL,HUBUNGI: FULAN"
.db 0
