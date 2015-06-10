;�ļ����ƣ�game.h
;ժ    Ҫ������������ĸ��ֳ�����һЩ���ݽṹ�Ķ��壬���й��������޸�

;��Ϸ״̬
GS_RUNNING	equ 0
GS_PAUSED 	equ 1
GS_OVER		equ 2
;��߿ɴﵽ�Ĺ���
LEVEL_LIMITT	equ 15
;��Ϸ������ʼλ�ü���С
GM_LEFT		equ 25
GM_TOP		equ 4
GM_WIDTH	equ 12   
GM_HEIGHT 	equ 20
GM_MASK		equ (1 SHL GM_WIDTH-1)
;���ܼ�ɨ����
KEY_ESC		equ 1h  ;ESC
KEY_LEFT	equ 4bh ;LEFT
KEY_RIGHT	equ 4dh ;RIGHT
KEY_ROLATE	equ 48h ;UP
KEY_DOWN	equ 50h ;DOWN
KEY_QUICKLY	equ 3dh ;F3
KEY_SLOW_DOWN	equ 3ch ;F2
KEY_TURN	equ 4fh ;End
KEY_PAUSE	equ 53h ;Delete
KEY_CHANG_MODE	equ 3bh ;F1

CHAR_CLEAR	equ ' ';�����ַ�,ascii
CHAR_BRICK	equ 2  ;��������,ascii

;0�� 1���� 2�� 3�� 4�� 5�� 6�� 7�Ұ�,���λ��1�������ʾ
COLOR_CLEAR	equ 0h
COLOR_DIED_BRICK equ 08h
COLOR_TITTLE	equ 7;
COLOR_NUMBER	equ 3 or 8

;��Ļ�ϸ�˵�����ֻ�װ��������꣬��Ϊ�����Ϸ�������Ͻ�
X_NEXT_BRICK 	equ -5
Y_NEXT_BRICK	equ 3
Y_LBOUND_CHAR	equ 17
Y_RBOUND_CHAR	equ 16
Y_BOUND_COLOR	equ 2 or 8;blue
X_UBOUND_CHAR	equ 15
X_DBOUND_CHAR	equ 15
X_BOUND_COLOR   equ 2 or 8;green
X_START 	equ (GM_WIDTH-1)/2
Y_START		equ -1
X_SCORE_STR	equ -10
X_LEVEL_STR	equ X_SCORE_STR
X_adjustLevelDelt_STR	equ X_SCORE_STR-4
X_MODE_STR	equ X_SCORE_STR-4
Y_SCORE_STR	equ 5
Y_LEVEL_STR	equ Y_SCORE_STR+2
Y_adjustLevelDelt_STR	equ Y_LEVEL_STR+2
Y_MODE_STR	equ Y_adjustLevelDelt_STR+2
X_SCORE_POS	equ -3
X_LEVEL_POS	equ X_SCORE_POS
X_adjustLevelDelt_POS	equ X_SCORE_POS
X_MODE_POS	equ X_SCORE_POS
Y_SCORE_POS	equ Y_SCORE_STR+1
Y_LEVEL_POS	equ Y_LEVEL_STR+1
Y_adjustLevelDelt_POS	equ Y_adjustLevelDelt_STR+1
Y_MODE_POS	equ Y_MODE_STR+1

X_GAME_OVER	equ -10
X_JUDGE_STR	equ X_GAME_OVER+5
X_GAME_NAME	equ GM_WIDTH/2-4
Y_GAME_NAME	equ -1
Y_GAME_OVER	equ -3
Y_JUDGE_STR	equ Y_GAME_OVER+1

;��Ӧ������Ӧ����Ӧ������ڵ�ַ��ƫ��
DIR_RIGHT	equ 0
DIR_LEFT	equ 2*1
DIR_DOWN	equ 2*2
DIR_ROTATE	equ 2*3
DIR_DOWN_COMPLETE equ 2*4
DIR_TURN	equ 2*5
KEY_WRONG_DIR	equ 2*11

;����ṹ
Pos struc
	pos_bX db ?
	pos_bY db ?
Pos ends
;��������
Brick struc
	;��Ի��������
	b_sPos Pos <>
Brick ends

;���������ɵĻ���Ԫ��
ManyBrick struc
	;�������
	mb_bCnt dw ?
	;�����̶�Ϊ4
	mb_sBrick Brick 4 dup(<>)
	;�����������ѡȡ�Ļ�������꣬Ҳ�������Ϸ�����ϽǶ���
	mb_sPos Pos<>
	;��Ԫ�ص���ɫ
	mb_bColor db ?		
ManyBrick ends
;��Ϸ�࣬
GameApp struc
	;��ҵ÷�
	ga_score 	dw ?
	;��Ϸ״̬
	ga_state	dw ?
	;��Ϸ��ͼ,��Ӧλ��λ���з����ڴ�
	ga_map 	dw GM_HEIGHT dup (0FFFFh)
GameApp ends
