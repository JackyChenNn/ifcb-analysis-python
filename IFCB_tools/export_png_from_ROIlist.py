import os
import numpy as np
from PIL import Image

def export_png_from_ROIlist(ROIfile_withpath, outputpath, ROInumbers=None):
    
    (basedir, filename) = os.path.split(ROIfile_withpath)
    (file, ext) = os.path.splitext(ROIfile_withpath)
    
    if not os.path.exists(outputpath):
        os.mkdir(outputpath)
        
    adcfile = filename + '.adc'
    adcdata = np.genfromtxt(adcfile, delimiter=',', dtype=float)
        
    if filename.startswith('I'):
        x = adcdata[:, 12]
        y = adcdata[:, 13]
        startbyte = adcdata[:, 14]
    else:
        x = adcdata[:, 15]
        y = adcdata[:, 16]
        startbyte = adcdata[:, 17]
        
    if ROInumbers is None:
        ROInumbers = np.where(x > 0)[0] + 1

    with open(ROIfile_withpath + '.roi', 'rb') as fid:
        for count in range(len(ROInumbers)):
            num = ROInumbers[count]
            fid.seek(int(startbyte[num-1]), 0)
            img = np.fromfile(fid, dtype=np.uint8, count=int(x[num-1]*y[num-1]))
            img = img.reshape(int(x[num-1]), int(y[num-1]), order='F')

            if img.size > 0:
                img = np.uint8(img)
                pngname = f"{filename}_{num:05}.png"
                outputfile = os.path.join(outputpath, pngname)
                im = Image.fromarray(img)
                im.save(outputfile)

    fid.close()