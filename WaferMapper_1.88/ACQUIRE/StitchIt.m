% Matlab stitching routine
% KH 4-5-2011

% clear all;
% close all;

%tile file name
%Z:\Hayworth\MasterUTSLDirectory\CortexUTSL008\Wafer007\TestMontage_Sec10to15\Wafer007_Sec10_Montage\Tile_r1-c1_Wafer007_sec10.tif

DirectoryContainingSections = 'Z:\Hayworth\MasterUTSLDirectory\CortexUTSL008\Wafer007\TestMontage_Sec10to15';%'C:\VMAT2_DAB\VMAT2_DAB_w01'; %'C:\ToBeStitchedFromRichard';
SectionPrefixStr = 'Wafer007_Sec';
SectionPostfixStr = '_Montage';
TargetDirectoryForStitchedStack = 'Z:\Hayworth\MasterUTSLDirectory\CortexUTSL008\Wafer007\TestMontage_Sec10to15'; %'C:\ToBeStitchedFromRichard\FolderForStitchedImages';
ApproximateOverlapFraction = 0.06; %0.06; %This is percent overlap divided by 100
%MaxPixelOffsetAllowed = 500;
IsReduceImages = false; %false;
ReductionFactor = 4;
StartSectionNumber = 10;
EndSectionNumber = 15;
NumTileRows = 2;
NumTileCols = 2;


IsDisplay = false; %true;
IsDisplayOnlyCoorelation = true;
IsDrawBorders = false; %NOTE: THIS WILL DRAW WHITE BORDERS BETWEEN TILES ON FINAL IMAGE %false;

%process all sections
for SectionNumber = StartSectionNumber:EndSectionNumber
    StartTimeForSection = tic;
    

    SectionDirectoryName = sprintf('%s%d%s', SectionPrefixStr, SectionNumber, SectionPostfixStr);
    MyStr = sprintf('Processing directory: %s',SectionDirectoryName);
    disp(' ');
    disp(MyStr);
    
    % TileOverviewFileName = sprintf('Tile_overview_%s%s.tif', SectionPrefixStr, SectionNumberStr);
    % TileOverviewFileFullPath = sprintf('%s\\%s\\%s',DirectoryContainingSections, SectionDirectoryName, TileOverviewFileName);
    % TileOverviewImage = imread(TileOverviewFileFullPath, 'tif');
    % figure(1);
    % imshow(TileOverviewImage);
    
    
    
    
    %Open each image, low pass filter it, and then resave at 4x reduced size
    %(required for memory problem)
    H_gaussian = fspecial('gaussian',[5 5],1.5); %fspecial('gaussian',[9 9],5); %fspecial('gaussian',[5 5],1.5);
   
    

% if IsReduceImages
%         for TileRowIndex = 1:NumTileRows
%             for TileColIndex = 1:NumTileCols
%                 %Tile_r1-c1_VMat2_sec01.tif
%                 %Tile_6_R1_C1.tif
%                 TileFileName = sprintf('Tile_%d_R%d-C%d.tif',SectionNumber,TileRowIndex,TileColIndex);
%                 TileFileFullPath = sprintf('%s\\%s\\%s',DirectoryContainingSections ,SectionDirectoryName ,TileFileName);
%                 MyStr = sprintf('  Opening, filtering, reducing, and resaving under a different name file: %s',TileFileFullPath);
%                 disp(MyStr);
%     
%                 Image = imread(TileFileFullPath,'tif');
%                 Image = imfilter(Image,H_gaussian);
%                 ReducedImage = imresize(Image,1/ReductionFactor,'nearest');
%                 ReducedImageFileName = sprintf('Tile_r%d-c%d_%s%s_Reduced.tif',TileRowIndex,TileColIndex,SectionPrefixStr,SectionNumberStr);
%                 ReducedImageFullPath = sprintf('%s\\%s\\%s',DirectoryContainingSections ,SectionDirectoryName ,ReducedImageFileName);
%     
%                 imwrite(ReducedImage,ReducedImageFullPath,'tif');
%     
%             end
%         end
% end
    
    
    %Stitch
    SubPlotIndex = 1;
    for TileRowIndex = 1:NumTileRows
        for TileColIndex = 1:NumTileCols
            
            
            %Tile_r1-c1_VMat2_sec01.tif
%             if IsReduceImages
%                 TileFileName = sprintf('Tile_r%d-c%d_%s%s_Reduced.tif',TileRowIndex,TileColIndex,SectionPrefixStr,SectionNumberStr);
%             else
                %Tile_r1-c1_Wafer007_sec10.tif
                TileFileName = sprintf('Tile_r%d-c%d_%s%d.tif',TileRowIndex,TileColIndex,SectionPrefixStr,SectionNumber);
