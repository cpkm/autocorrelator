# -*- coding: utf-8 -*-
"""
Created on Wed Nov 23 09:32:19 2016

@author: cpkmanchee
"""

import numpy as np
import scipy as sp
import matplotlib.pyplot as plt
import os
import csv
import pickle


file_formats = {'regen_monitor': 
                {'alias': ['regen_monitor','regen','monitor','mon'],
                 'header_lines': 9,
                 'number_data_columns': 6,
                 'column_labels': ['time','current','power','crossover','t2','t2'],
                 'column_units': ['', 'A','W','ratio','degC','degC'],
                 'delimiter': '\t',
                 },
            'thorlabs_pm': 
                {'alias': ['thorlabs_pm','thor','thorlabs','pm100','pm'],
                 'header_lines': 3,
                 'number_data_columns': 3,
                 'column_labels': ['time','power','units'],
                 'column_units': ['mm', 'W', ''],
                 'delimiter': '\t',
                 },
            'ocean_optics_spectrometer':
                {'alias': ['ocean_optics_spectrometer','oo_spectrometer','oospec','oo_spec','oo'],
                 'header_lines': 0,
                 'number_data_columns': 2,
                 'column_labels': ['wavelength','intensity'],
                 'column_units': ['nm', 'units'],
                 'delimiter': ',',
                 },
            'autocorrelator': 
                {'alias':['autocorrelator','ac','auto_correlator','auto'],
                 'header_lines': 0,
                 'number_data_columns': 2,
                 'column_labels': ['position','power'],
                 'column_units': ['mm', 'W'],
                 'delimiter': '\t',
                 }
            }
            
                
def filetype_lookup(file_dict, given_type):
    '''Identify file type for given input. Only first found match is returned.
    '''
    for k,v in file_dict.items():
        if given_type in file_dict.get(k).get('alias'):
            return(k)
        else:
            return(None)


filedir = '/Users/cpkmanchee/Google Drive/PhD/Data/2016-11-22 DILAS temp profile'
fileMON = '2016-11-22 MON temperature profile 10W.txt'
filePOW = '2016-11-22 PM100 temperature profile 10W.txt'

file = os.path.join(filedir,fileMON)
given_filetype = 'monitor'

filetype = filetype_lookup(file_formats,given_filetype)
if filetype is None:
    raise RuntimeError("File type lookup failed. File type not found") from filetype


header_lines = file_formats.get(filetype).get('header_lines')
delimiter = file_formats.get(filetype).get('delimiter')
column_labels = file_formats.get(filetype).get('column_labels')

#initialize header and output dictionary
header=[]
output={}
[output.update({c:[]}) for c in column_labels]
            
with open(file, 'r') as f:
    #extract header information only
    data = csv.reader(f, delimiter = delimiter)
    for i in range(header_lines):
        header.append(data.__next__())
    #write rest of data to dictionary, keys are column_labels, values = data 
    [[(output[c].append(row[c_ind])) for c_ind,c in enumerate(column_labels)] for row in data]

output.update({'header': header})

