;
;This file is part of EMUEMS.
;
;EMUEMS is free software; you can redistribute it and/or modify
;it under the terms of the GNU General Public License as published by
;the Free Software Foundation; either version 2 of the License, or
;(at your option) any later version.

;EMUEMS is distributed in the hope that it will be useful,
;but WITHOUT ANY WARRANTY; without even the implied warranty of
;MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;GNU General Public License for more details.

;You should have received a copy of the GNU General Public License
;along with EMUEMS; if not, write to the Free Software
;Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
;

LOCALS	@@

.MODEL		TINY

.STACK 128

ParamLen			EQU	80H
GETESTATE		EQU	40H
GETSEG			EQU	41H
GETPAGES			EQU	42H
ALLOC				EQU	43H
MAP				EQU	44H
FREE				EQU	45H
GETVERSION		EQU	46H
SAVEPAGEMAP		EQU	47H
LOADPAGEMAP		EQU	48H
COUNTHANDLE		EQU	4BH
PAGESHANDLE		EQU	4CH
PAGESHANDLES	EQU	4DH

ErrEmm			EQU	81H
ErrHandle 		EQU	83H
NoFunc			EQU	84H
NoHandles		EQU	85H
NoPagesT			EQU	87H
NoPages			EQU	88H
NoPageL			EQU	8AH
NoPageF			EQU	8BH

Mapa				STRUC
					Handle	DB		0
					Pages		DW		0
					ENDS

PMapa				STRUC
					PMOff		DW		?
					PHandle	DW		0
					Page		DW		0
					ENDS

.CODE

Buffer		DW		?
TotalPage	DW		?
FreePage		DW		?
NumHandles	DW		0
PSP			DW		?

EmsStr		DB		"EMMXXXX0"
EmsStrLen	EQU	$ - EmsStr
@Mapa			Mapa	256 DUP (<>)
HandlesEnd	EQU	OFFSET	$
@PMapa		LABEL		PMapa
				IRP	OFF,<0,4000H,8000H,0C000H>
					DW		OFF
					DW		0
					DW		0
					ENDM
FEmsNamePtr	DW		?
FNombre		DB		80	DUP	(0)
FNombreEnd	EQU	OFFSET $

make_name			proc

						MOV		DI,FEmsNamePtr
						MOV		CL,DH
						CLD
						CALL		@@hexa
						MOV		CL,DL
	@@hexa:
						MOV		AL,CL
						SHR		AL,4
						CALL		@@bit
						MOV		AL,CL
						AND		AL,0FH
	@@bit:
						ADD		AL,'0'
						CMP		AL,3AH
						JB			@@pon
						ADD		AL,'A'-3AH
	@@pon:
						STOSB

						RET

						ENDP

close_archivo		proc

						MOV		AH,3EH
						INT		21H
						MOV		DX,OFFSET FNombre
						MOV		AH,41H
						INT		21H
						JB			@@error
						XOR		AH,AH
						JMP		@@fin
	@@error:
						MOV		AH,ErrEmm
	@@fin:
						RET

						ENDP

ems_alloc			proc

						PUSH		DS
						PUSH		ES
						PUSH		BX
						PUSH		CX
						PUSH		DI
						PUSH		SI
						MOV		AX,CS
						MOV		DS,AX
						MOV		ES,AX
						CMP		WORD PTR [TotalPage],BX
						JB			@@nopagest
						CMP		WORD PTR [FreePage],BX
						JB			@@nopages
						MOV		DI,OFFSET @Mapa
						OR			BX,BX
						JZ			@@nopages
						MOV		CX,LENGTH @Mapa
						XOR		AL,AL
	@@bucle2:
						CMP		[DI],AL
						JZ			@@bien
						ADD		DI,SIZE Mapa
						LOOP		@@bucle2
                  MOV		AH,NoHandles
						JMP		@@fin	
	@@bien:
						MOV		DX,DI
						CALL		make_name
						MOV		DI,DX
						MOV		AH,3CH
						MOV		DX,OFFSET FNombre
						MOV		CX,20H
						INT		21H
						JB			@@error
						MOV		SI,BX
						MOV		WORD PTR [Adios],BX
						MOV		BX,AX
						XOR		DX,DX
						MOV		CX,4000H
	@@bucle:
						MOV		AH,40H
						INT		21H
						JB			@@close
						CMP		AX,CX
						JNZ		@@close
						DEC		SI
						JNZ		@@bucle
                  MOV		CX,WORD PTR [Adios]
						SUB		[FreePage],CX
						INC		WORD PTR [NumHandles]
						MOV		[DI].Mapa.Handle,BL
						MOV		[DI].Mapa.Pages,CX
						MOV		DX,DI
						XOR		AH,AH
						JMP		@@fin
	@@close:
						CALL		close_archivo
	@@error:
						MOV		AH,ErrEmm
						JMP		@@fin
	@@nopagest:
						MOV		AH,NoPagesT
						JMP		@@fin
	@@nopages:
						MOV		AH,NoPages
	@@fin:
						POP		SI
						POP		DI
						POP		CX
						POP		BX
						POP		ES
						POP		DS

						IRET

						ENDP

