OUT_DIR="build"
ROOT=$(odin root)
EXE=hot_reload_game.a
mkdir -p $OUT_DIR

case $(uname) in
	"Darwin")
		echo "Note: If using raygui the library is in macos-arm64"
		LIB_PATH="macos"
		DLL_EXT=".dylib"
		EXTRA_FLAGS="-Wl,-rpath ${ROOT}vendor/raylib/$LIB_PATH"
		echo EXTRA_FLAGS: $EXTRA_FLAGS
		;;
	*)
		DLL_EXT=".so"
		EXTRA_FLAGS="-Wl,-rpath \$ORIGIN/linux"

		if [ ! -d "$OUT_DIR/linux" ]; then
			mkdir -p $OUT_DIR/linux
			cp -r $ROOT/vendor/raylib/linux/libraylib*.so* $OUT_DIR/linux
		fi
		;;
esac

echo "Building game!"
odin build . \
	 -extra-linker-flags:"$EXTRA_FLAGS" \
	 -define:RAYLIB_SHARED=true \
	 -build-mode:dll \
	 -out:$OUT_DIR/game_tmp$DLL_EXT \
	 -strict-style -vet -debug

mv $OUT_DIR/game_tmp$DLL_EXT $OUT_DIR/game$DLL_EXT

if pgrep -f $EXE > /dev/null; then
	echo "Hot reloading"
	exit 0
fi

echo "Building $EXE"
odin build editor -out:$EXE -strict-style -vet -debug

