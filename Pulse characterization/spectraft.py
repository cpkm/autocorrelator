# -*- coding: utf-8 -*-
"""
Created on Fri Oct  2 21:13:11 2015

@author: cpkmanchee
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

def norm(x):
    '''
    X = norm(x)
    
    x should be 1D array,list
    X is output, 1D array, equal to input scaled by max(x)-min(x) shifted by min(x)
    '''
    
    return (x-min(x))/(max(x)-min(x))
    
def gaus(x,a,b,c,d):
    return a*np.exp(-(x-b)**2/(2*c**2)) + d   

def sech2(x,a,b,c,d):
    return a*(1/np.cosh((x-b)/c))**2 + d

#Initialize Tkinter window
root = tk.Tk()
root.withdraw()
#Use system window to select files (single file can be selected)   
file = filedialog.askopenfilename()
root.destroy()

data = np.genfromtxt(file,delimiter = ',').transpose()

c = 299792458.0
n = 2**12    #2^11=2048, number of interp samples

wl = data[0]
psd = norm(data[1])

nu = (c/(wl*1E-9))*1E-12    #nu in THz
nu0 = np.average(nu,weights = psd**2)

#display plot of spectrum
wl_bgn = 950        #in nm
wl_end = 1100
i_bgn = (np.abs(wl-wl_bgn)).argmin()
i_end = (np.abs(wl-wl_end)).argmin()

plt.subplot(2,1,1)
plt.plot(wl[i_bgn:i_end], psd[i_bgn:i_end])


#interpolate psd, linear freq spacing
nui = np.linspace(min(nu),max(nu),n)
df = (max(nu)-min(nu))/(n-1)
psdi = norm(np.interp(nui,np.flipud(nu),np.flipud(psd)))
i = (np.abs(nui-nu0)).argmin()     #centre freq index

#shift to centre, pad with zeros
if i < n/2:
    pad = (int(n-2*i),0)
elif i > n/2:
    pad = (0,int(2*i-n))
else:
    pad = (0,0)

pad = np.add(pad, int((n - np.abs(2*i-n))/2)).tolist() 
PSD = np.pad(psdi,pad,'constant', constant_values = (0,0))
NU = np.linspace(-df*n,df*(n-1),2*n)       


#perform FT-1, remove centre spike
t = np.fft.ifftshift(np.fft.fftfreq(2*n,df)[1:-1])
ac =norm(np.fft.ifftshift( (np.fft.ifft(np.fft.ifftshift(PSD)))[1:-1]))


#fit ac curve
#window size
N = 2*n     #equals len(t)
m = N//20

x = t[n-m:m-n]
y = np.abs(ac[n-m:m-n])**2

plt.subplot(2,1,2)
ac_plot, = plt.plot(x,y,'k.')

mean = np.average(x,weights = y)       
stdv = np.sqrt(np.average((x-mean)**2 ,weights = y))

poptSech2,pcovSech2 = curve_fit(sech2,x,y,[1,mean,stdv,0])
poptGaus,pcovGaus = curve_fit(gaus,x,y,[1,mean,stdv,0])

fwhmS = (1.76/1.54)*poptSech2[2]
fwhmG = (2*np.sqrt(2*np.log(2))/np.sqrt(2))*poptGaus[2]

gaus_plot, = plt.plot(x,gaus(x,*poptGaus), 'b-', label = 'Gaussian '+ '%.f' % (fwhmG*1000) +'fs')
sech2_plot, = plt.plot(x, sech2(x,*poptSech2), 'r-', label = 'Sech Squared '+ '%.f' % (fwhmS*1000) +'fs')

plt.legend(handles = [sech2_plot,gaus_plot])

#generate filename/path
origPath, origFilename = os.path.split(file)
origName, origExt = os.path.splitext(origFilename)
       
outFile = origPath + '/' + origName + '_result.txt'
    
OutputArray = np.vstack((x,y,gaus(x,*poptGaus),sech2(x,*poptSech2)))

parNames = ['a','x0','sigma', 'c0']
dictPars = {}
dictGaus = dict(zip(parNames,np.hstack((poptGaus,np.zeros(len(parNames)-len(poptGaus))))))
dictPars['gaus'] = dictGaus
dictSech2 = dict(zip(parNames,np.hstack((poptSech2,np.zeros(len(parNames)-len(poptSech2))))))
dictPars['sech2'] = dictSech2


dateCreated = 'dateCreated = ' + time.strftime('%x %X')
origData = 'origData = ' + file
xUnit = 'xUnit = ' + 'ps'
yUnit = 'yUnit = ' + 'W'   
labels = 'time,power,gausfit,sech2fit'
fitPars = json.dumps(dictPars)

header = '\n'.join([dateCreated,origData,xUnit,yUnit,fitPars,labels])

np.savetxt(outFile,OutputArray.transpose(), delimiter = ',', comments = '', header = header)   