;文件名称：game.h
;摘    要：程序中所需的各种常量及一些数据结构的定义，集中管理，便于修改

;游戏状态
GS_RUNNING	equ 0
GS_PAUSED 	equ 1
GS_OVER		equ 2
;最高可达到的关数
LEVEL_LIMITT	equ 15
;游戏区域起始位置及大小
GM_LEFT		equ 25
GM_TOP		equ 4
GM_WIDTH	equ 12   
GM_HEIGHT 	equ 20
GM_MASK		equ (1 SHL GM_WIDTH-1)
;功能键扫描码
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

CHAR_CLEAR	equ ' ';擦除字符,ascii
CHAR_BRICK	equ 2  ;方块外形,ascii

;0黑 1深蓝 2绿 3蓝 4红 5紫 6黄 7灰白,最高位置1则高亮显示
COLOR_CLEAR	equ 0h
COLOR_DIED_BRICK equ 08h
COLOR_TITTLE	equ 7;
COLOR_NUMBER	equ 3 or 8

;屏幕上各说明文字或装饰物的坐标，皆为相对游戏场地左上角
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

;相应键所对应的相应功能入口地址的偏移
DIR_RIGHT	equ 0
DIR_LEFT	equ 2*1
DIR_DOWN	equ 2*2
DIR_ROTATE	equ 2*3
DIR_DOWN_COMPLETE equ 2*4
DIR_TURN	equ 2*5
KEY_WRONG_DIR	equ 2*11

;坐标结构
Pos struc
	pos_bX db ?
	pos_bY db ?
Pos ends
;单个方块
Brick struc
	;相对基块的坐标
	b_sPos Pos <>
Brick ends

;多个方块组成的基本元素
ManyBrick struc
	;方块个数
	mb_bCnt dw ?
	;容量固定为4
	mb_sBrick Brick 4 dup(<>)
	;多个方块中所选取的基块的坐标，也是相对游戏场左上角而言
	mb_sPos Pos<>
	;此元素的颜色
	mb_bColor db ?		
ManyBrick ends
;游戏类，
GameApp struc
	;玩家得分
	ga_score 	dw ?
	;游戏状态
	ga_state	dw ?
	;游戏地图,相应位置位则有方块在此
	ga_map 	dw GM_HEIGHT dup (0FFFFh)
GameApp ends
