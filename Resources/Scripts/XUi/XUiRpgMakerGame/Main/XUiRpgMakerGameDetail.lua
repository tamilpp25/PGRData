--副本详情
local XUiRpgMakerGameDetail = XLuaUiManager.Register(XLuaUi, "UiRpgMakerGameDetail")

local MaxStarCount = XRpgMakerGameConfigs.MaxStarCount

function XUiRpgMakerGameDetail:OnAwake()
    self:InitUi()
    self:AutoAddListener()
end

function XUiRpgMakerGameDetail:OnStart(stageId, closeCb, tabGroupIndex)
    self.StageId = stageId
    self.CloseCb = closeCb
    self.TabGroupIndex = tabGroupIndex

    local numberName = XRpgMakerGameConfigs.GetRpgMakerGameNumberName(stageId)
    local name = XRpgMakerGameConfigs.GetRpgMakerGameStageName(stageId)
    self.TxtFightName.text = string.format("%s %s", numberName, name)
    self.TxtInfo.text = XRpgMakerGameConfigs.GetRpgMakerGameStageHint(stageId)

    local starConditionIdList = XRpgMakerGameConfigs.GetRpgMakerGameStarConditionIdList(stageId)
    local starConditionDesc
    for i, starConditionId in ipairs(starConditionIdList) do
        starConditionDesc = XRpgMakerGameConfigs.GetRpgMakerGameStarConditionDesc(starConditionId)
        if self["TxtUnActive" .. i] then
            self["TxtUnActive" .. i].text = starConditionDesc
        end
        if self["TxtActive" .. i] then
            self["TxtActive" .. i].text = starConditionDesc
        end
        self["GridStageStar" .. i].gameObject:SetActiveEx(true)
    end

    for i = #starConditionIdList + 1, MaxStarCount do
        self["GridStageStar" .. i].gameObject:SetActiveEx(false)
    end
end

function XUiRpgMakerGameDetail:OnEnable()
    self:Refresh()
end

function XUiRpgMakerGameDetail:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiRpgMakerGameDetail:InitUi()
    local gridStageStar
    for i = 1, MaxStarCount do
        gridStageStar = self["GridStageStar" .. i]
        if gridStageStar then
            self["PanelUnActive" .. i] = XUiHelper.TryGetComponent(gridStageStar.transform, "PanelUnActive")
            self["TxtUnActive" .. i] = XUiHelper.TryGetComponent(gridStageStar.transform, "PanelUnActive/TxtUnActive", "Text")
            self["PanelActive" .. i] = XUiHelper.TryGetComponent(gridStageStar.transform, "PanelActive")
            self["TxtActive" .. i] = XUiHelper.TryGetComponent(gridStageStar.transform, "PanelActive/TxtActive", "Text")
        end
    end
end

function XUiRpgMakerGameDetail:AutoAddListener()
    self:RegisterClickEvent(self.BtnMask, self.Close)
    self:RegisterClickEvent(self.BtnEnterFight, self.OnBtnEnterFightClick)
end

function XUiRpgMakerGameDetail:Refresh()
    local stageId = self:GetStageId()
    local starConditionIdList = XRpgMakerGameConfigs.GetRpgMakerGameStarConditionIdList(stageId)
    local stageDb = XDataCenter.RpgMakerGameManager.GetRpgMakerActivityStageDb(stageId)
    local isClear
    for i, starConditionId in ipairs(starConditionIdList) do
        isClear = stageDb and stageDb:IsStarConditionClear(starConditionId) or false
        self["PanelActive" .. i].gameObject:SetActiveEx(isClear)
        self["PanelUnActive" .. i].gameObject:SetActiveEx(not isClear)
    end
end

function XUiRpgMakerGameDetail:OnBtnEnterFightClick()
    local stageId = self:GetStageId()
    XLuaUiManager.Open("UiRpgMakerGameCharacter", stageId)
end

function XUiRpgMakerGameDetail:GetStageId()
    return self.StageId
end