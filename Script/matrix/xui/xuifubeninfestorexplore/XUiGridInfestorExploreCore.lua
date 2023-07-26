local MAX_LEVEL_NUM = 6

local XUiGridInfestorExploreCore = XClass(nil, "XUiGridInfestorExploreCore")

function XUiGridInfestorExploreCore:Ctor(ui, rootUi, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self:InitRootUi(rootUi)
    self:SetSelect(false)

    if self.BtnClick then
        self.BtnClick.CallBack = function() if clickCb then clickCb() end end
    end
end

function XUiGridInfestorExploreCore:InitRootUi(rootUi)
    self.RootUi = rootUi
end

function XUiGridInfestorExploreCore:Refresh(coreId, coreLevel, isNotShowImgHave)
    if self.RImgIcon then
        local icon = XFubenInfestorExploreConfigs.GetCoreIcon(coreId)
        self.RImgIcon:SetRawImage(icon)
    end

    if self.ImgQuality then
        local qualityIcon = XFubenInfestorExploreConfigs.GetCoreQualityIcon(coreId)
        self.RootUi:SetUiSprite(self.ImgQuality, qualityIcon)
    end

    local curLv = coreLevel or XDataCenter.FubenInfestorExploreManager.GetCoreLevel(coreId)
    local maxLv = XFubenInfestorExploreConfigs.GetCoreMaxLevel(coreId)
    for i = 1, MAX_LEVEL_NUM do
        local belowMaxLv = i <= maxLv
        self["GridLevel" .. i].gameObject:SetActiveEx(belowMaxLv)
        self["ImgMaxLevel" .. i].gameObject:SetActiveEx(belowMaxLv)

        local belowCurLv = i <= curLv
        self["ImgCurLevel" .. i].gameObject:SetActiveEx(belowCurLv)
    end

    if self.TxtMax then
        self.TxtMax.gameObject:SetActiveEx(curLv == maxLv)
    end

    if self.TxtName then
        self.TxtName.text = XFubenInfestorExploreConfigs.GetCoreName(coreId)
    end

    if self.TxtDes then
        self.TxtDes.text = XFubenInfestorExploreConfigs.GetCoreLevelDes(coreId, curLv)
    end

    local isHaveCore = XDataCenter.FubenInfestorExploreManager.IsHaveCore(coreId)
    local bagCoreLevel = isHaveCore and XDataCenter.FubenInfestorExploreManager.GetCoreLevel(coreId) or 0
    if self.ImgHave then 
        self.ImgHave.gameObject:SetActiveEx(not isNotShowImgHave and isHaveCore and bagCoreLevel < maxLv)
    end

    if self.ImgHaveMax then
        self.ImgHaveMax.gameObject:SetActiveEx(not isNotShowImgHave and isHaveCore and bagCoreLevel >= maxLv)
    end
end

function XUiGridInfestorExploreCore:SetSelect(value)
    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(value)
    end
end

return XUiGridInfestorExploreCore