; PIC16F628A Configuration Bit Settings
; Assembly source line config statements
#include "p16f628a.inc"

; CONFIG
; __config 0x3FF8
__CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _BOREN_ON & _LVP_ON & _CPD_OFF & _CP_OFF
  
    TMP_W	equ 0x20
 
    ORG		0x00
    GOTO	MAIN

    ORG		0x04 
    GOTO	ISR
    
LIMPIAR_DISPLAY
    movlw 0xff
    goto MOSTRAR_DISPLAY_END
MOSTRAR_DISPLAY_0
    movlw   b'10100000' 
    goto MOSTRAR_DISPLAY_END
MOSTRAR_DISPLAY_1
    movlw   b'11111001' 
    goto MOSTRAR_DISPLAY_END
MOSTRAR_DISPLAY_2
    movlw   b'01100100' 
    goto MOSTRAR_DISPLAY_END
MOSTRAR_DISPLAY_3
    movlw   b'01110000' 
    goto MOSTRAR_DISPLAY_END
MOSTRAR_DISPLAY_4
    movlw   b'00111001' 
    goto MOSTRAR_DISPLAY_END
MOSTRAR_DISPLAY_5
    movlw   b'00110010' 
    goto MOSTRAR_DISPLAY_END
MOSTRAR_DISPLAY_6
    movlw   b'00100010' 
    goto MOSTRAR_DISPLAY_END
MOSTRAR_DISPLAY_7
    movlw   b'11111000' 
    goto MOSTRAR_DISPLAY_END
MOSTRAR_DISPLAY_8
    movlw   b'00100000' 
    goto MOSTRAR_DISPLAY_END
MOSTRAR_DISPLAY_9
    movlw   b'00111000' 
    goto MOSTRAR_DISPLAY_END
MOSTRAR_DISPLAY_END
    movwf   PORTA
    goto CONFIG_DISPLAY_END
CONFIG_DISPLAY
    movwf   TMP_W
    call    LIMPIAR_DISPLAY
    
    movlw	'0'
    xorwf	TMP_W,W           
    btfsc	STATUS,Z               
    goto	MOSTRAR_DISPLAY_0    
    
    movlw	'1'
    xorwf	TMP_W,W           
    btfsc	STATUS,Z               
    goto	MOSTRAR_DISPLAY_1     
    
    movlw	'2'
    xorwf	TMP_W,W
    btfsc	STATUS,Z               
    goto	MOSTRAR_DISPLAY_2     
    
    movlw	'3'
    xorwf	TMP_W,W
    btfsc	STATUS,Z               
    goto	MOSTRAR_DISPLAY_3     
    
    movlw	'4'
    xorwf	TMP_W,W
    btfsc	STATUS,Z               
    goto	MOSTRAR_DISPLAY_4
    
    movlw	'5'
    xorwf	TMP_W,W
    btfsc	STATUS,Z
    goto	MOSTRAR_DISPLAY_5
    
    movlw	'6'
    xorwf	TMP_W,W
    btfsc	STATUS,Z
    goto	MOSTRAR_DISPLAY_6
    
    movlw	'7'
    xorwf	TMP_W,W
    btfsc	STATUS,Z 
    goto	MOSTRAR_DISPLAY_7
    
    movlw	'8'
    xorwf	TMP_W,W
    btfsc	STATUS,Z
    goto	MOSTRAR_DISPLAY_8
    
    movlw	'9'
    xorwf	TMP_W,W
    btfsc	STATUS,Z
    goto	MOSTRAR_DISPLAY_9
CONFIG_DISPLAY_END
    movf	TMP_W,W
    return
    
ENVIAR      
      bcf	PIR1,TXIF	    ; Restaura el flag del transmisor (buffer USART lleno)
      movwf	TXREG		    ; Se almacena el byte a transmitir
      bsf	STATUS,RP0	    ; BANCO 1 para poder consultar el estado
ENVIAR_WAIT
      btfss	TXSTA,TRMT	    ; Se transmitió el byte?
      goto	ENVIAR_WAIT	    ; No, volver a consultar
      bcf	STATUS,RP0	    ; Si, se vuelve al banco 1
      return			
      
MAIN
    bsf	    STATUS,RP0		    ; BANCO 1
    
    clrf    TRISA
    movlw   b'10011011'		  
    movwf   TRISB
    
    bcf	    OPTION_REG, NOT_RBPU    ; Configura los pines del puerto B con pull ups.
    
    bsf	    PIE1,RCIE		    ; Habilita USART receive interrupt

    bsf	    INTCON,GIE		    ; Habilita todas las interrupciones
    bsf	    INTCON,PEIE		    ; Habilita todas las interrupciones de periféricos

    movlw   d'25'		    ; 9600bps
    movwf   SPBRG		    ; 4MHz
    
    movlw   B'00100100'		    ; VER [NOTA 1]
    movwf   TXSTA;

    bcf	    STATUS,RP0		    ; BANCO 0

    movlw   B'10010000'		    ; VER [NOTA 2]
    movwf   RCSTA 
    
    call    LIMPIAR_DISPLAY

LOOP
    goto    LOOP
ISR
    btfss   PIR1,RCIF		    ; Buffer de recepción USART lleno?
    goto    ISR_END		    
    movf    RCREG,W		    ; Se guarda la info recibida en W
    call    CONFIG_DISPLAY	
    call    ENVIAR
ISR_END
    retfie
    end
    
; NOTAS

;[1] 00100100 -> TXSTA: 
;	7: Slave mode (Clock from external source); 
;	6: Selects 8-bit transmission; 
;	5: Transmit enabled; 
;	4: Asynchronous mode
;	3: Unimplemented: Read as '0'
;	2: High speed
;	1: TSR full
;	0: 9th bit of transmit data. Can be PARITY bit

;[2] 10010000 -> RCSTA
;	7: Serial port enabled
;	6: Selects 8-bit reception
;	5: Asynchronous mode: Don't care
;	4: Asynchronous mode: enables continuous receive
;	3: Asynchronous mode 8-bit (RX9=0): Unused in this mode Synchronous mode Unused in this mode
;	2: Disables address detection, all bytes are received, and ninth bit can be used as PARITY bit
;	1: No framing error
;	0: No overrun error