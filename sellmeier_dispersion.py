# -*- coding: utf-8 -*-
"""
Created on Thu Nov 24 20:28:42 2016

@author: cpkmanchee

Dispersioon calculation from Sellmeier eqn
"""

import numpy as np
import scipy as sp
import matplotlib.pyplot as plt
import sympy as sym
from sympy.plotting import plot as symplot

h = 6.62606957E-34  #J*s
c = 299792458.0     #m/s

l0 = 1.03E-6
w0 = 2*np.pi*c/l0

orders = 5
beta = np.zeros(orders+1,)
   
B =  np.array([1.03961212,0.231792344,1.01046945])
C = np.array([0.00600069867,0.0200179144,103.560653])*1E-12

n, w = sym.symbols('n, w')  

n = (1 + (B/(1-C*(w/(2*np.pi*c))**2)).sum() )**(1/2)

for i in range(orders+1):
    beta[i] = (1/c)*(i*sym.diff(n,w,i-1).subs(w,w0) + w0*sym.diff(n,w,i).subs(w,w0))


print(beta)

'''
b = np.zeros((5,x))

for i in range(x):
    N = 2**(4+i)
    
    w = np.linspace(w_range[1],w_range[0],N)
    dw = (w_range[0]-w_range[1])/(N-1)
    
    dn = np.zeros((b.shape[0]+1, w.size))
    
    dn[0,] = (1+(B1/(1-C1*w**2/(2*np.pi*c)**2))+(B2/(1-C2*w**2/(2*np.pi*c)**2))+(B3/(1-C3*w**2/(2*np.pi*c)**2)))**(1/2)
    
    for k in range(b.shape[0]):
        dn[k+1] = np.gradient(np.convolve(dn[k], np.ones(smooth)/smooth,'same'),dw)
   
    for j in range(b.shape[0]):
        b[j,i] = (1/c)*(j*np.interp(w0,w,dn[j]) + w0*np.interp(w0,w,dn[j+1]))
'''