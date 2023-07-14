local XUiNewAutoFightDialog = XLuaUiManager.Register(XLuaUi, "UiAutoFightEnter")

local tableinsert = table.insert

local CsTextManagerGetText = CS.XTextManager.GetText

function XUiNewAutoFightDialog:OnAwake()
    self:InitComponent()
end

function XUiNewAutoFightDialog:OnStart(stageId, stage)
    self:InitUI(stageId, stage)
end

function XUiNewAutoFightDialog:InitComponent()
    self.BtnSub.CallBack = function() self:OnBtnSubClick() end
    self.BtnAdd.CallBack = function() self:OnBtnAddClick() end
    self.BtnMax.CallBack = function() self:OnBtnMaxClick() end
    self.BtnEnter.CallBack = function() self:OnBtnEnterClick() end
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
end

function XUiNewAutoFightDialog:InitUI(stageId, stage)
    self.StageId = stageId
    self.Stage = stage
    self.StageData = XDataCenter.FubenManager.GetStageData(stageId)
    self.GridList = {}

    self.TxtTitle.text = CsTextManagerGetText("AutoFightDialogTitle")
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    local autoFightCfg = XAutoFightConfig.GetCfg(stageCfg.AutoFightId)

    local maxChallengeNum = XDataCenter.FubenManager.GetStageMaxChallengeNums(stageId)
    if maxChallengeNum > 0 then
        local chanllengedNum = 0
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        if stageInfo.Type == XDataCenter.FubenManager.StageType.Prequel then
            local info = XDataCenter.PrequelManager.GetUnlockChallengeStagesByStageId(stageId)
            if info then
                chanllengedNum = info.Count
            end
        else
            chanllengedNum = self.StageData and self.StageData.PassTimesToday or 0
        end
        maxChallengeNum = maxChallengeNum - chanllengedNum

        if autoFightCfg.Limit > 0 then
            maxChallengeNum = math.min(maxChallengeNum, autoFightCfg.Limit)
        end
    else
        maxChallengeNum = autoFightCfg.Limit
    end

    self.RequireAP = stageCfg.RequireActionPoint
    self.LeftTimes = maxChallengeNum
    self.RecordTime = self.StageData.LastRecordTime

    self.Head.gameObject:SetActiveEx(false)
    self.GridCommon.gameObject:SetActiveEx(false)
    self.PanelCostEx.gameObject:SetActiveEx(false)

    local cardIds = self.StageData.LastCardIds
    if stageCfg.RobotId and #stageCfg.RobotId > 0 then
        cardIds = {}
        for _, v in pairs(stageCfg.RobotId) do
            local charId = XRobotManager.GetCharacterId(v)
            tableinsert(cardIds, charId)
        end
    end

    self:InitCharacters(cardIds)
    self:InitRewards()

    self:SetFightTimes(1)
end

function XUiNewAutoFightDialog:InitCharacters(characterIds)
    local index = 0
    for _, id in pairs(characterIds) do
        if id > 0 then
            index = index + 1
            local transform
            if index == 1 then
                transform = self.Head
            else
                transform = CS.UnityEngine.Object.Instantiate(self.Head, self.CharacterContent)
            end

            local img = transform:Find("ImgIcon"):GetComponent("RawImage")
            local icon = XDataCenter.CharacterManager.GetCharRoundnessHeadIcon(id)
            img:SetRawImage(icon)
            transform.gameObject:SetActiveEx(true)
        end
    end
end

function XUiNewAutoFightDialog:InitRewards()
    local stageId = self.StageId
    local cfg = XDataCenter.FubenManager.GetStageLevelControl(stageId)

    local rewardId = (cfg and cfg.FinishRewardShow) or (self.Stage and self.Stage.FinishRewardShow)
    if not rewardId or rewardId == 0 then
        self.PanelRewards.gameObject:SetActiveEx(false)
        return
    else
        self.PanelRewards.gameObject:SetActiveEx(true)
    end

    local rewards = XRewardManager.GetRewardListNotCount(rewardId)
    if rewards then
        for i, item in ipairs(rewards) do
            local grid
            if self.GridList[i] then
                grid = self.GridList[i]
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
                grid = XUiGridCommon.New(self, ui)
                grid.Transform:SetParent(self.PanelRewards, false)
                self.GridList[i] = grid
            end
            grid:Refresh(item)
            grid.GameObject:SetActive(true)
        end
    end

    local rewardsCount = 0
    if rewards then
        rewardsCount = #rewards
    end

    for j = 1, #self.GridList do
        if j > rewardsCount then
            self.GridList[j].GameObject:SetActive(false)
        end
    end
end

function XUiNewAutoFightDialog:SetFightTimes(value)
    self.FightTimes = value
    self.TxtATNums.text = value * self.RequireAP
    self.TxtChallengeNum.text = value
    self.TxtRewardNum.text = "X" .. value

    local canSub = value > 1
    self.BtnSub.gameObject:SetActiveEx(canSub)
    self.ImgCantSub.gameObject:SetActiveEx(not canSub)

    local canAdd = value < self.LeftTimes
    self.BtnAdd.gameObject:SetActiveEx(canAdd)
    self.ImgCantAdd.gameObject:SetActiveEx(not canAdd)
end

function XUiNewAutoFightDialog:OnBtnSubClick()
    local tempTimes = self.FightTimes - 1
    if tempTimes < 1 then
        return
    end

    self:SetFightTimes(tempTimes)
end

function XUiNewAutoFightDialog:OnBtnAddClick()
    local tempTimes = self.FightTimes + 1
    if tempTimes > self.LeftTimes then
        return
    end

    self:SetFightTimes(tempTimes)
end

function XUiNewAutoFightDialog:OnBtnMaxClick()
    local ownActionPoint = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.ActionPoint)
    local times1 = self.RequireAP ~= 0 and math.floor(ownActionPoint / self.RequireAP) or self.LeftTimes
    local maxTimes = math.min(times1, self.LeftTimes)
    maxTimes = maxTimes > 0 and maxTimes or 1
    self:SetFightTimes(maxTimes)
end

function XUiNewAutoFightDialog:OnBtnEnterClick()
    if self.FightTimes == 0 then
        return
    end

    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    if not XDataCenter.FubenManager.CheckPreFight(stageCfg, self.FightTimes, true) then
        return
    end

    XDataCenter.AutoFightManager.RecordFightBeginData(self.StageId, self.FightTimes, self.StageData.LastCardIds)

    XDataCenter.AutoFightManager.StartNewAutoFight(self.StageId, self.FightTimes, function(res)
        if res.Code == XCode.Success then
            self:Close()
            XLuaUiManager.Open("UiNewAutoFightSettleWin", XDataCenter.AutoFightManager.GetAutoFightBeginData(), res)
        end
    end)
end

function XUiNewAutoFightDialog:OnBtnCloseClick()
    self:Close()
end