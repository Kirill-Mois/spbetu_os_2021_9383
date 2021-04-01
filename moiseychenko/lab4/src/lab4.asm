AStack	SEGMENT STACK
	DB 256 DUP(?)
AStack ENDS

DATA	SEGMENT

	flag DB 0
	interrupt_was_loaded_string DB 'Interrupt was loaded', 0DH, 0AH,'$'
	interrupt_was_unloaded_string DB 'Interrupt was unloaded', 0DH, 0AH,'$'
	interrupt_not_loaded_string DB 'Interrupt has not been loaded', 0DH, 0AH,'$'
	interrupt_already_loaded_string DB 'Interrupt has already been loaded', 0DH, 0AH,'$'

DATA	ENDS

CODE	SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:AStack


MY_INTERRUPT	PROC far
	jmp start_interrupt
	
	ID DW 0FFFFh
	PSP DW ?
	
	KEEP_IP DW 0
	KEEP_CS DW 0
	KEEP_SS DW 0
	KEEP_SP DW 0
	KEEP_AX DW 0

	INT_COUNTER DB 'Number of iterrups: 0000$'
	
	INT_STACK DW 128 DUP (?)
END_INT_STACK:
	
start_interrupt:
	mov KEEP_SS, SS
	mov KEEP_SP, SP
	mov KEEP_AX, AX
	
	mov AX, CS
	mov SS, AX
	mov SP, OFFSET END_INT_STACK
	
	push BX
	push CX
	push DX

	; получение курсора
	
	mov AH, 3h
	mov BH, 0h
	int 10h
	push DX
	
	; установка курсора
	
	mov AH, 2h
	mov BH, 0h
	mov DH, 2h
    mov DL, 5h
	int 10h
	
    push BP
	push SI
	push CX
	push DS

    mov AX, seg INT_COUNTER
    mov DS, AX
    mov SI, offset INT_COUNTER
    add SI, 20
    mov CX, 4
	
incr:
	mov BP, CX
	mov AH, [SI+BP]
	inc AH
	mov [SI+BP], AH
	cmp AH, 3Ah
	jne good
	mov AH, 30h
	mov [SI+BP], AH
	loop incr
	
good:
    pop DS
	pop CX
	pop SI
	
	push ES
	mov DX, SEG INT_COUNTER
	mov ES, DX
	mov BP, OFFSET INT_COUNTER
	mov AH, 13h
	mov AL, 0h
	mov CX, 24
	mov DX, 0h
	int 10h
	
	pop ES
	pop BP
	
	; возврат курсора
	
	mov AH, 02h
	mov BH, 0h
	pop DX
	int 10h
	
	pop DX
	pop CX
	pop BX
	
	mov AX, KEEP_SS
	mov SS, AX
	mov AX, KEEP_AX
	mov SP, KEEP_SP
	mov AL, 20h
	out 20h, AL
	
	iret
end_my_interrupt:
MY_INTERRUPT	endp



LOAD	PROC near
	
	push    AX
	push    CX
	push    DX

	mov     AH, 35h
	mov     AL, 1Ch
	int     21h
	mov     KEEP_IP, BX
	mov     KEEP_CS, ES
	
    push    DS
    mov     DX, OFFSET MY_INTERRUPT
    mov     AX, SEG MY_INTERRUPT
    mov     DS, AX
    mov     AH, 25h
    mov     AL, 1Ch
    int     21h
    pop     DS
	
    mov     DX, OFFSET END_INT_STACK
    mov     CL, 4
    shr     DX, CL
    inc     DX
    mov     AX, CS
    sub     AX, PSP
    add     DX, AX
    xor     AX, AX
    mov     AH, 31h
    int     21h
    pop     DX
    pop     CX
    pop     AX
    ret
        
LOAD	endp
	


UNLOAD	PROC near

        push    AX
        push    DX
        push    SI
        push    ES
	
        cli
        push    DS
        mov     AH, 35h
        mov     AL, 1Ch
        int     21h
        mov     SI, OFFSET KEEP_CS
        sub     SI, OFFSET MY_INTERRUPT
        mov     DX, ES:[BX+SI+2]
        mov     AX, ES:[BX+SI]
        mov     DS, AX
        mov     AH, 25h
        mov     AL, 1Ch
        int     21h
        pop     DS
        mov     AX, ES:[BX+SI-2]
        mov     ES, AX
        push    ES
        mov     AX, ES:[2Ch]
        mov     ES, AX
        mov     AH, 49h
        int     21h
        pop     ES
        mov     AH, 49h
        int     21h
        sti
        pop     ES
        pop     SI
        pop     DX
        pop     AX
        ret
        
UNLOAD	endp



LOAD_FLAG	PROC near

        push    AX
        mov     AL, ES:[82h]
        cmp     AL, '/'
        jne     end_load_flag
        mov     AL, ES:[83h]
        cmp     AL, 'u'
        jne     end_load_flag
        mov     AL, ES:[84h]
        cmp     AL, 'n'
        jne     end_load_flag
        mov     flag, 1h
end_load_flag: 
	pop     AX

LOAD_FLAG	endp



IS_LOAD	PROC near

        push    AX
        push    DX
        push    SI
        mov     flag, 1h
        mov     AH, 35h
        mov     AL, 1Ch
        int     21h
        mov     SI, OFFSET ID
        sub     SI, OFFSET MY_INTERRUPT
        mov     DX, ES:[BX+SI]
        cmp     DX, 0FFFFh
        je      loading
        
        mov     flag, 0
loading:     
	    pop     SI
        pop     DX
        pop     AX
        ret
        
IS_LOAD	endp



PRINT_STR	PROC near
        push    AX
        mov     AH, 09h
        int     21h
        pop     AX
        ret
PRINT_STR	endp



MAIN	PROC far

        mov     AX, DATA
        mov     DS, AX
        mov     PSP, ES
        mov     flag, 0
        call    LOAD_FLAG
        cmp     flag, 1
        je      un
        
	; loading
	
        call    IS_LOAD
        cmp     flag, 0
        je      notld
        mov     DX, OFFSET interrupt_already_loaded_string
        call    PRINT_STR
        jmp     fin
       
notld:  mov     DX, OFFSET interrupt_was_loaded_string
        call    PRINT_STR
        call    LOAD
        jmp     fin
        
	; unloading

un:     call    IS_LOAD
        cmp     flag, 0
        jne     alrld
        mov     DX, OFFSET interrupt_not_loaded_string
        call    PRINT_STR
        jmp     fin
        
alrld:  call    UNLOAD
        mov     DX, OFFSET interrupt_was_unloaded_string
        call    PRINT_STR
        
fin:    mov     AX, 4Ch    ; завершение
        int     21h
        
MAIN	endp
CODE	ENDS
	END	MAIN