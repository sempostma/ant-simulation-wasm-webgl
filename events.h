//
// Window and input event handling
//
#include "camera.h"

class EventHandler
{
public:
    EventHandler(const char* windowTitle);

    void processEvents();
    Camera& camera() { return mCamera; }
    void swapWindow();

private:
    // Camera
    Camera mCamera;

    // Window
    SDL_Window* mpWindow;
    Uint32 mWindowID;
    SDL_GLContext windowCtx;
    void windowResizeEvent(int width, int height);
    void initWindow(const char* title);

    // Pointer
    bool isPointerDown;
    float pointerPositionX;
    float pointerPositionY;

    // Events
    void moveMouse(float x, float y);
    void moveFinger(float x, float y);
    void pointerDown(int p);
};

inline EventHandler::EventHandler(const char* windowTitle)
    // Window
    : mpWindow (nullptr)
    , mWindowID (0)
 
    // Pointer input
    , pointerPositionX (-99.0f)
    , pointerPositionY (-99.0f)
    , isPointerDown (0)
{
    initWindow(windowTitle);
}