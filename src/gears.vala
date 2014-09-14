/* Ported to Vala by Dmitry Golovin <dima@golovin.in> */
/*
* 3-D gear wheels.  This program is in the public domain.
*
* Command line options:
*    -info      print GL implementation information
*    -exit      automatically exit after 30 seconds
*
*
* Brian Paul
*
*
* Marcus Geelnard:
*   - Conversion to GLFW
*   - Time based rendering (frame rate independent)
*   - Slightly modified camera that should work better for stereo viewing
*
*
* Camilla Berglund:
*   - Removed FPS counter (this is not a benchmark)
*   - Added a few comments
*   - Enabled vsync
*/

using GLFW;
using GL;

/* If non-zero, the program exits after that many seconds
*/
static int autoexit = 0;

/**

    Draw a gear wheel.  You'll probably want to call this function when
    building a display list since we do a lot of trig here.

    Input:  inner_radius - radius of hole at center
            outer_radius - radius at center of teeth
            width - width of gear teeth - number of teeth
            tooth_depth - depth of tooth

**/

static void gear (GLfloat inner_radius, GLfloat outer_radius, GLfloat width, GLint teeth, GLfloat tooth_depth) {
    GLint i;
    GLfloat r0, r1, r2;
    GLfloat angle, da;
    GLfloat u, v, len;

    r0 = inner_radius;
    r1 = outer_radius - tooth_depth / 2.0f;
    r2 = outer_radius + tooth_depth / 2.0f;

    da = 2.0f * (float) Math.PI / teeth / 4.0f;

    glShadeModel (GL_FLAT);

    glNormal3f (0.0f, 0.0f, 1.0f);

    /* draw front face */
    glBegin (GL_QUAD_STRIP);
        for (i = 0; i <= teeth; i++) {
            angle = i * 2.0f * (float) Math.PI / teeth;
            glVertex3f (r0 * (float) Math.cos (angle), r0 * (float) Math.sin (angle), width * 0.5f);
            glVertex3f (r1 * (float) Math.cos (angle), r1 * (float) Math.sin (angle), width * 0.5f);
            if (i < teeth) {
                glVertex3f (r0 * (float) Math.cos (angle), r0 * (float) Math.sin (angle), width * 0.5f);
                glVertex3f (r1 * (float) Math.cos (angle + 3 * da), r1 * (float) Math.sin (angle + 3 * da), width * 0.5f);
            }
        }
    glEnd ();

    /* draw front sides of teeth */
    glBegin (GL_QUADS);
        da = 2.0f * (float) Math.PI / teeth / 4.0f;
        for (i = 0; i < teeth; i++) {
            angle = i * 2.0f * (float) Math.PI / teeth;

            glVertex3f (r1 * (float) Math.cos (angle), r1 * (float) Math.sin (angle), width * 0.5f);
            glVertex3f (r2 * (float) Math.cos (angle + da), r2 * (float) Math.sin (angle + da), width * 0.5f);
            glVertex3f (r2 * (float) Math.cos (angle + 2 * da), r2 * (float) Math.sin (angle + 2 * da), width * 0.5f);
            glVertex3f (r1 * (float) Math.cos (angle + 3 * da), r1 * (float) Math.sin (angle + 3 * da), width * 0.5f);
        }
    glEnd ();

    glNormal3f (0.0f, 0.0f, -1.0f);

    /* draw back face */
    glBegin (GL_QUAD_STRIP);
        for (i = 0; i <= teeth; i++) {
            angle = i * 2.0f * (float) Math.PI / teeth;
            glVertex3f (r1 * (float) Math.cos (angle), r1 * (float) Math.sin (angle), -width * 0.5f);
            glVertex3f (r0 * (float) Math.cos (angle), r0 * (float) Math.sin (angle), -width * 0.5f);
            if (i < teeth) {
                glVertex3f (r1 * (float) Math.cos (angle + 3 * da), r1 * (float) Math.sin (angle + 3 * da), -width * 0.5f);
                glVertex3f (r0 * (float) Math.cos (angle), r0 * (float) Math.sin (angle), -width * 0.5f);
            }
        }
    glEnd ();

    /* draw back sides of teeth */
    glBegin (GL_QUADS);
        da = 2.0f * (float) Math.PI / teeth / 4.0f;
        for (i = 0; i < teeth; i++) {
            angle = i * 2.0f * (float) Math.PI / teeth;

            glVertex3f (r1 * (float) Math.cos (angle + 3 * da), r1 * (float) Math.sin (angle + 3 * da), -width * 0.5f);
            glVertex3f (r2 * (float) Math.cos (angle + 2 * da), r2 * (float) Math.sin (angle + 2 * da), -width * 0.5f);
            glVertex3f (r2 * (float) Math.cos (angle + da), r2 * (float) Math.sin (angle + da), -width * 0.5f);
            glVertex3f (r1 * (float) Math.cos (angle), r1 * (float) Math.sin (angle), -width * 0.5f);
        }
    glEnd ();

    /* draw outward faces of teeth */
    glBegin (GL_QUAD_STRIP);
        for (i = 0; i < teeth; i++) {
            angle = i * 2.0f * (float) Math.PI / teeth;

            glVertex3f (r1 * (float) Math.cos (angle), r1 * (float) Math.sin (angle), width * 0.5f);
            glVertex3f (r1 * (float) Math.cos (angle), r1 * (float) Math.sin (angle), -width * 0.5f);
            u = r2 * (float) Math.cos (angle + da) - r1 * (float) Math.cos (angle);
            v = r2 * (float) Math.sin (angle + da) - r1 * (float) Math.sin (angle);
            len = (float) Math.sqrt (u * u + v * v);
            u /= len;
            v /= len;
            glNormal3f (v, -u, 0.0f);
            glVertex3f (r2 * (float) Math.cos (angle + da), r2 * (float) Math.sin (angle + da), width * 0.5f);
            glVertex3f (r2 * (float) Math.cos (angle + da), r2 * (float) Math.sin (angle + da), -width * 0.5f);
            glNormal3f ((float) Math.cos (angle), (float) Math.sin (angle), 0.0f);
            glVertex3f (r2 * (float) Math.cos (angle + 2 * da), r2 * (float) Math.sin (angle + 2 * da), width * 0.5f);
            glVertex3f (r2 * (float) Math.cos (angle + 2 * da), r2 * (float) Math.sin (angle + 2 * da), -width * 0.5f);
            u = r1 * (float) Math.cos (angle + 3 * da) - r2 * (float) Math.cos (angle + 2 * da);
            v = r1 * (float) Math.sin (angle + 3 * da) - r2 * (float) Math.sin (angle + 2 * da);
            glNormal3f (v, -u, 0.0f);
            glVertex3f (r1 * (float) Math.cos (angle + 3 * da), r1 * (float) Math.sin (angle + 3 * da), width * 0.5f);
            glVertex3f (r1 * (float) Math.cos (angle + 3 * da), r1 * (float) Math.sin (angle + 3 * da), -width * 0.5f);
            glNormal3f ((float) Math.cos (angle), (float) Math.sin (angle), 0.0f);
        }

        glVertex3f (r1 * (float) Math.cos (0), r1 * (float) Math.sin (0), width * 0.5f);
        glVertex3f (r1 * (float) Math.cos (0), r1 * (float) Math.sin (0), -width * 0.5f);

    glEnd ();

    glShadeModel (GL_SMOOTH);

    /* draw inside radius cylinder */
    glBegin (GL_QUAD_STRIP);
        for (i = 0; i <= teeth; i++) {
            angle = i * 2.0f * (float) Math.PI / teeth;
            glNormal3f (-(float) Math.cos (angle), -(float) Math.sin (angle), 0.0f);
            glVertex3f (r0 * (float) Math.cos (angle), r0 * (float) Math.sin (angle), -width * 0.5f);
            glVertex3f (r0 * (float) Math.cos (angle), r0 * (float) Math.sin (angle), width * 0.5f);
        }
    glEnd ();
}

