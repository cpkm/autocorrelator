# -*- coding: utf-8 -*-
"""
Created on Wed Oct 19 11:02:23 2016

@author: cpkmanchee

Notes:

Diffraction grating pair
"""

import numpy as np
import matplotlib.pyplot as plt

'''
Simulate grating pair
pulse = input pulse object
L = grating separation (m), use (-) L for stretcher, (+) L for compressor geometry
N = lns/mm of gratings
AOI = angle of incidence (deg)

theta = diffraction angle (assumed 1 order, as is standard)
d = groove spacing

EVERYTHING IS FOR 1st order
'''

#constants
h = 6.62606957E-34  #J*s
c = 299792458.0     #m/s

def gdd2len(GDD, N, AOI, lambda0):
    m = 1
    g = AOI*np.pi/180    #convert AOI into rad
    d = 1E-3/N    #gives grove spacing in m

    w0 = 2*np.pi*c/lambda0
    theta = np.arcsin(m*2*np.pi*c/(w0*d) - np.sin(g))

    L = np.abs(GDD*(d**2*w0**3*np.cos(theta)**3)/(-m**2*2*4*(np.pi**2)*c))

    L_real = L/np.cos(theta)    
    
    return L, L_real
    
def beta2(N, AOI, lambda0):
    m = 1
    g = AOI*np.pi/180    #convert AOI into rad
    d = 1E-3/N    #gives grove spacing in m

    w0 = 2*np.pi*c/lambda0
    theta = np.arcsin(m*2*np.pi*c/(w0*d) - np.sin(g))
    
    beta2 = (-m**2*2*4*(np.pi**2)*c)/(d**2*w0**3*np.cos(theta)**3)

    return beta2
    

def dispCoef(L, N, AOI, lambda0):
    m = 1
    g = AOI*np.pi/180    #convert AOI into rad
    d = 1E-3/N    #gives grove spacing in m

    w0 = 2*np.pi*c/lambda0
    theta = np.arcsin(m*2*np.pi*c/(w0*d) - np.sin(g))
    
    phi0 = 4*L*w0*np.cos(theta)/c
    phi1 = (phi0/w0)*(1+(2*np.pi*c*m*np.sin(theta)/(w0*d*np.cos(theta)**2)))
    phi2 = (-m**2*2*4*(np.pi**2)*L*c/(d**2*w0**3))*(1/np.cos(theta)**3)
    phi3 = (-3*phi2/w0)*(1+(2*np.pi*c*m*np.sin(theta)/(w0*d*np.cos(theta)**2)))
    phi4 = ((2*phi3)**2/(3*phi2)) + phi2*(2*np.pi*c*m/(w0**2*d*np.cos(theta)**2))**2
    
    return np.array([phi0,phi1,phi2,phi3,phi4])
    

def diffAngle(N, AOI, lambda0):
    m = 1
    g = AOI*np.pi/180    #convert AOI into rad
    d = 1E-3/N    #gives grove spacing in m

    w0 = 2*np.pi*c/lambda0
    theta = np.arcsin(m*2*np.pi*c/(w0*d) - np.sin(g))
    
    return theta*180/np.pi
    
def transBeamSize(GDD, N, AOI, lambda0, dlambda):
    
    L, L_real = gdd2len(GDD, N, AOI, lambda0)
    dth = np.abs(diffAngle(N, AOI, lambda0 + dlambda/2) - diffAngle(N, AOI, lambda0-dlambda/2))
    
    dxMax = 2*L_real*np.arctan(dth*np.pi/(2*180))
    
    return dxMax
    
def litAngle(N, lambda0):
    
    d = 1E-3/N
    a = (180/np.pi)*np.arcsin(lambda0/(2*d))
    
    return a
    

aoi = np.linspace(0,90,50)
l0 = 1030E-9
dl = 10E-9
gdd = 37E-24

n = 1200

l,lr = gdd2len(gdd,n,aoi,l0)
x = transBeamSize(gdd,n,aoi,l0,dl)
da = diffAngle(n,aoi,l0)
xr = x/np.cos(da*np.pi/180)

plt.figure(0)
plt.plot(aoi,l,'--',aoi,lr,'-')

plt.figure(1)
plt.plot(aoi,x,'--',aoi,xr,'-')



n = 1500
l,lr = gdd2len(gdd,n,aoi,l0)
x = transBeamSize(gdd,n,aoi,l0,dl)
da = diffAngle(n,aoi,l0)
xr = x/np.cos(da*np.pi/180)

plt.figure(0)
plt.plot(aoi,l,'--',aoi,lr,'-')

plt.figure(1)
plt.plot(aoi,x,'--',aoi,xr,'-')


n = 1760
l,lr = gdd2len(gdd,n,aoi,l0)
x = transBeamSize(gdd,n,aoi,l0,dl)
da = diffAngle(n,aoi,l0)
xr = x/np.cos(da*np.pi/180)

plt.figure(0)
plt.plot(aoi,l,'--',aoi,lr,'-')

plt.figure(1)
plt.plot(aoi,x,'--',aoi,xr,'-')
