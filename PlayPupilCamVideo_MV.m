%________________________________________________________________________________________________________________________
% Written by Kevin L. Turner
% The Pennsylvania State University, Dept. of Biomedical Engineering
% https://github.com/KL-Turner
%________________________________________________________________________________________________________________________
%
%   Purpose: Converts a binary camera file into a streamable movie using information contained in the notes of the trial
%________________________________________________________________________________________________________________________

clear; clc;
% User inputs for file information
pupilCamFileID = uigetfile('*_PupilCam.bin','MultiSelect','off');
% RawData file IDs
rawDataFileStruct = dir('*_RawData.mat');
rawDataFiles = {rawDataFileStruct.name}';
rawDataFileIDs = char(rawDataFiles);
% Find corresponding RawData File
fileID = pupilCamFileID(1:end - 13);
for aa = 1:size(rawDataFileIDs,1)
    if contains(rawDataFileIDs(aa,:),fileID) == true
        rawDataFileID = rawDataFileIDs(aa,:);
        break
    end
end
% Load RawData file corresponding to binary movie file
disp(['Loading relevant file information from ' rawDataFileID '...']); disp(' ')
try
    load(rawDataFileID,'-mat')
catch
    disp([rawDataFileID ' does not appear to be in the current file path']); disp(' ')
    return
end
% Relevant information from RawData file's notes
trialDuration = RawData.notes.trialDuration_sec;
disp([pupilCamFileID ' is ' num2str(trialDuration) ' seconds long.']); disp(' ')
imageHeight = RawData.notes.pupilCamPixelHeight;                                                                                                            
imageWidth = RawData.notes.pupilCamPixelWidth;
Fs = RawData.notes.pupilCamSamplingRate;
% Input time indeces for video file
checkTime = 0;
while checkTime == 0
    startTime = input('Input the desired start time (sec): '); disp(' ')
    endTime = input('Input the desired end time (sec): '); disp(' ')
    if startTime >= trialDuration || startTime < 0
        disp(['A start time of ' num2str(startTime) ' is not a valid input']); disp(' ')
    elseif endTime > trialDuration || endTime <= startTime || endTime <= 0
        disp(['An end time of ' num2str(endTime) ' is not a valid input']); disp(' ')
    else
        checkTime = 1;
    end
end
% Index binary file to desired frames
frameStart = floor(startTime)*Fs;
frameEnd = floor(endTime)*Fs;         
frameInds = frameStart:frameEnd;
pixelsPerFrame = imageWidth*imageHeight;
skippedPixels = pixelsPerFrame;   % Multiply by two because there are 16 bits (2 bytes) per pixel
fid = fopen(pupilCamFileID);
fseek(fid,0,'eof');
fileSize = ftell(fid);
fseek(fid,0,'bof');
nFramesToRead = length(frameInds);
imageStack = zeros(imageHeight,imageWidth,nFramesToRead);
for a = 1:nFramesToRead
    disp(['Creating image stack: (' num2str(a) '/' num2str(nFramesToRead) ')']); disp(' ')
    fseek(fid,frameInds(a)*skippedPixels,'bof');
    z = fread(fid,pixelsPerFrame,'*uint8','b');
    img = reshape(z(1:pixelsPerFrame),imageWidth,imageHeight);
    imageStack(:,:,a) = flip(imrotate(img,-90),2);
end
fclose('all');
% Play movie
handle = implay(imageStack,Fs);
handle.Visual.ColorMap.UserRange = 1; 
handle.Visual.ColorMap.UserRangeMin = min(img(:)); 
handle.Visual.ColorMap.UserRangeMax = max(img(:));
