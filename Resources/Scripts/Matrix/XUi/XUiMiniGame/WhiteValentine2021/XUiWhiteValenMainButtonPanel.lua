-- 白色情人节约会活动主界面功能按钮面板
local XUiWhiteValenMainButtonPanel = XClass(nil, "XUiWhiteValenMainButtonPanel")

function XUiWhiteValenMainButtonPanel:Ctor(rootUi, ui)
    self.RootUi = rootUi
    XTool.InitUiObjectByUi(self, ui)
    self.GameController = XDataCenter.WhiteValentineManager.GetGameController()
    self:Init()
    self:RefreshPanel()
end

function XUiWhiteValenMainButtonPanel:Init()
    self:InitTaskBtn()
    self:InitPanelTaskBtn()
    self:InitEncounterBtn()
    self:InitInviteBtn()
    self.RedEvents = {}
    self:AddEventListeners()
    self:AddRedPointEvents()
end
--==================
--初始化任务按钮
--==================
function XUiWhiteValenMainButtonPanel:InitTaskBtn()
    self.BtnTask.CallBack = function()
        self:OnBtnTaskClick()
    end
end
--==================
--初始化偶遇按钮
--==================
function XUiWhiteValenMainButtonPanel:InitEncounterBtn()
    self.IconCoin:SetRawImage(self.GameController:GetCoinItemIcon())  
    self.BtnEncounter.CallBack = function()
        self:OnBtnEncounterClick()
    end
    self:RefreshEncounterBtn()
end
--==================
--刷新偶遇按钮提示文本
--==================
function XUiWhiteValenMainButtonPanel:RefreshEncounterBtn()
    if self.GameController:GetCoin() >= self.GameController:GetRandomMeetCostCoin() then
        self.TxtEncounterCost.text = self.GameController:GetRandomMeetCostCoin()
    else
        self.TxtEncounterCost.text = CS.XTextManager.GetText("WhiteValentineCoinNotEnoughStr", self.GameController:GetRandomMeetCostCoin())
    end
end
--==================
--初始化邀请按钮
--==================
function XUiWhiteValenMainButtonPanel:InitInviteBtn()   
    self.BtnInvite.CallBack = function()
        self:OnBtnInviteClick()
    end
    self:RefreshInviteBtn()
end
--==================
--刷新邀请按钮
--==================
function XUiWhiteValenMainButtonPanel:RefreshInviteBtn()
    self.TxtInviteCount.text = CS.XTextManager.GetText("WhiteValenDateInvite", self.GameController:GetInviteChance())
end

function XUiWhiteValenMainButtonPanel:InitPanelTaskBtn()
    self.BtnPanelTask.CallBack = function()
        self:OnBtnPanelTaskClick()
    end
end

function XUiWhiteValenMainButtonPanel:OnBtnTaskClick()
    XLuaUiManager.Open("UiWhitedayTask")
end

function XUiWhiteValenMainButtonPanel:OnBtnEncounterClick()
    if not self.GameController:CheckEncounterCoinEnough() then
        XUiManager.TipMsg(CS.XTextManager.GetText("WhiteValentineCoinNotEnough"))
        return
    end
    XUiManager.TipMsg(CS.XTextManager.GetText("WhiteValentineEncounterPreTip"), nil, function()
                if not self.GameController:CheckOutTeamCharaExist() then
                    XUiManager.TipMsgEnqueue(CS.XTextManager.GetText("WhiteValentineEncounterNoMemberTip"))
                else
                    XDataCenter.WhiteValentineManager.EncounterChara()
                end
            end)
end

function XUiWhiteValenMainButtonPanel:OnBtnInviteClick()
    if self.GameController:CheckCanInviteChara() then
        XLuaUiManager.Open("UiWhitedayInvite")
    else
        XUiManager.TipMsg(CS.XTextManager.GetText("WhiteValentineCantInvite"))
    end
end

