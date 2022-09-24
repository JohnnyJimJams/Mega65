Generic hardware line draw is working

white line at the bottom is raster time to draw those bad boys
It opens a bunch of doors
texture mapping, roto zoomers, 3d, cloth physics
I have 2 more research tasks I want to get out of the way: maths routines
and learning the Raster Rewrite Buffer
After that, I can knuckle down and start on the demo proper
The maths routines would be 16.16 bit signed mult / divide sin and cos
I can use that for a nice tweening routine for them sexy demo transitions
I also want them to try out a ray marching idea I've wanted to try out (but the c64 was just not quick enough)
When is Syntax?  Like, what date?

From cTrix
11TH / 12TH / 13TH of November

 - Math routines
 - 16.16 fixed
 - add / sub
 - comparision
 - mult
 - div
 - lookups for sin, cos
 - 8 virtual registers (f0 - f8)

Tweening library
 - Uses the maths lib
 - % towards target
 - linear, cos, bounce, exp

Stretching (Vertically) -- No :( But playing with LINESTEPLSB every raster showed some vertical stretching.  Not sure how to control it.
Crunching (Vertically)

Source based line draw (rotozoom)

Ray marching
Rotations
Projections
Filled polys
Textured polys
Music Player