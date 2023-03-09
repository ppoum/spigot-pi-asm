%.o: %.asm
	nasm -Wall -f elf64 -g -o $@ $<

main: main.o
	ld -o $@ $<

clean:
	rm -f main main.o