all:
	valac --vapidir=./vapi/ --pkg gl --pkg glfw3 -o glfw-sample src/glfw-sample.vala
