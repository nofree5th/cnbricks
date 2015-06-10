; Copyleft (c) 2007,God reserved all rights.
; 
; 文件名称：game.asm
; 
; 当前版本：0.13
; 作    者：邹伟
; 摘	要：各主要子程序都在此间
; 说	明：程序中用于输出字符的位置未加说明则默认为相对于游戏区域左上角即(GM_LEFT,GM_TOP)

public setDSAndES , GA_gameInit , GA_gameCircle , stackPoint
extern main_quit:far,restart_the_game:far
include game.h
;设置块坐标的宏
assignPos macro x,y
	mov (Brick ptr [si]).b_sPos.pos_bX,x
	mov (Brick ptr [si]).b_sPos.pos_bY,y
	add si,size Brick 
endm
assignBase macro x,y
	mov (ManyBrick ptr [di]).mb_sPos.pos_bX,x
	mov (ManyBrick ptr [di]).mb_sPos.pos_bY,y
endm

assume cs:GameCode,ds:MainData,ss:StackSpase
GameCode segment	
	;游戏循环---不断获取输入，根据与定义规则合理的转化为输出
	GA_gameCircle proc far
	    GA_gameCircle_again:
	    	mov dir,KEY_WRONG_DIR
	    	lea bx,levelFPS
	    	mov di,level
	    	add di,challenge
	    	cmp di,LEVEL_LIMITT
	    	jbe level_ok
	    	mov di,LEVEL_LIMITT
	    level_ok:
	      	shl di,1
	      	mov cx,[bx+di]
	    	   wast_time:
			call delay
			cmp dir,KEY_WRONG_DIR
			je may_be_life_is_long
			call Brick_goNext
			mov dir,KEY_WRONG_DIR
			call ManyBrick_drawSelf
		   may_be_life_is_long:
		   loop wast_time			   		   
		   	cmp dir,KEY_WRONG_DIR		   		   
		   	jz user_press_no_dir_key
			call Brick_goNext
		    user_press_no_dir_key:
			mov dir,DIR_DOWN
			call Brick_goNext
		cmp game.ga_state,GS_OVER
		jz GA_over		
		call ManyBrick_drawSelf		
	   jmp GA_gameCircle_again
	   GA_over:
	   	call doGameOver
		ret
	GA_gameCircle endp	
	;每次游戏开始时的初始化调用
	GA_gameInit proc far
		call clrScreen
		;hide the cursor
		mov ch,020h
		mov cl,020h
		mov ah,01h
		int 10h
		;初始化随机序列的第一个数，读取BIOS提供的当前秒
		xor al,al
		out 70h,al
		in ax,71h		
		mov seed,ax
		;初始化，如：得分，游戏状态，游戏地图
		mov challenge,0
		mov game.ga_score,0
		mov game.ga_state,GS_RUNNING
		lea di,game.ga_map
		mov cx,GM_HEIGHT		
		cld
		xor ax,ax
		rep stosw
		mov nextNO,0
		call MB_gernicNext
		call MB_gernicNext
		call drawNextBrick
		call moreBeautiful
		;show some strings
		mov si,offset scoreStr
		mov dl,X_SCORE_STR
		mov dh,Y_SCORE_STR
		mov cx,6
		call showStr

		mov si,offset levelStr
		mov dl,X_LEVEL_STR
		mov dh,Y_LEVEL_STR
		mov cx,6
		call showStr

		mov si,offset levelDeltStr
		mov dl,X_adjustLevelDelt_STR
		mov dh,Y_adjustLevelDelt_STR
		mov cx,10
		call showStr

		mov si,offset modeStr
		mov dl,X_MODE_STR
		mov dh,Y_MODE_STR
		mov cx,10
		call showStr
	
		mov si,offset usageStr
		mov dl,-GM_LEFT
		mov dh,-4
		mov cx,usageStrCNT
		call showStr
		mov si,offset usageStrEx
		mov dl,-GM_LEFT
		mov dh,-3
		mov cx,usageStrExCNT
		call showStr
		mov si,offset linkToCoderStr
		mov dl,-GM_LEFT
		mov dh,-2
		mov cx,linkToCoderCNT
		call showStr		

		;show some digitials
		call showScore
		call calcLevel
		call showadjustLevelDelt
		call showMode
		ret
	GA_gameInit endp
	;全局初始化，调用一次，设置DS,ES指向同一个数据段，程序运行过程中不再改变
	setDSAndES proc far
		mov ax,MainData
		mov ds,ax
		mov es,ax
		ret
	setDSAndES endp
	;判断游戏区域(dl,dh)位置是否为空
	;in  : dl-->x, dh-->y
	;out : flag register 
	isPosNotEmpty proc
		push dx
		push bx
		push ax
		push cx
		push di
		push si
		mov si,curMB
		mov si,(ManyBrick ptr [si]).mb_bCnt
		;ax--mask,第dl位置1
		mov ax,1
		mov cl,dl
		shl ax,cl		
		lea di,game.ga_map
		;map+2*dh 
		xor bh,bh
		mov bl,dh
		shl bl,1		
	   only_one_brick:
		and ax,[bx+di]
		je is_pos_empty_out
		cmp si,1
		jne is_pos_empty_out
		cmp bx,(2*GM_HEIGHT-2)
		je is_pos_empty_out_pre
		add bx,2
	   jmp only_one_brick
	   	;ensure the result is correct
	   is_pos_empty_out_pre:
	   	cmp bx,0
	   is_pos_empty_out:
	   	pop si
		pop di
		pop cx
		pop ax
		pop bx
		pop dx
		ret
	isPosNotEmpty endp
	;判断游戏是否结束
	isGameOver proc
		push bx
		mov bx,curMB
		cmp (ManyBrick ptr [bx]).mb_sPos.pos_bY,Y_START		
	    jne still_alive
		;游戏的确结束了
		mov game.ga_state,GS_OVER
		call doGameOver
	    still_alive:
		pop bx
		ret
	isGameOver endp
	;游戏结束后，调用此过程，显示一些提示信息，待等用户下一步指示,重玩或退出
	doGameOver proc	   
		call clrScreen	
		call moreBeautiful
		mov si,offset gameOverStr
		mov cx,45
		mov dl,X_GAME_OVER ;x
		mov dh,Y_GAME_OVER ;y
		call showStr		
		mov ax,game.ga_score		
		mov cx,43
		call AXModCX
		and ax,3
		mov di,ax
		shl di,1
		mov cx,judgeCnt[di]		
		mov si,judgeTable[di]
		mov dl,X_JUDGE_STR
		mov dh,Y_JUDGE_STR
		call showStr
		mov al,CHAR_BRICK
	    wait_for_restart:
	    	call randomDraw
	    	call delay
	    jmp wait_for_restart
		ret
	doGameOver endp
	;in : ax--ax0, cx--cx0
	;out: ax=ax0/cx0, cx=ax0%cx0
	AXModCX	proc
		push dx
		xor dx,dx
		div cx
		mov cx,dx
		pop dx
		ret
	AXModCX endp
	;信手涂鸦
	randomDraw proc
		push dx
		push bx
			push ax
			call getRand
			mov cx,GM_WIDTH
			call AXModCX
			mov dl,cl
			call getRand
			mov cx,GM_HEIGHT
			call AXModCX
			mov dh,cl
			call getRand
			and al,7
			or al,8
			mov bl,al
			pop ax
			call drawBrick
		pop bx
		pop dx
		ret
	randomDraw endp
	;游戏暂停时调用此过程，显示提示信息，按任意键继续
	doGamePaused proc	
		push si
		push cx
		push dx
		push ax		
		mov si,offset gamePausedStr
		mov cx,46 ;46 chars
		mov dl,0 ;x
		mov dh,GM_HEIGHT/2;y
		call showStr				
		call waitForKeyPress
	    	mov game.ga_state,GS_RUNNING 	
	    	mov dl,0
	    	mov dh,GM_HEIGHT/2
		mov al,CHAR_CLEAR
		mov cx,46 ;46 chars
	    erase_paused_words:
		mov bl,COLOR_CLEAR
	    	call drawBrick
	    	inc dl
	    loop erase_paused_words
	    	call moreBeautiful
	    	call drawMap
	    	call ManyBrick_drawSelf
	    	pop ax
	    	pop dx
	    	pop cx
	    	pop si
		ret
	doGamePaused endp
	;clear the screen
	clrScreen proc
		push ax		
		mov ah,00h
		mov al,03h
		int 10h
		pop ax
		ret
	clrScreen endp
	;游戏完成时跳转到此，表示对极富耐心者的景仰^_^，并退出游戏
	doGameFinished:
		call clrScreen
		call moreBeautiful
		mov si,offset gameFinishedStr
		mov cx,58 ;58 chars
		mov dl,-GM_LEFT+5
		mov dh,-2
		call showStr
	   dGF_keybuf_empty:
	   	call getRand
	   	call randomDraw
	   	mov ah,1
	   	int 16h	   	
	   jz dGF_keybuf_empty
		jmp main_quit
	;等待直到有键被按下
	waitForKeyPress proc
		push ax
	    key_buf_empty:
		mov ah,1
		int 16h		
	    jz key_buf_empty
	    	;ignore the key just press
	    	mov ah,0
		int 16h
	    	pop ax
		ret
	waitForKeyPress endp
	;方块下落停止时，设置当前下落方块所占用的地图位置，并消除满行
	lastBattle proc
		call ManyBrick_setMap
		call checkFull
		ret
	lastBattle endp
	;若map数组相应为置位 则在相应位置显示一个方块
	drawMap proc
		push ax
		push dx
		push bx
		push cx
		push si
		push di
		lea si,game.ga_map
		mov cx,GM_HEIGHT
		xor dh,dh		
	   drawMap_outer:
	   		push cx
	   		mov cx,GM_WIDTH
	   		xor dl,dl
	   		mov di,1
	   		push si
	   		mov si,[si]
	   		mov ah,3
	   	   drawMap_inner:
			mov bl,3
			sub bl,ah
			mov ah,bl
	   	   	test si,di
	   	   	jz clear_it
	   	   	;draw a brick
			mov al,CHAR_BRICK
			mov bl,COLOR_DIED_BRICK	   	   	
	   	   	jmp draw_map_over	   	   	
	   	   clear_it:
	   	   	cmp mode,2
	   	   jne ignor_background
	   	   	mov al,'|'
	   	   	mov bl,ah
	   	   	jmp draw_map_over
	   	   ignor_background:
			mov al,CHAR_CLEAR
			mov bl,COLOR_CLEAR
	   	   draw_map_over:
	   	   	call drawBrick
	   	   	inc dl
	   	   	shl di,1
	   	   loop drawMap_inner
	   	   	pop si	   	   
	   	   	pop cx
	   	add si,2
	   	inc dh
	   loop drawMap_outer
	   	pop di
	   	pop si
	   	pop cx
		pop bx
		pop dx
		pop ax
		ret
	drawMap endp
	;检查是否有满行的情况，满则消除，并增加得分...
	checkFull proc
		push ax
		push bx
		push cx
		push dx
		xor dx,dx ;此次能消除的行数
		lea bx,game.ga_map
		add bx,2*(GM_HEIGHT-1)		
		mov cx,GM_HEIGHT
	   check_full_again:
	   	mov ax,[bx]
	   	cmp ax,GM_MASK
	   	jne brick_not_full
	   	inc dx
	   	call mapScrollDown
	   loop check_full_again
	   brick_not_full:
	   	sub bx,2
	   loop check_full_again
	   	test dx,dx
	   	jz get_zero_score
	   		;此次得分：2*行数-1
	   		shl dx,1
	   		dec dx
	   		add game.ga_score,dx
			call calcLevel	   	
	   		call showScore
	   get_zero_score:
	   	pop dx
	   	pop cx
	   	pop bx
	   	pop ax
		ret
	checkFull endp
	;根据得分计算当前关数
	calcLevel proc
		push ax
		push bx
		push cx
		mov bx,offset levelScoreLast		
		xor ah,ah
		mov cx,LEVEL_LIMITT
	   add_level_again:
	   	mov al,[bx]
	   	cmp game.ga_score,ax
	   	jae  calc_level_out
	   	dec bx
	   loop add_level_again
	   calc_level_out:	   				
		mov level,cx
		cmp level,LEVEL_LIMITT
		jb game_unfinished
		add sp,6
		jmp doGameFinished
	   game_unfinished:
	    	call showLevel
		pop cx
		pop bx
		pop ax
		ret
	calcLevel endp
	;显示当前关
	showLevel proc
		push dx
		push bx
		push ax
		mov bl,COLOR_NUMBER
		mov dl,X_LEVEL_POS
		mov dh,Y_LEVEL_POS
		mov ax,level
		call showInt
		pop ax
		pop bx
		pop dx
		ret
	showLevel endp
	;显示当前得分
	showScore proc
		push dx
		push bx
		push ax
		mov bl,COLOR_NUMBER
		mov dl,X_SCORE_POS
		mov dh,Y_SCORE_POS
		mov ax,game.ga_score
		call showInt
		pop ax
		pop bx
		pop dx
		ret
	showScore endp	
	;显示当前自动提升的关数
	showAdjustLevelDelt proc
		push dx
		push bx
		push ax
		mov bl,COLOR_NUMBER
		mov dl,X_adjustLevelDelt_POS
		mov dh,Y_adjustLevelDelt_POS
		mov ax,challenge
		call showInt
		pop ax
		pop bx
		pop dx
		ret
	showAdjustLevelDelt endp	
	showMode proc
		push dx
		push bx
		push ax
		mov bl,COLOR_NUMBER
		mov dl,X_MODE_POS
		mov dh,Y_MODE_POS
		mov ax,mode
		call showInt
		call drawMap
		pop ax
		pop bx
		pop dx
		ret		
		ret
	showMode endp
	;在(dl,dh)为起始的位置显示ax中的一个整数
	;in :	ax--the integer to be show
	;	dl--x , dh--y;
	showInt	proc
		push cx
		push si
		push di
		xor di,di
		mov cx,10
	    show_int_again:
	    	inc di
	    	push dx
	    	xor dx,dx
	    	;dx:ax /cx, ax  ,dx
	    	div cx
	    	mov si,ax
	    	mov al,dl
	    	pop dx
	    	add al,30h
		call drawBrick
		dec dl
		mov ax,si
		cmp ax,0		
	    jnz show_int_again
	    	cmp di,1
	    jne no_need_to_clear
		mov al,CHAR_CLEAR
		push bx
		mov bl,COLOR_CLEAR
	    	call drawBrick
	    	pop bx
	    no_need_to_clear:
	    	pop di
	    	pop si
	    	pop cx
		ret
	showInt endp
	;在（X_NEXT_BRICK，Y_NEXT_BRICK）处显示下一个将要下落的方块s
	drawNextBrick proc
		push bx
		push dx
		;first clear the last draw
		mov bx,curMB
		mov dx,WORD ptr (ManyBrick ptr [bx]).mb_sPos.pos_bX 
		mov (ManyBrick ptr [bx]).mb_sPos.pos_bX ,X_NEXT_BRICK
		mov (ManyBrick ptr [bx]).mb_sPos.pos_bY ,Y_NEXT_BRICK
		call ManyBrick_clearCur
		mov WORD ptr (ManyBrick ptr [bx]).mb_sPos.pos_bX,dx
		;second draw the next-brick
		mov bx,nextMB
		mov dx,WORD ptr (ManyBrick ptr [bx]).mb_sPos.pos_bX 
		mov (ManyBrick ptr [bx]).mb_sPos.pos_bX ,X_NEXT_BRICK
		mov (ManyBrick ptr [bx]).mb_sPos.pos_bY ,Y_NEXT_BRICK
		xchg bx,curMB
		call ManyBrick_drawSelf
		xchg curMB,bx
		mov WORD ptr (ManyBrick ptr [bx]).mb_sPos.pos_bX,dx
		pop dx
		pop bx
		ret
	drawNextBrick endp
	;游戏区域对应map数组在bx行处下卷，即清除bx所在行
	;in:	bx --the line to be clear
	mapScrollDown proc
		push bx
		push ax
		push cx
		dec cx
		je scroll_over
		push si
		push di
		mov di,bx
		lea si,[di-2]		
		std
	   	rep movsw
		pop di
		pop si
	   scroll_over:
	   	mov game.ga_map,0
	   	call drawMap
		pop cx
		pop ax
		pop bx
		ret
	mapScrollDown endp
	;根据当前下落的方块所在位置设置游戏区域所代表的map数组
	ManyBrick_setMap proc
		push ax
		push bx
		push cx
		push dx
		push si
		push di
		push bp
		lea di,game.ga_map		
		mov bx,curMB
		mov cx,(ManyBrick ptr [bx] ).mb_bCnt
		lea si,(ManyBrick ptr [bx] ).mb_sBrick
		lea bp,(ManyBrick ptr [bx]).mb_sPos
	   setMap_again:		
			mov dh,(Brick ptr [si]).b_sPos.pos_bY
			add dh,ds:(Pos ptr[bp]).pos_bY
			mov dl,(Brick ptr [si]).b_sPos.pos_bX
			add dl,ds:(Pos ptr[bp]).pos_bX
			call isPosLeagel
			js setMap_ignore
			cmp dh,0
			js setMap_ignore			
			;map[dh]
			mov bl,dh
			shl bl,1
			xor bh,bh			
			;bx--&map[dh]
			lea bx,[bx+di]
			mov ax,1
			push cx
			mov cl,dl
			shl ax,cl
			pop cx
			or [bx],ax
	   	   setMap_ignore:
	   	add si,size Brick
	   	loop setMap_again
	   	cmp mode,0
	   jz color_stay
	   	call drawMap
	   color_stay:	   	
	   	pop bp
	   	pop di	   	
	   	pop si
	   	pop dx
		pop cx
		pop bx
		pop ax	
		ret
	ManyBrick_setMap endp	
	;接受用户输入，并转化为内部数据，有的立即响应，如：ESC退出
	processUserInput proc
		push ax
		push bx
		push cx
		mov ah,1
		int 16h
		jz just_ignore
		cmp game.ga_state,GS_OVER
		jnz no_need_to_restart
		jmp restart_the_game
	    no_need_to_restart:
		mov ah,0
		int 16h
		cmp ah,KEY_ESC
		jnz gameCont
		;quit the game
		jmp main_quit
	    gameCont:
		cmp ah,KEY_PAUSE
		jz away_for_a_while
		cmp ah,KEY_QUICKLY	    
		jz go_quickly
		cmp ah,KEY_SLOW_DOWN		
		jz go_slow_down
	    	cmp ah,KEY_LEFT
	    	jz set_dir_left
	    	cmp ah,KEY_RIGHT
	    	jz set_dir_right
	    	cmp ah,KEY_DOWN
	    	jz set_dir_down
	    	cmp ah,KEY_TURN
	    	jz set_dir_turn
		cmp ah,KEY_CHANG_MODE
		jz set_mode
		cmp ah,KEY_ROLATE
		jnz just_ignore
	    set_dir_rolate:
	    	mov dir,DIR_ROTATE
	    	jmp just_ignore
	    set_dir_left:
	    	mov dir,DIR_LEFT
	    	jmp just_ignore
	    set_dir_right:
	    	mov dir,DIR_RIGHT
	    	jmp just_ignore
	    set_dir_turn:
	    	mov dir,DIR_TURN
	    	jmp just_ignore
	    set_mode:
	    	inc mode
	    	mov ax,mode
	    	mov cx,3
	    	call AXModCX
	    	mov mode,cx
	    	call showMode
	    	jmp just_ignore
	    go_slow_down:
	    	dec challenge
	    	jmp adjustLevelDelt_adjust
	    go_quickly:
	    	inc challenge	    	
	    adjustLevelDelt_adjust:
	    	and challenge,0fh
		call showadjustLevelDelt
	    	jmp just_ignore
	    away_for_a_while:
	    	mov game.ga_state,GS_PAUSED
	    	call doGamePaused
	    	jmp just_ignore
	    set_dir_down:
	    	mov dir,DIR_DOWN_COMPLETE
	    just_ignore:	    	
		pop cx
		pop bx
		pop ax
		ret	
	processUserInput endp
	;判断方块下一步是否能继续，不能则转updateGameState
	Brick_goNext proc
		push ax
		push bx
		push cx
		push dx
		push di	
		push si
		mov si,dir
	    	;shl si,1
		mov bx,curMB
		xor ax,ax
	    down_complete_agian:
		mov cx,(ManyBrick ptr [bx]).mb_bCnt
		lea di,(ManyBrick ptr [bx]).mb_sBrick
	    Brick_goNext_again:		
		;jc Brick_goNext_can
			mov dl,(Brick ptr [di]).b_sPos.pos_bX			
			mov dh,(Brick ptr [di]).b_sPos.pos_bY			
			jmp cs:Brick_tryTable[si]
		   Brick_tryRight:
		   	inc dl
			jmp Brick_checkLegal
		   Brick_tryLeft:
			dec dl
			jmp Brick_checkLegal
		   Brick_tryDown:		   
			inc dh	
			jmp Brick_checkLegal
		   Brick_tryTrun:		   
			neg dl
			jmp Brick_checkLegal
		Brick_tryRotate:	
			xchg dl,dh
			neg dh
		   Brick_checkLegal:
			add dl,(ManyBrick ptr [bx]).mb_sPos.pos_bX
			add dh,(ManyBrick ptr [bx]).mb_sPos.pos_bY
			call isPosLeagel
			js do_more_work
			cmp dh,0
		   js go_next_check_again
			;now  0<=dl<GM_WIDTH,0<=dh<GM_HEIGHT
			call isPosNotEmpty
			jne do_more_work
		   go_next_check_again:
		add di,size Brick
		loop Brick_goNext_again
		cmp (ManyBrick ptr [bx]).mb_bCnt,1
		jne more_than_one_brick
		call drawMap
		jmp clear_pre_brick_over
	    more_than_one_brick:
	    	call ManyBrick_clearCur
	    clear_pre_brick_over:
		jmp cs:Brick_goTable[si]
	    Brick_goRight_can:
	    	inc (ManyBrick ptr [bx]).mb_sPos.pos_bX
	    	jmp Brick_goNext_over
	    Brick_goLeft_can:
	    	dec (ManyBrick ptr [bx]).mb_sPos.pos_bX
	    	jmp Brick_goNext_over	    
	    Brick_goDown_can:
	    	inc (ManyBrick ptr [bx]).mb_sPos.pos_bY
	    	jmp Brick_goNext_over
	    Brick_goTrun_can:
	    	call Brick_turn
	    	jmp Brick_goNext_over	    
	Brick_goRotate_can:	    
		call Brick_rotate
		jmp Brick_goNext_over
	    do_more_work:
	    	;ignor the left or right or down_complete lead to death
	    	cmp dir,DIR_DOWN
	    jne ring_up_and_ignore
	    	call updateGameState
	    	jmp Brick_goNext_over
	    ring_up_and_ignore:
	    	mov ax,1
	    Brick_goNext_over:
	    	cmp ax,0
	    	jne Brick_go_over
	    	cmp dir,DIR_DOWN_COMPLETE
	    	je down_complete_agian
	    Brick_go_over:
	    	pop si
	    	pop di
	    	pop dx
		pop cx
		pop bx
		pop ax
		ret
	    Brick_tryTable dw Brick_tryRight    , Brick_tryLeft    , Brick_tryDown    , Brick_tryRotate , Brick_tryDown , Brick_tryTrun
	    Brick_GoTable  dw Brick_goRight_can , Brick_goLeft_can , Brick_goDown_can , Brick_goRotate_can , Brick_goDown_can , Brick_goTrun_can
	Brick_goNext endp
	;在方块不能继续下落时，转到此，判断游戏结束，检查满行，产生新块等。
	updateGameState proc
	    	call isGameOver
	   	cmp game.ga_state,GS_RUNNING
	   jne game_is_not_running
	    	call lastBattle
	    	call MB_gernicNext
		call drawNextBrick
	   game_is_not_running:
		ret
	updateGameState endp
	;旋转较为麻烦，单独成子程序
	Brick_rotate proc
		push bx
		push cx
		push di
		push ax
			mov bx,curMB
			mov cx,(ManyBrick ptr [bx]).mb_bCnt
			lea di,(ManyBrick ptr [bx]).mb_sBrick		
		    Brick_rotate_again:
		    	sub cx,1
		    	jc Brick_rotate_over
		    		;rotate it
				neg (Brick ptr [di]).b_sPos.pos_bX
				mov al,(Brick ptr [di]).b_sPos.pos_bY
		    		xchg al,(Brick ptr [di]).b_sPos.pos_bX
		    		mov (Brick ptr [di]).b_sPos.pos_bY,al
		    	add di,size Brick
		    	jmp Brick_rotate_again
		    Brick_rotate_over:
		pop ax
		pop di
		pop cx
		pop bx
		ret
	Brick_rotate endp
	;同旋转，水平翻转也独立成子程序
	Brick_turn proc
		push bx
		push cx
		push di
		push ax
			mov bx,curMB
			mov cx,(ManyBrick ptr [bx]).mb_bCnt
			lea di,(ManyBrick ptr [bx]).mb_sBrick		
		    Brick_turn_again:
		    	sub cx,1
		    	jc Brick_turn_over
		    		;turn it
				neg (Brick ptr [di]).b_sPos.pos_bX
		    	add di,size Brick
		    	jmp Brick_turn_again
		    Brick_turn_over:
		pop ax
		pop di
		pop cx
		pop bx
		ret
	Brick_turn endp	
	;随机生成下一个方块
	MB_gernicNext proc
		push ax
		push bx
		push cx
		push si
		push di
		lea cx,mbArray
		mov di,cx
		mov ax,1
		sub ax,nextNO		
	     jnz cur_will_be_zero	        
	        add cx,size ManyBrick
	        jmp set_next_cur_over
	     cur_will_be_zero:
	      	add di,size ManyBrick	      	
	     set_next_cur_over:
	      	mov curMB,cx
	 	mov nextNO,ax
	 	mov nextMB,di
	     	;di----ManyBrick *	     		 
			assignBase X_START,Y_START
			call getRand
			and al,07h ;ensure the brick's color is <=8 and >=1
		   jnz brick_color_ok
			inc al
		   brick_color_ok:
		   	or al,8
			mov (ManyBrick ptr [di]).mb_bColor,al
			mov (ManyBrick ptr [di]).mb_bCnt ,4
			lea bx,(ManyBrick ptr [di]).mb_bCnt
			;si---Brick *
			lea si,(ManyBrick ptr [di]).mb_sBrick 
			call getRand
			;now di is use for other
			mov di,ax
			call getProperIndex		    	
			shl di,1
			jmp MB_gernicNext_jmpTable[di]
			MBM_gernicNext_Style_0:
				assignPos -1,0
				assignPos 0,0
				assignPos 1,0
				assignPos 2,0
				jmp MBM_gernicNext_over
			MBM_gernicNext_Style_1:			
				assignPos 0,0
				assignPos 1,0
				assignPos 0,-1
				assignPos 1,-1
				jmp MBM_gernicNext_over
			MBM_gernicNext_Style_2:
				assignPos -1,0
				assignPos 0,0
				assignPos 1,0
				assignPos 0,-1
				jmp MBM_gernicNext_over
			MBM_gernicNext_Style_3:
				assignPos -1,0
				assignPos 0,0
				assignPos 0,-1
				assignPos 1,-1	
				jmp MBM_gernicNext_over
			MBM_gernicNext_Style_4:
				assignPos 0,0
				assignPos 0,-1
				assignPos 0,-2
				assignPos 1,0		
				jmp MBM_gernicNext_over
			MBM_gernicNext_Style_5:
				mov (ManyBrick ptr [bx]).mb_bCnt,1
				assignPos 0,0
				jmp MBM_gernicNext_over
			MBM_gernicNext_Style_6:
				mov (ManyBrick ptr [bx]).mb_bCnt,2
				assignPos 0,0
				assignPos 0,1
				jmp MBM_gernicNext_over
			MBM_gernicNext_Style_7:
				mov (ManyBrick ptr [bx]).mb_bCnt,3
				assignPos 0,0
				assignPos -1,0
				assignPos 1,0
				jmp MBM_gernicNext_over
			MBM_gernicNext_Style_8:
				mov (ManyBrick ptr [bx]).mb_bCnt,3
				assignPos 0,0
				assignPos -1,0
				assignPos 0,-1
				jmp MBM_gernicNext_over				
			MBM_gernicNext_Style_9:
				mov (ManyBrick ptr [bx]).mb_bCnt,2
				assignPos 0,0
				assignPos 1,-1
				jmp MBM_gernicNext_over				
			;the next styles but style_F may more difficult
			MBM_gernicNext_Style_A:
				mov (ManyBrick ptr [bx]).mb_bCnt,3
				assignPos 0,0
				assignPos -1,0
				assignPos 1,-1
				jmp MBM_gernicNext_over
			MBM_gernicNext_Style_B:
				mov (ManyBrick ptr [bx]).mb_bCnt,3
				assignPos -1,0
				assignPos 1,0
				assignPos 0,-1
				jmp MBM_gernicNext_over
			MBM_gernicNext_Style_C:
				mov (ManyBrick ptr [bx]).mb_bCnt,3
				assignPos 0,0
				assignPos -1,1
				assignPos 1,-1
				jmp MBM_gernicNext_over
			MBM_gernicNext_Style_D:
				mov (ManyBrick ptr [bx]).mb_bCnt,4
				assignPos 0,0
				assignPos -1,0
				assignPos -1,-1
				assignPos 1,-1
				jmp MBM_gernicNext_over

			MBM_gernicNext_Style_E:
				mov (ManyBrick ptr [bx]).mb_bCnt,4
				assignPos 0,-1
				assignPos -1,0
				assignPos 1,0
				assignPos 0,1
				jmp MBM_gernicNext_over
			MBM_gernicNext_Style_F:
				mov (ManyBrick ptr [bx]).mb_bCnt,1
		MBM_gernicNext_over:
		pop di
		pop si
		pop cx
		pop bx
		pop ax
		ret
		;跳转表
		MB_gernicNext_jmpTable dw MBM_gernicNext_Style_0,MBM_gernicNext_Style_1,MBM_gernicNext_Style_2,MBM_gernicNext_Style_3,\
					  MBM_gernicNext_Style_4,MBM_gernicNext_Style_5,MBM_gernicNext_Style_6,MBM_gernicNext_Style_7,\
					  MBM_gernicNext_Style_8,MBM_gernicNext_Style_9,MBM_gernicNext_Style_A,MBM_gernicNext_Style_B,\
					  MBM_gernicNext_Style_C,MBM_gernicNext_Style_D,MBM_gernicNext_Style_E,MBM_gernicNext_Style_F
		
	MB_gernicNext endp
	;根据当前关数，选择下一个方块的类型
	;关数越高，类型越简单^_^
	;in: di--the random number
	;out: 0<=di <=0fh
	getProperIndex proc
		push ax
		push dx
		push cx
		mov dx,level
		add dx,challenge
		cmp dx,1
		jbe style_less_16
		cmp dx,4
		jbe style_less_13
		mov cx,10
		jmp set_style_out
	   style_less_16:
	   	mov cx,16
	   	jmp set_style_out
	   style_less_13:
	   	mov cx,13
	   set_style_out:
	    	xor dx,dx
	    	mov ax,di
	    	div cx
	    	mov di,dx
	    	pop cx
	    	pop dx
	    	pop ax
		ret
	getProperIndex endp
	;显示当前正下落的方块s
	ManyBrick_drawSelf proc
		push ax
		mov al,CHAR_BRICK
		call ManyBrick_drawCur
		pop ax	
		ret
	ManyBrick_drawSelf endp
	;用空格清除当前下落方块
	ManyBrick_clearCur proc
		push ax
		push cx
		push di
		mov al,CHAR_CLEAR
		mov di,curMB
		mov cl,(ManyBrick ptr [di]).mb_bColor
		mov (ManyBrick ptr [di]).mb_bColor,COLOR_CLEAR
		call ManyBrick_drawCur
		mov (ManyBrick ptr [di]).mb_bColor,cl
		pop di
		pop cx
		pop ax
		ret
	ManyBrick_clearCur endp	
	;显示当前正下落的方块s,方块形状（字符）al可变,用于擦除与显示
	;in:	ManyBrick *curBrick 
	;	al--the char
	ManyBrick_drawCur proc 
		push cx
		push si
		push dx
		push di
		push bx
		mov di,curMB
		mov cx,(ManyBrick ptr [di]).mb_bCnt
		lea si,(ManyBrick ptr [di]).mb_sBrick			
	   drawCur_again:
		mov dh,(Brick ptr [si]).b_sPos.pos_bY
		add dh,(ManyBrick ptr [di]).mb_sPos.pos_bY
		cmp dh,0
		   js ManyBrick_drawCur_ignore
			mov dl,(Brick ptr [si]).b_sPos.pos_bX
			add dl,(ManyBrick ptr [di]).mb_sPos.pos_bX
			mov bl,(ManyBrick ptr [di]).mb_bColor
			call drawBrick				
	   	   ManyBrick_drawCur_ignore:			
	   	add si,size Brick
	   loop drawCur_again
	   	pop bx
	   	pop di
		pop dx
		pop si
		pop cx
		ret
	ManyBrick_drawCur endp
	;显示游戏区域边框
	;in:	dh--y  ,dl--x;	al---char;  bl---color	
	moreBeautiful proc		
		mov bl,Y_BOUND_COLOR
		mov dh,-1
		mov cx,GM_HEIGHT+2		
	    draw_yBound_again:
	    		mov dl,-1
			mov al,Y_LBOUND_CHAR
	    		call drawBrick
	    		mov dl,GM_WIDTH
	    		mov al,Y_RBOUND_CHAR
	    		call drawBrick
	    		inc dh
	    	loop draw_yBound_again
	    	mov bl,X_BOUND_COLOR
	    	mov cx,GM_WIDTH
	    	mov dl,0
	    draw_xBound_again:
	    	mov dh,-1
	    	mov al,X_UBOUND_CHAR
	    	call drawBrick
	    	mov dh,GM_HEIGHT
	    	mov al,X_DBOUND_CHAR
	    	call drawBrick
	    	inc dl
	    	loop draw_xBound_again
		;显示版本信息
		mov si,offset gameNameStr
		mov dl,X_GAME_NAME
		mov dh,Y_GAME_NAME
		mov cx,8
		call showStr	    	
		ret
	moreBeautiful endp	
	;判断(dl,dh)是否在游戏区域内,注意未判断dl是否小于0
	;in:	dl--x,	dh--y
	isPosLeagel proc
		push ax
		cmp dl,0
		js  isPosLeagel_return		
		mov al,GM_WIDTH-1
		cmp al,dl
		js  isPosLeagel_return
		;cmp dh,0
		;js isPosLeagel_return
		mov al,GM_HEIGHT-1
		cmp al,dh
		isPosLeagel_return:
		pop ax
		ret
	isPosLeagel endp	
	;在(dl,dh)处以bl颜色显示一个al
	;in:	dl--x,	dh--y;  al---char;   bl---color
	drawBrick proc 		
		push dx
		push bx
		push cx
		push ax		
		;设置输出位置为(dl,dh)
		add dl,GM_LEFT
		add dh,GM_TOP
		mov ah,02h
		xor bh,bh
		int 10h
		pop ax
		push ax
		;在当前位置输出字符al
		mov ah,09h
		mov cx,1
		int 10h
		pop ax
		pop cx
		pop bx
		pop dx
		ret
	drawBrick endp	
	;在(dl,dh)处显示字符串(首地址si,长度cx,颜色默认)
	;in:	si--str buf;	cx--char count;	 dl--x,dh--y >>start pos
	showStr proc	
		push ax
		push bx
		mov bl,COLOR_TITTLE		
		cld
	   show_str_again:	   
	   	lodsb
	   	call drawBrick
	   	inc dl
	   loop show_str_again
	   	pop bx
	   	pop ax
		ret
	showStr endp
	;延时，期间还出理键盘输入
	delay	proc
		push cx
		mov cx,05fffh
	   delay_again:
	   	call processUserInput
	   	loop delay_again
	   	pop cx
		ret
	delay	endp
	;用线性同余法得到一个随机数
	;out: ax & seed ---the randomize number
	getRand proc
		;seed=(seed*217+25111)%31111，此公式常量测试所得,也许并不理想
		push dx
		push cx
		mov ax,217
		xor dx,dx
		mul seed
		add ax,25111
		adc dx,0
		mov cx,31111
		div cx
		mov seed,dx
		mov ax,dx
		pop cx
		pop dx
		ret
	getRand endp
