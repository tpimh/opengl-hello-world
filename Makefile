all: glfw-sample simple gears boing

glfw-sample: src/glfw-sample.vala
	valac --vapidir=./vapi/ --pkg gl --pkg glfw3 -o glfw-sample.out src/glfw-sample.vala

simple: src/simple.vala
	valac --vapidir=./vapi/ --pkg gl --pkg glfw3 -o simple.out src/simple.vala

gears: src/gears.vala
	valac --vapidir=./vapi/ --pkg gl --pkg glfw3 -X -lm -o gears.out src/gears.vala

boing: src/boing.vala
	valac --vapidir=./vapi/ --pkg gl --pkg glfw3 --pkg glu -X -lm -o boing.out src/boing.vala

clean:
	rm -rf *.out
