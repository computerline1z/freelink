DC=gdc
DFLAGS=-Icontrib
LFLAGS=-lSDL -lSDL_ttf
OBJECTS=obj/

all: freelink

resolve_imports:

freelink: $(subst .d,.o,$(shell find -iname "*.d"))
	$(DC) $(OBJECTS)*.o -o freelink $(LDFLAGS)

%.o: %.d
	mkdir -p $(OBJECTS)
	$(DC) $(DFLAGS) -c $< -o $(OBJECTS)$(subst /,_,$@)

clean:
	rm $(OBJECTS)*.o
