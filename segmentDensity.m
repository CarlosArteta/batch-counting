function [classMask, outDots, seg] = segmentDensity(densityEst,orgIm,d)

%plotting colors
colors = 'gbmyckrw';

%margins for text
usafeBandX = round(size(orgIm,2) - size(orgIm,2)*0.05);
usafeBandY = round(size(orgIm,1) - size(orgIm,1)*0.02);
lsafeBandY = round(size(orgIm,1)*0.02);

%estimated object centres dots
outDots = [];

img = uint8(255*mat2gray(densityEst));
%Setup for the MSER algorithm
numPixels = size(img,1)*size(img,2);
minPixels = 4;%(S.targScale/16)^2;
maxPixels = 1000;%numPixels;
BoD = 1; %Bright on Dark
DoB = 0; %Dark on Bright
regionTH = 7;
%Compute MSERs
[r,ell] = vl_mser(img,'MaxArea',maxPixels/numPixels,'MinArea',...
  minPixels/numPixels,'MaxVariation',0.2,'MinDiversity',0.2,...
  'Delta',1, 'BrightOnDark',BoD, 'DarkOnBright',DoB);

%Encode MSERs
nFeatures = 2;
lambda = -1;
beta = 0;
X = zeros(length(r), nFeatures);%feature Vector
sizeMSER = zeros(length(r), 1);
additionalU = 1;

for k = 1:length(r)
  sel = vl_erfill(img,r(k)) ;
  sizeMSER(k) = numel(sel);
  if isempty(sel) %|| numel(sel) < minPixels/2;
    X(k,:) = zeros(1,nFeatures);
  else
    X(k,1) = sum(densityEst(sel));
    %X(k,2) = var(densitySmooth(sel));
  end
end
I = round(X(:,1)); %estimated class of the region
scores = (1 - (X(:,1) - I)).^2 + lambda;%- beta*X(:,2); %scoring function
scores(round(X)==0) = -10; %discard regions that approximate to 0
scores(I>regionTH) = -10;

MSERtree = buildPylonMSER(img,r,sizeMSER);

[mask,labels,~,idMask] = PylonInference(img, scores, 0, sizeMSER, r, additionalU, MSERtree);

mask = logical(mask);
X(~labels,1) = 0;
regions = regionprops(mask, 'Centroid','PixelList','PixelIdxList');
nRegions = numel(regions);
class = zeros(length(r),1);
classMask = zeros(size(img,1), size(img,2),'uint8');
classText = cell(1,max(I));

for i = 1:nRegions
  class(i) = I(idMask(regions(i).PixelList(1,2),regions(i).PixelList(1,1)));
  if class(i) == 0
    continue;
  end
  classMask(regions(i).PixelIdxList) = class(i);
  classText{class(i)} = [classText{class(i)} ; round(regions(i).Centroid)];
end

classMask = PadIm(classMask,d.cropSize);
classMask = imresize(classMask,[size(orgIm,1) size(orgIm,2)],...
  'nearest');

%estimate object centres
for i = 1:nRegions
  if class(i) == 1
    outDots = [outDots ; round(regions(i).Centroid)];
  elseif class(i) > 1
    pixels = single(regions(i).PixelList);
    pixels = [pixels single(img(sub2ind(size(img),pixels(:,2),pixels(:,1))))/-255+1 ];
    if size(pixels,1) >= class(i)
      dots = round(vl_kmeans(pixels', class(i)));
      dots = dots(1:2,:)';
    else
      dots = pixels(:,1:2)';
    end
    outDots = [outDots ; dots];
  end
end

%produce output figure
if d.segment
  nClasses = max(classMask(:));
  imshow(orgIm);
  
  hold on;
  for class = 1:nClasses
    B = bwboundaries(classMask == class);
    if class > 8
      color = 'w';
    else
      color = colors(class);
    end
    for i=1:numel(B)
      hline = line(B{i}(:,2),B{i}(:,1),'Color',color,'LineWidth',3, 'LineStyle','-','marker','.');
    end
  end
  
  for class = 2:nClasses
    if ~isempty(classText{class})
      xy = classText{class};
      offside = (xy(:,1) > usafeBandX) |  (xy(:,2) > usafeBandY) ...
        |  (xy(:,2) < lsafeBandY);
      xy(offside,:) = [];
      h = text(xy(:,1), xy(:,2),num2str(class),'color',[0.5 0 0],'FontSize',28,'FontWeight', 'demi');
      set(h,'Clipping','on');
    end
  end
  
  hold off;
  
  seg = export_fig('-q100','-transparent');
else
  seg = [];
end
