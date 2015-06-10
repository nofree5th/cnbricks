#文件名称：makefile
#此文件用于描述源程序之间的相互关系并自动完成维护编译工作，简单而有效
#解析此文件需要make工具，MinGW(C++ IDE)中带有ASM=ml
ASM=ml
LINK=ml
MODEL_FLAG=/c /nologo
MODELS=entry.obj game.obj
all:cnb.exe
%.obj:%.ASM game.h
	$(ASM) $(MODEL_FLAG) $<
cnb.exe:$(MODELS)
	$(LINK) /Fe cnb.exe $(MODELS)
	cnb
clean:
	rm *.obj
	cls
	dir