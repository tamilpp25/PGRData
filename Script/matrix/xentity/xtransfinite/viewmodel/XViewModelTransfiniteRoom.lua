local XUiTransfiniteRoomProxy = require("XUi/XUiTransfinite/Main/XUiTransfiniteRoomProxy")

---@class XViewModelTransfiniteRoom
local XViewModelTransfiniteRoom = XClass(nil, "XViewModelTransfiniteRoom")

function XViewModelTransfiniteRoom:Ctor()
    self.Data = {
        BossModel = false,
        Progress = false,
        IsEnableLeftArrow = false,
        IsEnableRightArrow = false,
        Reward = false,
        ExtraReward = false,
        RewardAmount = false,
        ExtraRewardAmount = false,
        ExtraRewardTime = 0,
        ExtraCondition = false,
        ExtraDesc = false,
        ---@type XViewModelTransfiniteRoomMember[]
        Members = false,
        IsTeamEmpty = false,
        Time = false,
        Score = 0,
        IsStageReward = false,
        IsStageNormal = false,
        IsStageHidden = false,
        ---@type XViewModelTransfiniteRoomEvent[]
        Event = false,
        IsStagePassed = false,
        IsStageLock = false,
        TxtStageLock = false,
        IsStageCurrent = false,
        IsHideBtnReset = false,
        IsShowRepeatBtn = false,
        ImgScore = false
    }

    ---@type XTransfiniteStageGroup
    self._StageGroup = XDataCenter.TransfiniteManager.GetStageGroup()
    self._StageIndex = 0
    self._IsOpenRoom = false
end

function XViewModelTransfiniteRoom:SetStageGroup(stageGroup)
    self._StageGroup = stageGroup
    self:ResetIndex()
    if not stageGroup:IsBegin() then
        local team = stageGroup:GetTeam()
        if team:IsEmpty() then
            team:Load()
        end
    end

    if stageGroup:IsRecordNotConfirm() then
        self:ConfirmRecordResult()
    end
end

function XViewModelTransfiniteRoom:ResetIndex()
    self._StageIndex = self._StageGroup:GetCurrentIndex()
end