function XUiWhiteValenMainButtonPanel:OnBtnPanelTaskClick()
    XLuaUiManager.Open("UiWhitedayTask")
end

function XUiWhiteValenMainButtonPanel:AddEventListeners()
    if self.ListenersAdded then return end
    self.ListenersAdded = true
    self:AddRedPointEvents()
    XEventManager.AddEventListener(XEventId.EVENT_WHITEVALENTINE_SHOW_PLACE, self.RefreshPanel, self)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.RefreshMission, self)
end

function XUiWhiteValenMainButtonPanel:RemoveEventListeners()
    if not self.ListenersAdded then return end
    self:RemoveRedPointEvents()
    XEventManager.RemoveEventListener(XEventId.EVENT_WHITEVALENTINE_SHOW_PLACE, self.RefreshPanel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.RefreshMission, self)
    self.ListenersAdded = false
end

function XUiWhiteValenMainButtonPanel:RefreshMission()
    local task = XDataCenter.TaskManager.GetWhiteValentineFirstNotAcheivedMission()
    if task and task.State ~= XDataCenter.TaskManager.TaskState.Finish then
        self.IconTaskComplete.gameObject:SetActiveEx(task.State == XDataCenter.TaskManager.TaskState.Achieved)
        local config = XDataCenter.TaskManager.GetTaskTemplate(task.Id)
        if task.State == XDataCenter.TaskManager.TaskState.Achieved then
            self.BtnPanelTask:SetName(CS.XTextManager.GetText("WhiteValentineBlueStr", config.Desc))
        else
            self.BtnPanelTask:SetName(config.Desc)
        end
    else
        self.IconTaskComplete.gameObject:SetActiveEx(true)
        self.BtnPanelTask:SetName(CS.XTextManager.GetText("WhiteValentineMissionComplete"))
    end
end

function XUiWhiteValenMainButtonPanel:RefreshPanel()
    self:RefreshEncounterBtn()
    self:RefreshInviteBtn()
    self:RefreshMission()
end

--================
--注册页面红点事件
--================
function XUiWhiteValenMainButtonPanel:AddRedPointEvents()
    if self.AlreadyAddRed then return end
    self.AlreadyAddRed = true
    table.insert(self.RedEvents, XRedPointManager.AddRedPointEvent(self.BtnInvite, self.CheckInviteRedDot, self, { XRedPointConditions.Types.CONDITION_WHITEVALENTINE2021_INVITE }))
    table.insert(self.RedEvents, XRedPointManager.AddRedPointEvent(self.BtnEncounter, self.CheckEncounterRedDot, self, { XRedPointConditions.Types.CONDITION_WHITEVALENTINE2021_ENCOUNTER }))
    table.insert(self.RedEvents, XRedPointManager.AddRedPointEvent(self.BtnTask, self.CheckTaskRedDot, self, { XRedPointConditions.Types.CONDITION_WHITEVALENTINE2021_TASK }))
end
--================
--注销页面红点事件
--================
function XUiWhiteValenMainButtonPanel:RemoveRedPointEvents()
    if not self.AlreadyAddRed then return end
    for _, eventId in pairs(self.RedEvents) do
        XRedPointManager.RemoveRedPointEvent(eventId)
    end
    self.RedEvents = {}
    self.AlreadyAddRed = false
end
--================
--检查邀约按钮红点
--================
function XUiWhiteValenMainButtonPanel:CheckInviteRedDot(count)
    self.BtnInvite:ShowReddot(count >= 0)
end
--================
--检查偶遇按钮红点
--================
function XUiWhiteValenMainButtonPanel:CheckEncounterRedDot(count)
    self.BtnEncounter:ShowReddot(count >= 0)
end
--================
--检查任务按钮红点
--================
function XUiWhiteValenMainButtonPanel:CheckTaskRedDot(count)
    self.BtnTask:ShowReddot(count >= 0)
    self:RefreshMission()
end
return XUiWhiteValenMainButtonPanel