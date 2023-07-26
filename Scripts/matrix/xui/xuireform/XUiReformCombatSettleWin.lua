local CsXTextManager = CS.XTextManager
local XUiReformTool = require("XUi/XUiReform2nd/XUiReformTool")

--######################## XUiWinRoleGrid ########################
local XUiWinRoleGrid = XClass(nil, "XUiWinRoleGrid")

function XUiWinRoleGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

-- data : XCharacterViewModel
function XUiWinRoleGrid:SetData(icon, level)
    self.RImgIcon:SetRawImage(icon)
    self.TxtLevel.text = level
end

--######################## XUiReformCombatSettleWin ########################
local STAR_STATUS = {
    START = 1,
    PLAY = 2,
    WAIT = 3,
    END = 4,
}

----@class UiReformCombatSettleWin:XLuaUi
local XUiReformCombatSettleWin = XLuaUiManager.Register(XLuaUi, "UiReformCombatSettleWin")

function XUiReformCombatSettleWin:OnAwake()
    self.GridWinRole.gameObject:SetActiveEx(false)
    self.GridReward.gameObject:SetActiveEx(false)
    self.GridRewardList = {}
    self.RewardAnimationIndex = 1
    self:RegisterUiEvents()

    ---@type XUiReformToolStar[]
    self.UiStar = false
    ---@type XUiReformToolStar
    self.UiStarExtra = false

    self._StarStatus = STAR_STATUS.START
    self._Timer = XScheduleManager.ScheduleForever(function()
        self:Update()
    end, 0)
    self._Star2Play = 0
    self._IsMatchExtraStar2Play = false
    self._DurationPlay = 0.3
    self._Star = 0
    self._IsMatchExtraStar = false
    self._Time = 0
    self._GoalDesc = false
    self._IsUnlockHardMode = false

    self._StarMax = false
end

function XUiReformCombatSettleWin:OnDestroy()
    XScheduleManager.UnSchedule(self._Timer)
    if self._TimerDelayStar then
        XScheduleManager.UnSchedule(self._TimerDelayStar)
    end
end

