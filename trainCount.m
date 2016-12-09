function [b, dict] = trainCount(d,trainData)

nFrames = size(trainData,1);

if ~exist(fullfile(d.exppath,['dict_' num2str(d.dictSize) '.mat']),'file')
  posSamples = cell(1,nFrames);
  negSamples = cell(1,nFrames);
  N = d.dictSamples/nFrames;
  
  for f = 1:nFrames
    %%
    disp(['Sampling frame for dict. ' num2str(f) '/' num2str(nFrames)]);
    
    im = imread(fullfile(d.datapath,'train',[trainData{f,1} '.' d.imExt]));
    
    im = imresize(im,d.sFactor);
    
    dots = trainData{f,2};
    dots = round(dots*d.sFactor);
    
    imf = encodeImage(im,d);
    density = getDensity(im,dots,d.sigma,d.cropSize);
    imf = shiftdim(imf,2);
    imf = reshape(imf,size(imf,1),[]);
    
    highDensIdx = density(:)>=d.midDensity;
    lowDensIdx = density(:)<d.midDensity;
    
    posSamples{f} = vl_colsubset(imf(:,highDensIdx),round(2*N/3));
    negSamples{f} = vl_colsubset(imf(:,lowDensIdx),round(N/3));
  end
  
  posSamples(cellfun(@isempty,posSamples)) = [];
  negSamples(cellfun(@isempty,negSamples)) = [];
  posSamples = cell2mat(posSamples);
  negSamples = cell2mat(negSamples);
  
  
  %Try balancing
  disp('Balance');
  if size(negSamples,2) > size(posSamples,2)
    nDiscard = size(negSamples,2) - size(posSamples,2);
    
    disp(['Low density samples: ' num2str(size(negSamples,2))]);
    disp(['High density samples: ' num2str(size(posSamples,2))]);
    disp(['Discarded samples: ' num2str(nDiscard)]);
    
    toDiscard = randperm(size(negSamples,2));
    negSamples(:,toDiscard(1:nDiscard)) = [];
  end
  
  samples = [posSamples negSamples];
  clear posSamples negSamples
  
  %% Learn dictionary
  dict.means = vl_kmeans(samples,d.dictSize);
  dict.tree = vl_kdtreebuild(dict.means);
  
  save(fullfile(d.exppath,['dict_' num2str(d.dictSize) '.mat']),'dict');
else
  load(fullfile(d.exppath,['dict_' num2str(d.dictSize) '.mat']));
end


if ~exist(fullfile(d.exppath,['regressor_' num2str(d.dictSize) '.mat']),'file')
  %% encode training set
  X = cell(1,nFrames);
  Y = cell(1,nFrames);
    
  N = d.regSamples/nFrames;
  for f = 1:nFrames
    %%
    disp(['Sampling frame for regression ' num2str(f) '/' num2str(nFrames)]);
    im = imread(fullfile(d.datapath,'train',[trainData{f,1} '.' d.imExt]));
    
    im = imresize(im,d.sFactor);
    
    dots = trainData{f,2};
    dots = round(dots*d.sFactor);
    
    imf = encodeImage(im,d);
    sz = size(imf);
    density = getDensity(im,dots,d.sigma,d.cropSize);
    density = reshape(density,1,size(density,1)*size(density,2));
    imf = shiftdim(imf,2);
    imf = reshape(imf,size(imf,1),[]);
    
    Idx = uint16(vl_kdtreequery(dict.tree,dict.means,imf));
    
    li = size(Idx,2);
    scode = sparse(1:li,double(Idx),ones(1,li),li,d.dictSize);
    code = reshape(full(scode), sz(1),sz(2),d.dictSize);
    clear scode
    code = vl_imsmooth(code,d.sigma); %spatial smoothing of the code
    code = reshape(code,size(code,1)*size(code,2),d.dictSize)';
    
    highDensIdx = find(density(:)>=d.midDensity);
    lowDensIdx = find(density(:)<d.midDensity);
       
    [posSamples,possel] = vl_colsubset(code(:,highDensIdx),round(2*N/3));
    [negSamples,negsel] = vl_colsubset(code(:,lowDensIdx),round(N/3));
    
    highDensity = density(highDensIdx);
    lowDensity = density(lowDensIdx);
    
    X{f} = [posSamples negSamples];
    Y{f} = [highDensity(possel) lowDensity(negsel)];
    
  end
  
  %% learn regression
  X(cellfun(@isempty,X)) = [];
  Y(cellfun(@isempty,Y)) = [];
  X = cell2mat(X)';
  Y = cell2mat(Y)';
  
  %Try balancing
  disp('Balance');
  lowDensIdx = find(Y<d.midDensity);
  highDensIdx = find(Y>=d.midDensity);
  
  if numel(lowDensIdx) > numel(highDensIdx)
    nDiscard = numel(lowDensIdx) - numel(highDensIdx);
    
    disp(['Low dense samples: ' num2str(numel(lowDensIdx))]);
    disp(['High dense samples: ' num2str(numel(highDensIdx))]);
    disp(['Discarded samples: ' num2str(nDiscard)]);
    
    toDiscard = randperm(numel(lowDensIdx));
    Y(lowDensIdx(toDiscard(1:nDiscard))) = [];
    X(lowDensIdx(toDiscard(1:nDiscard)),:) = [];
  end
  
  clear lowDensIdx highDensIdx
  
  %add constant term
  X = [X ones(size(X,1),1)];
  negs = 1;
  
  disp('Doing ridge-regression');
  
  while numel(negs) > 0 %enforcing non-negativity
    b = (X'*X + speye(size(X,2)))\(X'*Y);
    negs = find(b<0);
    disp(['Neg. elem.: ' num2str(numel(negs)) '. Fit: ' num2str(sum(X*b)) '/' num2str(sum(Y))]);
    X(:,negs) = 0;
  end
  %U = X'*X;
  clear X Y
  save(fullfile(d.exppath,['regressor_' num2str(d.dictSize) '.mat']),'b');
  disp(['Model saved in ' fullfile(d.exppath,['regressor_' num2str(d.dictSize) '.mat'])]);
else
  load(fullfile(d.exppath,['regressor_' num2str(d.dictSize) '.mat']))
  disp(['Model loaded from ' fullfile(d.exppath,['regressor_' num2str(d.dictSize) '.mat'])]);
end