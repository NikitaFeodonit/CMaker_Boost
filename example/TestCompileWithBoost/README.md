# BoostCMaker example

For building the example:

```bash
git clone https://github.com/NikitaFeodonit/BoostCMaker
cp -r BoostCMaker/example/TestCompileWithBoost/ ./
mkdir TestCompileWithBoost/cmake
mkdir TestCompileWithBoost/build
cp -r BoostCMaker TestCompileWithBoost/cmake/
cd TestCompileWithBoost/build/
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=inst ../
cmake --build .
```
