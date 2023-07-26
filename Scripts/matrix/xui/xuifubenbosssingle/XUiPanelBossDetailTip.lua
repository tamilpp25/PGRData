local XUiPanelBossDetailTip = XClass(nil, "XUiPanelBossDetailTip")

function XUiPanelBossDetailTip:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.GridBuffList = {}

    XTool.InitUiObject(self)
    self:AutoAddListener()
    self:Init()
end

function XUiPanelBossDetailTip:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelBossDetailTip:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelBossDetailTip:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelBossDetailTip:AutoAddListener()
    self:RegisterClickEvent(self.BtnDetail, self.OnBtnDetailClick)
end

function XUiPanelBossDetailTip:Init()
    self.GridBuffDetail.gameObject:SetActiveEx(false)
end

function XUiPanelBossDetailTip:ShowBossTip(bossStageCfg)
    self.BossStageCfg = bossStageCfg

    local buffDetailIds = bossStageCfg.BuffDetailsId
    local featuresIds = bossStageCfg.FeaturesId
    local showFeatures = featuresIds and #featuresIds > 0
    local showBuff = buffDetailIds and #buffDetailIds > 0

    if not showBuff and not showFeatures then
        self:HidePanel()
        return
    end
    local isHideBoss = self.BossStageCfg.DifficultyType == XFubenBossSingleConfigs.DifficultyType.Hide
    self.PanelFeatures.gameObject:SetActiveEx(showFeatures)
    self.PanelBuffDetail.gameObject:SetActiveEx(showBuff)
    self.PanelHideBg.gameObject:SetActiveEx(isHideBoss)
    self.PanelBg.gameObject:SetActiveEx(not isHideBoss)

    -- 设置词缀
    if showFeatures then
        local featureCfg = XFubenConfigs.GetFeaturesById(featuresIds[1])
        self.TxtFeatureTitle.text = featureCfg.Name
        self.TxtFeatureDesc.text = featureCfg.Desc
    end

    for _, grid in pairs(self.GridBuffList) do
        grid.gameObject:SetActiveEx(false)
    end

    if showBuff then
        for i = 1, #buffDetailIds do
            local grid = self.GridBuffList[i]
            if not grid then
                grid = CS.UnityEngine.Object.Instantiate(self.GridBuffDetail)
                grid.transform:SetParent(self.PanelBuffContent, false)
                self.GridBuffList[i] = grid
            end

            local icon = XUiHelper.TryGetComponent(grid.transform, "RImgIcom", "RawImage")
            local name = XUiHelper.TryGetComponent(grid.transform, "TxtName", "Text")
            local bg = XUiHelper.TryGetComponent(grid.transform, "ImgfTriangleBg", "Image")
            local buffCfg = XFubenBabelTowerConfigs.GetBabelBuffConfigs(buffDetailIds[i])
            icon:SetRawImage(buffCfg.BuffBg)
            name.text = buffCfg.Name
            if buffCfg.BuffTriangleBg then
                self.RootUi:SetUiSprite(bg, buffCfg.BuffTriangleBg)
            end

            grid.gameObject:SetActiveEx(true)
        end
    end

    self.GameObject:SetActiveEx(true)
end

function XUiPanelBossDetailTip:OnBtnDetailClick()
    XLuaUiManager.Open("UiFubenBossSingleHide", self.BossStageCfg)
end

function XUiPanelBossDetailTip:HidePanel()
    self.GameObject:SetActiveEx(false)
end

return XUiPanelBossDetailTip