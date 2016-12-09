function imdb = setupData(d)

if exist(fullfile(d.datapath,'imdb.mat'),'file') == 0
  imdb.train = {};
  imdb.val = {};
  imdb.test = {};
  
  annotFilesTrain = dir(fullfile(d.datapath,'train',['*' d.imExt]));
  [~,annotFilesTrain] = ...
    cellfun(@fileparts, {annotFilesTrain.name}, 'UniformOutput',false);
  annotFilesVal = dir(fullfile(d.datapath,'val',['*' d.imExt]));
  [~,annotFilesVal] = ...
    cellfun(@fileparts, {annotFilesVal.name}, 'UniformOutput',false);
  annotFilesTest = dir(fullfile(d.datapath,'test',['*' d.imExt]));
  [~,annotFilesTest] = ...
    cellfun(@fileparts, {annotFilesTest.name}, 'UniformOutput',false);
  
  for s = 1:numel(annotFilesTrain) %train
    dots = load(fullfile(d.datapath,'train',[annotFilesTrain{s} '.mat']));
    inFile = fieldnames(dots);
    dots = dots.(inFile{1});
    imdb.train = [imdb.train ; {annotFilesTrain{s} dots}];
  end
  
  for s = 1:numel(annotFilesVal) %val
    dots = load(fullfile(d.datapath,'val',[annotFilesVal{s} '.mat']));
    inFile = fieldnames(dots);
    dots = dots.(inFile{1});
    imdb.val = [imdb.val ; {annotFilesVal{s} dots}];
  end
  
  for s = 1:numel(annotFilesTest) %test
    if exist(fullfile(d.datapath,'test',[annotFilesTest{s} '.mat']),'file') == 0
      %testing set can be without annotations
      dots = [];
    else
      dots = load(fullfile(d.datapath,'test',[annotFilesTest{s} '.mat']));
      inFile = fieldnames(dots);
      dots = dots.(inFile{1});
    end
    imdb.test = [imdb.test ; {annotFilesTest{s} dots}];
  end
  
  save(fullfile(d.datapath,'imdb.mat'),'imdb');
else
  load(fullfile(d.datapath,'imdb.mat'));
end