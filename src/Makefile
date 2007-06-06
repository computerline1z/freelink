DC=dmd
LIBS=-L-lSDL

all:
	$(DC) -c contrib/SDL.d
	$(DC) -c -Icontrib/ *.d
	$(DC) -offreelink *.o $(LIBS)

clean:
	rm *.o