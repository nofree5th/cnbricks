#�ļ����ƣ�makefile
#���ļ���������Դ����֮����໥��ϵ���Զ����ά�����빤�����򵥶���Ч
#�������ļ���Ҫmake���ߣ�MinGW(C++ IDE)�д���ASM=ml
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