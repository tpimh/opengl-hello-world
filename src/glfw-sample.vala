using GLFW;
using GL;

int main () {
    bool running = true;

    // Initialize GLFW
    init ();

    // Open an OpenGL window
    Window w;
    if ((w = new Window(640, 480, "GLFW3 Hello World", null, null)) == null) {
        terminate ();
        return 1;
    }
    
    w.make_context_current ();
    
    // Main loop
    while (running) {
        // OpenGL rendering goes here...
        glClear (GL_COLOR_BUFFER_BIT);
        glBegin (GL_TRIANGLES);
            glVertex3f ( 0.0f, 1.0f, 0.0f);
            glVertex3f (-1.0f,-1.0f, 0.0f);
            glVertex3f ( 1.0f,-1.0f, 0.0f);
        glEnd ();

        // Swap front and back rendering buffers
        w.swap_buffers ();
        
        // Update input values
        poll_events ();
        
        // Check if ESC key was pressed or window was closed
        running = !(ButtonState.PRESS == w.get_key (Key.ESCAPE) || w.should_close);
    }

    // Close window and terminate GLFW
    terminate ();

    // Exit program
    return 0;
}
