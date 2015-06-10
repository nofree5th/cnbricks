; Copyleft (c) 2007,God reserved all rights.
; 
; 文件名称：entry.asm
; 
; 当前版本：0.11
; 作    者：邹伟
; 完成日期：2007年12月21日
; 摘	要：整个程序从start开始执行，并从main_quit退出
public main_quit,restart_the_game
extern GA_gameInit:far,GA_gameCircle:far,setDSAndES:far,stackPoint:byte
assume  cs:EntryCode
EntryCode    segment
start:
	call setDSAndES
   restart_the_game:
   	mov sp,offset stackPoint
   main_do_forerer:
	call GA_gameInit
	;进入游戏循环，直到结束、完成或主动退出
	call GA_gameCircle
   jmp main_do_forerer
   	;按ESC键或整个游戏完成时，跳到这里
main_quit:
	;清除屏幕
	mov ah,00h
	mov al,03h
	int 10h	
	;返回DOS
	mov ax,4c00h
	int 21h	
EntryCode    ends
end start
