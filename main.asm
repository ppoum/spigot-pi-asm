%define GET_DEN(n)  2*n+1
%define ARRAY_ADDR(i) array+4*i

%define DIGIT_COUNT 100000
%define LENGTH 4*DIGIT_COUNT


section .data
    align 2
    digits_str: db '0123456789ABCDEF'
    array: times LENGTH dd 2
    printed_period: db 0
    held_count: db 0

section .bss
    align 2
    held: resd DIGIT_COUNT

section .text
global _start
_start:

    ; Initialize loop counter
    mov rbx, 0
    LOOP_START:

    call mult_array
    call reduce_array
    call extract_digit      ; pi digit in ax

    inc rbx
    cmp rbx, DIGIT_COUNT
    jl LOOP_START           ; loop DIGIT_COUNT times


    ; Print newline
    mov rdi, 10
    call print_char
    mov rdi, 0
    jmp exit_prog


itoa:
    ;
    ; Params
    ; rdi: Digit to convert to ASCII
    ; Return
    ; rax: ASCII repr of digit
    push rbx
    lea rbx, [digits_str + rdi]
    mov al, byte [rbx]
    pop rbx
    ret



print_char:
    ;
    ; Params
    ; rdi: Character to print
    
    ; Save regs to stack
    push rsi
    push rax
    push rdx
    push rdi

    mov rsi, rsp    ; top of stack has char, point to that
    mov rax, 0x01   ; syscall #
    mov rdi, 1      ; FD (stdout)
    mov rdx, 1      ; length (1 char only)
    syscall

    ; Restore stack
    pop rdi
    pop rdx
    pop rax
    pop rsi
    ret


mult_array:
    push rax
    push rbx
    push rcx
    push rdx

    mov rbx, 0
    MULT_LOOP_START:
    lea rcx, [ARRAY_ADDR(rbx)]
    mov eax, dword [rcx]
    mov rdx, 10
    mul rdx                     ; Multiply rax by 10
    mov dword [rcx], eax        ; Write multiplied value back into array

    inc rbx
    cmp rbx, LENGTH             ; Iterate LENGTH times (once per array index)
    jl MULT_LOOP_START

    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret


reduce_array:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi

    mov ebx, dword LENGTH       ; Loop from n-1 to 1 (inclusive), cover all indexes of array
    REDUCE_LOOP_START:
    dec rbx

    lea rcx, [ARRAY_ADDR(rbx)]
    mov eax, dword [rcx]        ; rax <- array[n]
    test eax, eax
    jz REDUCE_LOOP_END          ; if cell is 0, no quotient nor remainder. No action needed from us

    lea rdi, [GET_DEN(rbx)]     ; rdi <- nth denominator
    xor rdx, rdx                ; rdx <- 0
    div edi                     ; edx:eax/edi = array[n]/den[n]  (quotient=eax, remainder=edx)
    mov dword [rcx], edx        ; array[n] <- remainder

    mul ebx                     ; edx:eax <- num[n] * quotient

    test edx, edx
    jz REDUCE_VALID_MUL
    ; edx has value, which means result of multiplication is larger than 32 bit, panic
    jmp exit_error


    REDUCE_VALID_MUL:
    mov edx, dword [rcx-4]      ; rdx <- array[n-1]
    add edx, eax                ; array[n-1] += num[n] * quotient
    mov dword [rcx-4], edx      ; store previous operation into mem

    REDUCE_LOOP_END:
    cmp rbx, 1                  ; Iterate LENGTH times (once per array index)
    jg REDUCE_LOOP_START

    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret


extract_digit:
    ;
    ; Return
    ; rax: Next digit of pi
    ;
    push rbx
    push rdx
    push rdi

    mov eax, dword [array]      ; get array[0]
    mov rbx, 10
    div bx                      ; array[0] / 10 (quotient=ax, remainder=dx)
    mov rbx, array
    mov dword [rbx], edx        ; save remainder into array[0]

    cmp ax, 10
    je EXTRACT_DIGIT_10
    cmp ax, 9
    je EXTRACT_DIGIT_9
    jmp EXTRACT_DIGIT_NORMAL

    EXTRACT_DIGIT_9:
    movzx rdi, ax
    call hold_digit
    jmp EXTRACT_END

    EXTRACT_DIGIT_10:
    call increase_held_digits
    call release_digits
    mov rdi, 0                  ; push current digit as 0
    call hold_digit
    jmp EXTRACT_END


    EXTRACT_DIGIT_NORMAL:
    call release_digits
    movzx rdi, ax
    call hold_digit


    EXTRACT_END:
    pop rdi
    pop rdx
    pop rbx
    ret


hold_digit:
    ;
    ; Params
    ; rdi: digit to hold
    ;
    push rax
    push rbx

    movzx rbx, byte [held_count]
    lea rax, [held + rbx*4]         ; held[n] = di
    mov dword [rax], edi

    add byte [held_count], 1        ; n++
    pop rbx
    pop rax
    ret


pop_held_digit:
    ;
    ; Return
    ; rax: popped digit
    ;
    push rbx
    push rcx

    mov eax, dword [held]           ; pop first elem
    push rax                        ; save digit for later
    sub byte [held_count], 1        ; n--

    mov rax, 0
    POP_LOOP:
    lea rbx, [held + 4*rax]
    lea rcx, [rbx + 4]
    mov ecx, dword [rcx]
    mov dword [rbx], ecx

    inc rax
    cmp al, byte [held_count]
    jl POP_LOOP

    pop rax                         ; pop saved digit
    pop rcx                         ; restore rest of stack
    pop rbx
    ret


increase_held_digits:
    push rax
    push rbx
    push rcx

    mov rbx, 0
    HELD_INCREASE_LOOP:
    lea rcx, [held + 4*rbx]
    mov eax, dword [rcx]        ; rax <- held[n]
    add rax, 1

    cmp rax, 10
    jl HELD_INCREASE_END        ; digit is smaller than 10, no modification needed
    sub rax, 10                 ; digit was larger than 10, subtract 10 to simulate modulo (can never be bigger than 10, so should cover every case)

    HELD_INCREASE_END:
    mov dword [rcx], eax        ; write new val to mem
    inc rbx
    cmp bl, byte [held_count]
    jl HELD_INCREASE_LOOP

    pop rcx
    pop rbx
    pop rax
    ret


release_digits:
    push rax
    push rbx

    movzx rax, byte [held_count]
    test rax, rax
    jz RELEASE_END                  ; No release needed if no held digits

    RELEASE_LOOP:
    call pop_held_digit             ; pop into rax
    mov di, ax                      ; move digit into rdi
    call itoa                       ; convert to ascii
    mov rdi, rax
    call print_char                 ; print out char

    movzx rax, byte [printed_period]
    test rax, rax
    jnz RELEASE_NO_PERIOD_PRINT
    ; haven't printed period yet, print it and change flag
    mov rdi, '.'
    call print_char
    mov byte [printed_period], 1

    RELEASE_NO_PERIOD_PRINT:
    movzx rax, byte [held_count]
    test rax, rax
    jnz RELEASE_LOOP                ; loop until held_count is at 0

    RELEASE_END:
    pop rbx
    pop rax
    ret


exit_error:
    mov rdi, '!'
    call print_char
    mov rax, 0x3c
    mov rdi, 1
    syscall
    jmp $


exit_prog:
    ;
    ; Params
    ; rdi: Exit code
    ;
    mov rax, 0x3c   ; syscall number
    syscall
    jmp $           ; this line is never reached