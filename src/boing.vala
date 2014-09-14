/* Ported to Vala by Dmitry Golovin <dima@golovin.in> */
/*****************************************************************************
* Title:   GLBoing
* Desc:    Tribute to Amiga Boing.
* Author:  Jim Brooks  <gfx@jimbrooks.org>
*          Original Amiga authors were R.J. Mical and Dale Luck.
*          GLFW conversion by Marcus Geelnard
* Notes:   - 360' = 2*PI [radian]
*
*          - Distances between objects are created by doing a relative
*            Z translations.
*
*          - Although OpenGL enticingly supports alpha-blending,
*            the shadow of the original Boing didn't affect the color
*            of the grid.
*
*          - [Marcus] Changed timing scheme from interval driven to frame-
*            time based animation steps (which results in much smoother
*            movement)
*
* History of Amiga Boing:
*
* Boing was demonstrated on the prototype Amiga (codenamed "Lorraine") in
* 1985. According to legend, it was written ad-hoc in one night by
* R. J. Mical and Dale Luck. Because the bouncing ball animation was so fast
* and smooth, attendees did not believe the Amiga prototype was really doing
* the rendering. Suspecting a trick, they began looking around the booth for
* a hidden computer or VCR.
*****************************************************************************/

using GLFW;
using GLU;
using GL;

/*****************************************************************************
* Various declarations and macros
*****************************************************************************/

const float RADIUS            = 70.0f;
const float STEP_LONGITUDE    = 22.5f;   /* 22.5 makes 8 bands like original Boing */
const float STEP_LATITUDE     = 22.5f;

const float DIST_BALL         = (RADIUS * 2.0f + RADIUS * 0.1f);

const float VIEW_SCENE_DIST   = (DIST_BALL * 3.0f + 200.0f);    /* distance from viewer to middle of boing area */
const float GRID_SIZE         = (RADIUS * 4.5f);                /* length (width) of grid */
const float BOUNCE_HEIGHT     = (RADIUS * 2.1f);
const float BOUNCE_WIDTH      = (RADIUS * 2.1f);

const float SHADOW_OFFSET_X   = -20.0f;
const float SHADOW_OFFSET_Y   = 10.0f;
const float SHADOW_OFFSET_Z   = 0.0f;

const float WALL_L_OFFSET     = 0.0f;
const float WALL_R_OFFSET     = 5.0f;

/* Animation speed (50.0 mimics the original GLUT demo speed) */
const float ANIMATION_SPEED   = 50.0f;

/* Maximum allowed delta time per physics iteration */
const float MAX_DELTA_T       = 0.02f;

/* Draw ball, or its shadow */
enum DrawBall {
    DRAW_BALL,
    DRAW_BALL_SHADOW
}

/* Vertex type */
struct vertex_t {
    public float x;
    public float y;
    public float z;
}

/* Global vars */
int width;
int height;
GLfloat deg_rot_y       = 0.0f;
GLfloat deg_rot_y_inc   = 2.0f;
bool override_pos  = false;
GLfloat cursor_x        = 0.0f;
GLfloat cursor_y        = 0.0f;
GLfloat ball_x          = 0.0f;     // to be redefined 
GLfloat ball_y          = 0.0f;     // to be redefined 
GLfloat ball_x_inc      = 1.0f;
GLfloat ball_y_inc      = 2.0f;
DrawBall drawBallHow;
double  t;
double  t_old = 0.0f;
double  dt;

/* Random number generator */
const int RAND_MAX = 4095;

// next line was moved here due to compilation error (possibly compiler bug?)
const int        rowTotal    = 12;                   /* must be divisible by 2 */

/*****************************************************************************
* Truncate a degree.
*****************************************************************************/
GLfloat TruncateDeg (GLfloat deg) {
    if (deg >= 360.0f)
        return (deg - 360.0f);
    else
        return deg;
}

/*****************************************************************************
* Convert a degree (360-based) into a radian.
* 360' = 2 * PI
*****************************************************************************/
double deg2rad (double deg) {
    return deg / 360 * (2 * Math.PI);
}

/*****************************************************************************
* 360' Math.sin ().
*****************************************************************************/
double sin_deg  (double deg) {
    return Math.sin (deg2rad (deg));
}

