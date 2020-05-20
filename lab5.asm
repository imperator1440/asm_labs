                                          
.model small

.stack 100h

.data
handle dw 0
filepath db 50 dup(0)
only_for_test db '$'
symbol db 0 

is_letter db 0
is_even db 1
is_end db 0

tmp_count dw 0
word_size dw 0
on_start db 0
tmp_symbol db 0
buffer db 10001 dup(0)
pos_ax dw 0
pos_dx dw 0
shift_pos dw 0

error_no_args db "Error, cant find arguments(File path)!$"
find_err db "Can't find file!",10,13,0,'$'
path_err db "Can't find file path!",10,13,0,'$' 
toomany_err db "To many opened file!",10,13,0,'$'
accessdenied_err db "Access denied!",10,13,0,'$'
incorrectacces_err db "Incorrect access mode!",10,13,0,'$'

.code
changeOffset MACRO min,newOffset
    local cnt_change,cnt_changeoffset
    mov ah,42h
    mov al,1
    mov bx,handle
    mov dx,newOffset
    mov cl,0
    cmp cl,min
    je cnt_change
    
    neg dx
    mov cx,0FFFFh  ; na levo
    jmp cnt_changeoffset
    
    cnt_change:
    mov cx,0
    
    cnt_changeoffset:
    int 21h
 ENDM
;=====================================================================================================================================================================================
;=====================================================================================================================================================================================
;=====================================================================================================================================================================================
print MACRO str ;adress of string in dx
    push ax 
    push dx
    mov dx,offset str
    mov ah, 09h
    int 21h
    pop dx
    pop ax
 ENDM
;=====================================================================================================================================================================================
;=====================================================================================================================================================================================
;=====================================================================================================================================================================================
openFile PROC
    jmp openFile_start 
    
    cant_find_error:
    print find_err
    mov is_end,1
    jmp openFile_fin
    
    path_error:
    print path_err
    mov is_end,1
    jmp openFile_fin
    
    toomany_error:
    print toomany_err
    mov is_end,1
    jmp openFile_fin
    
    access_error:
    print accessdenied_err
    mov is_end,1
    jmp openFile_fin
    
    accessmode_error:
    print incorrectacces_err
    mov is_end,1
    jmp openFile_fin
    
    openFile_start:
    mov dx, offset filepath ;address of file to dx
    mov al,2h ;openfile (read-only)
    mov ah,3dh
    int 21h ;call the interupt
    jc openFile_fin_err ;if error occurs, terminate program
    mov bx,ax ;put handler to file in bx
    mov handle,bx
    jmp openFile_fin
    
    openFile_fin_err:
    cmp ax, 02h
    je cant_find_error
    cmp ax,03h
    je path_error
    cmp ax,04h
    je toomany_error
    cmp ax,05h
    je access_error
    cmp ax,0Ch
    je accessmode_error
    
    openFile_fin:
    ;print filepath
    ret
openFile ENDP 
;=====================================================================================================================================================================================
;=====================================================================================================================================================================================
;=====================================================================================================================================================================================
deleteWords PROC
    push ax
    push bx
    push cx
    push dx
    
    mov pos_ax,0
    mov pos_dx,0

    for_4: 
    
    mov ah,42h
    mov al,0
    mov bx,handle
    mov cx,pos_dx
    mov dx,pos_ax
    int 21h

    call skip_spaces
    cmp is_end,1
    je myfunc_fin 
    
    call skip_word
    cmp is_end,1
    je myfunc_fin
    
    changeOffset 0,1   ; pravo
    mov pos_dx,dx
    mov pos_ax,ax
    changeOffset 1,1   ; levo

    call skip_spaces
    cmp is_end,1
    je myfunc_fin

    call delete_word
    jmp for_4
    
    myfunc_fin:
    mov ah,3Eh
    mov bx,handle
    int 21h
    
    pop dx 
    pop cx
    pop bx
    pop ax     
    ret
deleteWords ENDP
;=====================================================================================================================================================================================
;=====================================================================================================================================================================================
;=====================================================================================================================================================================================
delete_word PROC
    push ax
    push bx
    push cx
    push dx
    push bp
    jmp del_start
    
    cnt_delete_word1:
    mov ah,42h
    mov al,2
    mov bx,handle
    
    mov dx,word_size
    dec dx
    neg dx
    
    mov cx,0FFFFh  ;vlevo na word size
    int 21h
    
    mov on_start,1
    jmp cnt_delete_word2
    
    del_start:
    mov on_start,0
    mov word_size,0
    
    mov bx,handle
    
    for_5:
    mov cx,1;read one symbol 
    mov ah,3fh ;read from the opened file (its handler in bx)
    mov dx,offset tmp_symbol
    int 21h 
    
    cmp ax,0 
    je cnt_delete_word1
    
    inc word_size
    mov al,tmp_symbol
    
    call letter
    
    cmp is_letter,1
    je for_5
    changeOffset 1,1;-1
    
    cnt_delete_word2:
    call file_shift_left
    ;set offset of file(interrupt)
    
    delete_word_fin: 
    pop bp
    pop dx
    pop cx
    pop bx
    pop ax
    ret
