#pragma once

#include <chrono>

class Timer {
private:
    std::chrono::time_point<std::chrono::steady_clock> m_StartTime;

public:
    float tick();
    void start();
};