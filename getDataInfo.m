function d = getDataInfo(rootpath)
%Setup all the paths and options for the crystal counting training/testing.

%---------------------------------------------------------------Paths setup
d.path = rootpath; %root path
d.datapath = fullfile(rootpath.data,'syntheticCells'); %path to the raw data and annotations
d.exppath = [d.datapath '/demoOutput']; %path to folder where the results are stored

if ~exist(d.exppath,'dir')
  mkdir(d.exppath);
end

%---------------------------------------------------------Input Information
d.objSize = 15; %Rough size of the object in the input images
d.imExt = 'png'; %image extension, png, jpg, etc...

%------------------------------------------------------------Output options
%save density maps in original resolution
d.saveDensity = 1;

%produce extremal-region visualization count (aside from default global 
%count) and save visualization mask
d.visCount = 1;

%Save density extremal-region visualization image
d.segment = 0;

%-------------------------------------------------------------Input options
%regression
d.subsetSize = 150;
d.regSamples = 0.5e6;

%visual vocabulary
d.dictSamples = 2e6;
d.dictSize = 512;

%image resizing
d.targScale = 10;
d.sFactor = d.targScale/d.objSize;
d.cropSize = ceil(d.targScale/4);

%GT density
d.sigma = sqrt(d.targScale);
d.midDensity = 0.001;

%features
d.textPatches = 0;
d.gabor = 1;
d.dog = 1;
d.int = 1;
d.sift = 0;
d.colorChannels = 0;

if d.int
  nFeat_int = 1;
else
  nFeat_int = 0;
end

if d.colorChannels
  nFeat_col = 3;
else
  nFeat_col = 0;
end
  

if d.textPatches
  %for the patch encoding
  neib = 9;
  d.feats.tp.neib = neib;%str2double(get(handles.txt_neib,'String'));
  d.feats.tp.cropSize = ceil(neib/2);
  d.feats.tp.orientBins = 16;
  nFeat_tp = neib^2 + 1;
else
  nFeat_tp = 0;
end

if d.gabor
  d.feats.gabor.nOrient = 4;
  d.feats.gabor.nScales = 5;
  d.feats.gabor.minWaveLength = d.targScale/3;
  d.feats.gabor.mult = 1.7;
  d.feats.gabor.sigmaOnf = 0.65;
  d.feats.gabor.dThetaOnSigma = 1.3;
  d.feats.gabor.Lnorm = 2;
  d.feats.gabor.feedback = 0;
  nFeat_gb = d.feats.gabor.nScales;
else
  nFeat_gb = 0;
end

if d.dog
  d.feats.dog.sigmaRange = [d.targScale/12 d.targScale/3];
  d.feats.dog.nPerOctave = 6;
  d.feats.dog.sigmas =...
    power(2,log2(d.feats.dog.sigmaRange(1))-(0.5/d.feats.dog.nPerOctave):...
    (1.0/d.feats.dog.nPerOctave):log2(d.feats.dog.sigmaRange(2))+(0.5/d.feats.dog.nPerOctave));
  nFeat_dog = numel(d.feats.dog.sigmas) - d.feats.dog.nPerOctave;
else
  nFeat_dog = 0;
end

if d.sift
  d.feats.sift.verbose = false;
  d.feats.sift.sizes = [2 4 6 8];
  d.feats.sift.fast = true;
  d.feats.sift.step = 1;
  d.feats.sift.color = 'gray';
  d.feats.sift.contrast_threshold = 0;%0.005;
  d.feats.sift.window_size = 1.5;
  d.feats.sift.magnif = 6;
  d.feats.sift.float_descriptors = true;
  d.feats.sift.remove_zero = false;
  d.feats.sift.rootsift = true;
  d.cropSize = 13; %overwrites cropSize to prioritize sift crop
  nFeat_sift = 128*numel(d.feats.sift.sizes);
else
  nFeat_sift = 0;
end

d.nFeats = nFeat_tp + nFeat_gb + nFeat_dog +...
  nFeat_int + nFeat_sift + nFeat_col;
d.nFeat_tp = nFeat_tp;
d.nFeat_gb = nFeat_gb;
d.nFeat_dog = nFeat_dog;
d.nFeat_int = nFeat_int;
d.nFeat_sift = nFeat_sift;
d.nFeat_col = nFeat_col;