delete_word ENDP
;=====================================================================================================================================================================================
;=====================================================================================================================================================================================
;=====================================================================================================================================================================================
file_shift_left PROC;speed up by using buffer 100x

    jmp shift_start
    
    fin_word_set_zero:
    ;in ax our actually readed string count
    mov tmp_count,ax

    mov shift_pos,ax
    mov ax,word_size
    add shift_pos,ax

    dec shift_pos;delete - trap

    changeOffset 1,shift_pos    ;levo

    mov cx,tmp_count;in tmp_count our saved string count without word size
    mov dx,offset buffer
    mov bx,handle
    mov ah,40h
    int 21h 
    ;then --> set 0 as file end
    
    mov ah,42h;cut file
    mov al,2
    mov bx,handle
    dec word_size
    mov dx,word_size
    neg dx
    mov cx,0FFFFh
    int 21h 

    finish_word:
    mov cx,0
    mov symbol,'!'
    mov dx,offset symbol
    mov bx,handle
    mov ah,40h
    int 21h
    jmp file_shift_left_fin

    fin_word_set_zero_tmp:
    jmp fin_word_set_zero
    ;jmp file_shift_left_fin
    shift_start:
    cmp on_start,1
    je finish_word

    mov shift_pos,10000      ;buffer
    mov ax,word_size
    add shift_pos,ax
    
    for_6:

    mov bx,handle
    mov cx,10000
    mov ah,3fh ;read from the opened file (its handler in bx)
    mov dx,offset buffer
    int 21h
    
    cmp ax,10000 ;esli end of file
    jb fin_word_set_zero_tmp
    
    ;change my pos in file 
    changeOffset 1,shift_pos   ;=10k + word size 
    changeOffset 0,1

    ;now we can print our symbol to file
    mov bx,handle    
    mov cx,10000
    mov ah,40h
    mov dx,offset buffer   ;zapi's v file i udalenie slova
    int 21h 
    
    ;pos++{just so}
    changeOffset 0,word_size
    changeOffset 1,1
    jmp for_6
    
    file_shift_left_fin:
    ret
file_shift_left ENDP
;=====================================================================================================================================================================================
;=====================================================================================================================================================================================
;=====================================================================================================================================================================================
skip_spaces PROC
    push ax
    push bx
    push cx
    push dx
    push bp
    
    mov bx,handle
    jmp for_1
    
    skip_spaces_fin_set:
    mov is_end,1
    jmp skip_spaces_fin

    for_1:
    mov cx,1;read one symbol
    mov ah,3fh ;read from the opened file (its handler in bx)
    mov dx,offset tmp_symbol
    int 21h 
    
    cmp ax,0
    je skip_spaces_fin_set
    
    mov al,tmp_symbol
    
    call letter
    cmp is_letter,0
    je for_1
    
    changeOffset 1,1;-1
    
    skip_spaces_fin: 
    pop bp
    pop dx
    pop cx
    pop bx
    pop ax
    ret
skip_spaces ENDP
;=====================================================================================================================================================================================
;=====================================================================================================================================================================================
;=====================================================================================================================================================================================
skip_word PROC
    push ax
    push bx
    push cx
    push dx
    push bp
    
    mov bx,handle
    jmp for_3

    skip_word_fin_set:
    mov is_end,1
    jmp skip_word_fin

    for_3:
    mov cx,1;read one symbol
    mov ah,3fh ;read from the opened file (its handler in bx)
    mov dx,offset tmp_symbol
    int 21h 
    
    cmp ax,0
    je skip_word_fin_set
    
    mov al,tmp_symbol
    
    call letter
    cmp is_letter,1
    je for_3
    
    skip_word_fin: 
    pop bp
    pop dx
    pop cx
    pop bx
    pop ax
    ret
skip_word ENDP
;=====================================================================================================================================================================================
;=====================================================================================================================================================================================
;=====================================================================================================================================================================================
letter PROC
    mov is_letter,0
    
    cmp al,'A'
    jb letter_fin
    cmp al,'Z'
    ja lower_eng
    
    mov is_letter,1
    jmp letter_fin
    
    lower_eng:
    cmp al,'a'
    jb letter_fin
    cmp al,'z'
    ja letter_fin
    
    mov is_letter,1
    
    letter_fin:
    ret
letter ENDP
;=====================================================================================================================================================================================
;=====================================================================================================================================================================================
;=====================================================================================================================================================================================
start:
mov ax,@data
mov ds,ax

jmp start_main

terminate_prnt:
print error_no_args
jmp terminate

start_main:
    mov cl,es:80h  ;comand line
    cmp cl,1  
    jbe terminate_prnt
 
    mov si,81h 
    ;cld
    xor di,di

    inc si
    dec cl
   
    get_parm:
    mov al, es:si
     inc si
    mov [filepath + di] , al 

    inc di
    loop get_parm

call openFile
cmp is_end,1
je terminate

call deleteWords

terminate: 
    
    mov ax, 4c00h
    int 21h
    int 20h
    ends
end start