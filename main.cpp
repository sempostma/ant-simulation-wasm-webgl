

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif

#include <SDL.h>
#include <SDL_opengles2.h>

#include "events.h"
#include "timer.h"

#include <string>
#include <cstdio>
#include <iostream>
#include <fstream>
#include <vector>

#define ANTS 30000
#define ANTS_DATA 6
#define ANTS_DATA_TOTAL 65532
#define ANTS_TEX_DIM 256
#define SCALE 10
#define ANTS_DATA_TEX_W 1000
#define ANTS_DATA_TEX_H 60

EM_JS(int, canvas_get_width, (), {
  return canv.width;
});

EM_JS(int, canvas_get_height, (), {
  return canv.height;
});

GLfloat antPointsVertices[ANTS * 3];

void initAntPointVertices() {
    for(int i = 0; i < ANTS; i++) {
        antPointsVertices[i*3] = (float)i;
        antPointsVertices[i*3+1] = 0.0f;
        antPointsVertices[i*3+2] = 0.0f;
    }
}

struct intBytes {
    GLbyte ho;
    GLbyte lo;
};

struct intBytes convertPositionToBytes(ushort pos) {
    struct intBytes b;
    b.ho = (GLbyte)(pos / 255);
    b.lo = (GLbyte)(pos % 255);
    return b;
}

ushort convertPositionToInt(GLbyte ho, GLbyte lo) {
    return (ushort)ho * 255 + (ushort)lo;
}

void loadShader(GLuint shader, const char *filePath)
{
    std::string content;
    std::ifstream fileStream(filePath, std::ios::in);

    if (!fileStream.is_open())
    {
        std::cerr << "Could not read file " << filePath << ". File does not exist." << std::endl;
        return;
    }

    std::string line = "";
    while (!fileStream.eof())
    {
        std::getline(fileStream, line);
        content.append(line + "\n");
    }

    fileStream.close();

    const char *str = content.c_str();

    printf("shader source %s:\n%s\n", filePath, str);

    glShaderSource(shader, 1, &str, nullptr);
    glCompileShader(shader);

    GLint compiled;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);

    if (!compiled)
    {
        GLint infoLen = 0;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLen);

        if (infoLen > 1)
        {
            char *infoLog = (char *)malloc(sizeof(char) * (size_t)infoLen);
            glGetShaderInfoLog(shader, infoLen, NULL, infoLog);
            printf("Error compiling shader %s:\n%s", filePath, infoLog);
            free(infoLog);
        }
        glDeleteShader(shader);
        return;
    }
}

// Vertex shader
GLint shaderPan, shaderZoom, shaderAspect, antsTextureLoc, v_antsTextureLoc, pheremonesTextureLoc, shaderProgram, v_renderMode, f_renderMode, viewport, f_viewport;
GLuint antsTextureName1, antsTextureName2, pheremonesTextureName1, pheremonesTextureName2, vbo, antsFbo1, antsFbo2, pheremonesFbo1, pheremonesFbo2;

void resizeShader(EventHandler &eventHandler)
{
    Camera &camera = eventHandler.camera();
    Rect &windowSize = camera.windowSize();

    glUniform2fv(viewport, 1, camera.viewport());
    glUniform2fv(f_viewport, 1, camera.viewport());
    glBindTexture(GL_TEXTURE_2D, pheremonesTextureName1);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, windowSize.width, windowSize.height, 0, GL_RGB, GL_UNSIGNED_BYTE, nullptr);

    glBindTexture(GL_TEXTURE_2D, pheremonesTextureName2);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, windowSize.width, windowSize.height, 0, GL_RGB, GL_UNSIGNED_BYTE, nullptr);

    printf("resize shader %ix%i\n", windowSize.width, windowSize.height);
}

void updateShader(EventHandler &eventHandler)
{
    Camera &camera = eventHandler.camera();

    glUniform2fv(shaderPan, 1, camera.pan());
    glUniform1f(shaderZoom, camera.zoom());
    glUniform1f(shaderAspect, camera.aspect());
}