GameCode ends

;数据段
MainData segment
	;两个方块s，一个用于当前下落的，一个用于下一个要下落的
	mbArray	ManyBrick <>,<>
	;分别指向当前与下一个要下落的方块s的指针，能据nextNO交替变换
	curMB 	dw ? ;ManyBrick*
	nextMB 	dw ? ;ManyBrick*
	nextNO	dw 0
	dir 	dw 2	
	game 	GameApp <>	
	challenge dw 0
	seed	dw ?
	levelFPS dw 023h,020h,1eh,01dh,01ch,01bh,01ah,010h,\
		    0fh ,0eh ,0dh,0ch,0bh,0ah,09h,01h; 0-15
	level	dw 0	
	
	levelScore db   -1,15,29,42,54,65,75,84,92,99,105,111,116,120,124;15 counts	
	levelScoreLast db 130 
	mode	dw 0
	;diedBrickColorSame db 0
	;showBackground	   db 1

	judgeTable	dw badJob,normalJob,goodJob
	judgeCnt	dw 41,16,27

	scoreStr 	db 'SCORE:';6 chars
	levelStr	db 'LEVEL:';6 chars
	levelDeltStr	db 'LevelDelt:';10 chars
	modeStr		db 'ColorMode:'; 10 chars
	gameOverStr	db '   Game come to end! Press any key to replay.';45 chars
	gamePausedStr	db 'Game is sleeping! Press any key to wake it up.';46 chars
	gameNameStr	db 'CNBv0.13'; 8 chars
	gameFinishedStr db 'Congratulations,you of genius can get a signature from ZW!';58 chars
	badJob		db 'Poor score,but sad not.You are not alone!';41
	normalJob	db 'Yeah,you normal!';16
	goodJob		db 'Smart you the same failure.';27
	
	usageStr	db 27,'mov left |',27,'mov right |',24,'rotate ',25,'down quickly |','END:turn horizontally'
	usageStrCNT	dw $-usageStr
	
	usageStrEx	db 'ESC:quit  |Del:pause  |F3:increase the LevelDelt  |F2:be contrary to F3'
	usageStrExCNT   dw $-usageStrEx
	
	linkToCoderStr	db 'F1 :chang color mode  | Any question please QQ to <307831078>.'
	linkToCoderCNT	dw $-linkToCoderStr	

MainData ends

;堆栈
StackSpase segment stack 'stack'
        db      100h    dup(?)
        stackPoint label byte
StackSpase ends

end