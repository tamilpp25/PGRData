local CsXTextManager = CS.XTextManager

--######################## XUiWinRoleGrid ########################
local XUiWinRoleGrid = XClass(nil, "XUiWinRoleGrid")

function XUiWinRoleGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

-- data : XReformMemberSource
function XUiWinRoleGrid:SetData(data)
    self.RImgIcon:SetRawImage(data:GetBigHeadIcon())
    self.TxtStar.text = data:GetStarLevel()
end

--######################## XUiReformCombatSettleWin ########################

local XUiReformCombatSettleWin = XLuaUiManager.Register(XLuaUi, "UiReformCombatSettleWin")

function XUiReformCombatSettleWin:OnAwake()
    self.GridWinRole.gameObject:SetActiveEx(false)
    self.GridReward.gameObject:SetActiveEx(false)
    self.GridRewardList = {}
    self.RewardAnimationIndex = 1
    self:RegisterUiEvents()
end

function XUiReformCombatSettleWin:OnStart(winData)
    local currDiff = winData.SettleData.ReformFightResult.CurrDiff
    local baseStage = XDataCenter.ReformActivityManager.GetBaseStage(winData.StageId)
    local evolvableStage = baseStage:GetEvolvableStageByDiffIndex(currDiff + 1)
    -- 名称
    self.TxtTitle.text = baseStage:GetName()
    -- 难度等级
    self.TxtDiffTitle.text = evolvableStage:GetName()
    -- 角色
    local teamData = evolvableStage:GetTeamData()
    local memberSource = nil
    local memberGroup = evolvableStage:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Member)
    local winRoleGo = nil
    local winRoleGrid = nil
    for _, sourceId in ipairs(teamData.SourceIdsInTeam) do
        memberSource = memberGroup:GetSourceById(sourceId)
        if memberSource then
            winRoleGo = CS.UnityEngine.Object.Instantiate(self.GridWinRole, self.PanelRoleContent)
            winRoleGo.gameObject:SetActiveEx(true)
            winRoleGrid = XUiWinRoleGrid.New(winRoleGo)
            winRoleGrid:SetData(memberSource)
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
        self.PanelAssist.gameObject:SetActiveEx(true)
        self.TxtAssist.text = CsXTextManager.GetText("ReformSettleScoreText", winData.SettleData.ReformFightResult.Score)
        local maxScore = evolvableStage:GetMaxScore()
        self.TxtAssistMax.gameObject:SetActiveEx(winData.SettleData.ReformFightResult.Score < maxScore)
        self.TxtAssistMax.text = CsXTextManager.GetText("ReformSettleMaxScoreTip", maxScore)
    else
        self.PanelAssist.gameObject:SetActiveEx(false)
    end
    local txtLevelName = XPlayer.IsHonorLevelOpen() and CS.XTextManager.GetText("HonorLevel") or nil
    if self.TxtLevelTitle and txtLevelName then
        self.TxtLevelTitle.text = txtLevelName
    end
    self.TxtPlayerLevel.text = XPlayer.GetLevelOrHonorLevel()
    self:PlayRewardAnimation()
end

--######################## 私有方法 ########################

function XUiReformCombatSettleWin:RegisterUiEvents()
    self.BtnBlock.CallBack = function() self:Close() end
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
    self:PlayAnimation("AnimEnable2", function()
        XLuaUiManager.SetMask(false)
        XDataCenter.FunctionEventManager.UnLockFunctionEvent()
        self.IsFirst = false;
    end)
end

function XUiReformCombatSettleWin:PlayReward(index, cb)
    self.GridRewardList[index].GameObject:SetActiveEx(true)
    self:PlayAnimation("GridReward", cb)
end

return XUiReformCombatSettleWin