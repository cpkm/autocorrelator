# -*- coding: utf-8 -*-
"""
Created on Mon Aug 31 09:55:00 2015

@author: cpkmanchee
"""

import inspect
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


class GetData:
    #autocorrelator internal reflection angle, in deg
    angle = 30
    c = 299792458*1E6   #in um/s    
    
    def __init__(self,file):
        #position in units of um
        #power in units of W
        #timedelay in fs
        self.data = np.loadtxt(file)
        self.position = self.data[:,0]
        self.power = self.data[:,1]
        self.timedelay = (2*self.position/(self.c*np.cos(self.angle*np.pi/360)))*1E15

    
def fitpeak(x,y,form, bgform = 'constant'):
    
    bgpar, bgform = background(x,y,form = bgform)
    
    mean = np.average(x,weights = y)       
    stdv = np.sqrt(np.average((x-mean)**2 ,weights = y))
      

#set fitting function (including background)
    if bgform.lower() in ['const','constant']:
        def fitfuncGaus(x,a,x0,sigma,p0):
            return gaus(x,a,x0,sigma) + p0
        def fitfuncSech2(x,a,x0,sigma,p0):
            return sech2(x,a,x0,sigma) + p0
        
    elif bgform.lower() in ['lin','linear']:
        def fitfuncGaus(x,a,x0,sigma,p0,p1):
            return gaus(x,a,x0,sigma) + p1*x + p0
        def fitfuncSech2(x,a,x0,sigma,p0,p1):
            return sech2(x,a,x0,sigma) + p1*x + p0

    elif bgform.lower() in ['quad','quadratic']:
        def fitfuncGaus(x,a,x0,sigma,p0,p1,p2):
            return gaus(x,a,x0,sigma) + p2*x**2 + p1*x + p0
        def fitfuncSech2(x,a,x0,sigma,p0,p1,p2):
            return sech2(x,a,x0,sigma) + p2*x**2 + p1*x + p0
    else:
        def fitfuncGaus(x,a,x0,sigma):
            return gaus(x,a,x0,sigma)
        def fitfuncSech2(x,a,x0,sigma):
            return sech2(x,a,x0,sigma)

    nFitArgs = len(inspect.getargspec(fitfuncGaus).args) - 1

#sets which functions are to be fit... this can be streamlined i think
    if form.lower() in ['both', 'all']:
        fitGaus = True
        fitSech2 = True
        
    elif form.lower() in ['gaus','gaussian']:
        fitGaus = True
        fitSech2 = False
        
    elif form.lower() in ['sech2','sech squared','hyperbolic secant squared']:
        fitGaus = False
        fitSech2 = True
        
    else:
        print('Unknown fit form: '+form[0])
        fitGaus = False
        fitSech2 = False
    
    #start fitting 
    popt=[]
    pcov=[]
    
    if type(bgpar) is np.float64:
        p0=[max(y)-min(y),mean,stdv,bgpar]
    elif type(bgpar) is np.ndarray:
        p0=[max(y)-min(y),mean,stdv]+bgpar.tolist()   
    else:
        p0=None
   
    if fitGaus:
        try:
            poptGaus,pcovGaus = curve_fit(fitfuncGaus,x,y,p0) 
        except RuntimeError:
            poptGaus = np.zeros(nFitArgs)
            pcovGaus = np.zeros((nFitArgs,nFitArgs))   
        
        popt.append(poptGaus)
        pcov.append(pcovGaus)
        
    if fitSech2:
        try:
            poptSech2,pcovSech2 = curve_fit(fitfuncSech2,x,y,p0)
        except RuntimeError:
            poptSech2 = np.zeros(nFitArgs)
            pcovSech2 = np.zeros((nFitArgs,nFitArgs))
                       
        popt.append(poptSech2)
        pcov.append(pcovSech2)

    return np.array(popt), np.array(pcov) 
  #    if form.lower() in ['gaus','gaussian']: 