function XViewModelTransfiniteRoom:Update(resetIndex)
    if resetIndex then
        self:ResetIndex()
    end

    local stageGroup = self._StageGroup
    local stage = stageGroup:GetStageByIndex(self._StageIndex)
    if not stage then
        self._StageIndex = 1
        stage = stageGroup:GetStageByIndex(self._StageIndex)
        if not stage then
            return
        end
    end
    local data = self.Data
    data.BossModel = stage:GetBossModel()
    local stageAmount = stageGroup:GetStageAmount()
    data.Progress = self._StageIndex .. "/" .. stageAmount
    data.IsEnableLeftArrow = self._StageIndex > 1
    data.IsEnableRightArrow = self._StageIndex < stageAmount

    local rewardId
    if stage:IsPassed() then
        rewardId = stage:GetRewardShow()
    else
        rewardId = stage:GetFirstRewardShow()
    end
    --local rewardList = XRewardManager.GetRewardList(rewardId)
    data.Reward = XDataCenter.ItemManager.ItemId.TransfiniteScore
    data.ExtraReward = XDataCenter.ItemManager.ItemId.TransfiniteScore
    data.RewardAmount = stage:GetRewardScore()
    data.ExtraRewardAmount = stage:GetRewardExtraScore()
    data.ExtraRewardTime = stage:GetRewardExtraTime()

    data.ExtraCondition = stage:GetCondition()

    local time = stageGroup:GetTotalClearTime()
    local timeStr = XUiHelper.GetTime(time)
    data.Time = XUiHelper.GetText("TransfiniteTimeFight", timeStr)

    data.IsStageNormal = stage:IsNormalStage()
    data.IsStageReward = stage:IsRewardStage()
    data.IsStageHidden = stage:IsHiddenStage()

    data.Event = {}
    local eventList = stage:GetFightEvent()
    for i = 1, #eventList do
        local event = eventList[i]
        ---@class XViewModelTransfiniteRoomEvent
        local dataEvent = {
            Name = event:GetName(),
            Icon = event:GetIcon(),
            Desc = event:GetDesc(),
        }
        data.Event[i] = dataEvent
    end

    data.Members = {}
    data.IsTeamEmpty = true
    if stageGroup:IsHaveTeam() then
        local team = stageGroup:GetTeam()
        local memberList = team:GetMembers()
        for i = 1, XTeamConfig.MEMBER_AMOUNT do
            local member = memberList[i]
            if member and member:IsValid() then
                local hp = member:GetHp() / 100

                ---@class XViewModelTransfiniteRoomMember
                local dataMember = {
                    Index = i,
                    Icon = XDataCenter.CharacterManager.GetCharBigRoundnessNotItemHeadIcon(member:GetId()),
                    Hp = hp,
                    Sp = member:GetSp() / 100,
                    IsCaptain = i == team:GetCaptainPos(),
                    IsFirst = i == team:GetFirstPos(),
                    IsDead = hp == 0,
                }

                if self._StageIndex == stageGroup:GetSaveStageIndex() then
                    if self._StageIndex == 1 then
                        dataMember.Hp = 1
                        dataMember.Sp = 0
                        dataMember.IsDead = false
                    else
                        local historyCharacter = stageGroup:GetHistoryCharacterByIndex(i)

                        if historyCharacter then
                            dataMember.Hp = historyCharacter.HpPercent / 100
                            dataMember.Sp = historyCharacter.Energy / 100
                            dataMember.IsDead = dataMember.Hp == 0
                        end
                    end
                end
                
                data.Members[i] = dataMember
                data.IsTeamEmpty = false
            end
        end
    end

    data.Score = stageGroup:GetScore()

    data.IsStageLock = stageGroup:IsStageLock(stage)
    if data.IsStageLock then
        local conditionArray = stage:GetCondition()
        local desc = XConditionManager.GetConditionDescById(conditionArray[1])
        data.TxtStageLock = desc
    end

    data.IsStagePassed = stage:IsPassed()
    data.IsStageCurrent = stageGroup:IsStageCurrent(stage)
    if data.IsStageCurrent then
        data.IsStagePassed = false
    end
    if stageGroup:IsClear() then
        data.IsStageCurrent = false
        data.IsStagePassed = true
    end

    if stageGroup:IsBegin() then
        data.IsHideBtnReset = false
    else
        data.IsHideBtnReset = true
    end
    
    data.IsShowRepeatBtn = self._StageIndex == stageGroup:GetSaveStageIndex()
    if stageGroup:IsIsland() then
        if self._StageIndex == XTransfiniteConfigs.IslandSpecialStage.FirstHideExtra then
            data.ExtraRewardTime = 0
        elseif self._StageIndex == XTransfiniteConfigs.IslandSpecialStage.SecondHideExtra then
            data.ExtraRewardTime = 0
        elseif self._StageIndex == XTransfiniteConfigs.IslandSpecialStage.ShowOtherExtra then
            if stage:IsAchievedExtraMission() then
                data.ExtraDesc = XUiHelper.GetText("TransfiniteTimeExtra6", data.ExtraRewardTime)
            else
                data.ExtraDesc = XUiHelper.GetText("TransfiniteTimeExtra7", data.ExtraRewardTime)
            end
        end
    else
        if stage:IsAchievedExtraMission() then
            data.ExtraDesc = XUiHelper.GetText("TransfiniteTimeExtra4", data.ExtraRewardTime)
        else
            data.ExtraDesc = XUiHelper.GetText("TransfiniteTimeExtra3", data.ExtraRewardTime)
        end
    end
    
    data.ImgScore = XItemConfigs.GetItemIconById(XDataCenter.ItemManager.ItemId.TransfiniteScore)
end

function XViewModelTransfiniteRoom:MoveLeft()
    self._StageIndex = self._StageIndex - 1
    if self._StageIndex <= 1 then
        self._StageIndex = 1
    end
end

function XViewModelTransfiniteRoom:MoveRight()
    self._StageIndex = self._StageIndex + 1
    local stageAmount = self._StageGroup:GetStageAmount()
    if self._StageIndex >= stageAmount then
        self._StageIndex = stageAmount
    end
end

