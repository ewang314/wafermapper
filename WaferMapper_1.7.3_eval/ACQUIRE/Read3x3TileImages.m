function AccumulatorImage3x3 = Read3x3TileImages(R, C)
global GuiGlobalsStruct;




max_tile_r = GuiGlobalsStruct.FullMapData.NumTileRows;
max_tile_c = GuiGlobalsStruct.FullMapData.NumTileColumns;


AccumulatorImage3x3 = uint8(zeros(GuiGlobalsStruct.FullMapData.ImageHeightInPixels*3, GuiGlobalsStruct.FullMapData.ImageWidthInPixels*3));



for tile_r = (R-1):(R+1)
    for tile_c = (C-1):(C+1)
        
        if (tile_r < 1) || (tile_r > max_tile_r) || (tile_c < 1) || (tile_c > max_tile_c) 
            %User picked close to edge, give a blank image
            MyTileImage = ReadTileImage(1, 1); 
            MyTileImage = 0*MyTileImage; %black       
        else
            MyTileImage = ReadTileImage(tile_r, tile_c);   
        end
        
        [max_r, max_c] = size(MyTileImage);
        
        %AccumTileRIndex goes from 1 to 3
        AccumTileRIndex = (tile_r - (R-1)) +1;
        AccumTileCIndex = (tile_c - (C-1)) +1;
        
        AccumulatorImage3x3( (((AccumTileRIndex-1)*max_r)+1):(AccumTileRIndex*max_r), (((AccumTileCIndex-1)*max_c)+1):(AccumTileCIndex*max_c) ) = ...
            MyTileImage;
        
%         for r = 1:max_r
%             r_accumIndex = (tile_r-R+1)*max_r + r;
%             for c = 1:max_c
%                 c_accumIndex = (tile_c-C+1)*max_c + c;
%                 
%                 AccumulatorImage3x3(r_accumIndex, c_accumIndex) = MyTileImage(r,c);
%                 
%             end
%         end
        
        
        
    end
end

