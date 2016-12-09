function im = PadIm(im, padSize)
pad = im(1:padSize,:,:);
im = [pad ; im];
pad = im(end-padSize+1:end,:,:);
im = [im ; pad];
pad = im(:,1:padSize,:);
im = [pad im];
pad = im(:,end-padSize+1:end,:);
im = [im pad];
end