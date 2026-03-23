Ant Simulation
===

This is an ant (slime mold) simulation that runs directly in the browser. Under the hood, it uses OpenGL 2.1 along with GLSL shaders to perform the simulation—not compute shaders, but traditional vertex and fragment shaders.

For IoT environments, where devices often only support OpenGL 2.1, this repository can serve as a template for improving pathfinding using Ant Colony Optimization.

This repository also serves as a great example of using Emscripten with WebAssembly (WASM) and OpenGL.

![preview](preview.jpg)

Read the full article explaining everything in detail [here](https://linkedin.com/pulse/general-purpose-gpu-programming-without-compute-shaders-sem-postma-enzre).
