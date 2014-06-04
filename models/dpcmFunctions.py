from scipy import signal
import matplotlib.pyplot as plt
from statsmodels.tsa import ar_model
from scipy.cluster.vq import *
import struct
import binascii
from bitstring import BitArray
import pandas as pd
import numpy as np
import warnings

def dpcmopt(sig,order,nCodeWords):
    am=ar_model.AR(sig)
    predictor=am.fit(order)
    leng=len(sig)
    preds=predictor.predict(order,leng)
    preds=np.append(np.zeros(order-1),preds)
    err=sig-preds;
    flag = 1
    while flag:
        with warnings.catch_warnings(record=True) as w:
            codebook, idx = kmeans2(err,nCodeWords)
            if len(w)==0:
                flag=0
                #print "Success!"
    codebook.sort()
    en=len(codebook)
    partition=(codebook[1:en]+codebook[0:en-1])/2;
    partition.sort()
    res=err
    return (partition, codebook, predictor)

def dpcmencoAfterOpt(partition, codebook, predictor,sig):
    order = len(predictor.params)-1
    len_sig=len(sig)
    x=np.zeros(order)
    indx= [0] * len_sig
    quanterr=np.zeros(len_sig)
    for i in xrange(order,len_sig):
        out =  sum(np.append(1,x)*predictor.params)
        e = sig[i] - out
        indx[i] = sum(partition<e)
        quanterr[i] = codebook[indx[i]]
        inp = quanterr[i] + out;
        x = np.append(inp,x[0:order-1])
    return indx

def bitPackDPCMModel(order,predictor,nCodeWords,codebook,sigLen,encodedx):
    a=BitArray(uint=order, length=8)
    b=BitArray().join(BitArray(float=x, length=32) for x in predictor.params)
    a.append(b)
    a.append(BitArray(uint=int(nCodeWords), length=8))
    b=BitArray().join(BitArray(float=x, length=32) for x in codebook)
    a.append(b)
    a.append(BitArray(uint=int(sigLen), length=32))
    nBits=int(np.ceil(np.log2(nCodeWords)));
    b=BitArray().join(BitArray(uint=x, length=nBits) for x in encodedx)
    a.append(b)
    return(a)

def dpcmBinenco(sig,order,nCodeWords):
    partition, codebook, predictor = dpcmopt(sig,order,nCodeWords)
    encodedx = dpcmencoAfterOpt(partition, codebook, predictor,sig)
    sigLen=len(sig);
    a=bitPackDPCMModel(order,predictor,nCodeWords,codebook,sigLen,encodedx)
    return (a)

def bitUnPackDPCMModel(a):
    pos=0
    order=a[0:8].int
    pos+=8
    string_blocks = (a[i:i+32] for i in range(pos, pos+32*(order+1), 32))
    params=np.zeros(order+1)
    count=0
    for fl in string_blocks:
        pos+=32
        params[count]=fl.float
        count+=1
    nCodeWords=a[pos:pos+8].int
    pos+=8
    string_blocks = (a[i:i+32] for i in range(pos, pos+32*(nCodeWords), 32))
    codebook=np.zeros(nCodeWords)
    count=0
    for fl in string_blocks:
        pos+=32
        codebook[count]=fl.float
        count+=1
    sigLen=a[pos:pos+32].int
    pos+=32
    nBits=int(np.ceil(np.log2(nCodeWords)));
    string_blocks = (a[i:i+nBits] for i in range(pos, pos+nBits*(sigLen), nBits))
    encodedx=np.zeros(sigLen)
    count=0
    for fl in string_blocks:
        pos+=nBits
        encodedx[count]=fl.uint
        count+=1
    am=ar_model.AR(range(0,sigLen))
    predictor=am.fit(order)
    predictor.params=params
    return (codebook, predictor,encodedx)

def dpcmdeco(codebook, predictor,indx):
    indx=indx.astype(int)
    order = len(predictor.params)-1
    len_sig = len(indx)
    quanterr = codebook[indx]
    nSig=np.zeros_like(quanterr)
    x = np.zeros(order);
    for i in xrange(0,len_sig):
        out = sum(np.append(1,x)*predictor.params)
        nSig[i] = quanterr[i] + out;
        x = np.append(nSig[i], x[0:order-1])
    return(nSig)

def dpcmBindeco(a):
    codebook, predictor,encodedx = bitUnPackDPCMModel(a)
    nSig = dpcmdeco(codebook, predictor,encodedx)
    return(nSig)