BienHandle			proc

						CMP		DX,OFFSET @Mapa
						JB			@@error2
						CMP		DX,HandlesEnd-1
						JA			@@error
						MOV		DI,DX
						MOV		DL,[DI].Mapa.Handle
						OR			DL,DL
						JNZ		@@fin
	@@error:
						STC
	@@error2:
						MOV		AH,ErrHandle
	@@fin:
						XOR		DH,DH

						RET

						ENDP

ems_map				proc

						PUSH		DS
						PUSH		BX
						PUSH		CX
						PUSH		DX
						PUSH		DI
						PUSH		SI
						CMP		AL,3
						JA			@@nopagef
						CBW
						SAL		AL,1
                  MOV		CX,AX
						SAL		AL,1
						ADD		AX,CX
						MOV		SI,OFFSET @PMapa
						ADD		SI,AX
						MOV		AX,CS
						MOV		DS,AX
						CALL		BienHandle
						JB			@@fin
						CMP		BX,[DI].Mapa.Pages
						JAE		@@nopagel
						CMP		DX,[SI].PMapa.PHandle
						JNZ		@@map
						CMP		BX,[SI].PMapa.Page
						JZ			@@nada
	@@map:
						PUSH		DX
						PUSH		BX
                  MOV		AH,40H
						CALL		@@pos
						POP		BX
						POP		DX
						JB			@@error
						MOV		WORD PTR [SI].PMapa.PHandle,DX
						MOV		WORD PTR [SI].PMapa.Page,BX
						MOV		AH,3FH
						CALL		@@pos
						JB			@@error
	@@nada:
						XOR		AH,AH
						JMP		@@fin
	@@error:
						MOV		AH,ErrEmm
						JMP		@@fin
	@@nopagel:
						MOV		AH,NoPageL
						JMP		@@fin
	@@nopagef:
						MOV		AH,NoPageF
	@@fin:
						POP		SI
						POP		DI
						POP		DX
						POP		CX
						POP		BX
						POP		DS

						IRET
	@@pos:
						MOV		BYTE PTR [Adios],AH
						MOV		AX,WORD PTR [SI].PMapa.Page
                  MOV		BX,WORD PTR [SI].PMapa.PHandle
						OR			BX,BX
						JZ			@@@fin
						XOR		DX,DX
						MOV		CX,4000H
						MUL		CX
						MOV		CX,DX
						MOV		DX,AX
						MOV		AX,4200H
						INT		21H
						JB			@@@fin
						MOV		CX,4000H
						MOV		DX,[SI].PMapa.PMOff
						MOV		AH,BYTE PTR [Adios]
						MOV		DS,[Buffer]
						INT		21H
						CMP		AX,CX
						MOV		BX,CS
						MOV		DS,BX
	@@@fin:
						RET

						ENDP

ems_free				proc

						PUSH		DS
						PUSH		ES
						PUSH		DI
						PUSH		BX
						PUSH		CX
						PUSH		DX
						MOV		AX,CS
						MOV		DS,AX
						MOV		ES,AX
						CALL		BienHandle
						JB			@@fin
						MOV		BX,OFFSET @PMapa
						MOV		CX,4
						XOR		AX,AX
	@@bucle:
						CMP		WORD PTR [BX].PMapa.PHandle,DX
						JNZ		@@noborra
						MOV		[BX].PMapa.PHandle,AX
	@@noborra:
						ADD		BX,SIZE PMapa
						LOOP		@@bucle
						MOV		BYTE PTR [DI].Mapa.Handle,AL
						MOV		AX,[DI].Mapa.Pages
						ADD		[FreePage],AX
						DEC		WORD PTR [NumHandles]
						MOV		BX,DX
						MOV		DX,DI
						CALL		make_name
						CALL		close_archivo
						JB			@@fin
						XOR		AH,AH
	@@fin:
						POP		DX
						POP		CX
                  POP		BX
						POP		DI
						POP		ES
						POP		DS

						IRET

						ENDP

