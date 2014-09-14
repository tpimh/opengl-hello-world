/* Ported to Vala by Dmitry Golovin <dima@golovin.in> */
//========================================================================
// Simple GLFW example
// Copyright (c) Camilla Berglund <elmindreda@elmindreda.org>
//
// This software is provided 'as-is', without any express or implied
// warranty. In no event will the authors be held liable for any damages
// arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//    claim that you wrote the original software. If you use this software
//    in a product, an acknowledgment in the product documentation would
//    be appreciated but is not required.
//
// 2. Altered source versions must be plainly marked as such, and must not
//    be misrepresented as being the original software.
//
// 3. This notice may not be removed or altered from any source
//    distribution.
//
//========================================================================
//! [code]

using GLFW;
using GL;

static void error_callback (ErrorCode error, string description) {
    stderr.printf("%s\n", description);
}

static void key_callback (Window window, Key key, int scancode, ButtonState action, ModifierFlags mods) {
    if (key == Key.ESCAPE && action == ButtonState.PRESS)
        window.should_close = true;
}

int main() {
    Window window;
    
    set_error_callback (error_callback);

    if (init () == false)
        return 1;
    
    window = new Window (640, 480, "Simple example", null, null);
    if (window == null) {
        terminate ();
        return 1;
    }

    window.make_context_current ();

    window.set_key_callback (key_callback);

    while (!window.should_close) {
        float ratio;
        int width, height;

        window.get_framebuffer_size (out width, out height);
        ratio = width / (float) height;

        glViewport (0, 0, width, height);
        glClear (GL_COLOR_BUFFER_BIT);

        glMatrixMode (GL_PROJECTION);
        glLoadIdentity ();
        glOrtho (-ratio, ratio, -1.0f, 1.0f, 1.0f, -1.0f);
        glMatrixMode (GL_MODELVIEW);

        glLoadIdentity ();
        glRotatef ((float) get_time() * 50.0f, 0.0f, 0.0f, 1.0f);

        glBegin (GL_TRIANGLES);
            glColor3f (1.0f, 0.0f, 0.0f);
            glVertex3f (-0.6f, -0.4f, 0.0f);
            glColor3f (0.0f, 1.0f, 0.0f);
            glVertex3f (0.6f, -0.4f, 0.0f);
            glColor3f (0.0f, 0.0f, 1.0f);
            glVertex3f (0.0f, 0.6f, 0.0f);
        glEnd ();

        window.swap_buffers ();
        poll_events ();
    }

    window = null;

    terminate ();
    return 0;
}
//! [code]
