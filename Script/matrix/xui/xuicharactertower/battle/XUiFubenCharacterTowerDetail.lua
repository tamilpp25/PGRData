---@class XUiFubenCharacterTowerDetail : XLuaUi
local XUiFubenCharacterTowerDetail = XLuaUiManager.Register(XLuaUi, "UiFubenCharacterTowerDetail")

local RELATION_DES_COLOR = {
    [true] = XUiHelper.Hexcolor2Color("188649ff"),
    [false] = XUiHelper.Hexcolor2Color("00000099")
}

function XUiFubenCharacterTowerDetail:OnAwake()
    self:RegisterUiEvents()
    self:InitStarPanels()
    self.GridStageStar.gameObject:SetActive(false)
end

function XUiFubenCharacterTowerDetail:OnStart(rootUi, chapterId)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.GridRelationList = {}
    self.RootUi = rootUi
    self.ChapterId = chapterId
    ---@type XCharacterTowerChapter
    self.ChapterViewModel = XDataCenter.CharacterTowerManager.GetCharacterTowerChapter(chapterId)
end

function XUiFubenCharacterTowerDetail:OnEnable()
    -- 动画
    self.IsPlaying = true
    self:PlayAnimation("AnimBegin", handler(self, function()
        self.IsPlaying = false
    end))
    self.IsOpen = true
end

function XUiFubenCharacterTowerDetail:OnDisable()
    self.IsOpen = false
end

function XUiFubenCharacterTowerDetail:InitStarPanels()
    self.GridStarList = {}
    for i = 1, 3 do
        local ui = self.Transform:Find("SafeAreaContentPane/PanelDetail/PanelTargetList/GridStageStar" .. i)
        ui.gameObject:SetActive(true)
        local grid = XUiGridStageStar.New(ui)
        self.GridStarList[i] = grid
    end
end

function XUiFubenCharacterTowerDetail:Refresh(stageId)
    self.StageId = stageId
    self.Stage = XDataCenter.FubenManager.GetStageCfg(stageId)
    self:UpdateCommon()
    self:UpdateDifficulty()
    self:UpdateStageFightControl()--更新战力限制提示
    self:UpdateRelation() -- 更新羁绊加成
end

function XUiFubenCharacterTowerDetail:UpdateCommon()
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)

    self.TxtTitle.text = self.Stage.Name
    self.TxtDesc.text = self.Stage.Description
    self.TxtATNums.text = XDataCenter.FubenManager.GetRequireActionPoint(self.StageId)

    local maxChallengeNum = XDataCenter.FubenManager.GetStageMaxChallengeNums(self.StageId)
    local buyChallengeCount = XDataCenter.FubenManager.GetStageBuyChallengeCount(self.StageId)

    self.PanelNums.gameObject:SetActive(maxChallengeNum > 0)
    self.PanelNoLimitCount.gameObject:SetActive(maxChallengeNum <= 0)
    self.BtnAddNum.gameObject:SetActive(buyChallengeCount > 0)
    local showAutoFightBtn = false
    if self.Stage.AutoFightId > 0 then
        local autoFightAvailable = XDataCenter.AutoFightManager.CheckAutoFightAvailable(self.StageId) == XCode.Success
        if autoFightAvailable then
            self:SetAutoFightState(XDataCenter.AutoFightManager.State.None)
            showAutoFightBtn = true
        end
    end
    self:SetAutoFightActive(showAutoFightBtn)

    if maxChallengeNum > 0 then
        local stageData = XDataCenter.FubenManager.GetStageData(self.StageId)
        local challengeNum = stageData and stageData.PassTimesToday or 0
        self.TxtAllNums.text = "/" .. maxChallengeNum
        self.TxtLeftNums.text = maxChallengeNum - challengeNum
    end

    for i = 1, 3 do
        self.GridStarList[i]:Refresh(self.Stage.StarDesc[i], stageInfo.StarsMap[i])
    end
end

function XUiFubenCharacterTowerDetail:UpdateDifficulty()
    local nanDuIcon = XDataCenter.FubenManager.GetDifficultIcon(self.StageId)
    --赏金任务
    local IsBountyTaskPreFight, task = XDataCenter.BountyTaskManager.CheckBountyTaskPreFight(self.StageId)
    if IsBountyTaskPreFight then
        local config = XDataCenter.BountyTaskManager.GetBountyTaskConfig(task.Id)
        nanDuIcon = config.StageIcon
    end
    self.RImgNandu:SetRawImage(nanDuIcon)
