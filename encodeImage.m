function xd = encodeImage(img,d)

xd = [];

if size(img,3) == 3
  %convert to LAB
  imlab = vl_xyz2lab(vl_rgb2xyz(img)) ;
  l = single(imlab(:,:,1));
  a = single(imlab(:,:,2));
  b = single(imlab(:,:,3));
else
  l = single(img);
end

l = anisodiff(l,1,20,.25,1);

if d.int
  xd = cat(3,xd,l);
end

if d.colorChannels
  xcc = zeros(size(img,1),size(img,2),nFeat_cc,'single');
  xcc(:,:,1) = single(l/max(l(:)));
  if numel(S.channels) == 3
    xcc(:,:,2) = single(a/max(a(:)));
    xcc(:,:,3) = single(b/max(b(:)));
  end
  xd = cat(3,xd,xcc);
  clear xcc
end

%%
if d.textPatches
  prm = d.feats.tp;
  xtp = zeros(size(img,1),size(img,2),d.nFeat_tp,'single');
  xtp(:,:,1:d.nFeat_tp)=...
    EncodePatchBased(l,prm.neib,prm.cropSize,...
    1,single(l/max(l(:))),0,prm.orientBins);
  xd = cat(3,xd,xtp);
  clear xtp
end

%%
if d.gabor
  prm = d.feats.gabor;
  xgb = zeros(size(img,1),size(img,2),d.nFeat_gb,'single');
  xgb_or = zeros(size(img,1),size(img,2),prm.nOrient,'single');
  EO = gaborconvolve(l, prm.nScales, prm.nOrient,...
    prm.minWaveLength, prm.mult, ...
    prm.sigmaOnf, prm.dThetaOnSigma,...
    prm.Lnorm, prm.feedback);
  for i = 1:prm.nScales
    for j=1:prm.nOrient
      %xgb(:,:,j+nOrient*(i-1)) = single(abs(EO{i,j}));
      xgb_or(:,:,j) = single(abs(EO{i,j}));
    end
    xgb(:,:,i) = sum(xgb_or,3);
    xgb(:,:,i) = xgb(:,:,i)/max(max(xgb(:,:,i)));
  end
  xd = cat(3,xd,xgb);
  clear E0 xgb
end

%%
if d.dog
  prm = d.feats.dog;
  %l_n = single(l-median(l(:)));
  imG = zeros([size(l) numel(prm.sigmas)],'single');
  
  for i = 1:size(imG,3)
    imG(:,:,i) = vl_imsmooth(l,prm.sigmas(i),'Padding','continuity');
  end
  xdog = zeros([size(img,1),size(img,2),numel(prm.sigmas)-prm.nPerOctave],'single');
  %sigma = zeros(1,numel(sigmas)-nPerOctave);
  for i = 1:size(imG,3)-prm.nPerOctave
    %   sigma(i) = sqrt(sigmas(i)*sigmas(i+nPerOctave));
    xdog(:,:,i) = imG(:,:,i)-imG(:,:,i+prm.nPerOctave);
  end
  xd = cat(3,xd,xdog,imG);
  clear imG xdog
end

%%
if d.sift
  [frames, feats] = vl_phow(single(l), 'Verbose', d.feats.sift.verbose, ...
    'Sizes', d.feats.sift.sizes, 'Fast', d.feats.sift.fast, 'step', d.feats.sift.step, ...
    'Color', d.feats.sift.color, 'ContrastThreshold', d.feats.sift.contrast_threshold, ...
    'WindowSize', d.feats.sift.window_size, 'Magnif', d.feats.sift.magnif, ...
    'FloatDescriptors',d.feats.sift.float_descriptors);
  feats = single(feats);
  
  xCrop = frames(1,1)-1;
  yCrop = frames(2,1)-1;
  out = frames(1,:) >= size(l,2)-xCrop+1 | frames(2,:) >= size(l,1)-yCrop+1;
  feats(:,out) = [];
  %frames(:,out) = [];
  
  c = size(feats,2)/4;
  
  feats = [feats(:,1:c);feats(:,c+1:2*c);feats(:,2*c+1:3*c);feats(:,3*c+1:4*c)];
  %frames = [frames(:,1:c);frames(:,c+1:2*c);frames(:,2*c+1:3*c);frames(:,3*c+1:4*c)];
  feats = reshape(feats',size(l,1)-2*yCrop,size(l,2)-2*xCrop,128*numel(d.feats.sift.sizes));
  %frames = reshape(frames',size(l,1)-2*yCrop,size(l,2)-2*xCrop,4*numel(d.feats.sift.sizes));
    
  if d.feats.sift.rootsift
    feats = sqrt(feats);
  end
  
  xd = feats;  
end
%% crop output to keep only valid regions
if ~d.sift
  xd(1:d.cropSize,:,:)=[];
  xd(end-d.cropSize+1:end,:,:)=[];
  xd(:,1:d.cropSize,:)=[];
  xd(:,end-d.cropSize+1:end,:)=[];
end
