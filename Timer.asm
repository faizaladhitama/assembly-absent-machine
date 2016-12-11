.include "m8515def.inc"

.org $00
	rjmp RESET
.org $0E
	rjmp ISR_TCOM0

RESET:
	ldi r17,3    ;counter
	ldi	r16,low(RAMEND)
	out	SPL,r16	            ;init Stack Pointer		
	ldi	r16,high(RAMEND)
	out	SPH,r16

	ldi r16, (1<<CS00) | (1<<CS02); 
	out TCCR0,r16			
	ldi r16,1<<OCF0
	out TIFR,r16		; Interrupt if compare true in T/C0
	ldi r16,1<<OCIE0
	out TIMSK,r16		; Enable Timer/Counter0 compare int
	ldi r16,0b0001000
	out OCR0,r17		; Set compared value
	ser r16
	out DDRB,r16		; Set port B as output
	sei

	ldi r16, 0b00000100
	out PORTB, r16

forever:
	rjmp forever

ISR_TCOM0:
	cpi r17, 0
	breq forever 		;nanti ganti jadi clear_lcd ya
	
	
	push r16
	in r16,SREG
	push r16
	in r16,PORTB	; read Port B
	lsl r16
	;com r16			; invert bits of r16 
	out PORTB,r16	; write Port B
	pop r16
	out SREG,r16
	pop r16
	subi r17,1
	reti
