function testCount(d,testData,b,dict)

nFrames = size(testData,1);
results = zeros(nFrames,4); %[GTcount EstimatedCount visCount];

for f = 1:nFrames
  
  disp(['Testing on frame ' num2str(f) '/' num2str(nFrames)]);
  
  orgIm = imread(fullfile(d.datapath,'test',[testData{f,1} '.' d.imExt]));
  orgImSz = size(orgIm);
  
  im = imresize(orgIm,d.sFactor);
  
  imf = encodeImage(im,d);
  sz = size(imf);
  imf = shiftdim(imf,2);
  imf = reshape(imf,size(imf,1),[]);
  
  Idx = uint16(vl_kdtreequery(dict.tree,dict.means,imf));
  
  densityEst = reshape(b(Idx)+b(end),sz(1),sz(2));
  densityEst = vl_imsmooth(densityEst,d.sigma/2);
  globalCount = sum(densityEst(:));
  
  if ~isempty(testData{f,2}) %get ground truth count if available
    dots = testData{f,2};
    dots = round(dots*d.sFactor);
    density = getDensity(im,dots,d.sigma,d.cropSize);
    disp(['Frame: ' num2str(f) '--> #Dots: ' num2str(size(dots,1))]);
    GT = sum(density(:));
  else %There is no GT or no objects in the image
    GT = NaN;
  end
  
  if d.saveDensity
    orgDensityEst = padarray(densityEst,[d.cropSize d.cropSize]);
    orgDensityEst = imresize(orgDensityEst,[orgImSz(:,1) orgImSz(:,2)]);
    normCte = sum(orgDensityEst(:))/sum(densityEst(:));
    orgDensityEst = orgDensityEst/normCte;
    
    ext = strfind(testData{f,1},'.');
    if isempty(ext)
      nameend = numel(testData{f,1});
    else
      nameend = ext-1;
    end
    save(fullfile(d.exppath,[testData{f,1}(1:nameend) '_density.mat']),'orgDensityEst');
  end
  
  if d.visCount %density visualization based on extremal regions
    orgDensityEst = padarray(densityEst,[d.cropSize d.cropSize]);
    orgDensityEst = imresize(orgDensityEst,[orgImSz(:,1) orgImSz(:,2)]);
    normCte = sum(orgDensityEst(:))/sum(densityEst(:));
    orgDensityEst = orgDensityEst/normCte;
    
    [classMask, outDots, seg] = segmentDensity(orgDensityEst,orgIm,d);
    visDenstity = orgDensityEst;
    visDenstity(classMask==0) = 0;
    maskCount = sum(visDenstity(:));
    visCount = size(outDots,1);
    
    ext = strfind(testData{f,1},'.');
    if isempty(ext)
      nameend = numel(testData{f,1});
    else
      nameend = ext-1;
    end
    save(fullfile(d.exppath,[testData{f,1}(1:nameend) '_mask.mat']),...
      'classMask','outDots');
    if d.segment %save visualization image
      imwrite(seg,fullfile(d.exppath,[testData{f,1}(1:nameend) '.jpg']));
    end
  else
    visCount = NaN;
    maskCount = NaN;
  end
  
  % store results for this frame
  results(f,:) = [GT globalCount maskCount visCount];
  disp(['Density GT: ' num2str(GT)]);
  disp('Estimated counts: ');
  disp(['Global: ' num2str(globalCount)]);
  disp(['Over mask : ' num2str(maskCount)]);
  disp(['Visualization : ' num2str(visCount)]);
  disp('');
  
end %end stack testing

save(fullfile(d.exppath,'Results.mat'),'results');

figure;
plot([0 max(results(:))],[0 max(results(:))],'-r','linewidth',2);
hold on,
plot(results(:,1),results(:,2),'ob','linewidth',3);
plot(results(:,1),results(:,3),'dg','linewidth',3);
plot(results(:,1),results(:,4),'sk','linewidth',3);
xlabel('GT count','fontsize',14);
ylabel('Estimated count','fontsize',14);
legend('Reference','GlobalCount','MaskCount','VisCount','Location','NorthWest');
title(['Predicted counts - Dictionary size: ' num2str(d.dictSize)]...
  ,'fontsize',14);
resIm = export_fig('-q100','-transparent');
imwrite(resIm,fullfile(d.exppath,'resultsPlot.png'));
end