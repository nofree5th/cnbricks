; Copyleft (c) 2007,God reserved all rights.
; 
; �ļ����ƣ�entry.asm
; 
; ��ǰ�汾��0.11
; ��    �ߣ���ΰ
; ������ڣ�2007��12��21��
; ժ	Ҫ�����������start��ʼִ�У�����main_quit�˳�
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
	;������Ϸѭ����ֱ����������ɻ������˳�
	call GA_gameCircle
   jmp main_do_forerer
   	;��ESC����������Ϸ���ʱ����������
main_quit:
	;�����Ļ
	mov ah,00h
	mov al,03h
	int 10h	
	;����DOS
	mov ax,4c00h
	int 21h	
EntryCode    ends
end start
