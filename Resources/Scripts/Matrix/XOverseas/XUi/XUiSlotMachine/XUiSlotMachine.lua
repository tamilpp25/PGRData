local CSXTextManagerGetText = CS.XTextManager.GetText
local CSXScheduleManager = CS.XScheduleManager
local tablePack = table.pack

local XUiSlotMachineRewardPanel = require("XOverseas/XUi/XUiSlotMachine/XUiSlotMachineRewardPanel")
local XUiSlotMachinePanel = require("XOverseas/XUi/XUiSlotMachine/XUiSlotMachinePanel")
local XUiSlotMachineTipsPanel = require("XOverseas/XUi/XUiSlotMachine/XUiSlotMachineTipsPanel")

local XUiSlotMachine = XLuaUiManager.Register(XLuaUi, "UiSlotmachine")

function XUiSlotMachine:OnAwake()
    self.RewardPanel = XUiSlotMachineRewardPanel.New(self, self.RewardBg)
    self.MachinePanel = XUiSlotMachinePanel.New(self, self.PanelSlotmachine)
    self.TipsPanel = XUiSlotMachineTipsPanel.New(self, self.PanelTips)
end

function XUiSlotMachine:OnStart()
    self:AutoAddListener()
    local machineId = XDataCenter.SlotMachineManager.GetCurMachineId()
    self:Refresh(machineId)
end

function XUiSlotMachine:OnEnable()
    self.BtnTask:ShowReddot(XDataCenter.SlotMachineManager.CheckTaskCanTakeByAllType(self.CurMachineEntity:GetId()))
    self:StartActivityTimer()
end

function XUiSlotMachine:OnDisable()
    self:StopActivityTimer()
end

function XUiSlotMachine:OnDestroy()
    XEventManager.UnBindEvent(self)
end

function XUiSlotMachine:AutoAddListener()
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.BtnStart.CallBack = function() self:OnBtnStartClick() end
    self.BtnNextMachine.CallBack = function() self:OnBtnNextMachineClick() end
    self.BtnRules.CallBack = function() self:OnBtnRulesClick() end
    self.BtnTask.CallBack = function() self:OnBtnTaskClick() end
    self.BtnObtain.CallBack = function() self:OnBtnObtainClick() end
end

function XUiSlotMachine:OnGetEvents()
    return {
        XEventId.EVENT_SLOT_MACHINE_STARTED,
        XEventId.EVENT_SLOT_MACHINE_GET_REWARD,
        XEventId.EVENT_SLOT_MACHINE_FINISH_TASK,
    }
end

function XUiSlotMachine:OnNotify(evt, ...)
    local args = tablePack(...)
    if evt == XEventId.EVENT_SLOT_MACHINE_STARTED then
        self.RaycastCover.gameObject:SetActiveEx(true)
        self.EffectPinmu.gameObject:SetActiveEx(false) -- 关闭屏幕特效
        self:PlayAnimation("SlotmachineEnable", function()
            self.RaycastCover.gameObject:SetActiveEx(false)
            self.HidePanel.gameObject:SetActiveEx(false)
            self.EffectFloor.gameObject:SetActiveEx(true) -- 底部流光特效
            self.MachinePanel:StartRoll(args[1], function()
                self.EffectDajiang.gameObject:SetActiveEx(false)
                if XDataCenter.SlotMachineManager.CheckIconListIsPrix(args[1]) then
                    CSXScheduleManager.ScheduleOnce(function()
                        self.EffectDajiang.gameObject:SetActiveEx(true)
                        CSXScheduleManager.ScheduleOnce(function()
                            self.EffectFloor.gameObject:SetActiveEx(false) -- 底部流光特效
                            self:ShowObtainpointsTips(args[2])
                        end, 1100)
                    end, 600)
                else
                    CSXScheduleManager.ScheduleOnce(function()
                        self.EffectFloor.gameObject:SetActiveEx(false) -- 底部流光特效
                        self:ShowObtainpointsTips(args[2])
                    end, 1000)
                end
            end)
        end)
    elseif evt == XEventId.EVENT_SLOT_MACHINE_GET_REWARD then
        self.RewardPanel:Refresh(self.CurMachineEntity:GetId())
    elseif evt == XEventId.EVENT_SLOT_MACHINE_FINISH_TASK then
        self.BtnTask:ShowReddot(XDataCenter.SlotMachineManager.CheckTaskCanTakeByAllType(self.CurMachineEntity:GetId()))
    end
end

function XUiSlotMachine:OnBtnStartClick()
    if self.CurMachineEntity then
        local machineState = XDataCenter.SlotMachineManager.CheckSlotMachineState(self.CurMachineEntity:GetId())
        if machineState == XSlotMachineConfigs.SlotMachineState.Locked then
            XUiManager.TipError(CSXTextManagerGetText("SlotMachineIsLocked"))
        elseif machineState == XSlotMachineConfigs.SlotMachineState.Finish then
            XUiManager.TipError(CSXTextManagerGetText("SlotMachineIsFinish"))
        else
            XDataCenter.SlotMachineManager.StartSlotMachine(self.CurMachineEntity:GetId())
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
    self:OpenChildUi("UiSlotmachineRules", self)
