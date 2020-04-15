    .stack 100h

    .data
    matrix dw 30 dup(?)
    sum dw 0000 
    raws db 5 
    size db 30   
    t db 5
    Buffer db 9 DUP(?)
    newline db 0ah, 0dh, '$'  
    notanumber db "error: not a number!$"
    instr db "enter number:",0Dh,0Ah,'$'
    overflowError db "overflow enter!$"
    overflowFlag db 0
    errorSumOverflow db "overflow sum!$"                                     
     
    .code       
         
    printStr macro string
    push dx
    push ax
    lea dx, string
    mov ah, 09H
    int 21h
    pop ax
    pop dx
    endm     
         
    printsum proc
    push si
    push cx
    push ax
    push dx

    lea si, sum
    xor cx, cx
    call toString
    printStr Buffer
    mov ah, 02h
    mov dl, ' '
    int 21h
    add si, 2
    printStr newline
    pop dx
    pop ax
    pop cx
    pop si
    ret
    printsum endp   
    
    modul proc ;AX contains number     
    push ax
    and ax, 8000h ;perevod v polozhit
    jz done  

    pop ax
    xor ax, -1
    inc ax
    push ax   
    
    done:  
    pop ax   
    ret
    modul endp
    
    toString proc ;SI points to number
    push ax
    push cx
    push di
    push dx

    xor di, di
    mov ax, [si]
    cmp ax, -1   ;>0
    jg posit
    mov Buffer[di], '-'
    inc di
    call modul   ;obratno v polozhit
    posit:
    mov cx, 10
    toStringLoop:
        xor dx, dx
        div cx      ;dx - ostatok
        add dx, '0'
        mov Buffer[di], dl  ;stavim chislo
        inc di
    cmp ax, 0
    jne toStringLoop
    mov Buffer[di], '$'

    call reverse

    pop dx
    pop di
    pop cx
    pop ax
    ret
    toString endp   
    
 reverse proc
    push ax
    push di
    push si

    xor di, di
    mov ah, Buffer[di]
    cmp ah, '-'
    jne getSI
    inc di  
    
    getSI:
    mov si, di
    siLoop:
        cmp Buffer[si], '$'
        je loopFin
        inc si
    jmp siLoop
    loopFin:
    dec si

    reverseLoop:
        mov al, Buffer[si]
        mov ah, Buffer[di]
        mov Buffer[si], ah
        mov Buffer[di], al
        inc di
        dec si
    cmp di, si
    jl reverseLoop
    pop si
    pop di
    pop ax
    ret
    reverse endp
    
    getStr proc
        push si
        mov si, dx
        mov [si], 7 ; size

        mov ah, 0Ah
        int 21h 

        xor ax, ax
        inc si
        LODSB ; download in al
 
        add si, ax
        mov [si + 1], '$'
   
        pop si
        ret
    getStr endp
    
    atoi proc
    push di
    push si
    push bx

    xor si, si
    mov si, 2
    cmp Buffer[si], '-'
    jne positive
    mov di, 1
    inc si

    positive:
        cmp Buffer[si], '0'
        jb notANumberloop
        cmp Buffer[si], '9'
        ja notANumberloop
    
    xor ax, ax
    mov cx, 10
    atoiLoop:                          
        xor bx, bx
        mov bl, Buffer[si]

        cmp bl, '0'
        jb parsed
        cmp bl, '9'
        ja parsed

        sub bl, '0'
        mul cx
        cmp dl, 0      ;rezultat mul perepolnenie
        jg overflow
        add ax, bx
        
        mov bx, ax
        and bx, 8000h
        jnz overflow  

        inc si
    jmp atoiLoop

    overflow:
        cmp di, 1
        jne error
        cmp ax, 8000h
        je parsed
        error:
        printStr overflowError     
        printStr newline
        jmp finish
    notANumberloop:
        printStr NotANumber  
        printStr newline
        jmp finish

    parsed:      
        xor cx, cx
        cmp di, 1      ;otricatelnoe
        jne finish       
        xor ax, -1
        inc ax
    finish:
    pop dx
    pop si
    pop di 
    ret
    atoi endp
    
    start:
        mov ax, @DATA
        mov ds, ax   
        xor si, si  
        xor cx, cx
        mov cl, size
    entermatrix:
        printStr instr   
        lea dx, Buffer
        call getStr
        printStr newline
        push cx
        call atoi          
        cmp cx, 0  
        pop cx
        jne entermatrix  
        
        mov matrix[si], ax  
        add si, 2      ;next element
        inc size
     
        next:
        dec size
    loop entermatrix 
    
    dec si
    dec si 
    newraw:
    xor cl, cl   
    mov cl, 6
    sumLoop:
      
        mov dx, matrix[si]
        mov ax, sum
        add ax, dx
        jo sumOverflow
        mov sum, ax
        sub si, 2    
        
    loop sumLoop   
    call printsum  
    mov sum, 0
    jmp  nextsum 
      
    
    sumOverflow:
    mov overFlowFlag, 1 
    printStr errorSumOverflow
    
    nextsum:
    dec raws
    cmp raws, 0 
    jne newraw 
   
    ends
    end start ; set entry point and stop the assembler.

