

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif

#include <SDL.h>
#include <SDL_opengles2.h>

#include "events.h"

#include <string>
#include <cstdio>
#include <iostream>
#include <fstream>
#include <vector>

#define ANTS 10
#define ANTS_DATA 3

void loadShader(GLuint shader, const char *filePath) {
    std::string content;
    std::ifstream fileStream(filePath, std::ios::in);

    if(!fileStream.is_open()) {
        std::cerr << "Could not read file " << filePath << ". File does not exist." << std::endl;
        return;
    }

    std::string line = "";
    while(!fileStream.eof()) {
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

    if (!compiled) {
        GLint infoLen = 0;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLen);

        if(infoLen > 1)
        {
            char* infoLog = (char *)malloc(sizeof(char) * (size_t)infoLen);
            glGetShaderInfoLog(shader, infoLen, NULL, infoLog);
            printf("Error compiling shader %s:\n%s", filePath, infoLog);
            free(infoLog);
        }
        glDeleteShader(shader);
        return;
    }
}

// Vertex shader
GLint shaderPan, shaderZoom, shaderAspect, texture1Loc;
GLuint texture1Name;

void updateShader(EventHandler& eventHandler)
{
    Camera& camera = eventHandler.camera();

    glUniform2fv(shaderPan, 1, camera.pan());
    glUniform1f(shaderZoom, camera.zoom()); 
    glUniform1f(shaderAspect, camera.aspect());
}

GLuint initShader(EventHandler& eventHandler)
{
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
    texture1Loc = glGetUniformLocation(shaderProgram, "texture1");
    updateShader(eventHandler);

    return shaderProgram;
}

void initTextures(GLuint shaderProgram) {
    float data[ANTS*ANTS_DATA];
    for(int i = 0; i < ANTS; i++) {
        // data[i*ANTS_DATA] = float(rand()%100)/100.0;
        // data[i*ANTS_DATA+1] = float(rand()%100)/100.0;
        // data[i*ANTS_DATA+2] = float(rand()%100)/100.0;
        // data[i*ANTS_DATA+3] = 1.0f;
        data[i*ANTS_DATA] = (float)i/(float)ANTS;
        data[i*ANTS_DATA+1] = 1.0f - (float)i/(float)ANTS;
        data[i*ANTS_DATA+2] = 0.0f;
        data[i*ANTS_DATA+3] = 1.0f;
    }
    
    glUniform1i(texture1Loc, 0);
    glActiveTexture(GL_TEXTURE0);
    glGenTextures(1, &texture1Name);
    glBindTexture(GL_TEXTURE_2D, texture1Name);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1, ANTS, 0, GL_RGBA, GL_FLOAT, data);
}

void initGeometry(GLuint shaderProgram)
{
    // Create vertex buffer object and copy vertex data into it
    GLuint vbo;
    glGenBuffers(1, &vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);

    GLfloat vertices[] = 
    {
        -1.0f, -1.0f, 0.0f,
        1.0f, -1.0f, 1.0f,
        -1.0f, 1.0f, 2.0f,
        1.0f, -1.0f, 3.0f,
        1.0f, 1.0f, 4.0f,
        -1.0f, 1.0f, 5.0f
    };

    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    // Specify the layout of the shader vertex data (positions only, 3 floats)
    GLint posAttrib = glGetAttribLocation(shaderProgram, "position");
    glEnableVertexAttribArray(posAttrib);
    glVertexAttribPointer(posAttrib, 3, GL_FLOAT, GL_FALSE, 0, 0);
}

void redraw(EventHandler& eventHandler)
{
    // Clear screen
    glClear(GL_COLOR_BUFFER_BIT);

    // Draw the vertex buffer
    glDrawArrays(GL_TRIANGLES, 0, 6);

    // Swap front/back framebuffers
    eventHandler.swapWindow();
}

void mainLoop(void* mainLoopArg) 
{   
    EventHandler& eventHandler = *((EventHandler*)mainLoopArg);
    eventHandler.processEvents();

    // Update shader if camera changed
    if (eventHandler.camera().updated())
        updateShader(eventHandler);

    redraw(eventHandler);
}

int main(int argc, char** argv)
{
    EventHandler eventHandler("Hello Triangle");

    // Initialize shader and geometry
    GLuint shaderProgram = initShader(eventHandler);
    initGeometry(shaderProgram);
    initTextures(shaderProgram);

    // Start the main loop
    void* mainLoopArg = &eventHandler;

#ifdef __EMSCRIPTEN__
    int fps = 0; // Use browser's requestAnimationFrame
    emscripten_set_main_loop_arg(mainLoop, mainLoopArg, fps, true);
#else
    while(true) 
        mainLoop(mainLoopArg);
#endif

    return 0;
}