end

function XUiSlotMachine:OnBtnTaskClick()
    self:OpenChildUi("UiSlotmachineTask", self)
end

function XUiSlotMachine:OnBtnObtainClick()
    self.PanelObtainpointsTips.gameObject:SetActiveEx(false)
    self.HidePanel.gameObject:SetActiveEx(true)
    self:RefreshOnFinishRoll()
    self:PlayAnimation("SlotmachineDisable", function()
        self.EffectPinmu.gameObject:SetActiveEx(true) -- 打开屏幕特效
    end)
end

function XUiSlotMachine:Refresh(machineId)
    self.CurMachineEntity = XDataCenter.SlotMachineManager.GetSlotMachineDataEntityById(machineId)
    self:RefreshBg()
    self:RefreshTitle()
    self:RefreshAssetPanel()
    self:RefreshBtnStart()
    self:RefreshBtnNextMachine()
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
    if self.CurMachineEntity then
        self.BgImage:SetRawImage(self.CurMachineEntity:GetBgImage())
    end
end

function XUiSlotMachine:RefreshTitle()
    if self.CurMachineEntity then
        self.TxtTitle.text = self.CurMachineEntity:GetName()
        self.TxtTimeDes.text = CSXTextManagerGetText("SlotMachineTimeTextDesc")
        self.BtnTask:ShowReddot(XDataCenter.SlotMachineManager.CheckTaskCanTakeByAllType(self.CurMachineEntity:GetId()))
    end
end

function XUiSlotMachine:RefreshAssetPanel()
    if self.CurMachineEntity then
        self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, self.CurMachineEntity:GetConsumeItemId())
        if XDataCenter.SlotMachineManager.GetSlotMachineActExchangeType() == XSlotMachineConfigs.ExchangeType.OnlyTask then
            XUiHelper.RegisterClickEvent(self, self.AssetPanel.BtnBuyJump1, function()
                self:OnBtnTaskClick()
            end)
        end
    end
end

function XUiSlotMachine:RefreshBtnStart()
    if self.CurMachineEntity then
        local machineState = XDataCenter.SlotMachineManager.CheckSlotMachineState(self.CurMachineEntity:GetId())
        if machineState == XSlotMachineConfigs.SlotMachineState.Locked then
            self.BtnStart:SetDisable(true)
            self.BtnStart:SetName(CSXTextManagerGetText("SlotMachineBtnStartLockName"))
            self.ConsumeCount.text = self.CurMachineEntity:GetConsumeCount()
        else
            self.BtnStart:SetDisable(false)
            self.BtnStart:SetName(CSXTextManagerGetText("SlotMachineBtnStartUnLockName"))
            if XDataCenter.SlotMachineManager.CheckConsumeItemIsEnough(self.CurMachineEntity:GetId()) then
                self.ConsumeCount.text = self.CurMachineEntity:GetConsumeCount()
            else
                self.ConsumeCount.text = string.format("%s%s%s", "<color=#FF0F0FFF>", self.CurMachineEntity:GetConsumeCount(), "</color>")
            end
        end

        self.ConsumeImage:SetRawImage(XDataCenter.ItemManager.GetItemIcon(self.CurMachineEntity:GetConsumeItemId()))
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

function XUiSlotMachine:ShowObtainpointsTips(addScore)
    if self.CurMachineEntity then
        self.PanelObtainpointsTips.gameObject:SetActiveEx(true)
        self.TxtScore.text = addScore
        self:PlayAnimation("TipsEnable")
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

function XUiSlotMachine:StartActivityTimer()
    local startTime, endTime = XDataCenter.SlotMachineManager.GetActivityTime()
    local nowTime = XTime.GetServerNowTimestamp()
    self.TxtTime.text = XUiHelper.GetTime(endTime - nowTime, XUiHelper.TimeFormatType.ACTIVITY)
    if nowTime < startTime then
        XUiManager.TipMsg(CSXTextManagerGetText("SlotMachineTimeNotOpen"), XUiManager.UiTipType.Wrong, function()
            XLuaUiManager.RunMain()
        end)
    elseif nowTime > endTime then
        XUiManager.TipMsg(CSXTextManagerGetText("SlotMachineTimeEnd"), XUiManager.UiTipType.Wrong, function()
            XLuaUiManager.RunMain()
        end)
    else
        self.ActivityTimer = CSXScheduleManager.ScheduleForever(function()
            local time = XTime.GetServerNowTimestamp()
            if time > endTime then
                XUiManager.TipError(CSXTextManagerGetText("SlotMachineTimeEnd"))
                self:StopActivityTimer()
                XLuaUiManager.RunMain()
                return
            end
            self.TxtTime.text = XUiHelper.GetTime(endTime - time, XUiHelper.TimeFormatType.ACTIVITY)
        end, CSXScheduleManager.SECOND, 0)
    end
end

function XUiSlotMachine:StopActivityTimer()
    if self.ActivityTimer then
        CSXScheduleManager.UnSchedule(self.ActivityTimer)
        self.ActivityTimer = nil
    end
end