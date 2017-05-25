# -*- coding: utf-8 -*-
"""
Created on Wed Sep  9 10:04:52 2015

@author: cpkmanchee

header format:
1 dateCreated = <string>
2 xUnit = <string>
3 yUnit = <string>
4 fitForm = <string> fit type (gaussian, sech2, both)
5 backgrounForm = <string> background type (linear, constant, quad)
6 <dictionary> fit parameters {'fitType': {'parameter': value,...}...}
7 data labels csv string <string1>, <string2>,...<stringn>
8-n data csv
"""

import pylab
import matplotlib.pyplot as plt
import scipy as sp
import numpy as np
import tkinter as tk
import os
import time
import json
from tkinter import filedialog
from scipy.optimize import curve_fit

#def loadresult(file):
#    
#    if not file[-4:] == '.txt':
#        file = file + '.txt.'
#
#    if not os.path.exists(file):
#        print('File not found')
#    return
#
#    # open in read only
#    with open(file, 'r') as f:
#        
#        hlines2Read = 7
#        header =[]
#        for i in range(hlines2Read):
#            header.append(f.readlines())        
#        
#    #parse header, see above for format
#    #fit/file info    
#    lines = [x.split('=') for x in header[:4]]
#    fitInfo = dict((x[0].strip(), x[1].strip()) for x in lines)
#    #fit parameter dictionary    
#    paramDict = json.loads(header[5])
#    #data column labels
#    colLabels = [x.strip() for x in header[6].split(',')]
#    
#    #get data
#    data = np.genfromtxt(file,delimiter = ',', skip_header = hlines2Read)

class LoadResult:
    
    def __init__(self,file):

        if not file[-4:] == '.txt':
            file = file + '.txt'
    
        if not os.path.exists(file):
            print('File not found')
            return
    
        # open in read only
        with open(file, 'r') as f:
            
            hlines2Read = 8
            header =[]
            for i in range(hlines2Read):
                header.append(f.readline())        
            
        #parse header, see above for format
        #fit/file info    
        lines = [x.split('=') for x in header[:6]]
        fitInfo = dict((x[0].strip(), x[1].strip()) for x in lines)
        #fit parameter dictionary    
        self.paramDict = json.loads(header[6])
        #data column labels
        self.colLabels = [x.strip() for x in header[7].split(',')]
        #get data
        self.data = np.genfromtxt(file,delimiter = ',', skip_header = hlines2Read)
        
        
        
        self.numfits = self.data.shape[1] - 2
        nFitLabels = len(self.colLabels) - 2

        if not self.numfits == nFitLabels:
            print('incorrect # of labels')
        
        self.x = self.data[:,0]
        self.y = self.data[:,1]
        self.xlabel = self.colLabels[0]
        self.ylabel = self.colLabels[1]

        if self.numfits > 0:
            self.fit1label = self.colLabels[2]
            self.fit1 = self.data[:,2]
        if self.numfits > 1:
            self.fit2label = self.colLabels[3]
            self.fit2 = self.data[:,3]
        
        self.date = fitInfo['dateCreated']
        self.xunit = fitInfo['xUnit']
        self.yunit = fitInfo['yUnit']
        self.fittype = fitInfo['fitForm']
        self.backgroundtype = fitInfo['backgroundForm']
        
    def test(self):
        print('all good')
            
    def popt(self,fitType, parameter):
        if fitType.lower() in ['gaus', 'gaussian']:
            fit = 'gaus'
        elif fitType.lower() in ['sech2','sech squared','hyperbolic secant squared']:
            fit = 'sech2'
        else:
            return('Unrecognized fit type. Must be "gaus" or "sech2"')
                
        if not parameter.lower() in ['a','x0','sigma','c0','c1','c2']:
            return('Unrecognized parameter. Must be "a","x0","sigma","c0","c1","c2"')
        
        try:
            return(self.paramDict[fit][parameter])
        except KeyError:
            return('parameter not found: check fit type and paramter')
        else:
            return('unknown error occured')
            
    def plot(self,*args):
        if not all(l in self.colLabels for l in args):
            return('label not found')
        
        if not len(args)%2 == 0:
            return('must plot in pairs: check number of inputs')
        
        numPlots = len(args)//2
        
        for i in range(numPlots):
            plt.plot(self.data[:,self.colLabels.index(args[2*i])],self.data[:,self.colLabels.index(args[2*i+1])], label = args[2*i+1])
            plt.legend()
            
    def fwhm(self, fitType):
        gA2I = 1/np.sqrt(2)
        sA2I = 1/1.54
        
        gS2F = 2*np.sqrt(2*np.log(2))
        sS2F = 1.76
        
        if fitType.lower() in ['gaus', 'gaussian']:
            return(gA2I*gS2F*self.paramDict['gaus']['sigma'])
            
        elif fitType.lower() in ['sech2','sech squared','hyperbolic secant squared']:
            return(sA2I*sS2F*self.paramDict['sech2']['sigma'])
        else:
            return('Unrecognized fit type. Must be "gaus" or "sech2"')
            
    def r2(self, fittype):
        y = self.y
        
        if fittype in aliasDict['gaus']:
            f = self.fit1
        elif fittype in aliasDict['sech2']:
            f = self.fit2
        else:
            return
            
        ybar = np.average(y)
        
        SStot = np.sum((y-ybar)**2)
        SSres = np.sum((y-f)**2)
        
        return 1-(SSres/SStot)

        
        
            
        
    
#will use this to parse input strings, checkfor correct input in various places   
aliasDict = {'x': ('x','X'), 
            'y': ('y','Y'), 
            'gaus':('gaus','gaussian','g'),
            'sech2': ('sech2','secant squared','hyperbolic secant squared','s'),
            'GausFit': ('GausFit','gaus','gaussian'),
            'Sech2Fit': ('Sech2Fit', 'sech2','secant squared','hyperbolic secant squared')
            }