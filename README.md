Data location - 'Pupil Camera Examples' folder on box

Desired output is a 1xN array of pixel diameter values that can later be converted to mm using a scale factor. Fs is 30 Hz

The pupil may need to be motion corrected if the mouse is quickly looking around. any frames that cannot accurately establish a diameter (such as blinking or long periods with eyes closed) should simply be tagged as NaNs. These can later be interpolated if under a reasonable time duration (TBD) or thrown out entirely for longer periods. For now, just keep every data point but as a NaN if the diameter is garbage or the eyes are closed.

The code should be a function that can be seemlessly integrated into other analysis. For example

pupilFilesDirectory = dir('*PupilCam.mat');
pupilCamFileNames = {pupilFilesDirectory.name}';
pupilCamFileList = char(pupilCamFileNames);

This gives an identical output to using: 
pupilCamFileList = ls('*PupilCam.mat');

However, I use the former because the latter does not work in macOS since the file system is different. The former works to obtain the same character list on both Windows/Unix-based OS so I use that.

Function should look something like:

ProcessPupilDiameter(pupilCamFileList, procDataFileList)   // called from my main script


    function [] = ProcessPupilDiameter(pupilCamFileList, procDataFileList)

        for a = 1:size(pupilCamFileList)
            fileID = pupilCamFileList(a,:);
            procDataFileID = procDataFileList(a,:);
            load(procDataFileID)   // this loads the variable/struct ProcData which is already created in previous analysis. The pupilDiameter should be added to it and then saved to cd.

            // Do the stuff in however many subfunctions you'd like to ultimately obtain pupilDiameter

            ProcData.data.pupilDiameter = pupilDiameter;
            save(procDataFileID, 'ProcData')   // saves the updated structure to the current folder where all the data is
        end
    end