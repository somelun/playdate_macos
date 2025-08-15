## Playdate MacOS

I develop playdate game on MacOS and I don't like to use simulator. That is why I made this is demo project. It works on both playdate (simulator and device) and MacOS native (using Metal as render backend). You may ask: why Metal? Well, I wanted to use some single header library to support standalone app, but then I realized I never use Windows at all. Also I wanted to experiment with Metal, even a little bit, so here we are.  
  
You can generate two differenet Xcode projects using same CMakeLists.txt file.  

To make MacOS native Xcode project run:

    cmake -S . -B build-macos -G Xcode -DBUILD_TARGET=macos

To make playdate Xcode project run:

    cmake -S . -B build-playdate -G Xcode -DBUILD_TARGET=playdate
