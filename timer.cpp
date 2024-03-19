#include "timer.h"

float Timer::tick()
{
    std::chrono::time_point<std::chrono::high_resolution_clock> now = std::chrono::high_resolution_clock::now();
    std::chrono::duration<float> duration = now - m_StartTime;
    m_StartTime = now;
    return duration.count();
}

void Timer::start()
{
    std::chrono::time_point<std::chrono::high_resolution_clock> now = std::chrono::high_resolution_clock::now();
    m_StartTime = now;
}
