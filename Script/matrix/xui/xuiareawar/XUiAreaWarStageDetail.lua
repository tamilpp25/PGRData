--关卡详情界面
local XUiAreaWarStageDetail = XLuaUiManager.Register(XLuaUi, "UiAreaWarStageDetail")

function XUiAreaWarStageDetail:OnAwake()
    local closeFunc = handler(self, self.OnClickBtnClose)
    for i = 1, 4 do
        self["BtnCloseMask" .. i].CallBack = closeFunc
    end
    self.BtnFight.CallBack = function()
        self:OnClickBtnFight()
    end
    self.BtnDispatch.CallBack = function()
        self:OnClickBtnDispatch()
    end
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    XDataCenter.ItemManager.AddCountUpdateListener(
        {
            XDataCenter.ItemManager.ItemId.AreaWarCoin,
            XDataCenter.ItemManager.ItemId.AreaWarActionPoint
        },
        handler(self, self.UpdateAssets),
        self.AssetActivityPanel
    )

    self.GridCommon.gameObject:SetActiveEx(false)

    self.RepeatChallengeCountDown = XAreaWarConfigs.GetEndTimeTip(1)
end

---@param isRepeatChallenge boolean 是否为鞭尸期
--------------------------
function XUiAreaWarStageDetail:OnStart(blockId, isRepeatChallenge, closeCb)
    self.BlockId = blockId
    self.IsRepeatChallenge = isRepeatChallenge
    self.CloseCb = closeCb
    self.RewardGrids = {}

    self:InitView()
end

function XUiAreaWarStageDetail:OnEnable()
    self:UpdateView()
    self:UpdateAssets()
end

function XUiAreaWarStageDetail:OnDisable()
    self:StopRepeatTimer()
end

function XUiAreaWarStageDetail:OnGetEvents()
    return {
        XEventId.EVENT_AREA_WAR_BLOCK_STATUS_CHANGE
    }
end

function XUiAreaWarStageDetail:OnNotify(evt, ...)
    if evt == XEventId.EVENT_AREA_WAR_BLOCK_STATUS_CHANGE then
        self:UpdateView()
    end
end

function XUiAreaWarStageDetail:UpdateAssets()
    self.AssetActivityPanel:Refresh(
        {
            XDataCenter.ItemManager.ItemId.AreaWarCoin,
            XDataCenter.ItemManager.ItemId.AreaWarActionPoint
        },
        {
            XDataCenter.ItemManager.ItemId.AreaWarActionPoint
        }
    )
end

function XUiAreaWarStageDetail:InitView()
    local blockId = self.BlockId

    --背景图片
    self.RImgIcon:SetRawImage(XAreaWarConfigs.GetBlockShowTypeStageBgByBlockId(blockId))

    if self.IsRepeatChallenge then
        self.RewardGrid = self.RewardGrid or XUiGridCommon.New(self, self.Grid128)
        local dispatchList = XAreaWarConfigs.GetBlockDetachWhippingPeriodRewardItems(self.BlockId)
        self.RewardGrid:Refresh(dispatchList[1])

        self.FightRewardGrid = self.FightRewardGrid or XUiGridCommon.New(self, self.Grid128Fight)
        local fightList = XAreaWarConfigs.GetBlockRepeatChallengeRewardItems(self.BlockId)
        self.FightRewardGrid:Refresh(fightList[1])
    else
        local rewardItemId = XDataCenter.AreaWarManager.GetCoinItemId()
        --派遣奖励（固定只显示货币图标，读不到真实奖励数量）
        self.RewardGrid = self.RewardGrid or XUiGridCommon.New(self, self.Grid128)
        self.RewardGrid:Refresh(rewardItemId)
        --作战奖励（固定只显示货币图标，读不到真实奖励数量）
        self.FightRewardGrid = self.FightRewardGrid or XUiGridCommon.New(self, self.Grid128Fight)
        self.FightRewardGrid:Refresh(rewardItemId)

        --全服奖励展示
        local block = XDataCenter.AreaWarManager.GetBlock(blockId)
        local rewards = block:GetRewardItems()
        for index, item in ipairs(rewards) do
            local grid = self.RewardGrids[index]
            if not grid then
                local go = index == 1 and self.GridCommon or CSObjectInstantiate(self.GridCommon, self.RewardParent)
                grid = XUiGridCommon.New(self, go)
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

    self.TxtName.text = XAreaWarConfigs.GetBlockName(blockId)
    self.TxtNumber.text = XAreaWarConfigs.GetBlockNameEn(blockId)

    if self.TxtFight then
        self.TxtFight.text = XAreaWarConfigs.GetStageDetailFightTip(self.IsRepeatChallenge)
    end
end

function XUiAreaWarStageDetail:UpdateView()
    local blockId = self.BlockId
    local isRepeatChallenge = self.IsRepeatChallenge
    
    local isFighting = XDataCenter.AreaWarManager.IsBlockFighting(blockId)
    
    local enable = (isFighting or isRepeatChallenge)
    
    self.BtnFight:SetDisable(not enable, enable)
    self.BtnDispatch:SetDisable(not enable, enable)
    
    
    self.PanelRepeat.gameObject:SetActiveEx(isRepeatChallenge)
    self.PanelReward.gameObject:SetActiveEx(not isRepeatChallenge)
    self.TextRepeatTime.gameObject:SetActiveEx(false)

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
            self.TextRepeatTime.gameObject:SetActiveEx(true)
            self:StartRepeatTimer()
        end
    end
end

function XUiAreaWarStageDetail:StartRepeatTimer()
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

function XUiAreaWarStageDetail:StopRepeatTimer()
    if not XTool.IsNumberValid(self.RepeatTimer) then
        return
    end
    XScheduleManager.UnSchedule(self.RepeatTimer)
    self.RepeatTimer = nil
end

function XUiAreaWarStageDetail:UpdateRepeat()
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

function XUiAreaWarStageDetail:OnClickBtnClose()
    self:Close()
    if self.CloseCb then
        self.CloseCb(self.BlockId)
    end
end

function XUiAreaWarStageDetail:OnClickBtnFight()
    XDataCenter.AreaWarManager.TryEnterFight(self.BlockId)
end

function XUiAreaWarStageDetail:OnClickBtnDispatch()
    XDataCenter.AreaWarManager.OpenUiDispatch(self.BlockId)
end
