# Halma-Boardgame

An implementation of the [Halma board game](https://en.wikipedia.org/wiki/Halma) that run on 16-bit DOS.

The program was written using Turbo Pascal and lots of 80286 assembly.  It makes heavy use of interrupt 0x33 (INT33) for mouse support and accesses the VGA graphic card directly.  Both of these aspects mean that it usually does not run on emulators or any other system, anymore.

While the game itself and its implementation is rather simplistic, the whole point of this project was to write my own graphics engine with support for Canvas, bitmaps and various GUI elements.  Unfortunately, I only preserved parts of the entire graphics engine, just enough for this example program.  One of the motivations for writing my own graphics engine was to make use of 256 colours with 640x480 resolution—besides the fun of tinkering with low-level interfaces, of course.  The game itself was then a relatively small layer on top to showcase the entire system.

The comments in the files are in German, unfortunately, but some of the code might still make sense :).
