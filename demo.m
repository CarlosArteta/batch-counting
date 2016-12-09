clc;
disp(' ')%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('============================================');
disp('--Counting through density estimation Demo--');
disp('============================================');
disp(' ')%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p = mfilename('fullpath');
cd(fileparts(p));

rootpath.code = fileparts(p);
rootpath.data = fileparts(p);

if exist('vl_setup','file') == 0
    error('Vl_feat required');
end

addpath('PylonCode/');
addpath('export_fig/');
addpath(genpath('MatlabFns/'))


%% ---------------------------------------------------Configure data to use
d = getDataInfo(rootpath);
imdb = setupData(d);

%% -------------------------------------------------------------------Train 
[b,dict] = trainCount(d,imdb.train);

%% --------------------------------------------------------------------Test 
testCount(d,imdb.test,b,dict);