/*****************************************************************************
* 360' Math.cos ().
*****************************************************************************/
double cos_deg (double deg) {
    return Math.cos (deg2rad (deg));
}

/*****************************************************************************
* Compute a cross product (for a normal vector).
*
* c = a x b
*****************************************************************************/
vertex_t CrossProduct (vertex_t a, vertex_t b, vertex_t c) {
    GLfloat u1, u2, u3;
    GLfloat v1, v2, v3;

    u1 = b.x - a.x;
    u2 = b.y - a.y;
    u3 = b.y - a.z;

    v1 = c.x - a.x;
    v2 = c.y - a.y;
    v3 = c.z - a.z;

    return vertex_t () { x = u2 * v3 - v2 * v3, y = u3 * v1 - v3 * u1, z = u1 * v2 - v1 * u2 };
}

/*****************************************************************************
* Calculate the angle to be passed to gluPerspective() so that a scene
* is visible.  This function originates from the OpenGL Red Book.
*
* Parms   : size
*           The size of the segment when the angle is intersected at "dist"
*           (ie at the outermost edge of the angle of vision).
*
*           dist
*           Distance from viewpoint to scene.
*****************************************************************************/
GLfloat PerspectiveAngle (GLfloat size, GLfloat dist) {
    GLfloat radTheta, degTheta;

    radTheta = 2.0f * (GLfloat) Math.atan2 (size / 2.0f, dist);
    degTheta = (180.0f * radTheta) / (GLfloat) Math.PI;
    return degTheta;
}

/*****************************************************************************
* init()
*****************************************************************************/
void init () {
    // global var reinitialization
    ball_x = -RADIUS;
    ball_y = -RADIUS;
    
    /*
    * Clear background.
    */
    glClearColor(0.55f, 0.55f, 0.55f, 0.0f);

    glShadeModel(GL_FLAT);
}


/*****************************************************************************
* display()
*****************************************************************************/
void display () {
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glPushMatrix();
        drawBallHow = DrawBall.DRAW_BALL_SHADOW;
        DrawBoingBall();

        DrawGrid();

        drawBallHow = DrawBall.DRAW_BALL;
        DrawBoingBall();
    glPopMatrix();
    glFlush();
}


/*****************************************************************************
* reshape()
*****************************************************************************/
void reshape (Window window, int w, int h) {
    glViewport (0, 0, (GLsizei) w, (GLsizei) h);

    glMatrixMode (GL_PROJECTION);
    glLoadIdentity ();

    gluPerspective (PerspectiveAngle (RADIUS * 2, 200), (GLfloat) w / (GLfloat) h, 1.0f, VIEW_SCENE_DIST);

    glMatrixMode (GL_MODELVIEW);
    glLoadIdentity ();

    gluLookAt (0.0, 0.0, VIEW_SCENE_DIST,   /* eye */
                0.0, 0.0, 0.0,              /* center of vision */
                0.0, -1.0, 0.0);            /* up vector */
}

void key_callback (Window window, Key key, int scancode, ButtonState action, ModifierFlags mods) {
    if (key == Key.ESCAPE && action == ButtonState.PRESS)
        window.should_close = true;
}

static void set_ball_pos (GLfloat x, GLfloat y) {
    ball_x = (width / 2) - x;
    ball_y = y - (height / 2);
}

void mouse_button_callback (Window window, int button, ButtonState action) {
    if (button != MouseButton.LEFT)
        return;

    if (action == ButtonState.PRESS) {
        override_pos = true;
        set_ball_pos (cursor_x, cursor_y);
    } else {
        override_pos = false;
    }
}

void cursor_position_callback (Window window, int x, int y) {
    cursor_x = (float) x;
    cursor_y = (float) y;

    if (override_pos)
        set_ball_pos (cursor_x, cursor_y);
}

