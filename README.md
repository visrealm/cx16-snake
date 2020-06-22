# Snake for the Commander x16

Planned Snake remake for the [Commander X16](https://github.com/commanderx16) r37.

Currently using [ACME Assembler](https://github.com/commanderx16).

This project is very new and subject to significant changes.

#### Videos

<img src="img/snake.gif" alt="Snake">

[![Adventures in Assembly 6 - Snake for the Commander X16.](https://img.visualrealmsoftware.com/youtube/thumb/RmOFRG29xEs)](https://youtu.be/RmOFRG29xEs "Adventures in Assembly 6 - Snake for the Commander X16.")

#### Run instructions

If you don't want to set up my build environment (I don't blame you). You can run the latest build by copying the files from:

```
snake/bin
```
In to your emulator folder. Then, run the emulator and:

```
LOAD "SNAKE.PRG"

RUN
```

#### Build instructions

Build batch files currently expect a given layout:

```c:\cx16
c:\cx16\x16emu       <-- the emulator
c:\cx16\acme         <-- acme assembler
c:\cx16\code\snake   <-- this repository
```

To build, head to c:\cx16\code\snake:

```
build.bat / b.bat   <-- build the project
run.bat / r.bat     <-- run it
br.bat              <-- build and run

c:\cx16\code\snake\src  <-- source files (also some in code\common)
c:\cx16\code\snake\bin  <-- output files - the disk image for the cx16
c:\cx16\code\snake\res  <-- various resources used to generate the final level, image, tile files
```
