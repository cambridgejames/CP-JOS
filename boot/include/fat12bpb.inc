; --------------------------------------------------------------
; 作者：彭剑桥
; 创建时间：2019-09-10 19:45 Feb.
; 编辑环境：	OS: Deepin 15.9.1 unstable
;         	Kernel: x86_64 Linux 4.15.0-29deepin-generic
; 功能：提供与 FAT12 磁盘格式相关的 BPB 头信息以及其他相关参数
; --------------------------------------------------------------

BS_OEMName		DB 'CP-James'		; OEM String，必须为8字节

BPB_BytesPerSec	DW 512				; 每扇区的字节数
BPB_SecPerClus	DB 1				; 每簇中的扇区数
BPB_RsvdSecCnt	DW 1				; Boot记录占用多少个扇区
BPB_NumFATs		DB 2				; 共有多少个FAT表
BPB_RootEntCnt	DW 224				; 根目录中文件数量的最大值
BPB_TotSec16	DW 2880				; 逻辑扇区总数
BPB_Media		DB 0xF0				; 媒体描述符
BPB_FATSz16		DW 9				; 每FAT的扇区数
BPB_SecPerTrk	DW 18				; 每磁道的扇区数
BPB_NumHeads	DW 2				; 磁头数（面数）
BPB_HiddSec		DD 0				; 隐藏扇区数
BPB_TotSec32	DD 0				; 该值在 BPB_TotSec16 为0时记录扇区数

BS_DrvNum		DB 0				; 中断13的驱动器号
BS_Reserved1	DB 0				; 未使用
BS_BootSig		DB 29h				; 扩展引导标记（29h）
BS_VolID		DD 0				; 卷序列号
BS_VolLab		DB 'CP-JOS Beta'	; 卷标，必须11个字节
BS_FileSysType	DB 'FAT12   '		; 文件系统类型，必须8字节

; --------------------------------------------------------------
; 以下是关于 FAT12 磁盘格式的一些常用常量定义
; 注意：上述BPB头信息改变后，需要重新计算下列常量的值
; --------------------------------------------------------------

; 根目录占用的扇区数
; RootDirSectors = (BPB_RootEntCnt * 32 + BPB_BytesPerSec - 1) / BPB_BytesPerSec
; 前述公式的结果需要进行上取整
RootDirSectors equ 14

; 根目录的第一个扇区号
; SecNoOfRootDir = BPB_RsvdSecCnt + (BPB_NumFATs * BPB_FATSz16)
SecNoOfRootDir equ 19
