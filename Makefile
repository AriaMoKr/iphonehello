# Build hello.exe with MinGW-w64 g++ (e.g. in an MSYS2 UCRT64 shell).

CXXFLAGS = -O2 -Wall -Wextra

hello.exe: hello.cpp
	$(CXX) $(CXXFLAGS) -o $@ $< -mwindows

clean:
	rm -f hello.exe

.PHONY: clean
