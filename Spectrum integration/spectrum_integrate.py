#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Feb 15 22:24:26 2017

@author: cpkmanchee
"""

import numpy as np
import csv
import matplotlib.pyplot as plt

file = 'test_spectrum.csv'

with open(file, 'r') as f:
    dataln = csv.reader(f)
    data = list(dataln)
    
data = np.asarray(data,dtype=np.float32)
wavelength = data[:,0]
intensity = data[:,1]-data[:,1].min()

wl1 = 1045
wl2 = 995

ind1 = (np.abs(wl1-wavelength)).argmin()
ind2 = (np.abs(wl2-wavelength)).argmin()

ind_s = np.min([ind1,ind2])
ind_e = np.max([ind1,ind2])

area = np.trapz(intensity[ind_s:ind_e],wavelength[ind_s:ind_e])

fig, ax1 = plt.subplots()
ax1.plot(wavelength[700:],intensity[700:])
ax1.fill_between(wavelength[ind_s:ind_e],intensity.min(),intensity[ind_s:ind_e], facecolor='green', alpha=0.5)
ax1.text(wavelength[ind_e],0.67*intensity.max(), 'Area = %.2f' % area , fontsize=15)