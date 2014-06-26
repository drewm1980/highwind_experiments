#!/usr/bin/env python
from scipy.io import netcdf
from numpy import array, diff
import pylab
from pylab import figure,plot,xlabel,ylabel,show,legend

print('loading data...')
rootName = 'lineAngleSensor2'

f = netcdf.netcdf_file(rootName+'Data.nc', 'r')

def plot_member(memberName, ylabel):
    data = f.variables[rootName+'.data.'+memberName].data[1:]
    ts_trigger = f.variables[rootName+'.data.ts_trigger'].data[1:]*1.0e-9
    figure()
    plot(ts_trigger-ts_trigger[0], data,'b.') 
    xlabel('Time [s]')
    pylab.ylabel(ylabel)

plot_member('azimuth', "Azimuth Line Angle [Rad]")
plot_member('elevation', "Elevation Line Angle [Rad]")

show()
print('...done')
