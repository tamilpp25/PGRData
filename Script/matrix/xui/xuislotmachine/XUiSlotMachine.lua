local XUiSlotMachineRewardPanel = require("XUi/XUiSlotMachine/XUiSlotMachineRewardPanel")
local XUiSlotMachinePanel = require("XUi/XUiSlotMachine/XUiSlotMachinePanel")
local XUiSlotMachineTipsPanel = require("XUi/XUiSlotMachine/XUiSlotMachineTipsPanel")

---@class XUiSlotMachine : XLuaUi
---@field RewardPanel XUiSlotMachineRewardPanel
---@field MachinePanel XUiSlotMachinePanel
---@field TipsPanel XUiSlotMachineTipsPanel
local XUiSlotMachine = XLuaUiManager.Register(XLuaUi, "UiSlotmachine")

local TargetRockTimes = {
    Once = 1, -- 一次
    Ten = 10, -- 十次
}

function XUiSlotMachine:OnAwake()
    self:AutoAddListener()

    self.TargetRockPanel = {
        [TargetRockTimes.Once] = {
            Button = self.BtnStart,
            Count = self.ConsumeCount,
            Image = self.ConsumeImage,
        },
        [TargetRockTimes.Ten] = {
            Button = self.BtnStart10,
            Count = self.ConsumeCount10,
            Image = self.ConsumeImage10,
        }
    }
end

function XUiSlotMachine:OnStart()
    self.RewardPanel = XUiSlotMachineRewardPanel.New(self, self.RewardBg)
    self.MachinePanel = XUiSlotMachinePanel.New(self, self.PanelSlotmachine)
    self.TipsPanel = XUiSlotMachineTipsPanel.New(self, self.PanelTips)

    local machineId = XDataCenter.SlotMachineManager.GetCurMachineId()
    self:Refresh(machineId)

    -- 开启自动关闭检查
    local _, endTime = XDataCenter.SlotMachineManager.GetActivityTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XDataCenter.SlotMachineManager.OnActivityEnd()
        else
            self:UpdateTimer()
        end
    end)
end

function XUiSlotMachine:OnEnable()
    self.Super.OnEnable(self)
    self:UpdateTimer()
    self:RefreshRedPoint()

    self.UpdateTimerId = XScheduleManager.ScheduleForeverEx(function()
        self:OnUpdate()
    end, 500)
end

function XUiSlotMachine:OnDisable()
    if XTool.IsNumberValid(self.UpdateTimerId) then
        XScheduleManager.UnSchedule(self.UpdateTimerId)
        self.UpdateTimerId = 0
    end
end

function XUiSlotMachine:OnDestroy()
    XEventManager.UnBindEvent(self)
end

function XUiSlotMachine:OnUpdate()
    if self.RewardPanel then
        self.RewardPanel:OnUpdate()
    end
end

function XUiSlotMachine:AutoAddListener()
    self.BtnBack.CallBack = function()
        self:Close()
    end
    self.BtnMainUi.CallBack = function()
        XLuaUiManager.RunMain()
    end
    self.BtnStart.CallBack = function()
        self:OnBtnStartClick()
    end
    self.BtnStart10.CallBack = function()
        self:OnBtnStart10Click()
    end
    self.BtnNextMachine.CallBack = function()
        self:OnBtnNextMachineClick()
    end
    self.BtnRules.CallBack = function()
        self:OnBtnRulesClick()
    end
    self.BtnTask.CallBack = function()
        self:OnBtnTaskClick()
    end
    self.BtnObtain.CallBack = function()
        self:OnBtnObtainClick()
    end
    self.BtnSkip.CallBack = function()
        self:OnBtnSkipClick()
    end
end

function XUiSlotMachine:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_TASK_SYNC,
    }
end

function XUiSlotMachine:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FINISH_TASK or evt == XEventId.EVENT_TASK_SYNC then
        self:RefreshRedPoint()
    end
end

function XUiSlotMachine:OnBtnStartClick()
    self:BtnStartClicked(TargetRockTimes.Once)
end

function XUiSlotMachine:OnBtnStart10Click()
    self:BtnStartClicked(TargetRockTimes.Ten)
end

function XUiSlotMachine:BtnStartClicked(targetRockTimes)
    if self.CurMachineEntity then
        local machineState = XDataCenter.SlotMachineManager.CheckSlotMachineState(self.CurMachineEntity:GetId())
        if machineState == XSlotMachineConfigs.SlotMachineState.Locked then
            XUiManager.TipText("SlotMachineIsLocked")
        elseif machineState == XSlotMachineConfigs.SlotMachineState.Finish then
            XUiManager.TipText("SlotMachineIsFinish")
        else
            XDataCenter.SlotMachineManager.StartSlotMachine(self.CurMachineEntity:GetId(), targetRockTimes, function(rockResults)
                self:DrawCallBack(rockResults, targetRockTimes)
            end)
        end
    end
end

function XUiSlotMachine:OnBtnNextMachineClick()
    if self.CurMachineEntity then
        self:Refresh(XDataCenter.SlotMachineManager.GetNextMachineId(self.CurMachineEntity:GetId()))
        self:PlayAnimation("QieHuan")
    end
