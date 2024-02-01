---@class XUiDoubleTowersSettlement:XLuaUi
local XUiDoubleTowersSettlement = XLuaUiManager.Register(XLuaUi, "UiDoubleTowersSettlement")

function XUiDoubleTowersSettlement:Ctor()
    self._AnimationTimer = false
    self.IsFirst = true
    self.GridRewardList = {}
end

function XUiDoubleTowersSettlement:OnStart(data)
    self.IsFirst = true
    self:RegisterBtnClick()
    self:InitInfo(data)
    XLuaUiManager.SetMask(true)
    self:PlayRewardAnimation()
end

function XUiDoubleTowersSettlement:OnEnable()
    if not self.IsFirst then
        XLuaUiManager.SetMask(true)
        self._AnimationTimer =
            XScheduleManager.ScheduleOnce(
            function()
                self._AnimationTimer = false
                self:PlaySecondAnimation()
            end,
            0
        )
    end
end

function XUiDoubleTowersSettlement:OnDisable()
    if self._AnimationTimer then
        XScheduleManager.UnSchedule(self._AnimationTimer)
        self._AnimationTimer = false
    end
end

function XUiDoubleTowersSettlement:OnDestroy()
    XDataCenter.AntiAddictionManager.EndFightAction()
end

function XUiDoubleTowersSettlement:InitInfo(data)
    local stageId = data.StageId
    self:SetStageName(stageId)

    if
        data.SettleData and data.SettleData.DoubleTowerFightResult and
            XDataCenter.DoubleTowersManager.IsSpecialStage(stageId)
     then
        self:SetWinStreak(data.SettleData.DoubleTowerFightResult.WinCount or 1)
    else
        self:SetWinStreak(false)
    end

    if data.SettleData then
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        local passTimeLimit = stageCfg.PassTimeLimit
        local leftTime = data.SettleData.LeftTime
        self:SetTime(math.max(0, passTimeLimit - leftTime))
    end

    if data.SettleData and data.SettleData.NpcHpInfo then
        for i = 1, #data.SettleData.NpcHpInfo do
            local CharacterId = data.SettleData.NpcHpInfo[i].CharacterId
            if CharacterId and CharacterId ~= 0 then
                self:SetRoleImg(CharacterId)
            end
        end
    end

    self:InitRewardList(data.RewardGoodsList)
end

-- 关卡名
function XUiDoubleTowersSettlement:SetStageName(stageId)
    self.TxtModeName.text = XDoubleTowersConfigs.GetStageName(stageId)
end

-- 连胜次数
function XUiDoubleTowersSettlement:SetWinStreak(value)
    if value then
        self.TxtWinCount.text = value
        self.WinCount2.gameObject:SetActiveEx(true)
    else
        self.WinCount2.gameObject:SetActiveEx(false)
    end
end

-- 通关记录
function XUiDoubleTowersSettlement:SetTime(seconds)
    self.TxtRecord.text = XUiHelper.GetTime(seconds)
end

-- 角色半身图
function XUiDoubleTowersSettlement:SetRoleImg(roldId)
    local path = XMVCA.XCharacter:GetCharHalfBodyBigImage(roldId)
    self.RImgRole:SetRawImage(path)
end

function XUiDoubleTowersSettlement:RegisterBtnClick()
    self:RegisterClickEvent(self.BtnLeft, self.OnBtnLeftClick)
    self:RegisterClickEvent(self.BtnRight, self.OnBtnRightClick)
end

function XUiDoubleTowersSettlement:OnBtnLeftClick()
    XLuaUiManager.RunMain()
end

function XUiDoubleTowersSettlement:OnBtnRightClick()
    self:Close()
end

--region copy from UiSettleWin
-- 奖励动画
function XUiDoubleTowersSettlement:PlayRewardAnimation()
    local delay = XDataCenter.FubenManager.SettleRewardAnimationDelay
    local interval = XDataCenter.FubenManager.SettleRewardAnimationInterval
    local this = self

    -- 没有奖励则直接播放第二个动画
    -- 暂时没有动画，先跳过
    if true or not self.GridRewardList or #self.GridRewardList == 0 then
        XScheduleManager.ScheduleOnce(
            function()
                this:PlaySecondAnimation()
            end,
            delay
        )
        return
    end

    self.RewardAnimationIndex = 1
    XScheduleManager.Schedule(
        function()
            if this.RewardAnimationIndex == #self.GridRewardList then
                this:PlayReward(
                    this.RewardAnimationIndex,
                    function()
                        this:PlaySecondAnimation()
                    end
                )
            else
                this:PlayReward(this.RewardAnimationIndex)
            end
            this.RewardAnimationIndex = this.RewardAnimationIndex + 1
        end,
        interval,
        #self.GridRewardList,
        delay
    )
end

-- 第二个动画
function XUiDoubleTowersSettlement:PlaySecondAnimation()
    local this = self
    -- self:PlayAnimation(
    -- "AnimEnable2",
    -- function()
    XLuaUiManager.SetMask(false)
    XDataCenter.FunctionEventManager.UnLockFunctionEvent()
    self.IsFirst = false
    -- end
    -- )
end

-- 物品奖励列表
function XUiDoubleTowersSettlement:InitRewardList(rewardGoodsList)
    rewardGoodsList = rewardGoodsList or {}
    local rewards = XRewardManager.MergeAndSortRewardGoodsList(rewardGoodsList)
    for i, item in ipairs(rewards) do
        local ui =
            self["GridReward" .. i] or
            CS.UnityEngine.Object.Instantiate(self.GridReward1, self.GridReward1.transform.parent)
        local grid = XUiGridCommon.New(self, ui)
        grid:Refresh(item, nil, nil, true)
        -- 暂时没有动画，先跳过
        -- grid.GameObject:SetActive(false)
        table.insert(self.GridRewardList, grid)
    end
    for i = #rewards + 1, 99 do
        local ui = self["GridReward" .. i]
        if not ui then
            break
        end
        ui.gameObject:SetActiveEx(false)
    end
end

function XUiDoubleTowersSettlement:PlayCondition(index, cb)
    self:PlayAnimation("GirdCond", cb)
end

function XUiDoubleTowersSettlement:PlayReward(index, cb)
    self.GridRewardList[index].GameObject:SetActive(true)
    self:PlayAnimation("GridReward", cb)
end
--endregion copy from UiSettleWin

return XUiDoubleTowersSettlement

-- return {
--             SettleData = settleData,
--             StageId = settleData.StageId,
--             RewardGoodsList = settleData.RewardGoodsList,
--             CharExp = beginData.CharExp,
--             RoleExp = beginData.RoleExp,
--             RoleLevel = beginData.RoleLevel,
--             RoleCoins = beginData.RoleCoins,
--             StarsMap = starsMap,
--             UrgentId = settleData.UrgentEnventId,
--             ClientAssistInfo = AssistSuccess and beginData.AssistPlayerData or nil,
--             FlopRewardList = settleData.FlopRewardList,
--             PlayerList = beginData.PlayerList,
--         }