#        def pfunc(x,a,x0,sigma):
#            return gaus(x,a,x0,sigma)
#
#    elif form.lower() in ['sech2','sech squared','hyperbolic secant squared']: 
#        def pfunc(x,a,x0,sigma):
#            return sech2(x,a,x0,sigma) 
#            
#    else:    
#        print('Unknown curve form')
     
     
#    if bgform.lower() in ['const','constant']:
#            def fitfunc(x,a,x0,sigma,p0):
#                return pfunc(x,a,x0,sigma) + p0
#        
#    elif bgform.lower() in ['lin','linear']:
#            def fitfunc(x,a,x0,sigma,p0,p1):
#                return pfunc(x,a,x0,sigma) + p1*x + p0
#
#    elif bgform.lower() in ['quad','quadratic']:
#            def fitfunc(x,a,x0,sigma,p0,p1,p2):
#                return pfunc(x,a,x0,sigma) + p2*x**2 + p1*x + p0
#    else:
#            def fitfunc(x,a,x0,sigma):
#                return pfunc(x,a,x0,sigma)  
    
def plotpeak(x,y,popt,form,xscale = 1,yscale = 1):
    
    def bgfunc(x,c0=0,c1=0,c2=0):
        return(c0+c1*x+c2*x**2)
           
    if form.lower() in ['gaus','gaussian']:
        def gaus(x,a,x0,sigma,c0=0,c1=0,c2=0):
            return a*np.exp(-(x-x0)**2/(2*sigma**2)) + c0+c1*x+c2*x**2

        plt.plot(x*xscale,y*yscale,'b+:',label='data')
        plt.plot(x*xscale,gaus(x,*popt)*yscale,'r-',label='fit')
        plt.plot(x*xscale,bgfunc(x,*popt[3:])*yscale, 'k.:')
    
    elif form.lower() in ['sech2','sech squared','hyperbolic secant squared']:
        
        def sech2(x,a,x0,sigma,c0=0,c1=0,c2=0):
            return a*(1/np.cosh((x-x0)/sigma))**2 + c0+c1*x+c2*x**2
            
        plt.plot(x*xscale,y*yscale,'b+:',label='data')
        plt.plot(x*xscale,sech2(x,*popt)*yscale,'ro:',label='fit')
        plt.plot(x*xscale,bgfunc(x,*popt[3:])*yscale, 'k.:')
        
    else:
        
        print('Unknown curve form')

def normdata(x,y):
    
    xscale = max(x)-min(x)
    yscale = max(y)-min(y)
    
    return xscale,yscale
        
def background(x,y,form = 'constant'):
    '''takes x,y data and the desired background form (default to constant
    returns p, the polynomial coefficients. p is variable in length'''

    if form.lower() in ['const','constant']:
        p = min(y)
        #p = np.hstack((p,[0,0]))
        
    elif form.lower() in ['lin','linear']:
        p = np.linalg.solve([[1,x[0]],[1,x[-1]]], [y[0],y[-1]])
        #p = np.hstack((p,0))

    elif form.lower() in ['quad','quadratic']:
        index = np.argmin(y)
        
        if index == 0:
            x3 = 2*x[0]-x[-1]
            y3 = y[-1]    
        elif index == len(y):
            x3 = 2*x[-1]-x[0]
            y3 = y[0]   
        else:
            x3 = x[index]
            y3 = y[index]
        
        a = [[1,x[0],x[0]**2],[1,x[-1],x[-1]**2],[1,x3,x3**2]]
        b = [y[0],y[-1],y3]
        p = np.linalg.solve(a,b)
        
    else:
        print('Unknown background form')
        p = np.zeros((3))
        
    return p, form


def outputresults(origFile,x,y,xscale,yscale,popt,form = ['all', 'lin']):
    #popt should be an n x 5 matrix, n is number of fit types (gaus, sech, etc.)
    
    #generate filename/path
    origPath, origFilename = os.path.split(origFile)
    origName, origExt = os.path.splitext(origFilename)
    
    resultFolder = origPath + '/Results'
    
    if not os.path.exists(resultFolder):
        os.makedirs(resultFolder)    
    
    outFile = resultFolder + '/' + origName + '_result' + origExt
    
    #scale fit parameters
    try:
        num_par = popt.shape[1]
        num_fits = popt.shape[0]
    except IndexError:
        num_par = popt.shape[0]
        num_fits = 1
    
    pscale = ['y','x','x'] + ['y']*(num_par-3)
    Pscale = [s + 'scale' for s in pscale]    
    
    Popt = np.zeros(np.shape(popt))
    parNames = ['a','x0','sigma', 'c0', 'c1', 'c2']

    #fit parmeters in orig units
    for j in  range(num_fits):  
        for i in range(num_par):
            Popt[j][i] = popt[j][i]*eval(Pscale[i])
            
    
    if form[0].lower() in ['both', 'all']:
        form[0] = ','.join(['gaussian', 'sech2'])
        gIn = 0
        sIn = 1
