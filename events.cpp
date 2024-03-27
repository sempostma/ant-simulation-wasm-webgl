//
// Window and input event handling
//
#include <algorithm>
#include <emscripten.h>
#include <SDL.h>
#include <SDL_opengles2.h>
#include <emscripten/html5.h>
#include "events.h" 
#include <iostream>
#include <stdio.h>

// #define EVENTS_DEBUG

void EventHandler::windowResizeEvent(int width, int height)
{
    printf("width=%i, height=%i\n", width, height);
    glViewport(0, 0, width, height);
    mCamera.setWindowSize(width, height);
}

void EventHandler::initWindow(const char* title)
{
    // Create SDL window
    mpWindow = 
        SDL_CreateWindow(title, 
                         SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                         mCamera.windowSize().width, mCamera.windowSize().height, 
                         SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE | SDL_WINDOW_SHOWN);
    mWindowID = SDL_GetWindowID(mpWindow);

    // Create OpenGLES 2 context on SDL window
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 0);
    SDL_GL_SetSwapInterval(1);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);

    #ifndef __EMSCRIPTEN__
      windowCtx = SDL_GL_CreateContext(window);
    #else
      EmscriptenWebGLContextAttributes conattr;
      emscripten_webgl_init_context_attributes(&conattr); //load default webgl1 attributes
      conattr.antialias = false;
      conattr.depth = false;
      conattr.alpha = false;
      conattr.premultipliedAlpha = false;
      EMSCRIPTEN_WEBGL_CONTEXT_HANDLE con = emscripten_webgl_create_context("#canvas", &conattr);
      emscripten_webgl_make_context_current(con);
      windowCtx = SDL_GL_GetCurrentContext();
    #endif
    windowCtx = SDL_GL_CreateContext(mpWindow);

    // Set clear color to black
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);

    // Initialize viewport
    windowResizeEvent(mCamera.windowSize().width, mCamera.windowSize().height);
}

void EventHandler::swapWindow()
{
    SDL_GL_SwapWindow(mpWindow);
}

void EventHandler::moveMouse(float x, float y) {
    pointerPositionX = x / mCamera.windowSize().width;
    pointerPositionY = 1 - (y / mCamera.windowSize().height);
    mCamera.setPointerPosition(pointerPositionX, pointerPositionY);
}

void EventHandler::moveFinger(float x, float y) {
    pointerPositionX = x;
    pointerPositionY = 1 - y;
    mCamera.setPointerPosition(pointerPositionX, pointerPositionY);
}

void EventHandler::pointerDown(int p) {
    isPointerDown = p;
    mCamera.setPointerDown(isPointerDown);
}

void EventHandler::processEvents()
{
    // Handle events
    SDL_Event event;
    while (SDL_PollEvent(&event))
    {
        switch (event.type)
        {
            case SDL_QUIT:
                std::terminate();
                break;

            case SDL_WINDOWEVENT:
            {
                if (event.window.windowID == mWindowID
                    && event.window.event == SDL_WINDOWEVENT_SIZE_CHANGED)
                {
                    int width = event.window.data1, height = event.window.data2;

                    if (width == 0 || height == 0) break;
                    
                    windowResizeEvent(width, height);
                }
                break;
            }

            case SDL_MOUSEMOTION: 
            {
                SDL_MouseMotionEvent *m = (SDL_MouseMotionEvent*)&event;
                moveMouse(m->x, m->y);
                break;
            }

            case SDL_MOUSEBUTTONDOWN: 
            {
                SDL_MouseButtonEvent *m = (SDL_MouseButtonEvent*)&event;
                if (m->button == SDL_BUTTON_LEFT)
                {
                    pointerDown(1);
                }
                if (m->button == SDL_BUTTON_RIGHT)
                {
                    pointerDown(2);
                }
                break;
            }

            case SDL_MOUSEBUTTONUP: 
            {
                SDL_MouseButtonEvent *m = (SDL_MouseButtonEvent*)&event;
                if (m->button == SDL_BUTTON_LEFT)
                    pointerDown(0);
                if (m->button == SDL_BUTTON_RIGHT)
                    pointerDown(0);
                break;
            }

            case SDL_FINGERMOTION:
            {
                SDL_TouchFingerEvent *m = (SDL_TouchFingerEvent*)&event;

                moveFinger(m->x, m->y);
                break;
            }

            case SDL_FINGERDOWN:
                pointerDown(1);
                break;

            case SDL_FINGERUP:
                pointerDown(0);
                break;
        }

        #ifdef EVENTS_DEBUG
            printf ("event=%d mousePos=%d,%d mouseButtonDown=%d fingerDown=%d pinch=%d aspect=%f window=%dx%d\n", 
                    event.type, mMousePositionX, mMousePositionY, mMouseButtonDown, mFingerDown, mPinch, mCamera.aspect(), mCamera.windowSize().width, mCamera.windowSize().height);      
            printf ("    zoom=%f pan=%f,%f\n", mCamera.zoom(), mCamera.pan()[0], mCamera.pan()[1]);
        #endif
    }
}