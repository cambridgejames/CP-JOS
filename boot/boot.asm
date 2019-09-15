; --------------------------------------------------------------
; 作者：彭剑桥
; 创建时间：2019-09-10 20:08 Feb.
; 编辑环境：	OS: Deepin 15.9.1 unstable
;         	Kernel: x86_64 Linux 4.15.0-29deepin-generic
; 功能：操作系统引导程序，用来在磁盘中寻找内核加载程序并将其载入内存，然后
;      将系统控制权转交给内核加载程序。
; --------------------------------------------------------------

;%define _BOOT_DEBUG_    			; 该语句用来将程序编译为COM文件
									; 当需要编译为bin文件时要将此句注释掉
%ifdef _BOOT_DEBUG_
	org 0100h
%else
	org 07c00h
%endif

; --------------------------------------------------------------
; 以下是宏定义
; --------------------------------------------------------------

%ifdef _BOOT_DEBUG_					; 定义堆栈的基地址
	BaseOfStack		equ 0100h
%else
	BaseOfStack		equ 07c00h
%endif

BaseOfLoader	equ 09000h	; 定义内核加载程序 LOADER.BIN 被加载到的段基址
OffsetOfLoader	equ 0100h	; 定义内核加载程序 LOADER.BIN 被加载到的偏移地址

; --------------------------------------------------------------
; 以下是引导扇区头部必须存在的短跳转指令
; --------------------------------------------------------------
	jmp short LABEL_START			; 开始引导
	nop

; 在此处引入 FAT12 磁盘头信息，方便操作系统识别
%include "fat12bpb.inc"

; --------------------------------------------------------------
; 以下是程序主体
; --------------------------------------------------------------

LABEL_START:
	mov ax, cs
	mov ds, ax
	mov es, ax
	; 初始化堆栈
	mov ss, ax
	mov sp, BaseOfStack
	; 复位软盘驱动器：AH=00h,DL=驱动器号
	mov ah, 0x00
	mov dl, [BS_DrvNum]
	int 13h

	; 输出正在引导的提示
	mov ax, BootingMsg
	mov cx, BootingLen
	call DispStr

	mov word [wSectorNo], SecNoOfRootDir

LABEL_SEARCH_IN_ROOT:
; 功能：从根目录读一个扇区，并判断还有没有扇区可读
	cmp word [wRootDirSize], 0		; 判断根目录是否已经读完
	jz LABEL_NO_LOADER				; 仍未找到加载程序但已读完，跳转
	dec word [wRootDirSize]			; 将未读扇区数减一，准备读扇区

	mov ax, BaseOfLoader
	mov es, ax						; 设置内核加载程序的目标段
	mov bx, OffsetOfLoader
	mov ax, [wSectorNo]				; ax 存储接下来要读取的扇区号
	mov cl, 1						; cl 存储要读取的扇区的个数
	call ReadSector 				; 调用 ReadSector 函数读取软盘

	mov si, LoaderFileName			; ds:si 是要寻找的文件名的首地址
	mov di, OffsetOfLoader			; es:di 是扇区加载的目标位置
	cld
	mov dx, 10h			; 每扇区最多包含16个文件头信息，所以最多循环16次

LABEL_SEARCH_HOLE_SECTOR:
; 功能：在整个扇区中逐个查找文件名是否为“LOADER  BIN”
	cmp dx, 0						; 如果当前扇区还剩下 0 个文件头没有读
	jz LABEL_NEXT_SECTOR			; 就准备读取下一个扇区
	dec dx							; 否则将未读文件数减 1
	mov cx, 11						; 文件名和扩展名共 11 字节

LABEL_CMP_FILENAME:
; 功能：在当前的文件头信息中逐个字节对比文件名，若有一个字节不一致则跳出循环
	cmp cx, 0						; 判断文件名是否已经比较完了
	jz LABEL_FIND_LOADER			; 若比较完了还未跳出说明找到了目标文件
	dec cx							; 否则剩余字节数减 1
	lodsb							; 将 ds:si 所指向的一字节拷入 al
	cmp al, byte [es:di]			; 比较当前字节是否一致,相同则 ZF 置0
	jnz LABEL_DIFFERENT				; 若不相同则跳出当前字符比较循环
	inc di 							; 若相同则准备比较下一个字符
	jmp LABEL_CMP_FILENAME			; 比较下一个字符

LABEL_DIFFERENT:
; 功能：在文件名比较失败时执行，用于准备下一个文件名来进行比较
	and di, 0ffe0h					; 将后五位清零，使 di 指向当前项的开头
	add di, 20h						; 使 di 指向下一个文件头信息的开头
	mov si, LoaderFileName			; 将 si 指回目标文件名的首地址
	jmp LABEL_SEARCH_HOLE_SECTOR	; 准备对比下一个文件项

