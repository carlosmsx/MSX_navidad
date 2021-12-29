;
; Merry christmas multilanguage ROM
;
; 2008 By ClubMSX Argentino
; http://www.ClubMSX.com.ar
;
; Compiled by Telemark Assembler (TASM) version 3.2
;
; Usted puede obtener una copia del compilador en
; http://www.msxhardware.com.ar
;
; Algunas subrutinas de esta rom fueron tomadas de 
; ejemplos en las webs de los siguientes msxeros:
;
; - http://map.tni.nl/
;
; - Rosby Petrus
;   
;
; Agradecemos a todos ellos!
;



#include "macro's.asm"
#define	RomSize(kbytes) .fill	(kbytes * 1024) - $ + StartProgram   ; para obtener siempre 
								     ; un archivo objeto de 32kb

        .ORG     4000h

StartProgram:

DELAY   .EQU     08000h
CONT    .EQU     08002h
ITER	.EQU     08004h
		
STAT_A  .EQU     08006H
STAT_B  .EQU     08010H
STAT_C  .EQU     0801AH
BOTTOM  .EQU     0FC48H
PROCNM	.EQU	 0FD89h

; ROM header

ID:     .DB      41h, 42h        ; acá van los bytes que identifican una ROM, sin esto la BIOS simplemente ignora la ROM
INIT:   .DW    	 INSTALL         ; tenemos una rutina START en la inicializacion de la ROM
STAT:	.DW	 0	   	 ; no agrega sentencias extendidas (CALL)
DEV:    .DW      0               ; no agrega dispositivos (devices)
TEXT:   .DW      0               ; no tiene programa en BASIC
        .DB      0,0,0,0,0,0	 ; estos 6 bytes deben ser 0 y estan reservados para futuros usos de la norma

EJEC:	


	DI
	PUSH	HL
	PUSH	BC
	PUSH	DE
	PUSH	IX
	PUSH	AF

        LD      HL,(CONT)       ;decremento contador de retardo principal
	DEC	HL
        LD      (CONT),HL
	LD	A,H		;ch.EQUeo contador=0
	OR	L
	RET	NZ		;si no es cero retorna

        LD      HL,(DELAY)      ;restauro contador a valor inicial
        LD      (CONT),HL

	LD	IX,STAT_A	; ejecuto canal A
	CALL	PLAY

	LD	IX,STAT_B	; ejecuto canal B
	CALL	PLAY

	LD	IX,STAT_C	; ejecuto canal C
	CALL	PLAY

	CALL	CHECK

        POP     AF
        POP     IX
        POP     DE
        POP     BC
        POP     HL
	EI
	RET

HOOK:	RST	30h
	.DB	1
	.DW	EJEC
	RET

INSTALL:

	call	PANTALLA
	
	DI


        LD      HL,(BOTTOM)
        LD      DE,36
        ADD     HL,DE
        LD      (BOTTOM),HL

	LD	DE,0FD9FH
	LD	HL,HOOK
	LD	BC,5
	LDIR

        LD      HL,1
        LD      (DELAY),HL
        LD      (CONT),HL

;para debugeo del engine de audio

;	LD	HL,CANALB
;	LD	DE,CANALA
;	SCF
;	CCF
;	SBC	HL,DE
;       LD      (LARGO),HL
	LD	A,3
	LD	(ITER),A

	CALL	VOL0
	CALL	SET0

	EI

				;loop infinito para el scroll
scroll:	LD	L,0
scrol2:	LD	BC,50000
sdelay:	DEC	BC
	LD	A,B
	OR	C
	JR	NZ,sdelay
	CALL	HMMM
	INC	L
	LD	A,L
	CP	90h
	JR	NZ,scrol2
	LD	BC,50000
sdela1:	LD	A,50
sdela2:	NOP
	DEC	A
	JR	NZ,sdela2
	DEC	BC
	LD	A,B
	OR	C
	JR	NZ,sdela1
	JR	scroll
		


