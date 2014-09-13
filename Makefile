all:
	valac --vapidir=./vapi/ --pkg gl --pkg libglfw -o glfw-sample src/glfw-sample.vala
