*= * "Image Data"
.var colsHT = Hashtable()
.var colIndex = 1
.var graflogo = LoadPicture("assets/logo1_640_296_q255.png")
.for (var x1=0;x1<80; x1++)
    .for (var y=0; y<400; y++)
        .for (var x=0;x<8; x++)
        {
            .var c = 0;
            .if (y<296)
            {
                .eval c = graflogo.getPixel(x1*8+x, y)
            }
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