function XViewModelTransfiniteRoom:OnClickReset()
    if self.Data.IsHideBtnReset then
        return
    end
    XUiManager.DialogTip(nil, XUiHelper.GetText("TransfiniteTimeReset"), nil, nil, function()
        XDataCenter.TransfiniteManager.RequestReset(self._StageGroup)
    end)
end

function XViewModelTransfiniteRoom:OnClickMember()
    local stageGroup = self._StageGroup
    --if stageGroup:IsBegin() then
    --    XUiManager.TipText("TransfiniteTimeLockTeam2")
    --    return
    --end

    local team = XDataCenter.TransfiniteManager.GetTeam()
    local stageGroupTeam = stageGroup:GetTeam()
    stageGroupTeam:UpdateXTeam(team)

    local stage = stageGroup:GetStageByIndex(self._StageIndex)
    local stageId = stage:GetId()
    self._IsOpenRoom = true
    XLuaUiManager.Open("UiBattleRoleRoom", stageId, team, XUiTransfiniteRoomProxy)
end

function XViewModelTransfiniteRoom:OnAwake()
    if self._StageGroup:IsIsland() then
        return
    end
    
    -- 第一次进入新周期，弹出环境
    local circleId = XDataCenter.TransfiniteManager.GetCircleId()
    if circleId then
        local key = "TransfiniteCycle" .. XPlayer.Id .. circleId
        if not XSaveTool.GetData(key) then
            XSaveTool.SaveData(key, true)
            self:ShowUiEnvironment()
        end
    end
end

function XViewModelTransfiniteRoom:ConfirmRecordResult()
    local stageGroup = self._StageGroup
    XLuaUiManager.Open("UiTransfiniteHint", stageGroup)
end

function XViewModelTransfiniteRoom:OnEnable()
    if self._IsOpenRoom then
        local stageGroup = self._StageGroup
        local team = XDataCenter.TransfiniteManager.GetTeam()
        local stageGroupTeam = stageGroup:GetTeam()
        stageGroupTeam:UpdateByEntityIds(team:GetEntityIds())
        stageGroupTeam:SetFirstPos(team:GetFirstFightPos())
        stageGroupTeam:SetCaptainPos(team:GetCaptainPos())
        stageGroupTeam:Save()
        self._IsOpenRoom = false
    end
end

function XViewModelTransfiniteRoom:_GetStage()
    return self._StageGroup:GetStageByIndex(self._StageIndex)
end

function XViewModelTransfiniteRoom:_Fight()
    local stage = self:_GetStage()
    local stageGroup = self._StageGroup
    if self._StageGroup:IsStageLock(stage) then
        XUiManager.TipText(self.Data.TxtStageLock)
        return
    end
    XDataCenter.TransfiniteManager.RequestFight(stage, stageGroup)
end

function XViewModelTransfiniteRoom:_FightAndSetTeam()
    XDataCenter.TransfiniteManager.RequestSetTeam(self._StageGroup, self._StageGroup:GetCurrentIndex() == 1, function()
        self:_Fight()
    end)
end

function XViewModelTransfiniteRoom:OnClickFight()
    local team = self._StageGroup:GetTeam()
    if not team:IsCaptainSelected() then
        XUiManager.TipText("TeamManagerCheckCaptainNil")
        return
    end
    -- 检查首发位置是否为空
    if not team:IsFirstPosValid() then
        XUiManager.TipText("TeamManagerCheckFirstFightNil")
        return
    end
    if team:IsFull() then
        XUiManager.DialogTip(nil, XUiHelper.GetText("TransfiniteTimeLockTeam"), nil, nil, function()
            self:_FightAndSetTeam()
        end)
        return
    end
    XUiManager.DialogTip(nil, XUiHelper.GetText("TransfiniteTimeLowOnMember"), nil, nil, function()
        self:_FightAndSetTeam()
    end)
end

function XViewModelTransfiniteRoom:OnClickEnvironment()
    self:ShowUiEnvironment()
end

function XViewModelTransfiniteRoom:ShowUiEnvironment()
    local stageGroup = self._StageGroup
    XLuaUiManager.Open("UiTransfiniteEnvironmentDetail", stageGroup:GetEnvironment())
end

return XViewModelTransfiniteRoom
