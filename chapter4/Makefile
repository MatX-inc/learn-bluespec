.PHONY: all clean run

all: calculator

calculator: Parser.hs Calculator.hs
	ghc -Wall Parser.hs Calculator.hs -o calculator

run: calculator
	./calculator

clean:
	rm -f calculator *.hi *.o