static GLfloat view_rotx = 20.0f;
static GLfloat view_roty = 30.0f;
static GLfloat view_rotz = 0.0f;
static GLuint gear1;
static GLuint gear2;
static GLuint gear3;
static GLfloat angle = 0.0f;

/* OpenGL draw function & timing */
static void draw () {
    glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glPushMatrix ();
        glRotatef (view_rotx, 1.0f, 0.0f, 0.0f);
        glRotatef (view_roty, 0.0f, 1.0f, 0.0f);
        glRotatef (view_rotz, 0.0f, 0.0f, 1.0f);

        glPushMatrix ();
            glTranslatef (-3.0f, -2.0f, 0.0f);
            glRotatef (angle, 0.0f, 0.0f, 1.0f);
            glCallList (gear1);
        glPopMatrix ();

        glPushMatrix ();
            glTranslatef (3.1f, -2.0f, 0.0f);
            glRotatef (-2.0f * angle - 9.0f, 0.0f, 0.0f, 1.0f);
            glCallList (gear2);
        glPopMatrix ();

        glPushMatrix ();
            glTranslatef (-3.1f, 4.2f, 0.0f);
            glRotatef (-2.0f * angle - 25.0f, 0.0f, 0.0f, 1.0f);
            glCallList (gear3);
        glPopMatrix ();
    glPopMatrix ();
}