end

function XUiFubenCharacterTowerDetail:UpdateStageFightControl()
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    if self.StageFightControl == nil then
        self.StageFightControl = XUiStageFightControl.New(self.PanelStageFightControl, self.Stage.FightControlId)
    end
    if not stageInfo.Passed and stageInfo.Unlock then
        self.StageFightControl.GameObject:SetActive(true)
        self.StageFightControl:UpdateInfo(self.Stage.FightControlId)
    else
        self.StageFightControl.GameObject:SetActive(false)
    end
end

function XUiFubenCharacterTowerDetail:UpdateRelation()
    local relationGroupId = self.ChapterViewModel:GetChapterRelationGroupId()
    ---@type XCharacterTowerRelation
    local relationViewModel = XDataCenter.CharacterTowerManager.GetCharacterTowerRelation(relationGroupId)
    local relationInfo = relationViewModel:GetRelationInfo()
    local fightEventIds = relationViewModel:GetRelationFightEventIds()

    for index, eventId in ipairs(fightEventIds) do
        if eventId > 0 then
            local grid = self.GridRelationList[index]
            if not grid then
                local go = index == 1 and self.TxtFetterDes or XUiHelper.Instantiate(self.TxtFetterDes, self.PanelContent)
                grid = {}
                XTool.InitUiObjectByUi(grid, go)
                self.GridRelationList[index] = grid
            end
            local unLock = relationInfo:CheckRelationUnlock(eventId)
            local color = RELATION_DES_COLOR[unLock]
            -- 描述
            grid.TxtFetterDes.text = XRoomSingleManager.GetEvenDesc(eventId)
            grid.TxtFetterDes.color = color
            -- 等级
            grid.TxtPosA1.text = XUiHelper.GetText("CharacterTowerRelationLevelDesc", index)
            grid.TxtPosA1.color = color
        end
    end
end

function XUiFubenCharacterTowerDetail:SetAutoFightActive(value)
    self.PanelAutoFightButton.gameObject:SetActive(value)
    self.BtnEnter.gameObject:SetActive(not value)
end

function XUiFubenCharacterTowerDetail:SetAutoFightState(value)
    local state = XDataCenter.AutoFightManager.State
    self.BtnAutoFight.gameObject:SetActive(value == state.None)
    self.ImgAutoFighting.gameObject:SetActive(value == state.Fighting)
    self.BtnAutoFightComplete.gameObject:SetActive(value == state.Complete)
end

function XUiFubenCharacterTowerDetail:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnAddNum, self.OnBtnAddNumClick)
    XUiHelper.RegisterClickEvent(self, self.BtnEnter, self.OnBtnEnterClick)
    XUiHelper.RegisterClickEvent(self, self.BtnEnterB, self.OnBtnEnterBClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAutoFight, self.OnBtnAutoFightClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAutoFightComplete, self.OnBtnAutoFightCompleteClick)
end

function XUiFubenCharacterTowerDetail:OnBtnEnterBClick()
    self:OnBtnEnterClick()
end

function XUiFubenCharacterTowerDetail:OnBtnAutoFightClick()
    XDataCenter.AutoFightManager.CheckOpenDialog(self.StageId, self.Stage)
end

function XUiFubenCharacterTowerDetail:OnBtnAutoFightCompleteClick()
    local index = XDataCenter.AutoFightManager.GetIndexByStageId(self.StageId)
    XDataCenter.AutoFightManager.ObtainRewards(index)
end

function XUiFubenCharacterTowerDetail:OnBtnAddNumClick()
    local challengeData = XDataCenter.FubenMainLineManager.GetStageBuyChallengeData(self.StageId)
    XLuaUiManager.Open("UiBuyAsset", 1, function()
        self:UpdateCommon()
    end, challengeData)
end

function XUiFubenCharacterTowerDetail:OnBtnEnterClick()
    if self.IsPlaying then
        return
    end

    if self.Stage == nil then
        XLog.Error("XUiFubenCharacterTowerDetail.OnBtnEnterClick: Can not find StageCfg!")
        return
    end
    
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_ENTERFIGHT, self.Stage)
end

function XUiFubenCharacterTowerDetail:Hide()
    if self.IsPlaying or not self.IsOpen then
        return
    end

    self.IsPlaying = true
    self:PlayAnimation("AnimEnd", handler(self, function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self.IsPlaying = false
        self:Close()
    end))
end

return XUiFubenCharacterTowerDetail