LABEL_NEXT_SECTOR:
; 功能：将即将读取的扇区号加一，然后准备读取下一个扇区
	add word [wSectorNo], 1			; 将即将读取的扇区号加一
	jmp LABEL_SEARCH_IN_ROOT		; 准备重新读取一个新的扇区

LABEL_NO_LOADER:
; 功能: 没有找到lodaer.bin时执行的操作
	mov ax, NoFileMsg
	mov cx, NoFileLen
	call DispStr
	jmp LABEL_PAULSE

LABEL_PAULSE:
; 功能: 等待指令，或重新引导
	jmp $

LABEL_FIND_LOADER:
; 功能: 找到lodaer.bin时执行的操作
	mov ax, FileFondMsg
	mov cx, FileFondLen
	call DispStr
	jmp LABEL_PAULSE

; --------------------------------------------------------------
; 以下是变量和字符串定义
; --------------------------------------------------------------

; 变量定义
wRootDirSize	dw RootDirSectors	; 根目录中的未读扇区数
wSectorNo		dw 0				; 即将读取的扇区号
bOdd			db 0				; 簇号是否为奇数
bRowIndex		db 0				; 下一个字符需要显示的行号

; 字符串定义
LoaderFileName	db 'LOADER  BIN'	; 内核加载程序的文件名，占11字节

BootingMsg:		db 'System booting...'
BootingLen:		equ $-BootingMsg
FileFondMsg:	db 'Kernel loader has been found.'
FileFondLen:	equ $-FileFondMsg
NoFileMsg:		db "There's no kernel loader."
NoFileLen:		equ $-NoFileMsg

; --------------------------------------------------------------
; 以下是函数定义
; --------------------------------------------------------------

DispStr:
; --------------------------------------------------------------
; 功能：显示以 ax 为首地址的长度为 cx 的字符串，然后换行
; --------------------------------------------------------------
	; 在当前位置显示字符
	mov bp, ax
	mov ax, ds
	mov es, ax
	mov ax, 01301h
	mov bx, 0007h
	mov dh, [bRowIndex]				; 设置行号
	mov dl, 0						; 设置光标在第0列（最左侧）
	int 10h
	add byte [bRowIndex], 1
	ret
; -- END OF FUNCTION 'DispStr' --

ReadSector:
; --------------------------------------------------------------
; 功能：将从第 ax 个 Sector 开始的 cl 个 Sector 读入 es:bx 中
; 原理：
;     设扇区号为 x，则可通过下面的方法计算出柱面号、起始扇区和磁头号：
;                               ┌ 柱面号 = y >> 1
;           x           ┌ 商 y ┤
;     -------------- => ┤      └ 磁头号 = y & 1
;       每磁道扇区数      │
;                       └ 余 z => 起始扇区号 = z + 1
; 注释：之所以使用 ax 存储开始的扇区号，是因为 div 指令的被除数必须保存在
;      eax 寄存器中，这样做可以减少指令数。
; --------------------------------------------------------------
	push bp
	mov bp, sp
	sub esp, 2			; 将 byte [bp-2] 处的两字节用来存放需要读取的扇区数
	mov byte [bp - 2], cl			; 将传入的扇区数存入堆栈

	; 下面开始计算柱面号、起始扇区和磁头号
	push bx							; 保存 bx ，因为接下来要使用 bl 进行除法运算
	mov bl, [BPB_SecPerTrk]			; bl 为每磁道的扇区数（在BPB中定义）
	div bl 				; 由于 bl 只有八位，所以商 y 在 al 中，余数 z 在 ah 中
	inc ah 							; ah = z + 1，得到起始扇区号
	mov dh, al
	shr al, 1						; 计算 al >> 1，得到柱面号
	and dh, 1						; 计算 dh & 1，得到磁头号
	pop bx							; 恢复 bx 的值

	; 下面将得到的值送入 13h 号中断所要求的寄存器中，并开始读取内容
	mov ch, al						; ch <- 柱面（磁道）号
	mov cl, ah 						; cl <- 起始扇区号
	mov dl, [BS_DrvNum]				; dl <- 驱动器号（在BPB中定义）
.DoReadSector:
	mov ah, 2						; 设置读模式
	mov al, byte [bp - 2]			; 设置需要读取的扇区数
	int 13h
	jc .DoReadSector	; ruo读取错误则 CF 会被置1，只需不停地读，直到正确为止

	; 函数结束
	add esp, 2
	pop bp
	ret
; -- END OF FUNCTION 'ReadSector' --

; 将引导扇区的剩余空间填充为0x00，并将最后两字节设为0xAA55
times 510-($-$$) db 0
dw 0xaa55
