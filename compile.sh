emcc -std=c++11 main.cpp events.cpp camera.cpp -s ASYNCIFY -s USE_SDL=2 -s FULL_ES2=1 -s WASM=1 --embed-file ./vertex.glsl --embed-file ./fragment.glsl -o index.js