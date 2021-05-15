ASTACK SEGMENT STACK
   DW 256 DUP(?)
ASTACK ENDS

DATA SEGMENT
    exec_param_block dw 0
    cmd_off dw 0 ; сегмент командной строки
    cmd_seg dw 0 ; смещение командной строки
    fcb1 dd 0 ; сегмент и смещение первого FCB
    fcb2 dd 0 ; сегмент и смещение второго FCB

    child_cmd_line db 1h, 0dh
    second_module_name db 'lab2_1.com', 0h
    second_module_path db 128 DUP(0)

    keep_ss dw 0
    keep_sp dw 0

    error_mem_free db 0
    mcb_crash_string db 'Error: Memory Control Block has crashed', 0DH, 0AH, '$'
    not_enough_memory_string db 'Error: Not Enough Memory', 0DH, 0AH, '$'
    wrong_address_string db 'Error: Wrong Address', 0DH, 0AH, '$'
    free_without_error_string db 'Freed successfully', 0DH, 0AH, '$'
    child_error_function_number db 'Error: Function number is incorrect', 0DH, 0AH, '$'
    child_error_file_not_found db 'Error: File is not found', 0DH, 0AH, '$'
    child_error_disk_error db 'Error: Disk error', 0DH, 0AH, '$'
    child_error_not_enough_mem db 'Error: Not enough memory', 0DH, 0AH, '$'
    child_error_path_string db 'Error: Path param error', 0DH, 0AH, '$'
    child_error_wrong_format db 'Error: Wrong Format', 0DH, 0AH, '$'
    child_std_exit db 'Child program finished: Exited With Code   ', 0DH, 0AH, '$'
    child_ctrl_exit db 'Child program finished: Ctrl+Break Exit', 0DH, 0AH, '$'
    child_device_error_exit db 'Child program finished: Device Error Exit', 0DH, 0AH, '$'
    child_int31h_exit db 'Child program finished: became resident, int 31h Exit', 0DH, 0AH, '$'


    data_end db 0
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:ASTACK

    WRITEWRD  PROC  NEAR
        push ax
        mov ah, 9
        int 21h
        pop ax
        ret
    WRITEWRD  ENDP

    WRITEBYTE  PROC  NEAR
        push ax
        mov ah, 02h
        int 21h
        pop ax
        ret
    WRITEBYTE  ENDP

    ENDLINE PROC NEAR
        push ax
        push dx
        mov dl, 0dh
        call WRITEBYTE
        mov dl, 0ah
        call WRITEBYTE
        pop dx
        pop ax
        ret
    ENDLINE ENDP

    FREE_UNUSED_MEMORY PROC FAR
        push ax
        push bx
        push cx
        push dx
        push es
        xor dx, dx
        mov error_mem_free, 0h
        mov ax, offset data_end
        mov bx, offset lafin
        add ax, bx
        mov bx, 10h
        div bx
        add ax, 100h
        mov bx, ax
        xor ax, ax
        mov ah, 4ah
        int 21h 
        jnc free_without_error
	    mov error_mem_free, 1h
    ;mcb crash
        cmp ax, 7
        jne not_enough_memory
        mov dx, offset mcb_crash_string
        call WRITEWRD
        jmp free_unused_memory_end

    not_enough_memory:
        cmp ax, 8
        jne wrong_address
        mov dx, offset not_enough_memory_string
        call WRITEWRD
        jmp free_unused_memory_end	

    wrong_address:
        cmp ax, 9
        jne free_unused_memory_end
        mov dx, offset wrong_address_string
        call WRITEWRD
        jmp free_unused_memory_end

    free_without_error:
        mov dx, offset free_without_error_string
        call WRITEWRD
        
    free_unused_memory_end:
        pop es
        pop dx
        pop cx
        pop bx
        pop ax
        ret

    FREE_UNUSED_MEMORY ENDP
        

    LOAD_MODULE PROC FAR
        push ax
        push bx
        push cx
        push dx
        push ds
        push es
        mov keep_sp, sp
        mov keep_ss, ss
        call GET_PATH
        mov ax, data
        mov es, ax
        mov bx, offset exec_param_block
        mov dx, offset child_cmd_line
        mov cmd_off, dx
        mov cmd_seg, ds 
        mov dx, offset second_module_path
        mov ax, 4b00h 
        int 21h 
        mov ss, keep_ss
        mov sp, keep_sp
        pop es
        pop ds

        call ENDLINE

      jnc loaded_successfully

    ;function number error
        cmp ax, 1
	    jne load_file_not_found
	    mov dx, offset child_error_function_number
	    call WRITEWRD
	    jmp load_module_end
    
    load_file_not_found:
        cmp ax, 2
	    jne load_disk_error
	    mov dx, offset child_error_file_not_found
	    call WRITEWRD
	    jmp load_module_end

    load_disk_error:
        cmp ax, 5
	    jne load_not_enough_memory
	    mov dx, offset child_error_disk_error
	    call WRITEWRD
	    jmp load_module_end

    load_not_enough_memory:
        cmp ax, 8
	    jne load_path_error
	    mov dx, offset child_error_disk_error
	    call WRITEWRD
	    jmp load_module_end

    load_path_error:
        cmp ax, 10
	    jne load_wrong_format
	    mov dx, offset child_error_path_string
	    call WRITEWRD
	    jmp load_module_end
    load_wrong_format:
        cmp ax, 11
	    jne load_module_end
	    mov dx, offset child_error_wrong_format
	    call WRITEWRD
	    jmp load_module_end

    loaded_successfully:
        mov ax, 4d00h 
	    int 21h
    ;std_exit
        cmp ah, 0
	    jne ctrl_exit
	    mov di, offset child_std_exit
        add di, 41
        mov [di], al
        mov dx, offset child_std_exit
	    call WRITEWRD
	    jmp load_module_end

    ctrl_exit:
        cmp ah, 1
	    jne device_error_exit
	    mov dx, offset child_ctrl_exit
	    call WRITEWRD
	    jmp load_module_end

    device_error_exit:
        cmp ah, 2
	    jne int31h_exit
	    mov dx, offset child_device_error_exit
	    call WRITEWRD
	    jmp load_module_end

    int31h_exit:
        cmp ah, 3
	    jne load_module_end
	    mov dx, offset child_int31h_exit
	    call WRITEWRD
	    jmp load_module_end

    load_module_end:
        pop dx
        pop cx
        pop bx
        pop ax
        ret

    LOAD_MODULE ENDP

    GET_PATH PROC NEAR

        push ax
        push dx
        push es
        push di
        xor di, di
        mov ax, es:[2ch]
        mov es, ax

    content_loop:
        mov dl, es:[di]
        cmp dl, 0
        je end_string2
        inc di
        jmp content_loop

    end_string2:

        inc di
        mov dl, es:[di]
        cmp dl, 0
        jne content_loop
        call PARSE_PATH
        pop di
        pop es
        pop dx
        pop ax
        ret

    GET_PATH ENDP

    PARSE_PATH PROC NEAR

        push ax
        push bx
        push bp
        push dx
        push es
        push di
        mov bx, offset second_module_path
        add di, 3

    boot_loop:
        mov dl, es:[di]
        mov [bx], dl
        cmp dl, '.'
        je parse_to_slash
        inc di
        inc bx
        jmp boot_loop

    parse_to_slash:
        mov dl, [bx]
        cmp dl, '\'
        je get_second_module_name
        mov dl, 0h
        mov [bx], dl
        dec bx
        jmp parse_to_slash
    get_second_module_name:
        mov di, offset second_module_name
        inc bx

    add_second_module_name:
        mov dl, [di]
        cmp dl, 0h
        je parse_path_end
        mov [bx], dl
        inc bx
        inc di
        jmp add_second_module_name

    parse_path_end:
        mov [bx], dl

        pop di
        pop es
        pop dx
        pop bp
        pop bx
        pop ax
        ret

    PARSE_PATH ENDP

    MAIN PROC FAR
        mov ax, data
        mov ds, ax
        call FREE_UNUSED_MEMORY
        cmp error_mem_free, 0h
        jne main_end
        call GET_PATH
        call LOAD_MODULE

    main_end:
        xor al, al
        mov ah, 4ch
        int 21h

    MAIN ENDP

lafin:
CODE ENDS

END MAIN