#        poptGaus = Popt[0]
#        poptSech2 = Popt[1]
        fitGaus = True
        fitSech2 = True
        
    elif form[0].lower() in ['gaus','gaussian']:
#        poptGaus = Popt
        gIn = 0
        fitGaus = True
        fitSech2 = False
        
    elif form[0].lower() in ['sech2','sech squared','hyperbolic secant squared']:
#        poptSech2 = Popt
        sIn = 0
        fitGaus = False
        fitSech2 = True
        
    else:
        print('Unknown fit form: '+form[0])
        fitGaus = False
        fitSech2 = False
    
    if all(not v for v in Popt[gIn]):
        fitGaus = False
    if all(not v for v in Popt[sIn]):
        fitSech2 = False
        
    def gausfit(x,a,x0,sigma,c0=0,c1=0,c2=0):
        return gaus(x,a,x0,sigma) + c0 + c1*x + c2*x**2
        
    def sech2fit(x,a,x0,sigma,c0=0,c1=0,c2=0):
        return sech2(x,a,x0,sigma) + c0 + c1*x + c2*x**2

             
    #scale x,y - i.e. yields orig data            
    X = x*xscale
    Y = y*yscale
    
    #assemble data, fits and column labels
    OutputArray = np.vstack((X,Y))
    OutputLabel = np.hstack(('x','y'))
    
    dictPars = {}    
    
    if fitGaus:
        Gfit = yscale*gausfit(x,*popt[gIn])
        OutputArray = np.vstack((OutputArray,Gfit))
        OutputLabel = np.hstack((OutputLabel,'GausFit'))
        dictGaus = dict(zip(parNames,np.hstack((Popt[gIn],np.zeros(len(parNames)-len(Popt[gIn]))))))
        dictPars['gaus'] = dictGaus
    
    if fitSech2:
        Sfit = yscale*sech2fit(x,*popt[sIn])
        OutputArray = np.vstack((OutputArray,Sfit))
        OutputLabel = np.hstack((OutputLabel,'Sech2Fit'))    
        dictSech2 = dict(zip(parNames,np.hstack((Popt[sIn],np.zeros(len(parNames)-len(Popt[sIn]))))))
        dictPars['sech2'] = dictSech2

    #create header
    dateCreated = 'dateCreated = ' + time.strftime('%x %X')
    origData = 'origData = ' + origFile
    xUnit = 'xUnit = ' + 'fs'
    yUnit = 'yUnit = ' + 'W'
    fitForm = 'fitForm = ' + form[0]
    backgroundForm = 'backgroundForm = ' + form[1] 
    fitPars = json.dumps(dictPars)


    
    header = '\n'.join([dateCreated,origData,xUnit,yUnit,fitForm,backgroundForm,fitPars, ','.join(OutputLabel)])
    
    np.savetxt(outFile,OutputArray.transpose(), delimiter = ',', comments = '', header = header)    
    
#    with open(outFile, 'wb') as f:
#        f.write(header)
#        np.savetxt(f, OutputArray.transpose(), delimiter = ',')
        
    return outFile


def gaus(x,a,x0,sigma):
    return a*np.exp(-(x-x0)**2/(2*sigma**2))  
def sech2(x,a,x0,sigma):
    return a*(1/np.cosh((x-x0)/sigma))**2    
        
        
        
#Initialize Tkinter window
root = tk.Tk()
root.withdraw()
#Use system window to select files (multiple can be selected)
file_path = filedialog.askopenfilenames()

for file in file_path:
    data = GetData(file)
    
    
    xscale, yscale = normdata(data.timedelay,data.power)
    
    x = data.timedelay/xscale
    y = data.power/yscale
    
    #remove NaN, NaN appears is x, but need to remove x and y rows
    nanmap = ~np.isnan(x)    
    x = x[nanmap]
    y = y[nanmap]
    
    fitform = 'all'    
    bgform = 'const'
    
    popt,pcov = fitpeak(x,y,fitform, bgform = bgform)
    
    outputresults(file,x,y,xscale,yscale,popt,form = [fitform, bgform])
    #plotpeak(x,y,popt,fitform, xscale=xscale, yscale=yscale)
    