GLuint initShader(EventHandler &eventHandler)
{
    Camera &camera = eventHandler.camera();

    // Create and compile vertex shader
    GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
    loadShader(vertexShader, "./vertex.glsl");

    // Create and compile fragment shader
    GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    loadShader(fragmentShader, "./fragment.glsl");

    // Link vertex and fragment shader into shader program and use it
    GLuint shaderProgram = glCreateProgram();
    glAttachShader(shaderProgram, vertexShader);
    glAttachShader(shaderProgram, fragmentShader);
    glLinkProgram(shaderProgram);
    glUseProgram(shaderProgram);

    // Get shader variables and initialize them
    shaderPan = glGetUniformLocation(shaderProgram, "pan");
    shaderZoom = glGetUniformLocation(shaderProgram, "zoom");
    shaderAspect = glGetUniformLocation(shaderProgram, "aspect");
    antsTextureLoc = glGetUniformLocation(shaderProgram, "antsTexture");
    v_antsTextureLoc = glGetUniformLocation(shaderProgram, "v_antsTexture");
    viewport = glGetUniformLocation(shaderProgram, "viewport");
    f_viewport = glGetUniformLocation(shaderProgram, "f_viewport");
    pheremonesTextureLoc = glGetUniformLocation(shaderProgram, "pheremonesTexture");
    v_renderMode = glGetUniformLocation(shaderProgram, "v_renderMode");
    f_renderMode = glGetUniformLocation(shaderProgram, "f_renderMode");

    glUniform1i(v_renderMode, 1);
    glUniform1i(f_renderMode, 1);
    glUniform2fv(viewport, 1, camera.viewport());

    updateShader(eventHandler);

    return shaderProgram;
}

int checkFramebufferStatus(const char* name) {
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    int error = 1;

    switch (status)
    {
    case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT:
        printf("GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT (%s)\n", name);

        break;

    case GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS:
        printf("GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS (%s)\n", name);

        break;

    case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
        printf("GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT (%s)\n", name);

        break;
    case GL_FRAMEBUFFER_UNSUPPORTED:
        printf("GL_FRAMEBUFFER_UNSUPPORTED (%s)\n", name);

        break;

    case GL_FRAMEBUFFER_COMPLETE:
        error = 0;
        break;

    default:
        printf("Uknown framebuffer error status (%s)\n", name);
        break;
    }

    return error;
}

void reportAntPosition(int index) {
    GLubyte data[8];
    glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
    glReadPixels(index * 2, 0, 2, 1, GL_RGBA, GL_UNSIGNED_BYTE, data);
    printf("reporting on ant %i\n", index);
    
    GLubyte xHO = data[0];
    GLubyte xLO = data[1];
    GLubyte yHO = data[2];
    GLubyte yLO = data[4];

    ushort xA = convertPositionToInt(xHO, xLO);
    ushort yA = convertPositionToInt(yHO, yLO);
    
    float xR = (float)xA / SCALE;
    float yR = (float)yA / SCALE;
    
    printf("Raw position: xHO=%u, xLO=%u, yHO=%u, yLO=%u\n", xHO, xLO, yHO, yLO);
    printf("Absolute position: x=%u, y=%u\n", xA, yA);
    printf("Scaled position: x=%.2f, y=%.2f\n", xR, yR);

    printf("Heading: %u\n", data[5]);
}

