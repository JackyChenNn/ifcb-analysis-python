import os
import numpy as np
import matlab
import matlab.engine


def export_png_from_ROIlist(ROIfile_withpath, outputpath, ROInumbers=None):
    ROIfile_withpath = "/Users/chenhaodong/Downloads/FYP/IFCBdata/D20200216T000215_IFCB999"
    outputpath = '/Users/chenhaodong/Downloads/FYP/IFCBdata/output'
    ROInumbers = None
    (basedir, filename) = os.path.split(
        ROIfile_withpath)  # extract the base directory and the filename with the given path
    (file, ext) = os.path.splitext(ROIfile_withpath)  # extract the extension with the given path

    if not os.path.exists(outputpath):
        os.mkdir(outputpath)

    adcfile = filename + '.adc'
    adcfile_open = open(os.path.join(basedir, adcfile), "r")
    adcdata = adcfile_open.readlines()
    adcfile_open.close()

    if filename.startswith('I'):
        x = adcdata[12]
        y = adcdata[13]
        startbyte = adcdata[14]
    else:
        x = adcdata[15]
        y = adcdata[16]
        startbyte = adcdata[17]
        
    x = list(map(float, x.decode().strip().split(',')))
    y = list(map(float, y.decode().strip().split(',')))
    startbyte = list(map(float, startbyte.decode().strip().split(',')))
        
    if ROInumbers is None:
        ROInumbers = [i for (i, v) in enumerate(x) if v > 0]

    fid = open(ROIfile_withpath + '.roi', "rb+")
    eng = matlab.engine.start_matlab()
    for count in range(len(ROInumbers)):
        num = ROInumbers[count]
        fid.seek(int(startbyte[num]), 0)
        img = fid.read(int(x[num]) * int(y[num]))
        
        img = np.array([x for x in img])
        img = img.reshape(int(x[num]), int(y[num]))
        print(num)
        pngname = filename + "_" + eng.num2str(num, '%05.0f') + '.png'
        if img.size > 0:
            cv2.imwrite(os.path.join(outputpath, pngname), img.astype(int))
            
    fid.close()