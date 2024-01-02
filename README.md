# strawberry_osx
Script for strawberry builds on OSX

This script allows the automated creation of Strawberry builds on Apple Silicon/Intel-based Macs.

Essentially, it's packaged version of the original [wiki page](https://wiki.strawberrymusicplayer.org/wiki/Compile_macOS_using_homebrew). 
The idea is to have a tooling available for the generation of avoiding the mandatory fee imposed by the [original project](https://www.strawberrymusicplayer.org/#download) 
for OSX builds. I'll publish the corresponing app zips / dmgs 

At the moment, only zipped app bundles are supported which require an installed Qt6 via Homebrew among other things. As deployment (ie. bundling of the required frameworks
and libraries in the app tree itself) and subsequent dmg creation require codesigning, I'll update the script once I've solved the current codesigning issues (PRs / hints are
welcome!). 

Prereqs:
- Recent OSX version (I've tested this on Ventura and Sononma but any recent OSX version should be sufficient),
- Homebrew installed (this requires a previous Xcode installation for the CLI tools),
- Using Homebrew install git and wget,
- About 500 MBs of disk space for sources and the build.
  
Caveats:
- macdeployqt does not handle relative linker paths well, the script incorporates a modified version of the [original script](https://wiki.strawberrymusicplayer.org/wiki/Compile_macOS_using_homebrew) to fix this,
- The [original recipe](https://wiki.strawberrymusicplayer.org/wiki/Compile_macOS_using_homebrew) leans towards Intel-based Macs (ie, location of Homebrew), the packaged version addresses this by properly prefixing. I've tested this primarily on Apple Silicon, it should also work on older Intel-based Macs (please open an issue if it doesn't),