/*****************************************************************************
* Draw the Boing ball.
*
* The Boing ball is sphere in which each facet is a rectangle.
* Facet colors alternate between red and white.
* The ball is built by stacking latitudinal circles.  Each circle is composed
* of a widely-separated set of points, so that each facet is noticably large.
*****************************************************************************/
void DrawBoingBall () {
    GLfloat lon_deg;        /* degree of longitude */
    double dt_total, dt2;

    glPushMatrix();
        glMatrixMode(GL_MODELVIEW);

        /*
        * Another relative Z translation to separate objects.
        */
        glTranslatef (0.0f, 0.0f, DIST_BALL);

        /* Update ball position and rotation (iterate if necessary) */
        dt_total = dt;
        while (dt_total > 0.0) {
            dt2 = dt_total > MAX_DELTA_T ? MAX_DELTA_T : dt_total;
            dt_total -= dt2;
            BounceBall (dt2);
            deg_rot_y = TruncateDeg (deg_rot_y + deg_rot_y_inc * ((float) dt2 * ANIMATION_SPEED));
        }

        /* Set ball position */
        glTranslatef (ball_x, ball_y, 0.0f);

        /*
        * Offset the shadow.
        */
        if (drawBallHow == DrawBall.DRAW_BALL_SHADOW)
            glTranslatef (SHADOW_OFFSET_X, SHADOW_OFFSET_Y, SHADOW_OFFSET_Z);

        /*
        * Tilt the ball.
        */
        glRotatef (-20.0f, 0.0f, 0.0f, 1.0f);

        /*
        * Continually rotate ball around Y axis.
        */
        glRotatef (deg_rot_y, 0.0f, 1.0f, 0.0f);

        /*
        * Set OpenGL state for Boing ball.
        */
        glCullFace (GL_FRONT);
        glEnable (GL_CULL_FACE);
        glEnable (GL_NORMALIZE);

        /*
        * Build a faceted latitude slice of the Boing ball,
        * stepping same-sized vertical bands of the sphere.
        */
        for (lon_deg = 0; lon_deg < 180; lon_deg += STEP_LONGITUDE) {
        /*
        * Draw a latitude circle at this longitude.
        */
            DrawBoingBallBand(lon_deg, lon_deg + STEP_LONGITUDE);
        }
    glPopMatrix();
}


/*****************************************************************************
* Bounce the ball.
*****************************************************************************/
void BounceBall (double delta_t) {
    GLfloat sign;
    GLfloat deg;

    if (override_pos)
        return;

    /* Bounce on walls */
    if (ball_x >  (BOUNCE_WIDTH / 2 + WALL_R_OFFSET)) {
        ball_x_inc = -0.5f - 0.75f * (GLfloat) (Random.next_double () / RAND_MAX);
        deg_rot_y_inc = -deg_rot_y_inc;
    }
    if (ball_x < -(BOUNCE_HEIGHT / 2 + WALL_L_OFFSET)) {
        ball_x_inc =  0.5f + 0.75f * (GLfloat) (Random.next_double () / RAND_MAX);
        deg_rot_y_inc = -deg_rot_y_inc;
    }

    /* Bounce on floor / roof */
    if (ball_y >  BOUNCE_HEIGHT / 2     ) {
        ball_y_inc = -0.75f - 1.0f * (GLfloat) (Random.next_double () / RAND_MAX);
    }
    if (ball_y < -BOUNCE_HEIGHT / 2 * 0.85) {
        ball_y_inc =  0.75f + 1.0f * (GLfloat) (Random.next_double () / RAND_MAX);
    }

    /* Update ball position */
    ball_x += ball_x_inc * ((float) delta_t * ANIMATION_SPEED);
    ball_y += ball_y_inc * ((float) delta_t * ANIMATION_SPEED);

    /*
    * Simulate the effects of gravity on Y movement.
    */
    if (ball_y_inc < 0) sign = -1.0f; else sign = 1.0f;

    deg = (ball_y + BOUNCE_HEIGHT / 2) * 90 / BOUNCE_HEIGHT;
    if (deg > 80) deg = 80;
    if (deg < 10) deg = 10;

    ball_y_inc = sign * 4.0f * (float) sin_deg (deg);
}


