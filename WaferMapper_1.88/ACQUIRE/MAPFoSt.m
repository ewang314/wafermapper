function [z,finalWD,I1,I2]=MAPFoSt(ImageHeightInPixels,ImageWidthInPixels,DwellTimeInMicroseconds,FileName,FOV,maxiter,fallback,verbosity)
%   Elias Wang's implementation of MAPFoSt
%   Adapted from Jonas Binding (Low-Dosage Maximum-A-Posteriori Focusing and Stigmation)
%   Should replace "sm.Execute('CMD_AUTO_FOCUS_FINE')" calls
%   *INPUTS:
%   ImageHeightInPixels, ImageWidthInPixels: desired dimension of test images
%   DwellTimeInMicroseconds: test image dwell time
%   FileName: temp filename for saved images
%   FOV: image Field of View
%   maxiter: max number of iterations if algorithm fails
%   fallback: default to Zeiss autofocus after maxiter
%   *OUTPUTS
%   z: (relative) aberration estimate, in um
%   finalWD: vector of final WD and stigmation values set by algorithm
%   I1,I2: two test images taken

if ~exist('maxiter','var')
    maxiter=1;
end
if ~exist('fallback','var')
    fallback=1;
end
if ~exist('verbosity','var')
    verbosity=0;
end

global GuiGlobalsStruct; % WaferMapper global variable
sm = GuiGlobalsStruct.MyCZEMAPIClass; %To shorten calls to global API variables in this function

% hardcoded test aberrations, in um
T1=15;
T2=-15;

% set delay after changing WD
%frametime=sm.Get_ReturnTypeSingle('AP_FRAME_TIME')/1000; %time in seconds to scan a whole frame
frametime=1; 

%begin MAPFoSt
CurrentWorkingDistance = sm.Get_ReturnTypeSingle('AP_WD');
CurrentStigX = sm.Get_ReturnTypeSingle('AP_STIG_X');
CurrentStigY = sm.Get_ReturnTypeSingle('AP_STIG_Y');
if verbosity
    disp('Beginning MAPFoSt...');
    disp(['starting values: ' num2str(10^6*CurrentWorkingDistance) 'um, ' num2str(CurrentStigX) '%, ' num2str(CurrentStigY) '%']);
end


%% Take first image
sm.Set_PassedTypeSingle('AP_WD',CurrentWorkingDistance+10^-6*T1);
pause(frametime);
T1WD=sm.Get_ReturnTypeSingle('AP_WD');
if verbosity
    disp(['first image WD: ' num2str(10^6*T1WD) 'um']);
end
sm.Fibics_WriteFOV(FOV);
%Wait for image to be acquired
sm.Fibics_AcquireImage(ImageWidthInPixels,ImageHeightInPixels,DwellTimeInMicroseconds,FileName);
while(sm.Fibics_IsBusy)
    pause(.01); %1
end

%Wait for file to be written
IsReadOK = false;
while ~IsReadOK
    IsReadOK = true;
    try
        I1 = imread(FileName);
    catch MyException
        IsReadOK = false;
        pause(0.1);
    end
end

delete(FileName); % for some reason, deleting image seemed to be necessary


%% Take second image
sm.Set_PassedTypeSingle('AP_WD',CurrentWorkingDistance+10^-6*T2);
pause(frametime);
T2WD=sm.Get_ReturnTypeSingle('AP_WD');
if verbosity
    disp(['second image WD: ' num2str(10^6*T2WD) 'um']);
end
sm.Fibics_WriteFOV(FOV);
%Wait for image to be acquired
sm.Fibics_AcquireImage(ImageWidthInPixels,ImageHeightInPixels,DwellTimeInMicroseconds,FileName);
while(sm.Fibics_IsBusy)
    pause(.01); %1
end

%Wait for file to be written
IsReadOK = false;
while ~IsReadOK
    IsReadOK = true;
    try
        I2 = imread(FileName);
    catch MyException
        IsReadOK = false;
        pause(0.1);
    end
end

delete(FileName);


% *** START: This sequence is designed to release the SEM from Fibics control
    sm.Execute('CMD_AUTO_FOCUS_FINE');
    pause(0.5);
    sm.Execute('CMD_ABORT_AUTO');
    while ~strcmp('Idle',sm.Get_ReturnTypeString('DP_AUTO_FUNCTION'))
        pause(0.02);
    end
    sm.Set_PassedTypeSingle('AP_WD',CurrentWorkingDistance);
    pause(0.1);
% *** END 

%get actual (test) aberrations, in um
    T1=10^6*(T1WD-CurrentWorkingDistance);
    T2=10^6*(T2WD-CurrentWorkingDistance);
    
%% MAPFoSt
% setup variables
Acc=5;
%NA= sqrt(40)*0.752 / (PixSize* (Acc*1000)^0.5); 
NA= 0.5596*ImageHeightInPixels / ((Acc*1000)^0.5); % empirically determined constant;
sigma =mean([std(double(I1(:))), std(double(I2(:)))]); % determine sigma for real space from images
[Kx, Ky]=meshgrid((mod(0.5+[0:ImageWidthInPixels-1]/ImageWidthInPixels,1)-0.5)*(6.28/FOV),(mod(0.5+[0:ImageHeightInPixels-1]/ImageHeightInPixels,1)-0.5)*(6.28/FOV)); % calculate wave vectors
fI1=fft2(double(I1)); %image should have dimension 2^n for faster FFT
fI2=fft2(double(I2)); 
init=0; % note: non-zero initialization seemed to work a bit better

% minimize parameters
p.length=20;
p.method='BFGS';
p.verbosity=verbosity;
p.MFEPLS = 30;   % Max Func Evals Per Line Search
p.MSR = 100;     % Max Slope Ratio default
% run minimization on 'MAP' function
O=minimize(init,@MAP,p,fI1,fI2,T1,T2,NA,sigma,Kx,Ky);

%%
if max(abs(O))<20 % make sure aberration estimate is reasonable (ie less than 20 um)
    % set new WD/Stig from algorithm
    sm.Set_PassedTypeSingle('AP_WD',CurrentWorkingDistance-10^-6*real(O)); 
    finalWD=[sm.Get_ReturnTypeSingle('AP_WD') sm.Get_ReturnTypeSingle('AP_STIG_X') sm.Get_ReturnTypeSingle('AP_STIG_Y')];
    if verbosity
        disp(['final WD: ' num2str(10^6*finalWD(1)) 'um' num2str(finalWD(2)) ' ' num2str(finalWD(3))]);
    end
    z=real(O);
elseif maxiter>1
    [z,finalWD,I1,I2]=MAPFoSt(ImageHeightInPixels,ImageWidthInPixels,DwellTimeInMicroseconds,FileName,FOV,maxiter-1,single); 
else
    if fallback
        sm.Execute('CMD_AUTO_FOCUS_FINE');
        pause(0.5);
        while ~strcmp('Idle',sm.Get_ReturnTypeString('DP_AUTO_FUNCTION'))
            pause(0.02);
        end
    end
    finalWD=[sm.Get_ReturnTypeSingle('AP_WD') sm.Get_ReturnTypeSingle('AP_STIG_X') sm.Get_ReturnTypeSingle('AP_STIG_Y')];
    if verbosity
        disp(['final zeiss/starting WD: ' num2str(10^6*finalWD(1)) 'um' num2str(finalWD(2)) ' ' num2str(finalWD(3))]);
    end
    z=NaN;
end

end