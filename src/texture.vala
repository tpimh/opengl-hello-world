/*
 * Simple texturing example. Also a basic GLFW program skeleton.
 * 
 * Copyright 2014 Dmitry Golovin
 * This document is free software; see LICENCE file.
 * 
 * Author: Dmitry Golovin <dima@golovin.in>
 */

using GLFW;
using GL;

static void error_callback (ErrorCode error, string description) {
    string errormsg = "[ERROR_";
    switch (error) {
    case ErrorCode.NOT_INITIALIZED:
        errormsg += "NOT_INITIALIZED";
        break;
    case ErrorCode.NO_CURRENT_CONTEXT:
        errormsg += "NO_CURRENT_CONTEXT";
        break;
    case ErrorCode.INVALID_ENUM:
        errormsg += "INVALID_ENUM";
        break;
    case ErrorCode.INVALID_VALUE:
        errormsg += "INVALID_VALUE";
        break;
    case ErrorCode.OUT_OF_MEMORY:
        errormsg += "OUT_OF_MEMORY";
        break;
    case ErrorCode.API_UNAVAILABLE:
        errormsg += "API_UNAVAILABLE";
        break;
    case ErrorCode.VERSION_UNAVAILABLE:
        errormsg += "VERSION_UNAVAILABLE";
        break;
    case ErrorCode.PLATFORM_ERROR:
        errormsg += "PLATFORM_ERROR";
        break;
    case ErrorCode.FORMAT_UNAVAILABLE:
        errormsg += "FORMAT_UNAVAILABLE";
        break;
    }
    errormsg += "]";
    
    stderr.printf("%s %s\n", errormsg, description);
}

/* exit on ESC */
static void key_press (Window window, Key k, int s, ButtonState action, ModifierFlags mods) {
    if (action != ButtonState.PRESS)
        return;

    if (k == Key.ESCAPE)
        window.should_close = true;
}

/* new window size */
static void reshape (Window window, int width, int height) {
    stdout.printf("size: %dx%d\n", width, height);
}

/* program entry */
int main (string[] args) {
    Window window;
    int width, height;
    
    set_error_callback (error_callback);

    if (GLFW.init () == false)
        return 1;

    if ((window = new Window (200, 200, "Texture", null, null)) == null) {
        terminate ();
        return 1;
    }

    // Set callback functions
    window.set_framebuffer_size_callback (reshape);
    window.set_key_callback (key_press);

    window.make_context_current ();
    swap_interval (1);

    window.get_framebuffer_size (out width, out height);
    reshape (window, width, height);

    // init begin
    bool growing = true;
    GLdouble size = 50.0;
    double time_passed = 0.0;
    
    set_time (0.0);     // reset time to zero
    
    glEnable (GL_BLEND);
    glEnable (GL_TEXTURE_2D);
    glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDisable (GL_DEPTH_TEST);      // don't need DEPTH_TEST, will not use 3d
    
    GLuint[] tex = new GLuint[1];
	glGenTextures (1, tex);

    float[] pixels =  { 0.0f, 0.0f, 0.0f,   1.0f, 1.0f, 1.0f,
                        1.0f, 1.0f, 1.0f,   0.0f, 0.0f, 0.0f };

    glBindTexture (GL_RGB, 1);                    

    glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, (GLint) GL_NEAREST);
    glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, (GLint) GL_NEAREST);
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, (GLint) GL_REPEAT);
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, (GLint) GL_REPEAT);
    
    glTexImage2D (GL_TEXTURE_2D, 0, (GLint) GL_RGB, 2, 2, 0, GL_RGB, GL_FLOAT, pixels);
    // init end
    
    // Main loop
    while (!window.should_close) {
        // update begin
        
        if (!growing)
            size -= (get_time () - time_passed) * 10.0;
        else
            size += (get_time () - time_passed) * 10.0;
        
        if (size <= 0.0)
            growing = true;
        
        if (size >= 50.0)
            growing = false;
        
        time_passed = get_time ();
        // update end
        
        // draw begin
        glClearColor (0.5f, 0.5f, 0.5f, 0.0f); // gray background
        glClear(GL_COLOR_BUFFER_BIT);
        
        glMatrixMode (GL_PROJECTION);
        glLoadIdentity ();
        glOrtho (0.0, (GLdouble) width, 0.0, (GLdouble) height, -1.0, 1.0);

        // first quad
        glBegin (GL_QUADS);
            glTexCoord2i (0, 0);
            glVertex2d (0.0, 0.0);
            glTexCoord2i (3, 0);
            glVertex2d (100.0 - size, 0.0);
            glTexCoord2i (3, 3);
            glVertex2d (100.0 - size, 100.0 - size);
            glTexCoord2i (0, 3);
            glVertex2d (0.0, 100.0 - size);
        glEnd ();
        
        // second quad        
        glBegin (GL_QUADS);
            glTexCoord2i (0, 0);
            glVertex2d (100.0 - size, 100.0 - size);
            glTexCoord2i (5 - (int) growing, 0);
            glVertex2d (150.0 - size, 100.0 - size);
            glTexCoord2i (5 - (int) growing, 5 - (int) growing);
            glVertex2d (150.0 - size, 150.0 - size);
            glTexCoord2i (0, 5 - (int) growing);
            glVertex2d (100.0 - size, 150.0 - size);
        glEnd ();
        
        // third quad
        glBegin (GL_QUADS);
            glTexCoord2i (0, 0);
            glVertex2d (150.0 - size, 150.0 - size);
            glTexCoord2i (3, 0);
            glVertex2d (200.0, 150.0 - size);
            glTexCoord2i (3, 3);
            glVertex2d (200.0, 200.0);
            glTexCoord2i (0, 3);
            glVertex2d (150.0 - size, 200.0);
        glEnd ();

        glFlush ();
        // draw end
        
        window.swap_buffers ();
        poll_events ();
    }
    
    set_error_callback (null);  // removing error callback
                                // without this we will get an error
    terminate ();
    return 0;
}