SETR7_1:LD	A,7
	LD	E,10111100b
	CALL	SOUND
	RET

SETR7_2:LD	A,7
	LD	E,10011100b
	CALL	SOUND
	RET

SETR7_3:LD	A,7
	LD	E,10011000b
	CALL	SOUND
	LD	A,3		;reset counter 
	LD	(ITER),A
	RET

SET0:	LD	A,(ITER)
	DEC	A
	LD	(ITER),A
	CP	2
	CALL	Z,SETR7_1
	CP	1
	CALL	Z,SETR7_2
	CP	0
	CALL	Z,SETR7_3

	PUSH	HL
	LD	HL,CANALA
        LD      (STAT_A),HL
        LD      IX,STAT_A
        LD      (IX+7),8
        LD      (IX+8),0
        LD      (IX+9),1
	CALL	FETCH

	LD	HL,CANALB
        LD      (STAT_B),HL
        LD      IX,STAT_B
        LD      (IX+7),9
        LD      (IX+8),2
        LD      (IX+9),3
	CALL	FETCH

	LD	HL,CANALC
        LD      (STAT_C),HL
        LD      IX,STAT_C
        LD      (IX+7),10
        LD      (IX+8),4
        LD      (IX+9),5
	CALL	FETCH

	POP	HL
	RET

FINAL:	DI
	LD A,0C9H
	LD (0FD9FH),A
	EI

	CALL	VOL0
	RET

VOL0:	LD	A,8
	LD	E,0
	CALL	SOUND
	LD	A,9
	LD	E,0
	CALL	SOUND
	LD	A,10
	LD	E,0
	CALL	SOUND
	LD	A,6
	LD	E,15
	CALL	SOUND
	LD	A,7
	LD	E,10011100B
	CALL	SOUND
	RET

CHECK:  LD      HL,(STAT_A)
	LD	DE,CANALB
	SCF
	CCF
	SBC	HL,DE
	LD	A,H
	OR	L	
	RET	NZ

	CALL	SET0
	RET

FETCH:	LD	L,(IX+0)	; recupera nota actual
	LD	H,(IX+1)
	PUSH	HL
	POP	IY
	LD	A,(IY+0)	; lee duracion
	LD	E,A		; multiplico 'tiempo' por 1.5
	SRA	A
	ADD	A,E
	LD	(IX+2),A	; inicializa duracion
	LD	H,(IY+1)	; lee tabla envolvente
	LD	L,0		; transforma en puntero a tabla evol(H)
	LD	DE, EVOL0
	ADD	HL,DE
	LD	(IX+3),L	; inicializa puntero a tabla evol(H)
	LD	(IX+4),H
	LD	L,(IY+2);	; lee octava/nota
	LD	H,0
	LD	DE,TABLA	; calcula parametros frecuencia nota
        ADD     HL,HL
	ADD	HL,DE
	LD	A,(HL)		; inicializa parametros frec. nota
	LD	(Ix+5),A	
	INC	HL
	LD	A,(HL)
	LD	(IX+6),A

	RET

SETVOL: LD      L,(IX+3)        ; recupero puntero a tabla evol
	LD	H,(IX+4)
	LD	A,(HL)		; recupero volumen actual y lo guardo en E
	CP	255		; ch.EQUea fin de DATA
	RET	Z		; retorna si fin DATA
	LD	E,A
	LD	A,(IX+7)	; recupera registro volumen
;
;	CP	10
;	JR	NZ,NORMAL
;PERCU:	LD	A,6
;	CALL	SOUND
;	LD	A,10
;

NORMAL:	CALL	SOUND
	INC	HL		; apunta a sigte
	LD	(IX+3),L	; guarda sigte
	LD	(IX+4),H
	RET

NOTA:	LD	E,(IX+5)
	LD	A,(IX+9)
	CALL	SOUND
	LD	E,(IX+6)
	LD	A,(IX+8)
	CALL	SOUND
	RET

