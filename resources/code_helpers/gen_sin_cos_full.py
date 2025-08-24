#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
This file generates a full-wave look up table for the 
direct digital synthesis module of the lock-in app. 

you only need the cos1 and sin1 files technically
author: metrosierra, based on script by "lolo"

T has to be a binary power for now, DDS module does not
allow for clean wrap around for non-binary power yet.
"""

#%%


from numpy import *
# import matplotlib.pyplot as plt


write_files=False

#T      = int(504)   #   2*3*3*7*4
#T      = int(48)   #   3*4*4
T      = int(4096)   #   4*4*3*10


xx     = arange(0,T)
A      = (2**12-1)
scos   = cos((xx+0.5)*2*pi/T)  *A
scos2  = cos((xx+0.5)*2*pi/T*2)*A
scos3  = cos((xx+0.5)*2*pi/T*3)*A
scos4  = cos((xx+0.5)*2*pi/T*4)*A
ssin   = sin((xx+0.5)*2*pi/T)  *A



#%%

write_files = True


files = ['data_full_sin1_{}points.dat'.format(T)] + ['data_full_cos{}_{}points.dat'.format(ii, T) for ii in range(1, 5)]
datas = [ssin, scos, scos2, scos3, scos4]
dlims = [1, 1, 2, 3, 4]


for dat,fn,dlim in zip(datas, files, dlims):
    tmp=dat[0:T//dlim].astype(uint16)
    # plt.plot(tmp,'.-')
    if write_files:
        with open(fn, 'w') as content_file:
            tmp2=[]
            for i in tmp:
                tmp2.append('{0:016b}'.format(i)[-14:])
            content_file.write('\n'.join(tmp2))
