function[PupilTracker]=PupilTracker_004(imageStack)
%Inputs:
%imageStack file of .bin pupil camera video
%Outputs:
%PupilTracker.Pupil_Area: framewise area measurement in pixels
%PupilTracker.Overlay: movie of raw image data with pupil tracking data
%overlayed as blue mask.

%% Constants
theangles=(1:1:180);
RadonThresh=0.5;
PupilThresh=0.35;
BlinkThresh=75;
%% Empty Structures
Pupil_Area(1:size(imageStack,3))=NaN; %Area of pupil
Pupil_Major(1:size(imageStack,3))=NaN;% Length of major axis of pupil
Pupil_Minor(1:size(imageStack,3))=NaN;% Length of minor axis of pupil
Pupil_Centroid(1:size(imageStack,3),2)=NaN; %Center of pupil
PupilBoundary(1:size(imageStack,1),1:size(imageStack,2),1:size(imageStack,3))=NaN;
PupilPix=cell(1,size(imageStack,3));
%Overlay(1:size(imageStack,1),1:size(imageStack,2),(1:3),1:size(imageStack,3))=NaN; %RGB image stack with movie overlayed with Pupil location and size

%% Select ROI
WorkingImg=imcomplement(uint8(imageStack(:,:,1))); %grab frame from image stack
fprintf('Draw roi around eye\n')
[BW]=roipoly(WorkingImg);
fprintf('Running\n')
tic
%% Framewise pupil area measurement
parfor framenum=1:size(imageStack,3)
    WorkingImg=imcomplement(uint8(imageStack(:,:,framenum))); %grab frame from image stack
    FiltImg=medfilt2(WorkingImg,[11 11]); %median filter image
    ThreshImg=uint8(double(FiltImg).*BW); %Only look at pixel values in ROI
    HoldImg=double(ThreshImg);
    HoldImg(HoldImg==0)=NaN;
    AvgPix=mean(HoldImg(:),'omitnan');
    MnsubImg=HoldImg-AvgPix; % Mean subtrack ROI pixels
    MnsubImg(isnan(MnsubImg))=0;
    MnsubImg(MnsubImg<0)=0; %set all negative pixel values to 0;
    RadPupil=radon(MnsubImg); %transform movie frame in to radon space
    minPupil=min(RadPupil,[],1);
    minMat=repmat(minPupil,size(RadPupil,1),1);
    MaxMat=repmat(max((RadPupil-minMat),[],1),size(RadPupil,1),1);
    NormPupil=(RadPupil-minMat)./MaxMat; %Normalize each projection angle to its min and max values. Each value should now be between [0 1]
    ThreshPupil=NormPupil;
    ThreshPupil(NormPupil>=RadonThresh)=1;
    ThreshPupil(NormPupil<RadonThresh)=0; %Binarize radon projection
    RadonPupil=iradon(double(ThreshPupil>RadonThresh*max(ThreshPupil(:))),theangles,'linear','Hamming',size(WorkingImg,2)); %transform back to image space
    [Pupil_Pix,Pupil_Boundary]=bwboundaries(RadonPupil>PupilThresh*max(RadonPupil(:)),'noholes'); %find area corresponding to pupil on binary image
    numPixels=cellfun(@length,Pupil_Pix);
    [~,idx]=max(numPixels);
    FillPupil=Pupil_Boundary;
    FillPupil(FillPupil~=idx)=0;
    FillPupil(FillPupil==idx)=1;
    FillPupil=imfill(FillPupil,'holes'); %fill any subthreshold pixels inside the pupil boundary
    if framenum==1
        CheckPupil=labeloverlay(uint8(imageStack(:,:,framenum)),FillPupil);
        figure;imshow(CheckPupil);
        title('Detected pupil vs video frame');
    end
    area_filled=regionprops(FillPupil,'FilledArea','Image','FilledImage','Centroid','MajorAxisLength','MinorAxisLength');
    Pupil_Area(framenum)=area_filled.FilledArea;
    Pupil_Major(framenum)=area_filled.MajorAxisLength;
    Pupil_Minor(framenum)=area_filled.MinorAxisLength;
    Pupil_Centroid(framenum,:)=area_filled.Centroid;
    PupilBoundary(:,:,framenum)=FillPupil;
    PupilPix{framenum}=Pupil_Pix{idx};
    Hold=labeloverlay(uint8(imageStack(:,:,framenum)),FillPupil);
    Overlay(:,:,:,framenum)=Hold;  
end
PupilTracker.Pupil_Area=Pupil_Area;
PupilTracker.Pupil_Major=Pupil_Major;
PupilTracker.Pupil_Minor=Pupil_Minor;
PupilTracker.Pupil_Centroid=Pupil_Centroid;
PupilTracker.Pupil_Boundary=PupilBoundary;
PupilTracker.Pupil_Pix=PupilPix;
PupilTracker.Overlay=Overlay;
PupilTracker.Eye_ROI=BW;
toc

Blinks=find(abs(diff(PupilTracker.Pupil_Area))>=BlinkThresh)+1;
PlotPupilArea=PupilTracker.Pupil_Area;
PlotPupilArea(Blinks)=NaN;
BlinkTimes(1:size(PupilTracker.Pupil_Area,2))=NaN;
BlinkTimes(Blinks)=1;
BlinkTimes=BlinkTimes*(1.1*max(PupilTracker.Pupil_Area(:)));
PupilTime=(1:length(PupilTracker.Pupil_Area))/30;
figure;plot(PupilTime,PlotPupilArea);
hold on; scatter(PupilTime,BlinkTimes);
xlabel('Time (sec)');
ylabel('Pupil area (pixels)');
title('Pupil area changes');
legend('Pupil area','Eyes closed');
end