PLAY:	CALL	NOTA
	CALL	SETVOL
	LD	A,(IX+2)	; recupero contador de duracion
	DEC	A		; actualizo cuenta
	LD	(IX+2),A
        OR      A
	RET	NZ		; si no llega a cero termina

NEXT:	LD	L,(IX+0)	; actualizo puntero a nota
	LD	H,(Ix+1)
	INC	HL
        INC     HL
        INC     HL
	LD	(IX+0),L
	LD	(IX+1),H
	CALL	FETCH		; seteo los valores para la sigte nota
	RET

SOUND:	PUSH	AF
	OUT	(0A0H),A
	LD	A,E
	OUT	(0A1H),A
	POP	AF
	RET

	;Index = octava*16 + nota
	;octaba (0-7)
	;nota (1=C,2=C#,3=D,4=D#,5=E,6=F,7=F#,8=G,9=G#,10=A,11=A#,12=B) other values are "silence" note

TABLA:	.DB 0,0,13,92,12,156,11,231,11,60,10,154,10,2,9,114,8,234,8,106,7,241,7,127,7,19,0,0,0,0,0,0
	.DB 0,0,6,174,6,78,5,243,5,158,5,77,5,1,4,185,4,117,4,53,3,248,3,191,3,137,0,0,0,0,0,0
	.DB 0,0,3,87,3,39,2,249,2,207,2,166,2,128,2,92,2,58,2,26,1,252,1,223,1,196,0,0,0,0,0,0
	.DB 0,0,1,171,1,147,1,124,1,103,1,83,1,64,1,46,1,29,1,13,0,254,0,239,0,226,0,0,0,0,0,0
	.DB 0,0,0,213,0,201,0,190,0,179,0,169,0,160,0,151,0,142,0,134,0,127,0,119,0,113,0,0,0,0,0,0
	.DB 0,0,0,106,0,100,0,95,0,89,0,84,0,80,0,75,0,71,0,67,0,63,0,59,0,56,0,0,0,0,0,0
	.DB 0,0,0,53,0,50,0,47,0,44,0,42,0,40,0,37,0,35,0,33,0,31,0,29,0,28,0,0,0,0,0,0

EVOL0:	.DB 15,14,14,13,13,13,13,12,12,12,12,12,12,11,11,11,11,11,11,11,11,10,10,10,10,10,10,10,10,10,10,10
	.DB 9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,8
	.DB 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
	.DB 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,7
	.DB 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
	.DB 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
	.DB 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
        .DB 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,255

EVOL1:	.DB 15,14,14,13,13,13,12,12,12,12,11,11,11,11,11,10,10,10,10,10,9,9,9,8,8,8,7,7,7,8,8,8
	.DB 9,9,7,7,5,5,7,7,9,9,7,7,5,5,7,7,9,9,7,7,5,5,7,7,9,9,7,7,5,5,7,7
	.DB 9,9,7,7,5,5,7,7,9,9,7,7,5,5,7,7,9,9,7,7,5,5,7,7,9,9,7,7,5,5,7,7
	.DB 8,5,1,5,8,5,1,5,8,5,1,5,8,5,1,5,8,5,1,5,8,5,1,5,8,5,1,5,8,5,1,5
	.DB 8,5,1,5,8,5,1,5,8,5,1,5,8,5,1,5,8,5,1,5,8,5,1,5,8,5,1,5,8,5,1,5
	.DB 7,4,1,4,7,4,1,4,7,4,1,4,7,4,1,4,7,4,1,4,7,4,1,4,7,4,1,4,7,4,1,4
	.DB 7,4,1,4,7,4,1,4,7,4,1,4,7,4,1,4,7,4,1,4,7,4,1,4,7,4,1,4,7,4,1,4
        .DB 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,2,2,2,2,2,2,2,2,2,2,2,2,2,255

EVOL2:	.DB 13,12,12,11,11,10,10,10,9,9,9,8,8,8,7,7,7,6,6,6,5,5,5,4,4,4,4,3,3,3,3,2
	.DB 2,2,2,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,255

	;duracion (128=redonda,64=blanca,32=negra,16=corchea,8=scorchea,4=fusa,2=sfusa)
	;tabla_vol (0-3)
	;nota 
CANALA: .DB	2,0,0
	.DB      48,0,51h, 16,0,53h, 32,0,55h, 16,0,55h, 16,0,55h				;128
	.DB	08,0,56h, 08,0,55h, 16,0,56h, 112,1,55h						;128+16
	.DB      16,0,51h, 16,0,51h, 16,0,53h, 16,0,55h, 16,0,55h, 16,0,55h, 16,0,55h		;128-16
	.DB	08,0,56h, 08,0,55h, 16,0,56h, 112,1,55h						;128+16
	.DB      16,0,53h, 16,0,55h, 16,0,56h, 16,0,58h, 16,0,58h, 16,0,58h, 16,0,5ah		;128-16
	.DB	08,0,58h, 08,0,56h, 16,0,55h, 112,1,53h						;128+16
	.DB      16,0,53h, 16,0,55h, 16,0,56h, 16,0,58h, 16,0,58h, 16,0,58h, 16,0,5ah		;128-16
	.DB	08,0,5bh, 08,0,5ah, 16,0,58h, 32,0,56h, 08,0,5ah, 08,0,58h, 16,0,56h, 32,0,55h	;128
	.DB	08,0,58h, 08,0,56h, 16,0,55h, 64,0,53h, 32,0,0h					;128

CANALB:	.DB	2,0,0
	.DB	32,1,21h, 32,1,21h, 32,1,21h, 32,1,21h
	.DB	32,1,21h, 32,1,21h, 32,1,21h, 16,1,21h, 16,1,18h
	.DB	32,1,21h, 32,1,21h, 32,1,21h, 32,1,21h
	.DB	32,1,21h, 32,1,21h, 32,1,21h, 16,1,21h, 16,1,13h
	.DB	32,1,18h, 32,1,18h, 32,1,18h, 32,1,18h
	.DB	32,1,18h, 32,1,18h, 32,1,18h, 32,1,18h
	.DB	32,1,18h, 32,1,18h, 16,1,21h, 16,1,18h, 16,1,21h, 16,1,18h
	.DB	16,1,16h, 16,1,11h, 16,1,16h, 16,1,11h, 16,1,21h, 16,1,18h, 16,1,21h, 16,1,18h
	.DB	32,1,18h, 32,1,18h, 32,1,18h, 16,1,18h, 16,1,18h

CANALC:	.DB	2,0,0
	.DB	18,2,31h, 5,2,31h, 5,2,31h, 5,2,31h, 18,2,31h, 5,2,31h, 5,2,31h, 5,2,31h
	.DB	18,2,31h, 5,2,31h, 5,2,31h, 5,2,31h, 16,2,31h, 16,2,31h
	.DB	18,2,31h, 5,2,31h, 5,2,31h, 5,2,31h, 18,2,31h, 5,2,31h, 5,2,31h, 5,2,31h
	.DB	18,2,31h, 5,2,31h, 5,2,31h, 5,2,31h, 16,2,31h, 16,2,31h
	.DB	18,2,31h, 5,2,31h, 5,2,31h, 5,2,31h, 18,2,31h, 5,2,31h, 5,2,31h, 5,2,31h
	.DB	18,2,31h, 5,2,31h, 5,2,31h, 5,2,31h, 16,2,31h, 16,2,31h
	.DB	18,2,31h, 5,2,31h, 5,2,31h, 5,2,31h, 18,2,31h, 5,2,31h, 5,2,31h, 5,2,31h
	.DB	18,2,31h, 5,2,31h, 5,2,31h, 5,2,31h, 16,2,31h, 16,2,31h
	.DB	18,2,28h, 5,2,28h, 5,2,28h, 5,2,28h, 18,2,28h, 5,2,28h, 5,2,28h, 5,2,28h
	.DB	18,2,28h, 5,2,28h, 5,2,28h, 5,2,28h, 16,2,28h, 16,2,28h
	.DB	18,2,28h, 5,2,28h, 5,2,28h, 5,2,28h, 18,2,28h, 5,2,28h, 5,2,28h, 5,2,28h
	.DB	18,2,28h, 5,2,28h, 5,2,28h, 5,2,28h, 16,2,28h, 16,2,28h
	.DB	18,2,28h, 5,2,28h, 5,2,28h, 5,2,28h, 18,2,28h, 5,2,28h, 5,2,28h, 5,2,28h
	.DB	18,2,31h, 5,2,31h, 5,2,31h, 5,2,31h, 16,2,31h, 16,2,31h
	.DB	18,2,26h, 5,2,26h, 5,2,26h, 5,2,26h, 18,2,26h, 5,2,26h, 5,2,26h, 5,2,26h
	.DB	18,2,31h, 5,2,31h, 5,2,31h, 5,2,31h, 16,2,31h, 16,2,31h
	.DB	18,2,28h, 5,2,28h, 5,2,28h, 5,2,28h, 18,2,28h, 5,2,28h, 5,2,28h, 5,2,28h
	.DB	18,2,28h, 5,2,28h, 5,2,28h, 5,2,28h, 16,2,28h, 16,2,28h






; Todo este pedazo de codigo en adelante sirve para:
;
; - Setear el modo screen 5 
;
; - Volcar la imagen raw en pantalla descomprimiendola
;   del formato RLE.
;
; - Setear la paleta de colores.
;
; - Volverme un poco loco..


PANTALLA:


	DI


	ld	a,5	;cambiamos a screen 5
	call	CHGMOD	


	LD	A,($F3E0)	; desactivo pantalla
	AND	10111111b
	OUT	($99),A
	LD	A,1+128
	OUT	($99),A


	CALL	SETVRAM8000
	LD	HL,SALUDOS	;Cargo HL con la direccion inicial
				;donde esta guardada la imagen comprimida.
	LD	IY,PALETA_RAW
	call	MUESTRA_IMG	;descomprime la imagen a medida
				;que la va poniendo en la VRAM 
				;y retorna.

	CALL	SETVRAM0000
	LD	HL,IMAGEN_RAW	;Cargo HL con la direccion inicial
				;donde esta guardada la imagen comprimida.
	LD	IY,SALUDOS
	call	MUESTRA_IMG	;descomprime la imagen a medida
				;que la va poniendo en la VRAM
				;y retorna.

                                           
	ld	HL,PALETA_RAW	; setea la paleta en base a la tabla
	call	SETEA_PALETA	; con los 32 valores de la paleta de colores
             
	LD	A,($F3E0)	; activo pantalla
	OUT	($99),A
	LD	A,1+128
	OUT	($99),A

	EI

	RET

;
;	Esta sub es la forma mas rapida de setear la paleta.
;	La direccion de inicio de la tabla de 32 bytes de la paleta
;	se carga en HL.


SETEA_PALETA
		xor     a		;Setea el puntero a cero
		di
		out     ($99),a
		ld      a,16+128	;registro 16
		ei
		out     ($99),a
		ld      c,$9A
		.DW      $A3ED,$A3ED,$A3ED,$A3ED   ;32x instrucciones OUTI
		.DW      $A3ED,$A3ED,$A3ED,$A3ED   ;(mas rapidas que 1 OTIR)
		.DW      $A3ED,$A3ED,$A3ED,$A3ED
		.DW      $A3ED,$A3ED,$A3ED,$A3ED
		.DW      $A3ED,$A3ED,$A3ED,$A3ED
		.DW      $A3ED,$A3ED,$A3ED,$A3ED
		.DW      $A3ED,$A3ED,$A3ED,$A3ED
		.DW      $A3ED,$A3ED,$A3ED,$A3ED
		ret

SETVRAM0000:
	XOR	A		; apunto a la direccion 0 de la VRAM en el VDP
	OUT	($99),A
	LD	A,14+128
	OUT	($99),A
	XOR	A
	OUT	($99),A
	OR	64
	OUT	($99),A
	RET

SETVRAM8000:
	LD	A,2		; apunto a la direccion 8000 de la VRAM en el VDP
	OUT	($99),A
	LD	A,14+128
	OUT	($99),A
	XOR	A
	OUT	($99),A
	OR	64
	OUT	($99),A
	RET

MUESTRA_IMG:
	LD	D,0
MNLOOP:	LD	A,(HL)	
	LD	B,A		; guardo temporalmente

	AND	0fh		; despejo el color
	LD	C,A		; guardo el color

	LD	A,B
	SRL	A		; despejo el número de repeticiones
	SRL	A
	SRL	A
	SRL	A
	JR	NZ,NO_ESC
	INC	HL		; recupero el sigte byte
	LD	B,(HL)
LOOP0:	CALL	WRTNIB
	DJNZ	LOOP0
	LD	A,15
NO_ESC:	LD	B,A
LOOP1:	CALL	WRTNIB
	DJNZ	LOOP1
	INC	HL
	PUSH	HL
	PUSH	IY
	POP	BC
	SCF
	CCF
	SBC	HL,BC
	LD	A,H
	OR	L
	POP	HL
	JR	NZ,MNLOOP
	RET
	

WRTNIB:	LD	A,D
	INC	D
	AND	1
	JR	NZ,WRBYTE
	LD	A,C
	SLA	A
	SLA	A
	SLA	A
	SLA	A
	LD	E,A
	RET
WRBYTE:	LD	A,C
	OR	E
	OUT	($98),A
	RET

;****************************************************************
;  List 4.10   HMMM sample
;		 to use, set H, L, D, E, B, C and go
;		 VRAM (H,L)-(D,E) ---> VRAM (B,C)
;		 DIX must be set in D(bit 2)
;****************************************************************
;
WRVDP:	.EQU	0007H

;----- program start -----

HMMM:	DI				;disable interrupt
	PUSH	BC
	PUSH	DE
	PUSH	HL

	CALL	WAIT.VDP		;wait end of command
	LD	C,99h
	LD	A,32
	OUT	(C),A
	LD	A,80H+17
	OUT	(C),A			;R#17 := 32

	INC	C
	INC	C			;C := PORT#3's address
	XOR	A
	OUT	(C),A			;SX
	OUT	(C),A
	OUT	(C),L			;SY
	INC	A			; apunta a vram pag. 1
	OUT	(C),A
	DEC	A
	OUT	(C),A			;DX
	OUT	(C),A
	LD	A,200
	OUT	(C),A			;DY
	XOR	A
	OUT	(C),A
	OUT	(C),A			;NX
	INC	A
	OUT	(C),A
	LD	A,12
	OUT	(C),A			;NY
	XOR	A
	OUT	(C),A
	OUT	(C),A			;dummy
	OUT	(C),A			;DIX and DIY
	LD	A,11010000B		;HMMM command
	OUT	(C),A

	POP	HL
	POP	DE
	POP	BC
	EI
	RET


GET.STATUS:
	PUSH	BC
	LD	BC,(WRVDP)
	INC	C
	OUT	(C),A
	LD	A,8FH
	OUT	(C),A
	LD	BC,(RDVDP)
	INC	C
	IN	A,(C)
	POP	BC
	RET

WAIT.VDP:
	LD	A,2
	CALL	GET.STATUS
	AND	1
	JP	NZ,WAIT.VDP
	XOR	A
	CALL	GET.STATUS
	RET

IMAGEN_RAW:

#include "mascota.asm"

saludos:

#include "saludos.asm"

PALETA_RAW:

	; Paleta de colores
        
 .DB 077h,007h,077h,007h,000h,004h,000h,000h
 .DB 060h,004h,004h,003h,070h,000h,060h,003h
 .DB 020h,001h,053h,002h,044h,004h,033h,003h
 .DB 070h,007h,052h,004h,074h,004h,022h,004h


	RomSize(32)


	.END