end

function XUiSlotMachine:OnBtnRulesClick()
    if not XLuaUiManager.IsUiShow("UiSlotmachineRules") then
        self:OpenOneChildUi("UiSlotmachineRules")
    end
    self:FindChildUiObj("UiSlotmachineRules"):Refresh(self.CurMachineEntity:GetId())
end

function XUiSlotMachine:OnBtnTaskClick()
    self:OpenOneChildUi("UiSlotmachineTask", self)
end

function XUiSlotMachine:OnBtnObtainClick()
    self:PlayAnimationWithMask("TipsDisable", function()
        self.PanelObtainpointsTips.gameObject:SetActiveEx(false)
        self:RefreshOnFinishRoll()
    end)
    if self.IsSkipAnim then
        return
    end
    self.HidePanel.gameObject:SetActiveEx(true)
    self:PlayAnimation("SlotmachineDisable", function()
        self.EffectPinmu.gameObject:SetActiveEx(true) -- 打开屏幕特效
    end)
end

function XUiSlotMachine:OnBtnSkipClick()
    self.IsSkipAnim = self.BtnSkip:GetToggleState()
    XDataCenter.SlotMachineManager.SaveSkipAnimationValue(self.IsSkipAnim)
end

function XUiSlotMachine:Refresh(machineId)
    self.CurMachineEntity = XDataCenter.SlotMachineManager.GetSlotMachineDataEntityById(machineId)
    self:RefreshBg()
    self:RefreshTitle()
    self:RefreshRedPoint()
    self:RefreshAssetPanel()
    self:RefreshBtnStart()
    self:RefreshBtnNextMachine()
    self:RefreshBtnSkip()
    self.RewardPanel:Refresh(machineId, true)
    self.MachinePanel:Refresh(machineId)
    self.TipsPanel:Refresh(machineId)
    self:AddItemUpdateListener()
    self.Effect01.gameObject:SetActiveEx(false)
    self.Effect02.gameObject:SetActiveEx(false)
    self.Effect03.gameObject:SetActiveEx(false)
    self.EffectDajiang.gameObject:SetActiveEx(false)
end

function XUiSlotMachine:RefreshOnFinishRoll()
    if self.CurMachineEntity then
        local machineId = self.CurMachineEntity:GetId()
        self:RefreshBtnStart()
        self.RewardPanel:Refresh(machineId)
        self.TipsPanel:Refresh(machineId)
    end
end

function XUiSlotMachine:RefreshBg()
    --if self.CurMachineEntity then
    --    self.BgImage:SetRawImage(self.CurMachineEntity:GetBgImage())
    --end
    if self.CurMachineEntity then
        self.BgImage1.gameObject:SetActiveEx(false)
        self.BgImage2.gameObject:SetActiveEx(false)
        self["BgImage" .. self.CurMachineEntity:GetId()].gameObject:SetActiveEx(true)
    end
end

function XUiSlotMachine:RefreshTitle()
    if self.CurMachineEntity then
        self.TxtTitle.text = self.CurMachineEntity:GetName()
        self.TxtTimeDes.text = XUiHelper.GetText("SlotMachineTimeTextDesc")
    end
end

function XUiSlotMachine:RefreshRedPoint()
    if self.CurMachineEntity then
        local taskRedPoint = XDataCenter.SlotMachineManager.CheckTaskCanTakeByMachineId(self.CurMachineEntity:GetId())
        self.BtnTask:ShowReddot(taskRedPoint)
    end
end

function XUiSlotMachine:RefreshAssetPanel()
    if self.CurMachineEntity then
        local itemId = self.CurMachineEntity:GetConsumeItemId()
        if not self.AssetPanel then
            self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ itemId }, self.PanelSpecialTool, self)
            self.AssetPanel:SetRootUiName(self.Name)
        else
            self.AssetPanel:Refresh({ itemId })
        end
    end
end

function XUiSlotMachine:RefreshBtnStart()
    if self.CurMachineEntity then
        local machineState = XDataCenter.SlotMachineManager.CheckSlotMachineState(self.CurMachineEntity:GetId())
        for _, v in pairs(TargetRockTimes) do
            local panel = self.TargetRockPanel[v]
            local totalNeedCount = self.CurMachineEntity:GetConsumeCount() * v
            if machineState == XSlotMachineConfigs.SlotMachineState.Running then
                panel.Button:SetDisable(false)
                panel.Button:SetName(XUiHelper.GetText("SlotMachineBtnStartUnLockName", XTool.ConvertNumberString(v)))
            else
                panel.Button:SetDisable(true)
                panel.Button:SetName(XUiHelper.GetText("SlotMachineBtnStartLockName", XTool.ConvertNumberString(v)))
            end
            if XDataCenter.SlotMachineManager.CheckConsumeItemIsEnough(self.CurMachineEntity:GetId(), v) then
                panel.Count.text = totalNeedCount
            else
                panel.Count.text = string.format("%s%s%s", "<color=#FF0F0FFF>", totalNeedCount, "</color>")
            end
            panel.Image:SetRawImage(XDataCenter.ItemManager.GetItemIcon(self.CurMachineEntity:GetConsumeItemId()))
        end
    end
