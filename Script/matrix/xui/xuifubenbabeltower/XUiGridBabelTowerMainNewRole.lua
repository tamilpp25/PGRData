local XUiGridBabelTowerMainNewRole = XClass(nil, "XUiGridBabelTowerMainNewRole")

function XUiGridBabelTowerMainNewRole:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridBabelTowerMainNewRole:Refresh(data)
    if data then
        self.RImgIcon:SetRawImage(data.MedalImg)

        local qualityImg = XArrangeConfigs.GeQualityPath(data.Quality)
        if qualityImg then
            self.ImgQuality:SetSprite(qualityImg)
            self.ImgQuality.gameObject:SetActiveEx(true)
        else
            self.ImgQuality.gameObject:SetActiveEx(false)
        end
        
        self.TxtCount.text = data.Name
    end
end

return XUiGridBabelTowerMainNewRole