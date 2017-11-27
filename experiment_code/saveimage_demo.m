load('VideoMatns.mat')
VideoMat=VideoMatns;
clear VideoMatns;

expressions=fieldnames(VideoMat);
itemall=fieldnames(VideoMat.Anger);
ii=0;
for iexp=1:size(expressions,1)
    for iitem=1:size(itemall,1)
        ii=ii+1;
        exptable(ii,1)=expressions(iexp);
        exptable(ii,2)=itemall(iitem);
    end
end
imagetmp = eval(['VideoMat.',expressions{1},'.',itemall{1}]);
[xsize, ysize, ~] = size(imagetmp(36:221, 36:221));
imageall = zeros(xsize*size(expressions,1), ysize*size(itemall,1));

temp = cell2table(exptable, 'VariableNames', {'exp', 'id'});
temp = sortrows(temp,'id','ascend');
temp = sortrows(temp,'exp','ascend');
%
for i = 1:size(temp, 1)
    imagetmp = eval(['VideoMat.',temp.exp{i},'.',temp.id{i},'(:,:,end)']);
    [a, b]=find(reshape([1:48], 8, 6)==i);
    imageall([1:xsize]+(b-1)*xsize, [1:ysize]+(a-1)*ysize) = imagetmp(36:221, 36:221);
end
imshow(uint8(imageall))
imwrite(uint8(imageall),'img1.tiff');