end

function XUiSlotMachine:RefreshBtnNextMachine()
    local machineEntityList = XDataCenter.SlotMachineManager.GetSlotMachineDataEntityList()
    if #machineEntityList <= 1 then
        self.BtnNextMachine.gameObject:SetActiveEx(false)
        return
    end
    if self.CurMachineEntity then
        self.BtnNextMachine:SetSprite(self.CurMachineEntity:GetNextMachineBtnImage())
        self.BtnNextMachine:SetName(self.CurMachineEntity:GetNextMachineBtnText())
        local nextMachineId = XDataCenter.SlotMachineManager.GetNextMachineId(self.CurMachineEntity:GetId())
        self.BtnNextMachine:ShowReddot(XDataCenter.SlotMachineManager.CheckHasRewardCanTake(nextMachineId))
    end
end

function XUiSlotMachine:ShowObtainpointsTips(rockResults, isRecoveryEnd)
    if self.CurMachineEntity then
        self:RefreshTemplateGrids(self.GridGain, rockResults, self.PanelGain, nil, "GridGainList", function(grid, data)
            grid.ImgIcon:SetSprite(XSlotMachineConfigs.GetSlotMachinesIconTemplateById(data.IconList[1]).IconImage)
            grid.TxtScore.text = data.Score
            local isPrix = XDataCenter.SlotMachineManager.CheckIconListIsPrix(data.IconList)
            grid.EffectHight.gameObject:SetActiveEx(isPrix)
        end)
        self.PanelObtainpointsTips.gameObject:SetActiveEx(true)
        self:PlayAnimation("TipsEnable", function()
            if isRecoveryEnd then
                XUiManager.TipText("SlotMachineRecoveryEndTips")
            end
        end)
    end
end

function XUiSlotMachine:AddItemUpdateListener()
    if self.CurMachineEntity then
        XEventManager.UnBindEvent(self)
        XDataCenter.ItemManager.AddCountUpdateListener(self.CurMachineEntity:GetConsumeItemId(), function()
            self:RefreshBtnStart()
        end, self)
    end
end

function XUiSlotMachine:RefreshBtnSkip()
    self.IsSkipAnim = XDataCenter.SlotMachineManager.GetSkipAnimationValue()
    self.BtnSkip:SetButtonState(self.IsSkipAnim and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiSlotMachine:UpdateTimer()
    if XTool.UObjIsNil(self.TxtTime) then
        return
    end
    local endTime = self.AutoCloseEndTime
    local leftTime = endTime - XTime.GetServerNowTimestamp()
    if leftTime <= 0 then
        leftTime = 0
    end
    self.TxtTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
end

-- 抽奖结果回调
function XUiSlotMachine:DrawCallBack(rockResults, targetRockTimes)
    -- 回收操作是否终止
    local isRecoveryEnd = targetRockTimes > 1
            and self.CurMachineEntity:GetTotalScore() >= self.CurMachineEntity:GetScoreLimit()
            and #rockResults < targetRockTimes
    if self.IsSkipAnim then
        self:ShowObtainpointsTips(rockResults, isRecoveryEnd)
        return
    end

    local asyncPlayAnim = asynTask(self.PlayAnimation, self)
    local asyncStartRoll = asynTask(self.MachinePanel.StartRollNew, self.MachinePanel)
    local asynWaitTime = asynTask(self.MachinePanel.AsynWaitTime, self.MachinePanel)
    RunAsyn(function()
        self.RaycastCover.gameObject:SetActiveEx(true)
        -- 关闭屏幕特效
        self.EffectPinmu.gameObject:SetActiveEx(false)
        -- 底部流光特效
        self.EffectFloor.gameObject:SetActiveEx(true)
        -- 奖励特效隐藏起来
        self.RewardPanel:SetRewardsEffectShow(false)
        local iconCardTmpCfgId = XDataCenter.SlotMachineManager.GetBestIconCfgId(rockResults)
        asyncPlayAnim("SlotmachineEnable")
        self.RaycastCover.gameObject:SetActiveEx(false)
        self.HidePanel.gameObject:SetActiveEx(false)
        -- 设置跳过状态
        self.MachinePanel:SetIsSkipActive(false)
        self.MachinePanel:SetBtnSkipActive(true)
        self.RewardPanel:SetRewardsEffectShow(true)
        for _, info in pairs(rockResults) do
            self.MachinePanel:SetShowCardSound(XDataCenter.SlotMachineManager.CheckIconListIsPrix(info.IconList))
            -- 播放翻拍动画
            self.MachinePanel:SetIconCardTmp(info.IconList[1])
            asyncPlayAnim("SlotmachineCardshow")
            asynWaitTime(1)

            if self.MachinePanel:GetIsSkipAnim() then
                break
            end
        end
        self.EffectFloor.gameObject:SetActiveEx(false)
        self.MachinePanel:SetBtnSkipActive(false)
        self:ShowObtainpointsTips(rockResults, isRecoveryEnd)
    end)
end

return XUiSlotMachine