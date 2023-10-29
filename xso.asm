; XSO
; Created by gzalo for Flashparty 2023 (my first intro!)

org 100h

start:
    mov al, 0x13
    int 0x10         ; Set 320x200x256 video mode

    push word 0xA000 ; DS:0 -> Start of video memory
    pop ds

mainLoop:
    in al, 0x40
    mov cl, al ; Read random byte to cl (Ypos, also color and wordIndex)
    in al, 0x40
    mov ch, al ; Read random byte to ch (Xpos)
    
    xor di, di ; DI: pixel pos (0-65536)
    
drawOctogon: ; uses AX (various), bx (second distance), CX (random word), DI
    mov ax, di
    mov bx, 320
    xor dx, dx
    div bx 
    mov bx, dx ; BX: x (0-319)
    ; AX: y (0-199)

    movzx dx, cl
    sub ax, dx ; AX = y-yorigin

    ;AX = abs(AX), trashes dx
    cwd ; dx:ax = ax extended (dx = 0xFFFF if negative else 0)
    xor ax, dx ; nots ax if it was negative
    sub ax, dx ; adds 1 (subtracts 0xFFFF) if ax was negative
    xchg si, ax ; deltaY in si
    
    movzx ax, ch
    add ax, 48 ; Centers a bit better horizontally 
    sub ax, bx ; AX = (xorigin+48)-x

    ;AX = abs(AX), trashes dx
    cwd ; dx:ax = ax extended (dx = 0xFFFF if negative else 0)
    xor ax, dx ; nots ax if it was negative
    sub ax, dx ; adds 1 (subtracts 0xFFFF) if ax was negative
    
    ;calculate third distance for octogonal edges
    ; (dx+dy)/sqrt(2) ~ (dx+dy)*3/4:
    ;AX, BX, SI containing deltax, deltay, 45deg calc
    mov bx, ax
    lea ax, [bx+si] ; AX=(deltax+deltay)
    imul ax, ax, 3 ; AX = 3(deltax+deltay)
    sar ax, 2 ; ax=3/4*(deltax+deltay)

    ; get max component ("octogonal distance")
    ; ax = max(ax, si)
    cmp bx, ax
    jb skipswap1
    xchg ax, bx
skipswap1:
    ; ax = max(ax, si)
    cmp si, ax
    jb skipswap2
    xchg ax, si
    
skipswap2:
    mov bl, ch ; color

    ; ax = octogonal distance
    cmp ax, 50   ; if(dist>50) skip
    ja nextpixel

    cmp al, 48   ; if(dist>48) outer ring
    jb nextcheck 

    jmp writenextpixel
nextcheck:
    cmp al, 42   ; if(dist<42)
    ja nextpixel2

    in al, 0x40 ; Random delta for pixel colors inside octogon
    aam 128 ; Keep only lsb
    add bl, ah

    jmp writenextpixel
nextpixel2:
    mov bl, 15  ; write white for inner ring
writenextpixel: 
    mov byte [ds:di], bl
nextpixel:
    inc di
    jnz drawOctogon

    ; ONLY CX has to be preserved from now on

    ; Draw text 
    mov ax, cx
    aam 5 ; Divide AX by 5 (remainder in AL)

    movzx dx, al ; texLen = idx + 3, has to be mov, no xchg
    add dl, 3
    
    ; Polynomial for indexing word start:
    ; 0 -> 0
    ; 1 -> 3
    ; 2 -> 7
    ; textStart = words + (wordIdx+5)*wordIdx/2;
    mov bl, al ; has to be mov, no xchg
    add bl, 5
    mul bl
    sar al, 1
    add ax, words
    
    xchg bp, ax
    pusha
    call drawText   ; Draw word
    popa
    
    ; Copy text to place - DI=text initial pixel
    movzx ax, cl
    add al, 16
    imul ax, ax, 320
    movzx bx, ch
    add ax, bx
    add ax, 48

    push ax
    shl dx, 2     ; Multiply by 4 to align in center of octogons
    sub ax, dx

    xchg di, ax
    call copyText

    mov bp, text    ; Draw "EXCESO DE"
    mov dl, 9
    call drawText

    ; Copy text to place - DI=text initial pixel
    pop di
    sub di, 320*25+34 ; Offset in relation to previous text
    call copyText
    
    ; Check ESC key
    in al, 0x60
    dec al
    jnz mainLoop
    ret

drawText: ; Draw text at top left of screen (first line), [es:bp] text, dl is text length
    mov ax, 0x1300
    mov bx, 0x00FF
    movzx cx, dl
    xor dx, dx
    int 0x10
    ret

copyText: ; Copies text from top left (first line) to a certain position - DI: dst position, trashes si
    mov si, 320*8
    step:
    cmp byte[ds:si],0xFF
    mov byte[ds:si],0    ; Fill source with black
    jne cont
    mov byte[ds:di],15
    cont:
    dec di
    dec si
    jnz step
    ret

section .data
align 1
text: db "EXCESO DE"
words: db "N",159,"TWEB3CL",233,"UDCR",157,"PTO",225,"IGDATA"