pageshandle			proc

						PUSH		DS
						PUSH		DI
						PUSH		DX
						MOV		AX,CS
						MOV		DS,AX
						CALL		BienHandle
						JB			@@fin
						MOV		BX,[DI].Mapa.Pages
						XOR		AH,AH
   @@fin:
						POP		DX
						POP		DI
						POP		DS

						IRET

						ENDP

pageshandles		proc

						PUSH		DS
						PUSH		DI
						PUSH		SI
						PUSH		CX
						PUSH		DX
						MOV		AX,CS
						MOV		DS,AX
						MOV		BX,[NumHandles]
						OR			BX,BX
						JZ			@@fin
						MOV		CX,BX
						MOV		SI,OFFSET @Mapa-2
						CLD
	@@bucle2:
						INC		SI
						INC		SI
	@@bucle:
						LODSB
						OR			AL,AL
						JZ			@@bucle2
						LEA		AX,DS:[SI-1]
						STOSW
						MOVSW
	@@otro:
						LOOP		@@bucle
	@@fin:
						XOR		AH,AH
						POP		DX
                  POP		CX
						POP		SI
						POP		DI
						POP		DS

						IRET

						ENDP

EmsInt				proc	FAR

						CMP		AH,GETESTATE
						JZ			@@estado
						CMP		AH,GETSEG
						JZ			@@getseg
						CMP		AH,GETPAGES
						JZ			@@getpages
						CMP		AH,ALLOC
						JZ			@@alloc
						CMP		AH,MAP
						JZ			@@map
						CMP		AH,FREE
						JZ			@@free
						CMP		AH,GETVERSION
						JZ			@@getversion
						CMP		AH,SAVEPAGEMAP
						JZ			@@estado
						CMP		AH,LOADPAGEMAP
						JZ			@@estado
						CMP		AH,COUNTHANDLE
						JZ			@@handles
						CMP		AH,PAGESHANDLE
						JZ			@@paghandle
						CMP		AH,PAGESHANDLES
						JZ			@@paghandles
						MOV		AH,NoFunc
						IRET
	@@getseg:
						MOV		BX,CS:[Buffer]
	@@estado:
						XOR		AH,AH
						IRET
	@@getpages:
						MOV		BX,CS:[FreePage]
						MOV		DX,CS:[TotalPage]
						XOR		AH,AH
						IRET
	@@alloc:
						JMP		ems_alloc
	@@map:
						JMP		ems_map
	@@free:
						JMP		ems_free
	@@getversion:
						MOV		AX,0030H
						IRET
	@@handles:
						MOV		BX,CS:[NumHandles]
						XOR		AH,AH
						IRET
	@@paghandle:
						JMP		pageshandle
	@@paghandles:
						JMP		pageshandles

						ENDP

Adios					proc

						REP		STOSW
						MOV		AX,3100H
						INT		21H

						ENDP

FinEms		EQU		$+15
OFFinEms		EQU		OFFSET	FinEms

Logotipo		DB		"(c) Emulador de memoria Expandida (LIM) 2.0 por Oscar Hern ndez Ba¤¢ 1994",10,13,'$'
InstEmsStr	DB		"Memoria Expandida ya instalada",7,10,13,'$'
SintaxisStr	LABEL		BYTE
							DB	10,13,"EMUEMS <directorio> <megas>",10,13,10,13
							DB	"<directorio>  = Directorio donde el programa pone sus ficheros temporales",10,13
							DB	"<megas>       = Numero de megas de memoria Expandida",10,13,10,13
							DB	"Ejemplo :",10,13,10,13
							DB	"EMUEMS C:\ 1  ( Emulaci¢n de un mega en el directorio C:\ )",10,13,'$'
NoDirStr		DB		"Directorio no encontrado",7,10,13,'$'
FinStr		DB		"Memoria Expandida instalada",10,13,'$'
NoMem			DB		"No hay memoria disponible",7,10,13,'$'

FEmsName		DB		"EMS$0000.$$$"
FEmsNameLen	EQU	$ - FEmsName