/* update animation parameters */
static void animate () {
    angle = 100.0f * (float) get_time ();
}

/* change view angle, exit upon ESC */
void key_press (Window window, Key k, int s, ButtonState action, ModifierFlags mods) {
    if (action != ButtonState.PRESS)
        return;

    switch (k) {
    case Key.Z:
        if ((bool) (mods & ModifierFlags.SHIFT))
            view_rotz -= 5.0f;
        else
            view_rotz += 5.0f;
        break;
    case Key.ESCAPE:
        window.should_close = true;
        break;
    case Key.UP:
        view_rotx += 5.0f;
        break;
    case Key.DOWN:
        view_rotx -= 5.0f;
        break;
    case Key.LEFT:
        view_roty += 5.0f;
        break;
    case Key.RIGHT:
        view_roty -= 5.0f;
        break;
    default:
        return;
    }
}

/* new window size */
void reshape (Window window, int width, int height) {
    GLfloat h = (GLfloat) height / (GLfloat) width;
    GLfloat xmax, znear, zfar;

    znear = 5.0f;
    zfar  = 30.0f;
    xmax  = znear * 0.5f;

    glViewport (0, 0, (GLint) width, (GLint) height);
    glMatrixMode (GL_PROJECTION);
    glLoadIdentity ();
    glFrustum (-xmax, xmax, -xmax * h, xmax * h, znear, zfar);
    glMatrixMode (GL_MODELVIEW);
    glLoadIdentity ();
    glTranslatef (0.0f, 0.0f, -20.0f);
}

/* program & OpenGL initialization */
static void init (string[] args) {
    GLfloat pos[4] = {5.0f, 5.0f, 10.0f, 0.0f};
    GLfloat red[4] = {0.8f, 0.1f, 0.0f, 1.0f};
    GLfloat green[4] = {0.0f, 0.8f, 0.2f, 1.0f};
    GLfloat blue[4] = {0.2f, 0.2f, 1.0f, 1.0f};

    glLightfv (GL_LIGHT0, GL_POSITION, pos);
    glEnable (GL_CULL_FACE);
    glEnable (GL_LIGHTING);
    glEnable (GL_LIGHT0);
    glEnable (GL_DEPTH_TEST);

    /* make the gears */
    gear1 = glGenLists (1);
    glNewList (gear1, GL_COMPILE);
        glMaterialfv (GL_FRONT, GL_AMBIENT_AND_DIFFUSE, red);
        gear (1.0f, 4.0f, 1.0f, 20, 0.7f);
    glEndList ();

    gear2 = glGenLists (1);
    glNewList (gear2, GL_COMPILE);
        glMaterialfv (GL_FRONT, GL_AMBIENT_AND_DIFFUSE, green);
        gear (0.5f, 2.0f, 2.0f, 10, 0.7f);
    glEndList ();

    gear3 = glGenLists (1);
    glNewList (gear3, GL_COMPILE);
        glMaterialfv (GL_FRONT, GL_AMBIENT_AND_DIFFUSE, blue);
        gear (1.3f, 2.0f, 0.5f, 10, 0.7f);
    glEndList ();

    glEnable (GL_NORMALIZE);

    foreach (string arg in args) {
        if (arg == "-info") {
            GLib.stdout.printf ("GL_RENDERER   = %s\n", glGetString (GL_RENDERER));
            GLib.stdout.printf ("GL_VERSION    = %s\n", glGetString (GL_VERSION));
            GLib.stdout.printf ("GL_VENDOR     = %s\n", glGetString (GL_VENDOR));
            GLib.stdout.printf ("GL_EXTENSIONS = %s\n", glGetString (GL_EXTENSIONS));
        }
        else if (arg == "-exit") {
            autoexit = 30;
            GLib.stdout.printf ("Auto Exit after %i seconds.\n", autoexit);
        }
    }
}

/* program entry */
int main (string[] args) {
    Window window;
    int width, height;

    if (GLFW.init () == false) {
        GLib.stderr.printf ("Failed to initialize GLFW\n");
        return 1;
    }
    
    WindowHint.DEPTH_BITS.set(16);

    window = new Window (300, 300, "Gears", null, null);
    if (window == null) {
        GLib.stderr.printf ("Failed to open GLFW window\n");
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

    // Parse command-line options
    init (args);

    // Main loop
    while (!window.should_close) {
        // Draw gears
        draw ();

        // Update animation
        animate ();

        // Swap buffers
        window.swap_buffers ();
        poll_events ();
    }

    // Terminate GLFW
    terminate ();

    // Exit program
    return 0;
}
