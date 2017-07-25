# CMaker_Boost example

For building the example:
```
git clone https://github.com/NikitaFeodonit/CMaker_Boost
cp -r CMaker_Boost/example/TestCompileWithBoost/ ./
mkdir TestCompileWithBoost/cmake
mkdir TestCompileWithBoost/build
cp -r BoostCMaker TestCompileWithBoost/cmake/
cd TestCompileWithBoost/build/

cmake ../ \
 -DCMAKE_BUILD_TYPE=Release \
 -DCMAKE_INSTALL_PREFIX=inst

cmake --build .
```

Configure command for Android (also should work with Android's gradle):
```
/path/to/android-sdk-linux/cmake/3.6.3155560/bin/cmake ../ \
 -DCMAKE_INSTALL_PREFIX=inst \
 -DCMAKE_BUILD_TYPE=Release \
 -DANDROID_NDK=/path/to/android-sdk-linux/ndk-bundle \
 -DCMAKE_TOOLCHAIN_FILE=/path/to/android-sdk-linux/ndk-bundle/build/cmake/android.toolchain.cmake \
 -DANDROID_ABI=armeabi-v7a \
 -DANDROID_NATIVE_API_LEVEL=9 \
 "-DANDROID_CPP_FEATURES=rtti exceptions" \
\
 -DANDROID_TOOLCHAIN=clang \
 -DANDROID_STL=c++_static \
\
 "-GAndroid Gradle - Ninja" \
 "-DCMAKE_MAKE_PROGRAM=/path/to/android-sdk-linux/cmake/3.6.3155560/bin/ninja" \

```

Options for Android NDK's gcc:
```
 -DANDROID_TOOLCHAIN=gcc \
 -DANDROID_STL=gnustl_static \
```

Options for Android's building with 'make' command:
```
 "-GAndroid Gradle - Unix Makefiles" \
 -DCMAKE_MAKE_PROGRAM=make \
```

For other Android's CMake options see:<br />
https://developer.android.com/ndk/guides/cpp-support.html  <br />
https://developer.android.com/ndk/guides/cmake.html
