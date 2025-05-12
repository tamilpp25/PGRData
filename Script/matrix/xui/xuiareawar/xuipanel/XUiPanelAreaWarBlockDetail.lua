local XUiPanelArea = require("XUi/XUiMission/XUiPanelArea")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

---@class XUiPanelAreaWarBlockDetail : XUiNode 正常关卡详情
---@field 
local XUiPanelAreaWarBlockDetail = XClass(XUiNode, "XUiPanelAreaWarBlockDetail")

function XUiPanelAreaWarBlockDetail:DoAwake()
    self.BtnFight.CallBack = function()
        self:OnClickBtnFight()
    end
    self.BtnDispatch.CallBack = function()
        self:OnClickBtnDispatch()
    end
    
    self.GridCommon.gameObject:SetActiveEx(false)
    self.RepeatChallengeCountDown = XAreaWarConfigs.GetEndTimeTip(1)
end

function XUiPanelAreaWarBlockDetail:OnStart(blockId, isRepeatChallenge, closeCb)
    self.BlockId = blockId
    self.IsRepeatChallenge = isRepeatChallenge
    self.CloseCb = closeCb
    self.RewardGrids = {}
    self:DoAwake()
    self:InitView()
end

function XUiPanelAreaWarBlockDetail:OnEnable()
    self:UpdateView()
end

function XUiPanelAreaWarBlockDetail:OnDisable()
    self:StopRepeatTimer()
end

function XUiPanelAreaWarBlockDetail:OnDestroy()
    if self.CloseCb then
        self.CloseCb(self.BlockId)
    end
end

function XUiPanelAreaWarBlockDetail:InitView()
    local blockId = self.BlockId

    --背景图片
    self.RImgIcon:SetRawImage(XAreaWarConfigs.GetBlockShowTypeStageBgByBlockId(blockId))
    self.TxtType.text = XAreaWarConfigs.GetBlockLevelDesc(blockId)
    self.ImgType:SetSprite(XAreaWarConfigs.GetBlockLevelTypeIcon(blockId))

    if self.IsRepeatChallenge then
        self.RewardGrid = self.RewardGrid or XUiGridCommon.New(self.Parent, self.Grid128)
        local dispatchList = XAreaWarConfigs.GetBlockDetachWhippingPeriodRewardItems(self.BlockId)
        self.RewardGrid:Refresh(dispatchList[1])

        self.FightRewardGrid = self.FightRewardGrid or XUiGridCommon.New(self.Parent, self.Grid128Fight)
        local fightList = XAreaWarConfigs.GetBlockRepeatChallengeRewardItems(self.BlockId)
        self.FightRewardGrid:Refresh(fightList[1])
    else
        local rewardItemId = XDataCenter.AreaWarManager.GetCoinItemId()
        --派遣奖励（固定只显示货币图标，读不到真实奖励数量）
        self.RewardGrid = self.RewardGrid or XUiGridCommon.New(self.Parent, self.Grid128)
        self.RewardGrid:Refresh(rewardItemId)
        --作战奖励（固定只显示货币图标，读不到真实奖励数量）
        self.FightRewardGrid = self.FightRewardGrid or XUiGridCommon.New(self.Parent, self.Grid128Fight)
        self.FightRewardGrid:Refresh(rewardItemId)

        --全服奖励展示
        local block = XDataCenter.AreaWarManager.GetBlock(blockId)
        local rewards = block:GetRewardItems()
        for index, item in ipairs(rewards) do
            local grid = self.RewardGrids[index]
            if not grid then
                local go = index == 1 and self.GridCommon or 
                        CSObjectInstantiate(self.GridCommon, self.RewardParent)
                grid = XUiGridCommon.New(self.Parent, go)
                self.RewardGrids[index] = grid
            end

            grid:Refresh(item)
            --奖励已发放
            local isFinished = XDataCenter.AreaWarManager.IsBlockClear(blockId)
            grid:SetReceived(isFinished)
            grid.GameObject:SetActiveEx(true)
        end
        for index = #rewards + 1, #self.RewardGrids do
            self.RewardGrids[index].GameObject:SetActiveEx(false)
        end
    end

    --作战消耗
    local icon = XDataCenter.AreaWarManager.GetActionPointItemIcon()
    self.RImgCost:SetRawImage(icon)
    self.RImgCostFight:SetRawImage(icon)
    --派遣消耗
    local costCount = XAreaWarConfigs.GetBlockDetachActionPoint(blockId)
    self.BtnDispatch:SetNameByGroup(0, costCount)
    --战斗消耗
    local costCount = XAreaWarConfigs.GetBlockActionPoint(blockId)
    self.BtnFight:SetNameByGroup(0, costCount)
    self.IsOpenMultiChallenge = XDataCenter.AreaWarManager.GetPersonal():IsOpenMultiChallenge()
    self.BtnFight:SetNameByGroup(1, XAreaWarConfigs.GetBtnChallengeText(self.IsOpenMultiChallenge))

    self.TxtName.text = XAreaWarConfigs.GetBlockName(blockId)
    self.TxtNumber.text = XAreaWarConfigs.GetBlockNameEn(blockId)

    local txtFight = self.TxtFight
    if txtFight then
        txtFight.text = XAreaWarConfigs.GetStageDetailFightTip(self.IsRepeatChallenge)
    end