/*****************************************************************************
* Draw a faceted latitude band of the Boing ball.
*
* Parms:   long_lo, long_hi
*          Low and high longitudes of slice, resp.
*****************************************************************************/
void DrawBoingBallBand(GLfloat long_lo, GLfloat long_hi) {
    vertex_t vert_ne;            /* "ne" means south-east, so on */
    vertex_t vert_nw;
    vertex_t vert_sw;
    vertex_t vert_se;
    vertex_t vert_norm;
    GLfloat  lat_deg;
    bool color_toggle = false;

    vert_ne = vertex_t () { x = 0, y = 0, z = 0 };
    vert_nw = vertex_t () { x = 0, y = 0, z = 0 };
    vert_sw = vertex_t () { x = 0, y = 0, z = 0 };
    vert_se = vertex_t () { x = 0, y = 0, z = 0 };

    /*
    * Iterate thru the points of a latitude circle.
    * A latitude circle is a 2D set of X,Z points.
    */
    for (lat_deg = 0; lat_deg <= (360 - STEP_LATITUDE); lat_deg += STEP_LATITUDE) {
    /*
    * Color this polygon with red or white.
    */
    if (color_toggle)
        glColor3f (0.8f, 0.1f, 0.1f);
    else
        glColor3f (0.95f, 0.95f, 0.95f);
/*
    if (lat_deg >= 180)
        if (color_toggle)
            glColor3f(0.1f, 0.8f, 0.1f);
        else
            glColor3f(0.5f, 0.5f, 0.95f);
*/
    color_toggle = ! color_toggle;

    /*
    * Change color if drawing shadow.
    */
    if (drawBallHow == DrawBall.DRAW_BALL_SHADOW)
    glColor3f (0.35f, 0.35f, 0.35f);

    /*
    * Assign each Y.
    */
    vert_ne.y = vert_nw.y = (float) cos_deg (long_hi) * RADIUS;
    vert_sw.y = vert_se.y = (float) cos_deg (long_lo) * RADIUS;

    /*
    * Assign each X,Z with Math.sin ,cos values scaled by latitude radius indexed by longitude.
    * Eg, long=0 and long=180 are at the poles, so zero scale is Math.sin (longitude),
    * while long=90 (sin(90)=1) is at equator.
    */
    vert_ne.x = (float) cos_deg (lat_deg                ) * (RADIUS * (float) sin_deg (long_lo + STEP_LONGITUDE));
    vert_se.x = (float) cos_deg (lat_deg                ) * (RADIUS * (float) sin_deg (long_lo                 ));
    vert_nw.x = (float) cos_deg (lat_deg + STEP_LATITUDE) * (RADIUS * (float) sin_deg (long_lo + STEP_LONGITUDE));
    vert_sw.x = (float) cos_deg (lat_deg + STEP_LATITUDE) * (RADIUS * (float) sin_deg (long_lo                 ));

    vert_ne.z = (float) sin_deg (lat_deg                ) * (RADIUS * (float) sin_deg (long_lo + STEP_LONGITUDE));
    vert_se.z = (float) sin_deg (lat_deg                ) * (RADIUS * (float) sin_deg (long_lo                 ));
    vert_nw.z = (float) sin_deg (lat_deg + STEP_LATITUDE) * (RADIUS * (float) sin_deg (long_lo + STEP_LONGITUDE));
    vert_sw.z = (float) sin_deg (lat_deg + STEP_LATITUDE) * (RADIUS * (float) sin_deg (long_lo                 ));

    /*
    * Draw the facet.
    */
    glBegin(GL_POLYGON);
        vert_norm = CrossProduct (vert_ne, vert_nw, vert_sw);
        glNormal3f (vert_norm.x, vert_norm.y, vert_norm.z);

        glVertex3f (vert_ne.x, vert_ne.y, vert_ne.z);
        glVertex3f (vert_nw.x, vert_nw.y, vert_nw.z);
        glVertex3f (vert_sw.x, vert_sw.y, vert_sw.z);
        glVertex3f (vert_se.x, vert_se.y, vert_se.z);
    glEnd();

#if DEBUG
    stdout.printf("----------------------------------------------------------- \n");
    stdout.printf("lat = %f  long_lo = %f  long_hi = %f \n", lat_deg, long_lo, long_hi);
    stdout.printf("vert_ne  x = %.8f  y = %.8f  z = %.8f \n", vert_ne.x, vert_ne.y, vert_ne.z);
    stdout.printf("vert_nw  x = %.8f  y = %.8f  z = %.8f \n", vert_nw.x, vert_nw.y, vert_nw.z);
    stdout.printf("vert_se  x = %.8f  y = %.8f  z = %.8f \n", vert_se.x, vert_se.y, vert_se.z);
    stdout.printf("vert_sw  x = %.8f  y = %.8f  z = %.8f \n", vert_sw.x, vert_sw.y, vert_sw.z);
#endif
}

    /*
    * Toggle color so that next band will opposite red/white colors than this one.
    */
    color_toggle = ! color_toggle;

    /*
    * This circular band is done.
    */
    return;
}