IsEms					proc

						MOV		AX,3567H
						INT		21H
						MOV		DI,0AH
						MOV		SI,DI
						MOV		CX,EmsStrLen
						CLD
						REPZ		CMPSB

						RET

						ENDP

EspParam				proc

						OR			CX,CX
						JZ			@@fin
						MOV		DS,CS:[PSP]
						MOV		ES,CS:[PSP]
						MOV		DI,SI
						MOV		AL,' '
						REPZ		SCASB
						JZ			@@fin
						INC		CX
						DEC		DI
						MOV		SI,DI
	@@fin:
						RET

						ENDP

GetDir				proc
						
						CALL		EspParam
						JZ			@@mal
						MOV		BX,CS
						MOV		ES,BX
						MOV		DI,OFFSET FNombre
						CLD
	@@bucle:
						LODSB
						CMP		AL,' '
						JZ			@@bien
						STOSB
						LOOP		@@bucle
	@@mal:
						STC
						RET
	@@bien:
						CMP		DI,FNombreEnd
						JAE		@@mal
						CMP		BYTE PTR ES:[DI-1],'\'
						JZ			@@nopon
						MOV		AL,'\'
						STOSB
	@@nopon:
						MOV		DS,BX
						DEC		CX
						LEA		BX,DS:[DI+4]
						MOV		[FEmsNamePtr],BX
						MOV		DX,CX
						MOV		BX,SI
						MOV		SI,OFFSET FEmsName
						MOV		CX,FEmsNameLen
						REP		MOVSB
						CMP		DI,FNombreEnd
						JAE		@@mal
						MOV		SI,BX
						MOV		CX,DX
						CLC
						RET
						ENDP

GetMegas				proc

						CALL		EspParam
						JZ			@@mal
						XOR		BX,BX
	@@bucle:
						MOV		AX,BX
						SAL		BX,3
						ADD		BX,AX
						LODSB
						SUB		AL,'0'
						JB			@@mal
						CMP		AL,9
						JA			@@mal
						CBW
						ADD		BX,AX
						LOOP		@@bucle
						MOV		AX,CS
						MOV		DS,AX
						MOV		ES,AX
						SAL		BX,6
						MOV		[TotalPage],BX
						MOV		[FreePage],BX
						CLC
						RET
	@@mal:
						STC
						RET

						ENDP

Write					proc

						MOV		AH,9
						INT		21H

						RET

						ENDP

Error					proc

						MOV		AX,CS
						MOV		DS,AX
						CALL		Write
						MOV		AX,4C01H
						INT		21H

						ENDP

comienzo:

emuems				proc

						MOV		CS:[PSP],DS
						MOV		AX,CS
						MOV		DS,AX
						MOV		DX,OFFSET Logotipo
						CALL		Write
						CALL		IsEms
						JNZ		@@sigue
						MOV		DX,OFFSET InstEmsStr
						JMP		Error
	@@sigue:
						MOV		ES,CS:[PSP]
						MOV		CL,BYTE PTR ES:[ParamLen]
						XOR		CH,CH
						MOV		SI,ParamLen+1
						CALL		GetDir
						JC			@@mal
						CALL		GetMegas
						JNC		@@sigue2
	@@mal:
						MOV		DX,OFFSET SintaxisStr
						JMP		Error
	@@sigue2:
						MOV		DX,OFFSET FNombre
						MOV		AH,4EH
						MOV		CX,20H
						INT		21H
						JNC		@@sigue3
						CMP		AL,3
						JNZ		@@sigue3
						MOV		DX,OFFSET NoDirStr
						JMP		Error
	@@sigue3:
						MOV		BX,OFFinEms
						SHR		BX,4
						MOV		CX,CS
						ADD		CX,BX
						MOV		[Buffer],CX
						ADD		BX,10H+1000H
						PUSH		BX
						MOV		ES,[PSP]
						MOV		AH,4AH
						INT		21H
						JNC		@@sigue4
						MOV		DX,OFFSET NoMem
						JMP		Error
	@@sigue4:
						MOV		DX,OFFSET EmsInt
						MOV		AX,2567H
						INT		21H
						MOV		DX,OFFSET FinStr
						CALL		Write
						POP		DX
						MOV		ES,[Buffer]
						XOR		AX,AX
						MOV		DI,AX
						CLD
						MOV		CX,2000H
						JMP		Adios

						ENDP

END	comienzo
