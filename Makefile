# Build hello.exe with MinGW-w64 g++ (e.g. in an MSYS2 UCRT64 shell), or with Clang: make CXX=clang++
# (in MSYS2's CLANGARM64 for ARM64, which has no g++).

CXXFLAGS = -O2 -Wall -Wextra

# The version, as in CMakeLists.txt: the newest release tag at or before this commit, as git describe
# gives it. 0.5.0 on the commit tagged v0.5.0, 0.5.0-3-g<commit> three commits later, and 0.0.0 without git
# or such a tag. As four numbers for Windows, with the commits since the tag last: 0,5,0,0 or 0,5,0,3.
VERSION := $(or $(patsubst v%,%,$(shell git describe --tags --match 'v[0-9]*.[0-9]*.[0-9]*' 2>/dev/null)),0.0.0)
VERSION_NUMBERS := $(shell echo $(VERSION) | sed -E 's/^([0-9]+)\.([0-9]+)\.([0-9]+)(-([0-9]+)-g.*)?$$/\1,\2,\3,\5/; s/,$$/,0/')

hello.exe: hello.cpp version.o
	$(CXX) $(CXXFLAGS) -o $@ $^ -mwindows

# The version resource (version.rc). version.txt holds the version and is only rewritten when that
# changes, so a new commit or tag makes version.o and hello.exe again.
version.o: version.rc version.txt
	windres -DNAME=hello -DVERSION=$(VERSION) -DVERSION_NUMBERS=$(VERSION_NUMBERS) $< $@

version.txt: FORCE
	@[ "$$(cat $@ 2>/dev/null)" = '$(VERSION)' ] || echo '$(VERSION)' > $@

FORCE:

clean:
	rm -f hello.exe version.o version.txt

.PHONY: clean