end

function XUiPanelAreaWarBlockDetail:UpdateView()
    local blockId = self.BlockId
    local isRepeatChallenge = self.IsRepeatChallenge

    local isFighting = XDataCenter.AreaWarManager.IsBlockFighting(blockId)

    local enable = (isFighting or isRepeatChallenge)

    self.BtnFight:SetDisable(not enable, enable)
    self.BtnDispatch:SetDisable(not enable, enable)


    self.PanelRepeat.gameObject:SetActiveEx(isRepeatChallenge)
    self.PanelReward.gameObject:SetActiveEx(not isRepeatChallenge)
    local txtRepeatTime = self.TextRepeatTime
    txtRepeatTime.gameObject:SetActiveEx(false)

    if isRepeatChallenge then
        local chapterId = XDataCenter.AreaWarManager.GetFirstNotOpenChapterId()
        if XTool.IsNumberValid(chapterId) then
            local timeId = XAreaWarConfigs.GetChapterTimeId(chapterId)
            self.ChapterStartTime = XFunctionManager.GetStartTimeByTimeId(timeId)
        else
            self.ChapterStartTime = XDataCenter.AreaWarManager.GetEndTime()
        end
        if self.ChapterStartTime then
            self:UpdateRepeat()
            txtRepeatTime.gameObject:SetActiveEx(true)
            self:StartRepeatTimer()
        end
    end
end

function XUiPanelAreaWarBlockDetail:StartRepeatTimer()
    if XTool.IsNumberValid(self.RepeatTimer) or not self.ChapterStartTime then
        return
    end
    self.RepeatTimer = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.GameObject) then
            self:StopRepeatTimer()
            return
        end
        self:UpdateRepeat()
    end, XScheduleManager.SECOND)
end

function XUiPanelAreaWarBlockDetail:StopRepeatTimer()
    if not XTool.IsNumberValid(self.RepeatTimer) then
        return
    end
    XScheduleManager.UnSchedule(self.RepeatTimer)
    self.RepeatTimer = nil
end

function XUiPanelAreaWarBlockDetail:UpdateRepeat()
    local timeOfNow = XTime.GetServerNowTimestamp()
    local remainder = math.max(0, self.ChapterStartTime - timeOfNow)
    self.TextRepeatTime.text = string.format(self.RepeatChallengeCountDown, XUiHelper.GetTime(remainder, XUiHelper.TimeFormatType.SHOP_REFRESH))

    --倒计时结束
    if remainder <= 0 then
        self.IsRepeatChallenge = XDataCenter.AreaWarManager.IsRepeatChallengeTime()
        if self.IsRepeatChallenge then
            XLog.Error("异常，鞭尸倒计时结束后，仍为鞭尸期，请检查TimeId配置")
            self.IsRepeatChallenge = false
        end
        self:UpdateView()
        self:StopRepeatTimer()
    end
end

function XUiPanelAreaWarBlockDetail:OnClickBtnFight()
    if self.IsOpenMultiChallenge then
        local personal = XDataCenter.AreaWarManager.GetPersonal()
        local ratio = XAreaWarConfigs.GetBlockActionPoint(self.BlockId)
        local itemId = XDataCenter.ItemManager.ItemId.AreaWarActionPoint
        local onConfirm = function(count) 
            personal:SetSelectLocal(count)
            XDataCenter.AreaWarManager.TryEnterFight(self.BlockId, count)
        end
        XLuaUiManager.Open("UiAreaWarRepeatChallenge", personal:GetSelectSkipNum(ratio), 
                personal:GetSkipNum(), itemId, ratio, nil, nil, onConfirm)
        return
    end
    XDataCenter.AreaWarManager.TryEnterFight(self.BlockId, 1)
end

function XUiPanelAreaWarBlockDetail:OnClickBtnDispatch()
    XDataCenter.AreaWarManager.OpenUiDispatch(self.BlockId, false)
end

return XUiPanelAreaWarBlockDetail