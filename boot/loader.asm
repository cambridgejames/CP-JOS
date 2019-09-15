; --------------------------------------------------------------
; 作者：彭剑桥
; 创建时间：2019-09-10 20:00 Feb.
; 编辑环境：	OS: Deepin 15.9.1 unstable
;         	Kernel: x86_64 Linux 4.15.0-29deepin-generic
; 功能：操作系统内核加载程序，用于在磁盘中寻找系统内核并将其载入内存，然后
;      将系统控制权转交给内核
; --------------------------------------------------------------

; TODO： 以下是内核加载测试程序
	mov ax, cs
	mov ds, ax
	mov es, ax
	call DispStr
	jmp $

; 屏幕输出例程
DispStr:
	mov ax, LoaderMessage
	mov bp, ax
	mov cx, LoaderMessageLen
	mov ax, 01301h
	mov bx, 000ch
	mov dl, 0
	int 10h
	ret
LoaderMessage: db "The loader has been loaded successfully.", 10
LoaderMessageLen equ $-LoaderMessage
