from dir_file import *
from read_day_roi import read_day_roi
import os
import fnmatch

# -*- coding: utf-8 -*-
def read_month_roi():
    filepaths = []  # initialize the list to store the file paths
    filepaths = all_files_path(filepaths, "/Users/chenhaodong/Downloads/FYP/IFCBdata")  # replaced by the actual path

    for i in filepaths:
        a = i
    #   use "_" as the temp variable for testing here, should be replaced by 'rawdata'
        b = a.split('_')
        c = b[0]
        d = b[1]
        e = c + 'png' + d
        print(a)
        print(e)
        read_day_roi(a, e)