local XUiGridSummerEpisodePicture = XClass(nil,"XUiGridSummerEpisodePicture")

function XUiGridSummerEpisodePicture:Ctor(ui)
    self.GameObject = ui
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridSummerEpisodePicture:Refresh(imgPath)
    if not imgPath then return end
    self.RImgPicture:SetRawImage(imgPath)
end

return XUiGridSummerEpisodePicture