%             end
            TileFileFullPath = sprintf('%s\\%s\\%s',DirectoryContainingSections ,SectionDirectoryName ,TileFileName);
            MyStr = sprintf('  Stitching in tile: %s',TileFileFullPath);
            disp(MyStr);
            
            info = imfinfo(TileFileFullPath,'tif');
            width = info(1).Width;
            height = info(1).Height;
            OverlapStripWidthInPixels = floor(width*ApproximateOverlapFraction);
            MaxPixelOffsetAllowed = OverlapStripWidthInPixels;
            if mod(OverlapStripWidthInPixels,2) == 1
                OverlapStripWidthInPixels = 1+OverlapStripWidthInPixels;  %This makes sure strip width is even
            end
            
            
            Tile(TileRowIndex, TileColIndex).ImageStruct.TileFileFullPath = TileFileFullPath;
            Tile(TileRowIndex, TileColIndex).ImageStruct.Width = info(1).Width;
            Tile(TileRowIndex, TileColIndex).ImageStruct.Height = info(1).Height;
            DisplaySubsamplingIncrement = 16; %this subsamples the image to prevent memory errors
            Tile(TileRowIndex, TileColIndex).ImageStruct.SubSampledImage  = imread(TileFileFullPath, 'PixelRegion',...
                {[1 DisplaySubsamplingIncrement  height],...
                [1 DisplaySubsamplingIncrement  width]} );
            
            if IsDisplay
                figure(2);
                subplot(NumTileRows, NumTileCols, SubPlotIndex);
                imshow(Tile(TileRowIndex, TileColIndex).ImageStruct.SubSampledImage );
                drawnow;
                SubPlotIndex = SubPlotIndex + 1;
            end
            
            
            
            
            if TileColIndex == 1
                if TileRowIndex == 1
                    Tile(TileRowIndex, TileColIndex).ImageStruct.r_offset = 0;
                    Tile(TileRowIndex, TileColIndex).ImageStruct.c_offset = 0;
                else
                    %stitching for images in first col is based on previous row
                    BottomStripOfPrevious  = imread(Tile(TileRowIndex-1, TileColIndex).ImageStruct.TileFileFullPath, 'PixelRegion',...
                        {[height-(OverlapStripWidthInPixels-1)   height], [1   width]} );
                    
                    if IsDisplay
                        figure(3);
                        subplot(1,2,1);
                        imshow(BottomStripOfPrevious);
                        drawnow;
                    end
                    
                    TopStripOfCurrent  = imread(Tile(TileRowIndex, TileColIndex).ImageStruct.TileFileFullPath, 'PixelRegion',...
                        {[1 OverlapStripWidthInPixels], [1   width]} );
                    
                    CenterR = floor(OverlapStripWidthInPixels/2);
                    CenterC = floor(width/2);
                    
                    TopStripOfCurrent_OuterPartRemoved = ...
                        TopStripOfCurrent((CenterR-floor(OverlapStripWidthInPixels/3)):(CenterR+floor(OverlapStripWidthInPixels/3)),...
                        (CenterC-floor(width/3)):(CenterC+floor(width/3)) );
                    
                    if IsDisplay 
                        figure(3);
                        subplot(1,2,2);
                        imshow(TopStripOfCurrent);
                        drawnow;
                    end
                    
                    C = normxcorr2(TopStripOfCurrent_OuterPartRemoved, BottomStripOfPrevious);
                    
                    
                    
                    %zero out all non-allowable regions
                    
                    [HeightC, WidthC] = size(C);
                    for r = 1:HeightC
                        for c = 1:WidthC
                            if sqrt((r - HeightC/2)^2 + (c - WidthC/2)^2) > MaxPixelOffsetAllowed
                                C(r,c) = 0;
                            end
                        end
                    end
                    
                    if IsDisplay || IsDisplayOnlyCoorelation
                        figure(4);
                        imagesc(C);
                        colorbar;
                        drawnow;
                    end
                    
                    %Pick out the row col of the peak
                    [max_C, imax] = max(C(:));
                    [rpeak, cpeak] = ind2sub(size(C),imax(1));
                    
                    r_offset = rpeak - HeightC/2;
                    c_offset = cpeak - WidthC/2;
                    
                    MyStr = sprintf('   r_offset = %d, c_offset = %d',r_offset, c_offset);
                    disp(MyStr);
                    
                    Tile(TileRowIndex, TileColIndex).ImageStruct.r_offset = r_offset;
                    Tile(TileRowIndex, TileColIndex).ImageStruct.c_offset = c_offset;
                    
                end
                
            else
                %stitching for image (r,c) is based on image (r,c-1)
                RightSideStripOfPrevious  = imread(Tile(TileRowIndex, TileColIndex-1).ImageStruct.TileFileFullPath, 'PixelRegion',...
                    {[1   height],[width-(OverlapStripWidthInPixels-1)   width]} );
                
                if IsDisplay
                    figure(3);
                    subplot(1,2,1);
                    imshow(RightSideStripOfPrevious);
                    drawnow;
                end
                
                LeftSideStripOfCurrent  = imread(Tile(TileRowIndex, TileColIndex).ImageStruct.TileFileFullPath, 'PixelRegion',...
                    {[1   height],[1 OverlapStripWidthInPixels]} );
                
                CenterR = floor(height/2);
                CenterC = floor(OverlapStripWidthInPixels/2);
                
                LeftSideStripOfCurrent_OuterPartRemoved = ...
                    LeftSideStripOfCurrent((CenterR-floor(height/3)):(CenterR+floor(height/3)),...
                    (CenterC-floor(OverlapStripWidthInPixels/3)):(CenterC+floor(OverlapStripWidthInPixels/3)) );
                
                
                if IsDisplay
                    figure(3);
                    subplot(1,2,2);
                    imshow(LeftSideStripOfCurrent);
                    drawnow;
                end
                
                C = normxcorr2(LeftSideStripOfCurrent_OuterPartRemoved, RightSideStripOfPrevious);
                
                %zero out all non-allowable regions
                
                [HeightC, WidthC] = size(C);
                for r = 1:HeightC
                    for c = 1:WidthC
                        if sqrt((r - HeightC/2)^2 + (c - WidthC/2)^2) > MaxPixelOffsetAllowed
                            C(r,c) = 0;
                        end
                    end
                end
                
                if IsDisplay || IsDisplayOnlyCoorelation
                    figure(4);
                    imagesc(C);
                    colorbar;
                    drawnow;
                end
                
                
                %Pick out the row col of the peak
                [max_C, imax] = max(C(:));
                [rpeak, cpeak] = ind2sub(size(C),imax(1));
                [HeightC, WidthC] = size(C);
                r_offset = rpeak - HeightC/2;
                c_offset = cpeak - WidthC/2;
                
                MyStr = sprintf('   r_offset = %d, c_offset = %d',r_offset, c_offset);
                disp(MyStr);
                
                Tile(TileRowIndex, TileColIndex).ImageStruct.r_offset = r_offset;
                Tile(TileRowIndex, TileColIndex).ImageStruct.c_offset = c_offset;
                

            end
            
        end
    end

    
    TileWidth = Tile(1, 1).ImageStruct.Width;
    TileHeight = Tile(1, 1).ImageStruct.Height;
    
    %Determine all insertion points in larger stitched image (allows negatives)
    for TileRowIndex = 1:NumTileRows
        for TileColIndex = 1:NumTileCols
            
            if (TileRowIndex == 1) && (TileColIndex == 1)
                Tile(TileRowIndex, TileColIndex).ImageStruct.RowInsertionPosition = 1;
                Tile(TileRowIndex, TileColIndex).ImageStruct.ColInsertionPosition = 1;
            elseif (TileColIndex == 1)
                Tile(TileRowIndex, TileColIndex).ImageStruct.RowInsertionPosition =...
                    Tile(TileRowIndex-1, TileColIndex).ImageStruct.RowInsertionPosition +...
                    Tile(TileRowIndex, TileColIndex).ImageStruct.Height - OverlapStripWidthInPixels +...
                    + Tile(TileRowIndex, TileColIndex).ImageStruct.r_offset;
                Tile(TileRowIndex, TileColIndex).ImageStruct.ColInsertionPosition =...
                    Tile(TileRowIndex-1, TileColIndex).ImageStruct.ColInsertionPosition +...
                    + Tile(TileRowIndex, TileColIndex).ImageStruct.c_offset;
                
            else
                Tile(TileRowIndex, TileColIndex).ImageStruct.RowInsertionPosition =...
                    Tile(TileRowIndex, TileColIndex-1).ImageStruct.RowInsertionPosition +...
                    + Tile(TileRowIndex, TileColIndex).ImageStruct.r_offset;
                Tile(TileRowIndex, TileColIndex).ImageStruct.ColInsertionPosition =...
                    Tile(TileRowIndex, TileColIndex-1).ImageStruct.ColInsertionPosition +...
                    Tile(TileRowIndex, TileColIndex).ImageStruct.Width - OverlapStripWidthInPixels +...
                    + Tile(TileRowIndex, TileColIndex).ImageStruct.c_offset;
            end
            
        end
    end
    
    %Determine overall size of stitched image
    MinimumRowInsertionPosition = +1000000;
    MinimumColInsertionPosition = +1000000;
    MaximumRowInsertionPosition = -1000000;
    MaximumColInsertionPosition = -1000000;
    for TileRowIndex = 1:NumTileRows
        for TileColIndex = 1:NumTileCols
            
            if Tile(TileRowIndex, TileColIndex).ImageStruct.RowInsertionPosition < MinimumRowInsertionPosition
                MinimumRowInsertionPosition = Tile(TileRowIndex, TileColIndex).ImageStruct.RowInsertionPosition;
            end
            
            if Tile(TileRowIndex, TileColIndex).ImageStruct.RowInsertionPosition > MaximumRowInsertionPosition
                MaximumRowInsertionPosition = Tile(TileRowIndex, TileColIndex).ImageStruct.RowInsertionPosition;
            end
            
            if Tile(TileRowIndex, TileColIndex).ImageStruct.ColInsertionPosition < MinimumColInsertionPosition
                MinimumColInsertionPosition = Tile(TileRowIndex, TileColIndex).ImageStruct.ColInsertionPosition;
            end
            
            if Tile(TileRowIndex, TileColIndex).ImageStruct.ColInsertionPosition > MaximumColInsertionPosition
                MaximumColInsertionPosition = Tile(TileRowIndex, TileColIndex).ImageStruct.ColInsertionPosition;
            end
            
        end
    end
    
    %Create proper sized array to hold final stitched image
    FinalStitchedWidth = (MaximumColInsertionPosition + TileWidth) - MinimumColInsertionPosition;
    FinalStitchedHeight = (MaximumRowInsertionPosition + TileHeight) - MinimumRowInsertionPosition;
    FinalStitchedImage = uint8(zeros(FinalStitchedHeight, FinalStitchedWidth));
    
    for TileRowIndex = 1:NumTileRows
        for TileColIndex = 1:NumTileCols
            
            RowInsertionPosition = Tile(TileRowIndex, TileColIndex).ImageStruct.RowInsertionPosition - (MinimumRowInsertionPosition-1);
            ColInsertionPosition = Tile(TileRowIndex, TileColIndex).ImageStruct.ColInsertionPosition - (MinimumColInsertionPosition-1);
            
            TileImageToInsert = imread(Tile(TileRowIndex, TileColIndex).ImageStruct.TileFileFullPath,'tif');
            
            
            BorderSize = 4;
            if IsDrawBorders
                TileImageToInsert(1:BorderSize,1:end) = 255;
                TileImageToInsert(end-(BorderSize-1):end,1:end) = 255;
                TileImageToInsert(1:end,1:BorderSize) = 255;
                TileImageToInsert(1:end,end-(BorderSize-1)) = 255;
            end
            
            FinalStitchedImage(RowInsertionPosition:((RowInsertionPosition-1)+TileHeight), ColInsertionPosition:((ColInsertionPosition-1)+TileWidth)) = ...
                TileImageToInsert;
            
            
            
            
        end
    end
    
    %Save final stitched image
    FinalStitchedImageFileName = sprintf('Stitched_%s%d.tif',SectionPrefixStr,SectionNumber);
    FinalStitchedImageFullPath = sprintf('%s\\%s',TargetDirectoryForStitchedStack, FinalStitchedImageFileName);
    MyStr = sprintf('  Saving final stitched image: %s',FinalStitchedImageFullPath);
    disp(MyStr);
    imwrite(FinalStitchedImage,FinalStitchedImageFullPath,'tif');
    
    %delete reduced images
    if IsReduceImages
        for TileRowIndex = 1:NumTileRows
            for TileColIndex = 1:NumTileCols
                %Tile_r1-c1_VMat2_sec01.tif
                ReducedImageFileName = sprintf('Tile_r%d-c%d_%s%s_Reduced.tif',TileRowIndex,TileColIndex,SectionPrefixStr,SectionNumberStr);
                ReducedImageFullPath = sprintf('%s\\%s\\%s',DirectoryContainingSections ,SectionDirectoryName ,ReducedImageFileName);
                MyStr = sprintf('  Deleting file: %s',ReducedImageFullPath);
                disp(MyStr);
                
                delete(ReducedImageFullPath);
                
            end
        end
    end
    
    if IsDisplay
        figure(100);
        imshow(FinalStitchedImage,[0 255]);
    end
    
    ElapsedTimeForSection = toc(StartTimeForSection);
    MyStr = sprintf('   Total section processing time = %0.5g seconds', ElapsedTimeForSection);
    disp(MyStr);
end