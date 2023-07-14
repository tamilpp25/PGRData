--===========================
--超级爬塔增益控件
--===========================
local XUiSuperTowerEnhanceGrid = XClass(nil, "XUiSuperTowerEnhanceGrid")

function XUiSuperTowerEnhanceGrid:Ctor(uiGameObject, onClickCallBack)
    self:Init(uiGameObject, onClickCallBack)
end

function XUiSuperTowerEnhanceGrid:Init(uiGameObject, onClickCallBack)
    XTool.InitUiObjectByUi(self, uiGameObject)
    if onClickCallBack then
        self.OnClickCb = onClickCallBack
    end
    XUiHelper.RegisterClickEvent(self, self.BtnClick or self.RImgIcon, function()
            self:OnClick()
        end)
end

function XUiSuperTowerEnhanceGrid:RefreshData(enhanceId)
    self.EnhanceId = enhanceId
    self.EnhanceCfg = XSuperTowerConfigs.GetEnhanceCfgById(enhanceId)
    if self.RImgIcon then self.RImgIcon:SetRawImage(self.EnhanceCfg.Icon) end
    if self.ImgQuality then self.ImgQuality:SetSprite(XSuperTowerConfigs.GetStarIconByQuality(self.EnhanceCfg.Quality)) end
    if self.TxtName then self.TxtName.text = self.EnhanceCfg.Name end
    if self.ImgQualityBg then self.ImgQualityBg:SetSprite(XSuperTowerConfigs.GetStarBgByQuality(self.EnhanceCfg.Quality)) end
end

function XUiSuperTowerEnhanceGrid:OnClick()
    if self.OnClickCb then
        self.OnClickCb(self)
    end
end

function XUiSuperTowerEnhanceGrid:ShowPanel()
    self.GameObject:SetActiveEx(true)
end

function XUiSuperTowerEnhanceGrid:HidePanel()
    self.GameObject:SetActiveEx(false)
end

return XUiSuperTowerEnhanceGrid