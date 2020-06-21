import os, sys, csv
from PIL import Image, ImageDraw

IN_TILE_SIZE  = 32
OUT_TILE_SIZE = 16

for infile in sys.argv[1:]:
    f, e = os.path.splitext(infile)
    outfile = f + ".strip" + e
    try:
        src = Image.open(infile)
        dst = Image.new(src.mode, (OUT_TILE_SIZE, int(src.width / OUT_TILE_SIZE * src.height) * 2))
        
        tileSizeRatio = int(IN_TILE_SIZE / OUT_TILE_SIZE)
        inTilesX = int(src.width / IN_TILE_SIZE)
        inTilesY = int(src.height / IN_TILE_SIZE)
        numInTiles = inTilesX * inTilesY

        numOutTiles = numInTiles * tileSizeRatio * tileSizeRatio

        i = 0
        for y in range(inTilesY):
          for x in range(inTilesX):
            xOff = x * IN_TILE_SIZE
            yOff = y * IN_TILE_SIZE
            inTile = src.crop((xOff, yOff, xOff + IN_TILE_SIZE, yOff + IN_TILE_SIZE))
            rotTile = inTile.rotate(90)
            for sy in range(tileSizeRatio):
              for sx in range(tileSizeRatio):
                xOff = sx * OUT_TILE_SIZE
                yOff = sy * OUT_TILE_SIZE
                outTile = inTile.crop((xOff, yOff, xOff + OUT_TILE_SIZE, yOff + OUT_TILE_SIZE))
                dst.paste(outTile, (0, i * OUT_TILE_SIZE))
                
                outTile = rotTile.crop((xOff, yOff, xOff + OUT_TILE_SIZE, yOff + OUT_TILE_SIZE))
                dst.paste(outTile, (0, (i + numOutTiles) * OUT_TILE_SIZE))                
                
                i = i + 1

        dst.save(outfile)
        dst.close()
        src.close()
    except IOError:
        print("cannot convert", infile)
        
    mapfile = f + ".csv"
    try:
        with open(mapfile, newline='') as csvfile:
            img = Image.open(outfile)
            mapImage = Image.new(dst.mode, (100 + IN_TILE_SIZE, IN_TILE_SIZE * 90))
            reader = csv.DictReader(csvfile)
            i = 0
            for row in reader:
                ul = img.crop((0, int(row['ul']) * OUT_TILE_SIZE, 16, int(row['ul']) * OUT_TILE_SIZE + 16))
                ur = img.crop((0, int(row['ur']) * OUT_TILE_SIZE, 16, int(row['ur']) * OUT_TILE_SIZE + 16))                
                bl = img.crop((0, int(row['bl']) * OUT_TILE_SIZE, 16, int(row['bl']) * OUT_TILE_SIZE + 16))                
                br = img.crop((0, int(row['br']) * OUT_TILE_SIZE, 16, int(row['br']) * OUT_TILE_SIZE + 16))
                
                if row['hflip'] == '1':
                  ul = ul.transpose(Image.FLIP_LEFT_RIGHT)
                  ur = ur.transpose(Image.FLIP_LEFT_RIGHT)
                  bl = bl.transpose(Image.FLIP_LEFT_RIGHT)
                  br = br.transpose(Image.FLIP_LEFT_RIGHT)
                  
                if row['vflip'] == '1':
                  ul = ul.transpose(Image.FLIP_TOP_BOTTOM)
                  ur = ur.transpose(Image.FLIP_TOP_BOTTOM)
                  bl = bl.transpose(Image.FLIP_TOP_BOTTOM)
                  br = br.transpose(Image.FLIP_TOP_BOTTOM)
                  
                ImageDraw.Draw(mapImage).text((0, i + 10), row['name'], fill=(0,0,0,255))
                mapImage.paste(ul, (100, i))
                mapImage.paste(ur, (100 + OUT_TILE_SIZE, i))
                mapImage.paste(bl, (100, i + OUT_TILE_SIZE))
                mapImage.paste(br, (100 + OUT_TILE_SIZE, i + OUT_TILE_SIZE))
                
                i = i + IN_TILE_SIZE
                
            mapImage.save(f + ".map" + e)
    except IOError:
        print("cannot map", mapfile)
            