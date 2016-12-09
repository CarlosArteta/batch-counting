function density = getDensity(im,dots,sigma,cropSize)

annot = zeros(size(im,1),size(im,2),'single');
out = dots<1;
dots(out) = 1;
out = dots(:,1)>size(im,2);
dots(out,1) = size(im,2);
out = dots(:,2)>size(im,1);
dots(out,2) = size(im,1);

annot(sub2ind(size(annot), dots(:,2), dots(:,1))) = 1;
density = vl_imsmooth(annot,sigma);

density(1:cropSize,:,:)=[];
density(end-cropSize+1:end,:,:)=[];
density(:,1:cropSize,:)=[];
density(:,end-cropSize+1:end,:)=[];