TESTPC SEGMENT
		ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		ORG 100H
START: JMP BEGIN
; ДАННЫЕ

AVAILABLE_MEMORY DB 'Available memory: ', '$'
EXTENDED_MEMORY DB 'Extended memory: ', '$'
STRING_BYTE DB ' byte ', '$'
MCB_TABLE DB 'MCB table: ', 0DH, 0AH, '$'
ADDRESS DB 'Address:     ', '$'
PSP_ADDRESS DB 'PSP address:      ', '$'
STRING_SIZE DB 'Size: ', '$'
SC_SD DB 'SC/SD: ', '$'
NEW_STRING DB 0DH,0AH,'$'
SPACE_STRING DB ' ', '$'
MEMORY_REQUEST_FAIL DB 'Memory request failed', 0DH, 0AH, '$'
MEMORY_REQUEST_SUCCESS DB 'Memory request succeeded', 0DH, 0AH, '$'

;ПРОЦЕДУРЫ
;-----------------------------------------------------
TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
; байт в AL переводится в два символа шестн. числа в AX
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX ;в AL старшая цифра
	pop CX ;в AH младшая
	ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
	push BX
	mov BH,AH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	dec DI
	mov AL,BH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	pop BX
	ret
WRD_TO_HEX ENDP
;--------------------------------------------------
BYTE_TO_DEC PROC near
; перевод в 10с/с, SI - адрес поля младшей цифры
	push CX
	push DX
	xor AH,AH
	xor DX,DX
	mov CX,10
loop_bd: div CX
	or DL,30h
	mov [SI],DL
	dec SI
	xor DX,DX
	cmp AX,10
	jae loop_bd
	cmp AL,00h
	je end_l
	or AL,30h
	mov [SI],AL
end_l: pop DX
	pop CX
	ret
BYTE_TO_DEC ENDP
;-------------------------------

WRITE_STR PROC near
	push ax
	mov ah,9h
	int 21h
	pop ax
	ret
WRITE_STR ENDP

PARAGRAPHS_TO_BYTES PROC
	mov bx, 0ah
	xor cx, cx

division_loop:
	div bx
	push dx
	inc cx
	sub dx, dx
	cmp ax, 0h
	jne division_loop

write_symbol:
	pop dx			
	add dl,30h		
	mov ah,02h
	int 21h
			
	loop write_symbol

	ret

PARAGRAPHS_TO_BYTES ENDP


MEMORY_AVAILABLE PROC near
	mov dx, offset AVAILABLE_MEMORY
	call WRITE_STR
	mov ah, 4ah
	mov bx, 0ffffh 
	int 21h        
	mov ax, bx
	mov bx, 16
	mul bx		
	call PARAGRAPHS_TO_BYTES

	mov dx, offset STRING_BYTE
	call WRITE_STR

	mov dx, offset NEW_STRING
	call WRITE_STR

	ret
MEMORY_AVAILABLE ENDP


MEMORY_EXTENDED proc near
    mov al, 30h
    out 70h, al
    in al, 71h
   	
	mov al, 31h
    out 70h, al
    in al, 71h
    mov ah, al		
	mov bh, al
	mov ax, bx	
	
	mov dx, offset EXTENDED_MEMORY
	call WRITE_STR

	mov bx, 010h
	mul bx

	call PARAGRAPHS_TO_BYTES 

	mov dx, offset STRING_BYTE
	call WRITE_STR

	mov dx, offset NEW_STRING
	call WRITE_STR

	ret
MEMORY_EXTENDED ENDP


MCB PROC near
	mov ah, 52h
	int 21h
	mov ax, es:[bx-2]
	mov es, ax
	mov dx, offset MCB_TABLE
	call WRITE_STR

MCB_loop:
    mov ax, es                 ;адрес
    mov di, offset ADDRESS
    add di, 12
    call WRD_TO_HEX
    mov dx, offset ADDRESS
    call WRITE_STR
	mov dx, offset SPACE_STRING
	call WRITE_STR

	mov ax, es:[1]             ;psp адрес
	mov di, offset PSP_ADDRESS
	add di, 16
	call WRD_TO_HEX
	mov dx, offset PSP_ADDRESS
	call WRITE_STR

	mov dx, offset STRING_SIZE  ;размер
	call WRITE_STR	
	mov ax, es:[3] 
	mov di, offset STRING_SIZE 
	add di, 6
	mov bx, 16
	mul bx
	call PARAGRAPHS_TO_BYTES 
	mov dx, offset SPACE_STRING
	call WRITE_STR

	mov bx, 8                    ;SC/SD
	mov dx, offset SC_SD
	call WRITE_STR
	mov cx, 7

SC_SD_loop:
	mov dl, es:[bx]
	mov ah, 02h
	int 21h
	inc bx
	loop SC_SD_loop
	
	mov dx, offset NEW_STRING 
 	call WRITE_STR
	
	mov bx, es:[3h]
	mov al, es:[0h]
	cmp al, 5ah
	je MCB_END

	mov ax, es
	inc ax
	add ax, bx
	mov es, ax
	jmp MCB_loop

MCB_END:
	ret

MCB ENDP


FREE_UNUSED_MEMORY PROC near
    mov ax, cs
    mov es, ax
    mov bx, offset TESTPC_END
    mov ax, es
    mov bx, ax
    mov ah, 4ah
    int 21h
    ret
FREE_UNUSED_MEMORY ENDP


MEMORY_REQUEST PROC near
    mov bx, 1000h
    mov ah, 48h
    int 21h
    
    jb memory_fail
    jmp memory_success

memory_fail:   
    mov dx, offset MEMORY_REQUEST_FAIL 
    call WRITE_STR
    jmp memory_request_end

memory_success:
    mov dx, offset MEMORY_REQUEST_SUCCESS
    call WRITE_STR

memory_request_end:    
    ret

MEMORY_REQUEST ENDP


BEGIN:
	call MEMORY_REQUEST
	call MEMORY_AVAILABLE
	call MEMORY_EXTENDED
	call FREE_UNUSED_MEMORY
	call MCB

; Выход в DOS
	xor al, al
    mov ah, 4ch
    int 21h

TESTPC_END:
TESTPC ENDS
	END START
