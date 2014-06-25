#!/usr/bin/env python
from scipy.io import netcdf
from numpy import array, diff, mean
import pylab
from pylab import figure,plot,xlabel,ylabel,show,legend,title

print('loading data...')

print('loading timing data to plot jitter...')

fileRoots = ['controller', 'resampler', 'lineAngleSensor2', 'siemensSensors']

figure('Jitter, based on diff of timestamps')
for i in range(len(fileRoots)):
    pylab.subplot(len(fileRoots),1,i+1)
    if i==0:
        title('Component startHooks jitter')
    f = netcdf.netcdf_file(fileRoots[i]+'Data.nc', 'r')
    ts_trigger = f.variables[fileRoots[i]+'.data.ts_trigger'].data[1:]*1.0e-9
    jitter = diff(ts_trigger) * 1e3 # ms
    jitter = jitter - mean(jitter)
    times = ts_trigger-ts_trigger[0]
    plot(times[:-1], jitter ,'b.') 
    ylabel(fileRoots[i]+' jitter [ms]')
    if i==len(fileRoots)-1:
        xlabel('Time [s]')

show()
