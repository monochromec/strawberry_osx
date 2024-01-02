#!/usr/bin/env bash

if ! which brew; then
    echo "Please install Homebrew first" >&2
    exit -1
fi

if ! which wget; then
    echo "wget is missing" >&2
    exit -1
fi

if ! which git; then
    echo "git is required" >&2
    exit -1
fi

BP=$(brew --prefix)

fix_rel_paths() {
    for library in $(find -E $1 -type f -regex '.*/lib/.*\.framework/Versions/A/Qt(Core|Concurrent|Network|Sql|Widgets|Gui|DBus)' -o -name '*.dylib'); do
	library_paths=$(otool -L "${library}" | sed -n "s/^\t\(.*\) (compatibility version [0-9]*\.[0-9]*\.[0-9]*, current version [0-9]*\.[0-9]*\.[0-9]*)/\1/p")
	for library_path in ${library_paths}; do
	    if ! [ "$(echo "${library_path}" | grep "^@loader_path" || true)" = "" ]; then
		new_library_path=$(echo "${library_path}" | sed -E "s|@loader_path(\/\.\.)+\/opt/|${BP}\/opt/|g")
		if ! [ "${new_library_path}" = "" ] && ! [ "${new_library_path}" = "${library_path}" ] && [ -e "${new_library_path}" ]; then
		    install_name_tool -change "${library_path}" "${new_library_path}" "${library}"
		else
		    echo "${library} points to ${library_path}, could not resolve to absolute path."
		fi
	    fi
	done
    done
}

install_packages() {
    # Install missing packages
    PKGS="pkg-config cmake ninja meson bison flex wget create-dmg gettext boost protobuf protobuf-c glib glib-openssl glib-networking gdk-pixbuf gobject-introspection orc libffi openssl sqlite fftw libmtp libplist libxml2 libsoup libogg libvorbis flac wavpack opus speex mpg123 lame twolame taglib chromaprint libebur128 libbs2b libcdio libopenmpt faad2 faac fdk-aac musepack game-music-emu"

    for PKG in ${PKGS}; do
	if ! brew list ${PKG} >/dev/null; then
	    brew install ${PKG}
	fi
    done

    # Treat qt6 differently: if present, reinstall including its dependencies as qt plugins (see below for removal) are required for installation
    if brew list qt6 >/dev/null; then
	brew reinstall qt6 $(brew deps qt6)
    else
	brew install qt6
    fi
}

remove_qt_plugins() {    
    FILES="opt/qt6/share/qt/plugins/virtualkeyboard opt/qt6/share/qt/plugins/platforminputcontexts Cellar/qt/*/share/qt/plugins/imageformats/libqpdf.dylib"
    for FILE in ${FILES}; do
	if [[ -e ${BP}/FILE ]]; then
	    rm -rf ${BP}/FILE
	fi
    done
}

install_gstreamer() {
    brew tap homebrew/core
    for FILE in gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav; do
	if ! brew list ${FILE} >/dev/null; then 
	    wget -O ${BP}/Library/Taps/homebrew/homebrew-core/Formula/g/${FILE}.rb https://files.strawberrymusicplayer.org/patches/${FILE}.rb
	    brew install --build-from-source ${FILE}
	fi
    done
}

#fix_rel_paths ${BP}/Cellar
#install_packages
#install_gstreamer

git clone --recursive https://github.com/strawberrymusicplayer/strawberry
cd strawberry
VER=$(git tag -l | sort -V | tail -1)
mkdir build
cd build

export GIO_EXTRA_MODULES=${BP}/lib/gio/modules
export GST_PLUGIN_SCANNER=${BP}/opt/gstreamer/libexec/gstreamer-1.0/gst-plugin-scanner
export GST_PLUGIN_PATH=${BP}/lib/gstreamer-1.0

cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=${BP}/opt/qt6/lib/cmake -DBUILD_WITH_QT6=ON -DUSE_BUNDLE=ON -DENABLE_SPARKLE=OFF -DICU_ROOT=${BP}/opt/icu4c -DENABLE_DBUS=OFF -DPROTOBUF_INCLUDE_DIRS=${BP}/include
PROCS=$(sysctl -n hw.ncpu)
make -j${PROCS}
make -j${PROCS} install

remove_qt_plugins

mkdir -p strawberry.app/Contents/Frameworks
cp ${BP}/lib/libsoup-3.0.0.dylib strawberry.app/Contents/Frameworks/

#make -j${PROCS} deploy
#make deploycheck
#make dmg
zip -r9  strawberry-${VER}.zip strawberry.app
