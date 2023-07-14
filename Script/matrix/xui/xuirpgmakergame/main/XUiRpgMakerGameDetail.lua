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
    local coinReward
    local coinItemId = XDataCenter.ItemManager.ItemId.RpgMakerGameHintCoin
    for i, starConditionId in ipairs(starConditionIdList) do
        local gridStageStar = self["GridStageStar" .. i]
        if gridStageStar then
            --达成条件
            starConditionDesc = XRpgMakerGameConfigs.GetRpgMakerGameStarConditionDesc(starConditionId)
            gridStageStar:SetNameByGroup(1, starConditionDesc)
            --奖励代币
            coinReward = XRpgMakerGameConfigs.GetStarConditionReward(starConditionId)
            gridStageStar:SetNameByGroup(0, "x" .. coinReward)
            --代币图标
            gridStageStar:SetRawImage(XItemConfigs.GetItemIconById(coinItemId))
            gridStageStar.gameObject:SetActiveEx(true)
        end
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
            --已激活状态
            self["PanelActive" .. i] = XUiHelper.TryGetComponent(gridStageStar.transform, "PanelActive")
            --已激活有奖励状态
            self["PanelActiveSet" .. i] = XUiHelper.TryGetComponent(gridStageStar.transform, "PanelActive/PanelSet")
            --已激活无奖励状态
            self["PanelActiveUnSet" .. i] = XUiHelper.TryGetComponent(gridStageStar.transform, "PanelActive/PanelUnSet")
            --未激活状态
            self["PanelUnActive" .. i] = XUiHelper.TryGetComponent(gridStageStar.transform, "PanelUnActive")
            --未激活有奖励状态
            self["PanelUnActiveSet" .. i] = XUiHelper.TryGetComponent(gridStageStar.transform, "PanelUnActive/PanelSet")
            --未激活无奖励状态
            self["PanelUnActiveUnSet" .. i] = XUiHelper.TryGetComponent(gridStageStar.transform, "PanelUnActive/PanelUnSet")
        end
    end
end

function XUiRpgMakerGameDetail:AutoAddListener()
    self:RegisterClickEvent(self.BtnMask, self.Close)
    self:RegisterClickEvent(self.BtnEnterFight, self.OnBtnEnterFightClick)
    self:RegisterClickEvent(self.BtnMap, self.OnBtnMapClick)
end

function XUiRpgMakerGameDetail:Refresh()
    local stageId = self:GetStageId()
    local starConditionIdList = XRpgMakerGameConfigs.GetRpgMakerGameStarConditionIdList(stageId)
    local stageDb = XDataCenter.RpgMakerGameManager.GetRpgMakerActivityStageDb(stageId)
    local isClear
    local isReward
    for i, starConditionId in ipairs(starConditionIdList) do
        isClear = stageDb and stageDb:IsStarConditionClear(starConditionId) or false
        self["PanelActive" .. i].gameObject:SetActiveEx(isClear)
        self["PanelUnActive" .. i].gameObject:SetActiveEx(not isClear)

        isReward = XTool.IsNumberValid(XRpgMakerGameConfigs.GetStarConditionReward(starConditionId))
        self["PanelActiveSet" .. i].gameObject:SetActiveEx(isClear and isReward)
        self["PanelActiveUnSet" .. i].gameObject:SetActiveEx(isClear and not isReward)
        self["PanelUnActiveSet" .. i].gameObject:SetActiveEx(not isClear and isReward)
        self["PanelUnActiveUnSet" .. i].gameObject:SetActiveEx(not isClear and not isReward)
    end
end

function XUiRpgMakerGameDetail:OnBtnMapClick()
    local stageId = self:GetStageId()
    local mapId = XRpgMakerGameConfigs.GetStageMapId(stageId)
    XLuaUiManager.Open("UiRpgMakerGameMapTip", mapId, true)
end

function XUiRpgMakerGameDetail:OnBtnEnterFightClick()
    local stageId = self:GetStageId()
    XLuaUiManager.Open("UiRpgMakerGameCharacter", stageId)
end

function XUiRpgMakerGameDetail:GetStageId()
    return self.StageId
end