/*****************************************************************************
* Draw the purple grid of lines, behind the Boing ball.
* When the Workbench is dropped to the bottom, Boing shows 12 rows.
*****************************************************************************/
void DrawGrid() {
    int              row, col;
    const int        colTotal    = rowTotal;             /* must be same as rowTotal */
    const GLfloat    widthLine   = 2.0f;                 /* should be divisible by 2 */
    const GLfloat    sizeCell    = GRID_SIZE / rowTotal;
    const GLfloat    z_offset    = -40.0f;
    GLfloat          xl, xr;
    GLfloat          yt, yb;

    glPushMatrix ();
        glDisable (GL_CULL_FACE);

        /*
        * Another relative Z translation to separate objects.
        */
        glTranslatef (0.0f, 0.0f, DIST_BALL);

        /*
        * Draw vertical lines (as skinny 3D rectangles).
        */
        for (col = 0; col <= colTotal; col++) {
            /*
            * Compute co-ords of line.
            */
            xl = -GRID_SIZE / 2 + col * sizeCell;
            xr = xl + widthLine;

            yt =  GRID_SIZE / 2;
            yb = -GRID_SIZE / 2 - widthLine;

            glBegin (GL_POLYGON);
                glColor3f (0.6f, 0.1f, 0.6f);       /* purple */

                glVertex3f (xr, yt, z_offset);      /* NE */
                glVertex3f (xl, yt, z_offset);      /* NW */
                glVertex3f (xl, yb, z_offset);      /* SW */
                glVertex3f (xr, yb, z_offset);      /* SE */
            glEnd ();
        }

        /*
        * Draw horizontal lines (as skinny 3D rectangles).
        */
        for (row = 0; row <= rowTotal; row++) {
            /*
            * Compute co-ords of line.
            */
            yt = GRID_SIZE / 2 - row * sizeCell;
            yb = yt - widthLine;

            xl = -GRID_SIZE / 2;
            xr =  GRID_SIZE / 2 + widthLine;

            glBegin (GL_POLYGON);
                glColor3f (0.6f, 0.1f, 0.6f);       /* purple */

                glVertex3f (xr, yt, z_offset);      /* NE */
                glVertex3f (xl, yt, z_offset);      /* NW */
                glVertex3f (xl, yb, z_offset);      /* SW */
                glVertex3f (xr, yb, z_offset);      /* SE */
            glEnd ();
        }
    glPopMatrix ();

    return;
}


/*======================================================================*
* main()
*======================================================================*/

int main () {
    Window window;

    /* Init GLFW */
    if (!GLFW.init ())
        return 1;

    WindowHint.DEPTH_BITS.set (16);

    window = new Window(400, 400, "Boing (classic Amiga demo)", null, null);
    if (window == null) {
        terminate();
        return 1;
    }

    window.set_framebuffer_size_callback (reshape);
    window.set_key_callback (key_callback);
    window.set_mouse_button_callback (mouse_button_callback);
    window.set_cursor_pos_callback (cursor_position_callback);

    window.make_context_current ();
    swap_interval (1);

    window.get_framebuffer_size (out width, out height);
    reshape (window, width, height);

    set_time (0.0);

    init ();

    /* Main loop */
    for (;;) {
        /* Timing */
        t = get_time ();
        dt = t - t_old;
        t_old = t;

        /* Draw one frame */
        display ();

        /* Swap buffers */
        window.swap_buffers ();
        poll_events ();

        /* Check if we are still running */
        if (window.should_close)
            break;
    }

    terminate();
    return 0;
}
