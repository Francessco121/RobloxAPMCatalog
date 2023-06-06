@echo off
setlocal

rem Enter project root
cd ..

rem Remove old build folder
if exist "build" (
    echo Removing previous build...
    rmdir /s /q build
)

rem Install node modules
echo Installing Node modules...
call npm install

rem Build the Dart project
echo Building Dart project...
call npm run build

rem Replace Dart packages symlink with the actual folder
rem echo Replacing packages symlink...
rem move build\packages build\web\packages

rem Install node modules for build
cd build
echo Installing Node modules for build...
call npm install

rem Reduce node module duplication
echo Reducing Node module duplication...
call npm dedupe

rem Build the Electron project
echo Building Electron project...
call npm run build

endlocal