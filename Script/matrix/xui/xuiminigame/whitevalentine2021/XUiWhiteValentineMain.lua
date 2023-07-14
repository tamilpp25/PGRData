--白色情人节约会活动主界面
local XUiWhiteValentineMain = XLuaUiManager.Register(XLuaUi, "UiWhitedayMain")
local XUiCommonAsset = require("XUi/XUiCommon/XUiCommonAsset")
function XUiWhiteValentineMain:OnAwake()
    XTool.InitUiObject(self)
end

function XUiWhiteValentineMain:OnStart()
    self.GameController = XDataCenter.WhiteValentineManager.GetGameController()
    self:InitButtons()
    self:InitPanels()
end

function XUiWhiteValentineMain:OnEnable()
    self:SetGameTimer()
    self:SetTimer()
    self:AddEventListeners()
    XDataCenter.WhiteValentineManager.OnEnterActivity()
end

function XUiWhiteValentineMain:OnDisable()
    self:StopTimer()
    self:RemoveEventListeners()
end

function XUiWhiteValentineMain:OnDestroy()
    self:StopTimer()
    self:RemoveEventListeners()
end
--================
--设置页面计时器
--================
function XUiWhiteValentineMain:SetTimer()
    self:StopTimer()
    self.Timer = XScheduleManager.ScheduleForever(function()
            self:SetEnergyTimer()
            self:SetGameTimer()
        end, XScheduleManager.SECOND, 0)
end
--================
--设置体力恢复计时器
--================
function XUiWhiteValentineMain:SetEnergyTimer()
    if self.GameController:CheckIsMaxEnergy() then return end
    local now = XTime.GetServerNowTimestamp()
    if self.GameController:GetNextEnergyRecoveryTimeStamp() == 0 then
        return
    elseif self.GameController:GetNextEnergyRecoveryTimeStamp() == now then
        self.GameController:AddOneEnergy()
        self.GameController:CalculateNextEnergyRecoveryTimeStamp()
    elseif self.GameController:GetNextEnergyRecoveryTimeStamp() < now then
        self.GameController:CalculateDeltaEnergyRecoveryTimeStamp()
    end
end
--================
--设置活动倒计时
--================
function XUiWhiteValentineMain:SetGameTimer()
    local endTimeSecond = self.GameController:GetActivityEndTime()
    local now = XTime.GetServerNowTimestamp()
    local leftTime = endTimeSecond - now
    self.TxtTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
    if leftTime <= 0 then
        self:OnGameEnd()
    end
end
--================
--停止计时器
--================
function XUiWhiteValentineMain:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiWhiteValentineMain:OnGetEvents()
    return { XEventId.EVENT_WHITEVALENTINE_ENCOUNTER_CHARA,
             XEventId.EVENT_WHITEVALENTINE_INVITE_CHARA,
             XEventId.EVENT_WHITEVALENTINE_REFRESH_PLACE,
             XEventId.EVENT_WHITEVALENTINE_OPEN_PLACE }
end

function XUiWhiteValentineMain:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_WHITEVALENTINE_ENCOUNTER_CHARA then
        self.ButtonPanel:RefreshPanel()
        XLuaUiManager.Open("UiWhitedayObtain", args[1], XDataCenter.WhiteValentineManager.StoryType.Encounter)
    elseif evt == XEventId.EVENT_WHITEVALENTINE_INVITE_CHARA then
        self.ButtonPanel:RefreshPanel()
        XLuaUiManager.Open("UiWhitedayObtain", args[1], XDataCenter.WhiteValentineManager.StoryType.Invite)
    elseif evt == XEventId.EVENT_WHITEVALENTINE_REFRESH_PLACE then
        self.ButtonPanel:RefreshPanel()
        self.EventPanel:RefreshPlaces(args[1])
    elseif evt == XEventId.EVENT_WHITEVALENTINE_OPEN_PLACE then
        self.EventPanel:OpenNewPlaces(args[1])
    end
end
--================
--初始化按钮
--================
function XUiWhiteValentineMain:InitButtons()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self.BtnHelp.CallBack = function() self:OnBtnHelpClick() end
end
--================
--返回按钮
--================
function XUiWhiteValentineMain:OnBtnBackClick()
    self:Close()
end
--================
--主界面按钮
--================
function XUiWhiteValentineMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end
--================
--帮助按钮
--================
function XUiWhiteValentineMain:OnBtnHelpClick()
    XUiManager.ShowHelpTip("WhiteValentine2021Help")
end
--================
--初始化面板
--================
function XUiWhiteValentineMain:InitPanels()
    self:InitButtonPanel()
    self:InitEventPanel()
    self:InitAssetPanel()
end
--================
--初始化功能按钮面板
--================
function XUiWhiteValentineMain:InitButtonPanel()
    local ButtonPanel = require("XUi/XUiMiniGame/WhiteValentine2021/XUiWhiteValenMainButtonPanel")
    self.ButtonPanel = ButtonPanel.New(self, self.PanelButton)
end
--================
--初始化地点事件面板
--================
function XUiWhiteValentineMain:InitEventPanel()
    local EventPanel = require("XUi/XUiMiniGame/WhiteValentine2021/XUiWhiteValenMainEventPanel")
    self.EventPanel = EventPanel.New(self, self.PanelEvent)
end
--================
--初始化右上角的资源道具面板
--================
function XUiWhiteValentineMain:InitAssetPanel()
    local AssetsList = {}
    local assetItem1 = {
            ShowType = XUiCommonAsset.ShowType.BagItem,
            ItemId = self.GameController:GetContributionItemId(),
        }
    table.insert(AssetsList, assetItem1)
    local assetItem2 = {
            ShowType = XUiCommonAsset.ShowType.BagItem,
            ItemId = self.GameController:GetCoinItemId()
        }
    table.insert(AssetsList, assetItem2)
    local assetItem3 = {
            ShowType = XUiCommonAsset.ShowType.RecoverPoint,
            Icon = self.GameController:GetEnergyIconPath(),
            GetCountFunc = function() return self.GameController:GetEnergy() end,
            GetMaxCountFunc = function() return self.GameController:GetMaxEnergy() end,
            ChangeEventId = XEventId.EVENT_WHITEVALENTINE_ENERGY_REFRESH
        }
    table.insert(AssetsList, assetItem3)
    local AssetPanel = require("XUi/XUiCommon/XUiCommonAssetPanel")
    self.AssetPanel = AssetPanel.New(self.PanelAsset, AssetsList)
    self.TxtEnergyRecover.text = CS.XTextManager.GetText("WhiteValentineEnergyCountDown", XUiHelper.GetTime(self.GameController:GetEnergyRecoverySpeed(), XUiHelper.TimeFormatType.CHATEMOJITIMER))
end
--================
--活动结束时处理
--================
function XUiWhiteValentineMain:OnGameEnd()
    if self.IsReseting then return end
    self.IsReseting = true
    self:StopTimer()
    XLuaUiManager.RunMain()
    XUiManager.TipMsg(CS.XTextManager.GetText("CommonActivityEnd"))
end
--================
--添加事件
--================
function XUiWhiteValentineMain:AddEventListeners()
    self.ButtonPanel:AddEventListeners()
    self.EventPanel:AddEventListeners()
end
--================
--移除事件
--================
function XUiWhiteValentineMain:RemoveEventListeners()
    self.ButtonPanel:RemoveEventListeners()
    self.EventPanel:RemoveEventListeners()
end