*= * "Image Data"
.var colsHT = Hashtable()
.var colIndex = 1
.var graflogo = LoadPicture("3d-graffiti.png")
.for (var y1=0; y1<25; y1++)
    .for (var x1=0;x1<40; x1++)
        .for (var y=0; y<8; y++)
            .for (var x=0;x<8; x++)
            {
                .var c = graflogo.getPixel(x1*8+x, y1*8+y)
                .if (colsHT.containsKey(c))
                {
                    .byte colsHT.get(c)
                }
                else
                {
                    .byte colIndex
                    .eval colsHT.put(c, colIndex)
                    .eval colIndex = colIndex + 1
                }
                
            }

.print "------"
.print colIndex
.print "------"