void initTextures(GLuint shaderProgram, EventHandler &eventHandler)
{
    Camera &camera = eventHandler.camera();
    Rect &windowSize = camera.windowSize();

    int maxTextureSize;
    glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
    printf("Max texture size %i\n", maxTextureSize);
    printf("Current tex dimensions %ix%i\n", ANTS_TEX_DIM, ANTS_TEX_DIM);

    // ants data texture
    GLubyte antsData[ANTS * ANTS_DATA];

    for (int i = 0; i < ANTS; i++)
    {
        auto x = convertPositionToBytes(windowSize.width * SCALE / 2);
        auto y = convertPositionToBytes(windowSize.height * SCALE / 2);

        antsData[i * ANTS_DATA] = x.ho;                   // position x, higher order
        antsData[i * ANTS_DATA + 1] = x.lo;        // position x, lower order
        antsData[i * ANTS_DATA + 2] = y.ho;                                                             // position y, higher order
        antsData[i * ANTS_DATA + 3] = y.lo;               // positoin y, lower order
        antsData[i * ANTS_DATA + 4] = (GLubyte)((float)i / (float)ANTS * 255);        // angle (0 - 255 instead of 0 - 360)
        antsData[i * ANTS_DATA + 5] = 0;                                                             // not used
    }

    // ants data texture
    // GLubyte phereomonesData[windowSize.width * windowSize.height * 3];
    // for (int i = 0; i < windowSize.width * windowSize.height; i++)
    // {
    //     phereomonesData[i * 3] = 0;                 
    //     phereomonesData[i * 3 + 1] = 0;      
    //     phereomonesData[i * 3 + 2] = 0;                                                          
    // }

    // initialize texture uniform
    glUniform1i(antsTextureLoc, 0);
    glUniform1i(v_antsTextureLoc, 0);
    glUniform1i(pheremonesTextureLoc, 1);

    // initialize pheremones texture 1
    glActiveTexture(GL_TEXTURE0 + 1);
    glGenTextures(1, &pheremonesTextureName1);
    glBindTexture(GL_TEXTURE_2D, pheremonesTextureName1);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, windowSize.width, windowSize.height, 0, GL_RGB, GL_UNSIGNED_BYTE, nullptr);

    // initialize pheremones texture 2
    glActiveTexture(GL_TEXTURE0 + 1);
    glGenTextures(1, &pheremonesTextureName2);
    glBindTexture(GL_TEXTURE_2D, pheremonesTextureName2);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, windowSize.width, windowSize.height, 0, GL_RGB, GL_UNSIGNED_BYTE, nullptr);

    // initialize ants texture 1 (this contains the initial state)
    glActiveTexture(GL_TEXTURE0);
    glGenTextures(1, &antsTextureName1);
    glBindTexture(GL_TEXTURE_2D, antsTextureName1);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, ANTS_DATA_TEX_W, ANTS_DATA_TEX_H, 0, GL_RGB, GL_UNSIGNED_BYTE, antsData);

    // initialize ants texture 2
    glActiveTexture(GL_TEXTURE0);
    glGenTextures(1, &antsTextureName2);
    glBindTexture(GL_TEXTURE_2D, antsTextureName2);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, ANTS_DATA_TEX_W, ANTS_DATA_TEX_H, 0, GL_RGB, GL_UNSIGNED_BYTE, nullptr);

    // initialize ants fbo 1
    glGenFramebuffers(1, &antsFbo1);
    glBindFramebuffer(GL_FRAMEBUFFER, antsFbo1);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, antsTextureName1, 0);
    checkFramebufferStatus("ants FBO 1");

    // initialize ants fbo 2
    glGenFramebuffers(1, &antsFbo2);
    glBindFramebuffer(GL_FRAMEBUFFER, antsFbo2);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, antsTextureName2, 0);
    checkFramebufferStatus("ants FBO 2");

    // initialize pheremones fbo 1
    glGenFramebuffers(1, &pheremonesFbo1);
    glBindFramebuffer(GL_FRAMEBUFFER, pheremonesFbo1);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, pheremonesTextureName1, 0);
    checkFramebufferStatus("pheremones FBO 1");

    // initialize pheremones fbo 2
    glGenFramebuffers(1, &pheremonesFbo2);
    glBindFramebuffer(GL_FRAMEBUFFER, pheremonesFbo2);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, pheremonesTextureName2, 0);
    checkFramebufferStatus("pheremones FBO 2");

    resizeShader(eventHandler);
}

GLfloat vertices[] =
    {
        -1.0f, -1.0f, 0.0f,
        1.0f, -1.0f, 1.0f,
        -1.0f, 1.0f, 2.0f,
        1.0f, -1.0f, 3.0f,
        1.0f, 1.0f, 4.0f,
        -1.0f, 1.0f, 5.0f
    };

