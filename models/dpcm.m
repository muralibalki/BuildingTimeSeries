clear all
clc
% based heavily and modified slightly from the matlab builtin
% changed lloyds to kmeans (worse)
% Levinson to full inverse (better)

t = [0:pi/50:2*pi];
sig = sawtooth(3*t); % x is a row vector
ini_codebook = [-1:.1:1]; % Initial guess at codebook

% learn ar model or order ord
ord=1; %ar model order 
a=ar(sig,ord);
predictor=polydata(a);

% predictior is stored as 1-A(z)
predictor(1)=0;
predictor(2:end)=-predictor(2:end);

len=length(sig);
err = zeros(len-ord,1);
% compute prediction errors:
for i = ord+1 : len
    err(i-ord) =sig(i)-(predictor*sig(i:-1:i-ord)');
end;

% learn a codebook for the prediction errors
NITER=100;
[IDX, codebook] = kmeans(err, length(ini_codebook),'MaxIter',NITER,'Replicates',1);
codebook=sort(codebook);
partition=sort((codebook(2:end)+codebook(1:end-1))/2);


sP=predictor;
% encoding
len_predictor =length(predictor)-1;
predictor = predictor(2:len_predictor+1);
predictor = predictor(:)';
len_sig = length(sig);

x = zeros(len_predictor,1);
for i = 1 : len_sig;
    out = predictor * x;
    e = sig(i) - out;
    % index
    indx(i) = sum(partition<e);
    % quantized value
    quanterr(i) = codebook(indx(i)+1);
    inp = quanterr(i) + out;
    % renew the estimated output
    x = [inp; x(1:len_predictor-1)];
end;

encodedx=indx;
predictor=sP;

% decoding
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

% compute end to end distortion
distor = sum((sig-decodedx).^2)/length(sig) % Mean square error
