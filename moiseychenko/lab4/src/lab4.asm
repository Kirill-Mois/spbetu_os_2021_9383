ASSUME CS:CODE, DS:DATA, SS:MY_STACK

MY_STACK SEGMENT STACK
	DW 64 DUP(?)
MY_STACK ENDS

CODE SEGMENT


INTERRUPT PROC far
	jmp START_FUNCTION
	
	PSP_ADDRESS_0 DW 0
	PSP_ADDRESS_1 DW 0
	KEEP_CS DW 0
	KEEP_IP DW 0
	KEEP_SP DW 0
	KEEP_SS DW 0
	KEEP_AX DW 0
	INTERRUPT_SET DW 0FEDCh
	INT_COUNT DB 'Interrupts call count: 0000  $'
	BStack DW 64 DUP(?)

START_FUNCTION:
	mov KEEP_SP, sp
	mov KEEP_AX, ax
	mov KEEP_SS, ss
	mov sp, offset START_FUNCTION
	mov ax, seg BStack
	mov ss, ax

	push ax
	push bx
	push cx
	push dx

	mov ah, 03h
	mov bh, 00h
	int 10h
	push dx
	mov ah, 02h
	mov bh, 00h
	mov dx, 0220h 
	int 10h

	push si
	push cx
	push ds

	mov ax, SEG INT_COUNT
	mov ds, ax
	mov si, offset INT_COUNT
	add si, 1Ah
	mov ah,[si]
	inc ah
	mov [si], ah
	cmp ah, 3Ah
	jne END_CLC
	mov ah, 30h
	mov [si], ah

	mov bh, [si - 1]
	inc bh
	mov [si - 1], bh
	cmp bh, 3Ah
	jne END_CLC
	mov bh, 30h
	mov [si - 1], bh

	mov ch, [si - 2]
	inc ch
	mov [si - 2], ch
	cmp ch, 3Ah
	jne END_CLC
	mov ch, 30h
	mov [si - 2], ch

	mov dh, [si - 3]
	inc dh
	mov [si - 3], dh
	cmp dh, 3Ah
	jne END_CLC
	mov dh, 30h
	mov [si - 3],dh

END_CLC:
	pop ds
	pop cx
	pop si

	push es
	push bp

	mov ax, SEG INT_COUNT
	mov es, ax
	mov ax, offset INT_COUNT
	mov bp, ax
	mov ah, 13h
	mov al, 00h
	mov cx, 1Dh
	mov bh, 0
	int 10h

	pop bp
	pop es

	pop dx
	mov ah, 02h
	mov bh, 0h
	int 10h

	pop dx
	pop cx
	pop bx
	pop ax

	mov ss, KEEP_SS
	mov ax, KEEP_AX
	mov sp, KEEP_SP

	iret

INTERRUPT endp


MEMORY_AREA PROC
MEMORY_AREA endp


IS_INTERRUPT_SET PROC near
	push bx
	push dx
	push es

	mov ah, 35h
	mov al, 1Ch
	int 21h

	mov dx, es:[bx + 17]
	cmp dx, 0FEDCh
	je IS_INTER_SET
	mov al, 00h
	jmp POP_REG

IS_INTER_SET:
	mov al, 01h
	jmp POP_REG

POP_REG:
	pop es
	pop dx
	pop bx

	ret

IS_INTERRUPT_SET endp


IS_COMMAND_PROMT PROC near
	push es

	mov ax, PSP_ADDRESS_0
	mov es, ax

	mov bx, 0082h

	mov al, es:[bx]
	inc bx
	cmp al, '/'
	jne NULL_CMD

	mov al, es:[bx]
	inc bx
	cmp al, 'U'
	jne NULL_CMD

	mov al, es:[bx]
	inc bx
	cmp al, 'N'
	jne NULL_CMD

	mov al, 0001h
NULL_CMD:
	pop es

	ret
IS_COMMAND_PROMT endp


LOAD_INTERRUPT PROC near
	push ax
	push bx
	push dx
	push es

	mov ah, 35h
	mov al, 1Ch
	int 21h
	mov KEEP_IP, bx
	mov KEEP_CS, es

	push ds
    	mov dx, offset INTERRUPT
   	mov ax, seg INTERRUPT
    	mov ds, ax
    	mov ah, 25h
   	mov al, 1Ch
    	int 21h
	pop ds

	mov dx, offset INTERRUPT_LOADING
	call PRINT_STRING

	pop es
	pop dx
	pop bx
	pop ax

	ret
LOAD_INTERRUPT endp


UNLOAD_INTERRUPT PROC near
	push ax
	push bx
	push dx
	push es

	mov ah, 35h
	mov al, 1Ch
	int 21h

	cli
	push ds
	mov dx, es:[bx + 9]
	mov ax, es:[bx + 7]
	mov ds, ax
	mov ah, 25h
	mov al, 1Ch
	int 21h

	pop ds
	sti

	mov dx, offset INTERRUPT_RESTORED
	call PRINT_STRING

	push es
	mov cx, es:[bx + 3]
	mov es, cx
	mov ah, 49h
	int 21h
	pop es

	mov cx, es:[bx + 5]
	mov es, cx
	int 21h

	pop es
	pop dx
	pop bx
	pop ax

	ret

UNLOAD_INTERRUPT endp


PRINT_STRING PROC near
	push ax
   	mov ah, 09h
   	int 21h
	pop ax
   	ret
PRINT_STRING endp


MAIN PROC FAR
	mov bx, 02Ch
	mov ax, [bx]
	mov PSP_address_1, ax
	mov PSP_address_0, ds
	sub ax, ax
	sub bx, bx

	mov ax, DATA
	mov ds, ax

	call IS_COMMAND_PROMT
	cmp al, 01h
	je START_UNLOAD

	call IS_INTERRUPT_SET
	cmp al, 01h
	jne INTERRUPT_NOT_LOADED

	mov dx, offset INTERRUPT_LOADED
	call PRINT_STRING
	jmp EXIT_PR

	mov ah, 4Ch
	int 21h

INTERRUPT_NOT_LOADED:
	call LOAD_INTERRUPT

	mov dx, offset MEMORY_AREA
	mov cl, 04h
	shr dx, cl
	add dx, 1Bh

	mov ax, 3100h 
	int 21h

START_UNLOAD:
	call IS_INTERRUPT_SET
	cmp al, 00h
	je INTERRUPT_NOT_SET
	call UNLOAD_INTERRUPT
	jmp EXIT_PR

INTERRUPT_NOT_SET:
	mov dx, offset INT_NOT_SET
	call PRINT_STRING
    	jmp EXIT_PR

EXIT_PR:
	mov ah, 4Ch
	int 21h

MAIN endp


CODE ENDS


DATA SEGMENT
	INT_NOT_SET DB 'Interruption did not load.', 0dh, 0ah, '$'
	INTERRUPT_RESTORED DB 'Interruption was restored.', 0dh, 0ah, '$'
	INTERRUPT_LOADED DB 'Interruption is loaded.', 0dh, 0ah, '$'
	INTERRUPT_LOADING DB 'Interruption is loading.', 0dh, 0ah, '$'
DATA ENDS


END MAIN 