void initGeometry(GLuint shaderProgram)
{
    // Create vertex buffer object and copy vertex data into it
    glGenBuffers(1, &vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    // Specify the layout of the shader vertex data (positions only, 3 floats)
    GLint posAttrib = glGetAttribLocation(shaderProgram, "position");
    glEnableVertexAttribArray(posAttrib);
    glVertexAttribPointer(posAttrib, 3, GL_FLOAT, GL_FALSE, 0, 0);
}

GLfloat antsLineVertices[] =
    {
        -1.0f,
        0.0f,
        0.0f,
        1.0f,
        0.0f,
        0.0f,
};

float d1 = 0.0;
float d2 = 0.0;
float d3 = 0.0;
float d4 = 0.0;
float d5 = 0.0;
float d6 = 0.0;
float d7 = 0.0;
float d8 = 0.0;
int iterations = 0;

Timer t;
auto const start_time = std::chrono::steady_clock::now();
auto const wait_time = std::chrono::milliseconds{ 17 };
auto next_time = start_time + wait_time;

void redraw(EventHandler &eventHandler)
{
    // make sure the program runs no faster than 60fps
    auto then = std::chrono::high_resolution_clock::now();
    auto sleep_time = std::chrono::duration_cast<std::chrono::milliseconds> (next_time - then);
    int ms = sleep_time.count();
    if (ms > 0) emscripten_sleep(ms);

    // start rendering

    Camera &camera = eventHandler.camera();
    Rect &windowSize = camera.windowSize();

    d1 += t.tick();

    // Clear screen
    glClear(GL_COLOR_BUFFER_BIT);

    glUniform1i(v_renderMode, 1);
    glUniform1i(f_renderMode, 1);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, antsTextureName1);
    glActiveTexture(GL_TEXTURE0 + 1);
    glBindTexture(GL_TEXTURE_2D, pheremonesTextureName1);
    glBindFramebuffer(GL_FRAMEBUFFER, antsFbo2);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    glViewport(0, 0, ANTS_DATA_TEX_W, ANTS_DATA_TEX_W);
    glDrawArrays(GL_TRIANGLES, 0, 6);

    d2 += t.tick();

    // swap ant textures and frame buffers
    GLuint antsTextureNameTmp = antsTextureName1;
    antsTextureName1 = antsTextureName2;
    antsTextureName2 = antsTextureNameTmp;

    GLuint antsFboTmp = antsFbo1;
    antsFbo1 = antsFbo2;
    antsFbo2 = antsFboTmp;

    // reportAntPosition(1);

    d3 += t.tick();

    glViewport(0, 0, windowSize.width, windowSize.height);

    // write to pheremonebuffer
    glUniform1i(v_renderMode, 3);
    glUniform1i(f_renderMode, 3);

    glBindFramebuffer(GL_FRAMEBUFFER, pheremonesFbo2);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, antsTextureName1);
    glActiveTexture(GL_TEXTURE0 + 1);
    glBindTexture(GL_TEXTURE_2D, pheremonesTextureName1);
    glBufferData(GL_ARRAY_BUFFER, sizeof(antPointsVertices), antPointsVertices, GL_STATIC_DRAW);
    glDrawArrays(GL_POINTS, 0, ANTS);

    d4 += t.tick();

    // swap pheremones textures and frame buffers
    GLuint pheremonesTextureNameTmp = pheremonesTextureName1;
    pheremonesTextureName1 = pheremonesTextureName2;
    pheremonesTextureName2 = pheremonesTextureNameTmp;

    GLuint pheremonesFboTmp = pheremonesFbo1;
    pheremonesFbo1 = pheremonesFbo2;
    pheremonesFbo2 = pheremonesFboTmp;

    d5 += t.tick();

    // blur pheremone texture
    glUniform1i(v_renderMode, 2);
    glUniform1i(f_renderMode, 2);
    glActiveTexture(GL_TEXTURE0 + 1);
    glBindFramebuffer(GL_FRAMEBUFFER, pheremonesFbo2);
    glBindTexture(GL_TEXTURE_2D, pheremonesTextureName1);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    glDrawArrays(GL_TRIANGLES, 0, 6);

    d6 += t.tick();

    // draw result to screen
    glBindFramebuffer(GL_FRAMEBUFFER, 0); // remove the frame buffer
    glActiveTexture(GL_TEXTURE0 + 1);
    glBindTexture(GL_TEXTURE_2D, pheremonesTextureName2);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    glUniform1i(v_renderMode, 4);
    glUniform1i(f_renderMode, 4);
    glDrawArrays(GL_TRIANGLES, 0, 6);

    d7 += t.tick();

    // Swap front/back framebuffers
    eventHandler.swapWindow();

    d8 += t.tick();

    iterations++;

    if (iterations == 10) {
        // skip the first inconsistent frames
        d1 = 0.0;
        d2 = 0.0;
        d3 = 0.0;
        d4 = 0.0;
        d5 = 0.0;
        d6 = 0.0;
        d7 = 0.0;
        d8 = 0.0;

        printf("Start measuring\n");
    }

    if (iterations == 300) {
        printf("Times d1=%f, d2=%f, d3=%f, d4=%f, d5=%f, d6=%f, d7=%f, d8=%f\n", d1, d2, d3, d4, d5, d6, d7, d8);
    }

    auto elasped_time = std::chrono::duration_cast<std::chrono::milliseconds> (std::chrono::high_resolution_clock::now() - then);
    next_time += wait_time;
}

void mainLoop(void *mainLoopArg)
{
    EventHandler &eventHandler = *((EventHandler *)mainLoopArg);
    eventHandler.processEvents();

    // Update shader if camera changed
    if (eventHandler.camera().updated())
        updateShader(eventHandler);

    if (eventHandler.camera().windowResized()) {
        resizeShader(eventHandler);
    }

    redraw(eventHandler);
}

int main(int argc, char **argv)
{
    EventHandler eventHandler("Hello Triangle");
    t.start();

    Camera &camera = eventHandler.camera();
    int width = canvas_get_width();
    int height = canvas_get_height();
    camera.setWindowSize(width, height);

    // Initialize shader and geometry
    initAntPointVertices();
    shaderProgram = initShader(eventHandler);
    initGeometry(shaderProgram);
    initTextures(shaderProgram, eventHandler);

    // Start the main loop
    void *mainLoopArg = &eventHandler;

#ifdef __EMSCRIPTEN__
    int fps = 0; // Use browser's requestAnimationFrame
    emscripten_set_main_loop_arg(mainLoop, mainLoopArg, fps, true);
#else
    while (true)
        mainLoop(mainLoopArg);
#endif

    return 0;
}