//
// Camera - pan, zoom, and window resizing
//
struct Rect { int width, height; };
struct Vec2 { GLfloat x, y; };

class Camera
{
public:
    Camera();
    bool updated();
    bool pointerChanged();
    bool windowResized();

    GLfloat aspect() { return mAspect; }

    Rect& windowSize() { return mWindowSize; }
    void setWindowSize (int width, int height);
    GLfloat* viewport() { return (GLfloat*)&mViewport; }
    GLfloat* pointerPosition() { return (GLfloat*)&mPointerPosition; }
    GLint pointerDown() { return mPointerDown; }
 
    void setAspect (GLfloat aspect) { mAspect = aspect; mCameraUpdated = true; }
    void setPointerPosition(GLfloat x, GLfloat y) { mPointerPosition = { x, y }; mPointerUpdated = true; }
    void setPointerDown(int pointerDown) { mPointerDown = pointerDown; mPointerUpdated = true; }

    void normWindowToDeviceCoords (float normWinX, float normWinY, float& deviceX, float& deviceY);
    void windowToDeviceCoords (int winX, int winY, float& deviceX, float& deviceY);
    void deviceToWorldCoords (float deviceX, float deviceY, float& worldX, float& worldY);
    void windowToWorldCoords (int winX, int winY, float& worldX, float& worldY);
    void normWindowToWorldCoords (float normWinX, float normWinY, float& worldX, float& worldY);

private:
    float clamp (float val, float lo, float hi);

    bool mCameraUpdated;
    bool mWindowResized;
    bool mPointerUpdated;
    Rect mWindowSize;
    Vec2 mViewport;  
    Vec2 mPointerPosition;
    GLint mPointerDown; 
    GLfloat mAspect; 
};

inline Camera::Camera()
    : mCameraUpdated (false)
    , mWindowResized (false)
    , mWindowSize ({})
    , mViewport ({})
    , mPointerPosition({-99.0f, -99.0f})
    , mPointerDown(0)
    , mAspect(0.0f)
{
    setWindowSize(1920, 1080);
}