

default rel

extern XOpenDisplay
extern XDefaultScreen
extern XRootWindow
extern XCreateSimpleWindow
extern XMapWindow
extern XCreateGC
extern XSetForeground
extern XFillRectangle
extern XNextEvent
extern XSelectInput
extern XFlush
extern XCloseDisplay

global main

section .bss
    event resb 192

section .text
main:
    push rbp
    mov rbp, rsp
    ; wyrównanie stosu do 16 bajtów
    and rsp, -16
    ; display = XOpenDisplay(NULL)
    xor rdi, rdi
    call XOpenDisplay
    mov r12, rax

    ; screen = XDefaultScreen(display)
    mov rdi, r12
    call XDefaultScreen
    mov r13, rax

    ; root = XRootWindow(display, screen)
    mov rdi, r12
    mov rsi, r13
    call XRootWindow
    mov r14, rax

    ; window = XCreateSimpleWindow(display, root, 100,100,640,640,1,0,0)
    mov rdi, r12
    mov rsi, r14
    mov rdx, 100
    mov rcx, 100
    mov r8, 640
    mov r9, 640
    sub rsp, 16
    mov qword [rsp], 1        ; border width
    mov qword [rsp+8], 0      ; border
    push 0                      ; background
    call XCreateSimpleWindow
    add rsp, 24
    mov r15, rax

    ; select ExposureMask
    mov rdi, r12
    mov rsi, r15
    mov rdx, 0x00008000
    call XSelectInput

    ; map window
    mov rdi, r12
    mov rsi, r15
    call XMapWindow

    ; GC = XCreateGC(display, win, 0, NULL)
    mov rdi, r12
    mov rsi, r15
    xor rdx, rdx
    xor rcx, rcx
    call XCreateGC
    mov rbx, rax

event_loop:
    mov rdi, r12
    lea rsi, [rel event]
    call XNextEvent

    mov eax, dword [event]
    cmp eax, 12       ; Expose
    jne event_loop

    ; rysowanie szachownicy
    xor r8, r8       ; row = 0
row_loop:
    cmp r8, 8
    jge done_draw
    xor r9, r9       ; col = 0
col_loop:
    cmp r9, 8
    jge next_row

    ; kolor
    mov rax, r8
    add rax, r9
    and rax, 1
    cmp rax, 0
    je white_square

black_square:
    mov rdi, r12
    mov rsi, rbx
    mov rdx, 0x444444
    call XSetForeground
    jmp draw_square

white_square:
    mov rdi, r12
    mov rsi, rbx
    mov rdx, 0xDDDDDD
    call XSetForeground

draw_square:
    mov rdi, r12
    mov rsi, r15
    mov rdx, rbx
    mov rcx, r9
    imul rcx, 80
    mov rax, r8
    imul rax, 80
    push rax
    push 80
    push 80
    call XFillRectangle
    add rsp, 24

    inc r9
    jmp col_loop
next_row:
    inc r8
    jmp row_loop

done_draw:
    mov rdi, r12
    call XFlush
    jmp event_loop