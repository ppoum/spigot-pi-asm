%.o: %.asm
	nasm -Wall -f elf64 -g -o $@ $<

all: main.o
	ld -o spigot-pi $<

clean:
	rm -f main main.o