function XUiReformCombatSettleWin:OnStart(winData, isUnlockHardMode)
    self._IsUnlockHardMode = isUnlockHardMode
    local stageId = winData.StageId
    local stage = XDataCenter.Reform2ndManager.GetStage(stageId)
    --local currDiff = winData.SettleData.ReformFightResult.CurrDiff
    --local baseStage = XDataCenter.ReformActivityManager.GetBaseStage(winData.StageId)
    --local evolvableStage = baseStage:GetEvolvableStageByDiffIndex(currDiff + 1)
    -- 名称
    self.TxtTitle.text = stage:GetName()
    -- 难度等级
    self.TxtDiffTitle.text = ""
    -- 角色
    local team = XDataCenter.Reform2ndManager.GetTeam(stageId)
    --local memberSource = nil
    --local memberGroup = evolvableStage:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Member)
    local winRoleGo = nil
    local winRoleGrid = nil
    for _, entityId in ipairs(team:GetEntityIds()) do
        if entityId > 0 then
            local icon = nil
            local level = XDataCenter.CharacterManager.GetCharacterLevel(entityId)

            winRoleGo = CS.UnityEngine.Object.Instantiate(self.GridWinRole, self.PanelRoleContent)
            winRoleGo.gameObject:SetActiveEx(true)
            winRoleGrid = XUiWinRoleGrid.New(winRoleGo)

            if XRobotManager.CheckIsRobotId(entityId) then
                entityId = XRobotManager.GetCharacterId(entityId)
            end

            icon = XDataCenter.CharacterManager.GetCharBigHeadIcon(entityId)

            --memberSource = memberGroup:GetSourceById(entityId)
            winRoleGrid:SetData(icon, level)
        end
    end

    self.RewardList.gameObject:SetActiveEx(winData.RewardGoodsList ~= nil and #winData.RewardGoodsList > 0)
    self.PanelAssist.gameObject:SetActiveEx(winData.RewardGoodsList == nil or #winData.RewardGoodsList <= 0)
    -- 奖励
    if winData.RewardGoodsList ~= nil and #winData.RewardGoodsList > 0 then
        self.RewardList.gameObject:SetActiveEx(true)
        local rewards = XRewardManager.FilterRewardGoodsList(winData.RewardGoodsList)
        rewards = XRewardManager.MergeAndSortRewardGoodsList(rewards)
        local rewardGo = nil
        local rewardGrid = nil
        for _, item in ipairs(rewards) do
            rewardGo = CS.UnityEngine.Object.Instantiate(self.GridReward)
            rewardGrid = XUiGridCommon.New(self, rewardGo)
            rewardGrid.Transform:SetParent(self.PanelRewardContent, false)
            rewardGrid:Refresh(item, nil, nil, true)
            rewardGo.gameObject:SetActiveEx(false)
            table.insert(self.GridRewardList, rewardGrid)
        end
    else
        self.RewardList.gameObject:SetActiveEx(false)
    end
    -- 积分
    if winData.RewardGoodsList == nil or #winData.RewardGoodsList <= 0 then
        --self.PanelAssist.gameObject:SetActiveEx(true)
        --self.TxtAssist.text = CsXTextManager.GetText("ReformSettleScoreText", winData.SettleData.ReformFightResult.Score)
        --local maxScore = stage:GetPressureHistory()
        --self.TxtAssistMax.gameObject:SetActiveEx(winData.SettleData.ReformFightResult.Score < maxScore)
        --self.TxtAssistMax.text = CsXTextManager.GetText("ReformSettleMaxScoreTip", maxScore)
    else
    end
    self.PanelAssist.gameObject:SetActiveEx(false)
    local txtLevelName = XPlayer.IsHonorLevelOpen() and CS.XTextManager.GetText("HonorLevel") or nil
    if self.TxtLevelTitle and txtLevelName then
        self.TxtLevelTitle.text = txtLevelName
    end
    self.TxtPlayerLevel.text = XPlayer.GetLevelOrHonorLevel()
    self:PlayRewardAnimation()

    local isMatchExtraStar = winData.SettleData.ReformFightResult.ExtraStar ~= 0--stage:IsExtraStar()
    --XUiReformTool.UpdateStar(self, stage:GetStarHistory(false), stage:GetStarMax(), isMatchExtraStar)
    local isEasyMode
    if isUnlockHardMode then
        isEasyMode = false
    end
    local starMax = stage:GetStarMax(isEasyMode)
    local pressure = winData.SettleData.ReformFightResult.Score

    XUiReformTool.UpdateStar(self, 0, starMax, false)
    --self._Star2Play = stage:GetStarHistory(false)
    self._Star2Play = XDataCenter.Reform2ndManager.GetStarByPressure(pressure, winData.StageId)
    self._IsMatchExtraStar2Play = isMatchExtraStar
    self._GoalDesc = stage:GetGoalDesc()
    if isMatchExtraStar then
        self.PanelCondition.gameObject:SetActiveEx(false)
    else
        self:UpdateConditionExtraStar(isMatchExtraStar)
    end
    self._StarMax = stage:GetStarMax()
    self._Stage = stage
end

--######################## 私有方法 ########################

function XUiReformCombatSettleWin:RegisterUiEvents()
    self.BtnBlock.CallBack = function()
        self:Close()
    end
end

-- 奖励动画
function XUiReformCombatSettleWin:PlayRewardAnimation()
    XLuaUiManager.SetMask(true)
    local delay = XDataCenter.FubenManager.SettleRewardAnimationDelay
    local interval = XDataCenter.FubenManager.SettleRewardAnimationInterval
    -- 没有奖励则直接播放第二个动画
    if #self.GridRewardList == 0 then
        XScheduleManager.ScheduleOnce(function()
            self:PlaySecondAnimation()
        end, delay)
        return
    end
    self.RewardAnimationIndex = 1
    XScheduleManager.Schedule(function()
        if XTool.UObjIsNil(self.GridRewardList[self.RewardAnimationIndex].GameObject) then
            return
        end
        if self.RewardAnimationIndex == #self.GridRewardList then
            self:PlayReward(self.RewardAnimationIndex, function()
                self:PlaySecondAnimation()
            end)
        else
            self:PlayReward(self.RewardAnimationIndex)
        end
        self.RewardAnimationIndex = self.RewardAnimationIndex + 1
    end, interval, #self.GridRewardList, delay)
end

function XUiReformCombatSettleWin:PlaySecondAnimation()
    --self:PlayAnimation("AnimEnable2", function()
    XLuaUiManager.SetMask(false)
    XDataCenter.FunctionEventManager.UnLockFunctionEvent()
    self.IsFirst = false;
    --end)
end

function XUiReformCombatSettleWin:PlayReward(index, cb)
    self.GridRewardList[index].GameObject:SetActiveEx(true)
    self:PlayAnimation("GridReward", cb)
end

function XUiReformCombatSettleWin:Update()
    if self._StarStatus == STAR_STATUS.END then
        return
    end
    if self._StarStatus == STAR_STATUS.START then
        self._StarStatus = STAR_STATUS.WAIT
        return
    end
    if self._StarStatus == STAR_STATUS.PLAY then
        if self._Star >= self._Star2Play then
            if self._IsMatchExtraStar2Play == self._IsMatchExtraStar then

                -- 最后播放解锁新难度
                if self._IsUnlockHardMode then
                    self._IsUnlockHardMode = false
                    self._TimerDelayStar = XScheduleManager.ScheduleOnce(function()
                        local starHardMode = self._StarMax
                        local star = self.UiStar[starHardMode]
                        star.Root.gameObject:SetActiveEx(true)
                        XUiReformTool.SetStarEnable(star, false)
                    end, 200)
                    local name = self._Stage:GetName()
                    XUiManager.PopupLeftTip(name, XUiHelper.GetText("ReformDiffUnlockedTip", ""))
                end
                self._StarStatus = STAR_STATUS.END
                return
            end

            self._IsMatchExtraStar = true
            local star = self.UiStarExtra
            if star then
                XUiReformTool.SetStarEnable(star, true)
                self._StarStatus = STAR_STATUS.WAIT
            end
            self:UpdateConditionExtraStar(self._IsMatchExtraStar)
            return
        end

        self._Star = self._Star + 1
        local index = self._Star
        local star = self.UiStar[index]
        if star then
            XUiReformTool.SetStarEnable(star, true)
            self._StarStatus = STAR_STATUS.WAIT
        end
    end

    if self._StarStatus == STAR_STATUS.WAIT then
        self._Time = self._Time + CS.UnityEngine.Time.deltaTime
        if self._Time > self._DurationPlay then
            self._Time = 0
            self._StarStatus = STAR_STATUS.PLAY
        end
    end
end

function XUiReformCombatSettleWin:UpdateConditionExtraStar(isMatchExtraStar)
    self.PanelCondition.gameObject:SetActiveEx(true)
    if isMatchExtraStar then
        if self.GridCondition then
            self.GridCondition.gameObject:SetActiveEx(true)
        end
        if self.GridDis then
            self.GridDis.gameObject:SetActiveEx(false)
        end
        self.Text.text = self._GoalDesc
    else
        if self.GridCondition then
            self.GridCondition.gameObject:SetActiveEx(false)
        end
        if self.GridDis then
            self.GridDis.gameObject:SetActiveEx(true)
            self.Text2.text = self._GoalDesc
        end
    end
end

return XUiReformCombatSettleWin