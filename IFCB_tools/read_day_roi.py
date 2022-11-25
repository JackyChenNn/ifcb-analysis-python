from dir_file import *
import os
import fnmatch

def read_day_roi(day_ROI_folder, day_PNG_folder):
    # fileFolder = "/Users/chenhaodong/Downloads/FYP/IFCBdata"
    fileFolder = os.path.join(day_ROI_folder)
    fileNames = fnmatch.filter(os.listdir(fileFolder), '*.adc')  # store the fileNames with extension '.adc'
    print(fnmatch.filter(os.listdir(fileFolder), '*.adc'))

    for i in fileNames:
        a = i
        a = a.split(".")
        path1name = os.path.join(day_ROI_folder, a[0])
        path2name = os.path.join(day_PNG_folder, a[0])
        export_png_from_ROIlist(path1name, path2name)