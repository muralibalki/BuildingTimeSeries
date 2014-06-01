clear all
clc
t = [0:pi/50:2*pi];
sig = sawtooth(3*t); % x is a row vector
ini_codebook = [-1:.1:1]; % Initial guess at codebook
% Optimize parameters, using initial codebook and order 1.

ord=1;
a=ar(sig,ord);
predictor=polydata(a);
predictor(1)=0;
predictor(2:end)=-predictor(2:end);

predictor=[0 0.8095];

len=length(sig);
err = zeros(len-ord,1);
% continue to find the partition and codebook.
% calculate the predictive errors:
for i = ord+1 : len
    err(i-ord) = sig(i) - predictor * sig(i:-1:i-ord)';
end;


% learn codebook
%[partition, codebook] = lloyds(err, ini_codebook);
NITER=1;
[IDX, codebook] = kmeans(err, length(ini_codebook),'MaxIter',NITER,'Replicates',1);
codebook=sort(codebook);
partition=sort((codebook(2 : end)+ codebook(1 : end-1)) / 2);

len_predictor = length(predictor) - 1;
sP=predictor;
predictor = predictor(2:len_predictor+1);
predictor = predictor(:)';
len_sig = length(sig);

x = zeros(len_predictor, 1);
for i = 1 : len_sig;
    out = predictor * x;
    e = sig(i) - out;
    % index
    indx(i) = sum(partition < e);
    % quantized value
    quanterr(i) = codebook(indx(i) + 1);
    inp = quanterr(i) + out;
    % renew the estimated output
    x = [inp; x(1:len_predictor-1)];
end;

encodedx=indx;
predictor=sP;


% Quantize x using DPCM.
%encodedx = dpcmenco(x,codebook,partition,predictor);
% Try to recover x from the modulated signal.
len_predictor = length(predictor) - 1;
predictor = predictor(2:len_predictor+1);
predictor = predictor(:)';
len_sig = length(indx);

quanterr = indx;
quanterr = codebook(indx+1);

x = zeros(len_predictor, 1);
for i = 1 : len_sig;
    out = predictor * x;
    nSig(i) = quanterr(i) + out;
    % renew the estimated output
    x = [nSig(i); x(1:len_predictor-1)];
end;

decodedx=nSig;


%decodedx = dpcmdeco(encodedx,codebook,predictor);
distor = sum((sig-decodedx).^2)/length(sig) % Mean square error
