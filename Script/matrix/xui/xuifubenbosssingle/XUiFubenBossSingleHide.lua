local XUiFubenBossSingleHide = XLuaUiManager.Register(XLuaUi, "UiFubenBossSingleHide")

function XUiFubenBossSingleHide:OnAwake()
    self:AutoAddListener()
    self.GridFeatureList = {}
    self.GridBuffDetailList = {}
end

function XUiFubenBossSingleHide:OnStart(bossStageCfg)
    self:Init(bossStageCfg)
end

function XUiFubenBossSingleHide:OnEnable()

end

function XUiFubenBossSingleHide:OnDisable()

end

function XUiFubenBossSingleHide:AutoAddListener()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnBackClick)
end

function XUiFubenBossSingleHide:Init(bossStageCfg)
    self.BossStageCfg = bossStageCfg
    self.GridFeatures.gameObject:SetActiveEx(false)
    self.GridBuffTitle.gameObject:SetActiveEx(false)
    self.GridBuffDetails.gameObject:SetActiveEx(false)
    self.IsHideBoss = self.BossStageCfg.DifficultyType == XFubenBossSingleConfigs.DifficultyType.Hide

    local buffDetailIds = self.BossStageCfg.BuffDetailsId
    local featuresIds = self.BossStageCfg.FeaturesId
    local showFeatures = featuresIds and #featuresIds > 0
    local showBuff = buffDetailIds and #buffDetailIds > 0

    if not showBuff and not showFeatures then
        return
    end

    self:SetFeatures(showFeatures)
    self:SetBuffTitle(showBuff)
    self:SetBuffDetails(showBuff)
end

function XUiFubenBossSingleHide:SetFeatures(showFeatures)
    if not showFeatures then
        return
    end

    for _, grid in pairs(self.GridFeatureList) do
        grid.gameObject:SetActiveEx(false)
    end

    for i = 1, #self.BossStageCfg.FeaturesId do
        local grid = self.GridFeatureList[i]
        if not grid then
            grid = CS.UnityEngine.Object.Instantiate(self.GridFeatures)
            grid.transform:SetParent(self.PanelContent, false)
            self.GridFeatureList[i] = grid
        end

        local desc = XUiHelper.TryGetComponent(grid.transform, "TxtDesc", "Text")
        local name = XUiHelper.TryGetComponent(grid.transform, "TxtName", "Text")
        local featuresCfg = XFubenConfigs.GetFeaturesById(self.BossStageCfg.FeaturesId[i])
        desc.text = featuresCfg.Desc
        name.text = self.IsHideBoss and CS.XTextManager.GetText("BossSingleLevelHideBoss", featuresCfg.Name)
        or CS.XTextManager.GetText("BossSingleLevel", featuresCfg.Name)

        grid.gameObject:SetActiveEx(true)
    end
end

function XUiFubenBossSingleHide:SetBuffTitle(showBuff)
    if not showBuff then
        return
    end

    local grid = CS.UnityEngine.Object.Instantiate(self.GridBuffTitle)
    grid.transform:SetParent(self.PanelContent, false)
    local hide = XUiHelper.TryGetComponent(grid.transform, "PanelBuffHideTitle")
    local normal = XUiHelper.TryGetComponent(grid.transform, "PanelBuffTitle")
    hide.gameObject:SetActiveEx(self.IsHideBoss)
    normal.gameObject:SetActiveEx(not self.IsHideBoss)
    grid.gameObject:SetActiveEx(true)
end

function XUiFubenBossSingleHide:SetBuffDetails(showBuff)
    if not showBuff then
        return
    end

    for _, grid in pairs(self.GridBuffDetailList) do
        grid.gameObject:SetActiveEx(false)
    end

    for i = 1, #self.BossStageCfg.BuffDetailsId do
        local grid = self.GridBuffDetailList[i]
        if not grid then
            grid = CS.UnityEngine.Object.Instantiate(self.GridBuffDetails)
            grid.transform:SetParent(self.PanelContent, false)
            self.GridBuffDetailList[i] = grid
        end

        local desc = XUiHelper.TryGetComponent(grid.transform, "TxtDesc", "Text")
        local name = XUiHelper.TryGetComponent(grid.transform, "TxtName", "Text")
        local icon = XUiHelper.TryGetComponent(grid.transform, "RImgIcon", "RawImage")
        local bg = XUiHelper.TryGetComponent(grid.transform, "ImgfTriangleBg", "Image")
        local buffDetailsCfg = XFubenBabelTowerConfigs.GetBabelBuffConfigs(self.BossStageCfg.BuffDetailsId[i])
        desc.text = buffDetailsCfg.Desc
        name.text = buffDetailsCfg.Name
        icon:SetRawImage(buffDetailsCfg.BuffBg)
        if buffDetailsCfg.BuffTriangleBg then
            self:SetUiSprite(bg, buffDetailsCfg.BuffTriangleBg)
        end

        grid.gameObject:SetActiveEx(true)
    end
end

function XUiFubenBossSingleHide:OnBtnBackClick()
    self:Close()
end