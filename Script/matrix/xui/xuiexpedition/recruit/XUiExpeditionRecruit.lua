local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
--虚像地平线招募主界面
local XUiExpeditionRecruit = XLuaUiManager.Register(XLuaUi, "UiExpeditionRecruit")
local XUiExpeditionRecruitComboPanel = require("XUi/XUiExpedition/Recruit/XUiExpeditionComboPanel/XUiExpeditionRecruitComboPanel")
local XUiExpeditionRecruitMemberPanel = require("XUi/XUiExpedition/Recruit/XUiExpeditionMemberPanel/XUiExpeditionRecruitMemberPanel")
local XUiExpeditionRecruitCoreMemberPanel = require("XUi/XUiExpedition/Recruit/XUiExpeditionMemberPanel/XUiExpeditionRecruitCoreMemberPanel")
local XUiExpeditionRecruitShopPanel = require("XUi/XUiExpedition/Recruit/XUiExpeditionRoomChar/XUiExpeditionRecruitShopPanel")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local UiExpeditionRoleDetails = "UiExpeditionRoleDetails"

function XUiExpeditionRecruit:OnAwake()
    XTool.InitUiObject(self)
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:AddListener()
    self:SetComboList()
    self:SetCharacterList()
    self:Set3DCharacter()
    self:CheckDefault()
end

function XUiExpeditionRecruit:OnEnable()
    self.TxtNumber.text = XDataCenter.ExpeditionManager.GetRecruitNumInfoString()
    XDataCenter.ItemManager.AddCountUpdateListener(XDataCenter.ItemManager.ItemId.Coin, function() self:RefreshRecruitNumber() end, self.Ui)
    self:SetRecruitRefreshTimer()
    self:Refresh()
end

function XUiExpeditionRecruit:CheckDefault()
    local defaultTeamId = XDataCenter.ExpeditionManager.GetDefaultTeamId()
    if defaultTeamId and defaultTeamId > 0 then

    else
        XLuaUiManager.Open("UiExpeditionDefaultTeam", handler(self, self.OnDefaultTeamClose))
    end
end

function XUiExpeditionRecruit:OnDefaultTeamClose()
    self:Close()
end

function XUiExpeditionRecruit:OnDisable()
    self:StopTimer()
end

function XUiExpeditionRecruit:OnDestroy()
    self:StopTimer()
end

function XUiExpeditionRecruit:Refresh()
    self:RefreshRecruitLevel()
    self:RefreshRecruitNumber()
end

function XUiExpeditionRecruit:RefreshRecruitLevel()
    self.TxtRecruitLevel.text = CS.XTextManager.GetText("ExpeditionRecruitLevel", XDataCenter.ExpeditionManager.GetRecruitLevel())
end

function XUiExpeditionRecruit:RefreshRecruitNumber()
    local canRecruit = XDataCenter.ExpeditionManager.GetCanRecruit()
    local canBuy = XDataCenter.ExpeditionManager.GetCanBuyDraw()
    self.TxtNumber.gameObject:SetActiveEx(canRecruit or not canBuy)
    self.TxtBuy.gameObject:SetActiveEx((not canRecruit) and canBuy)
    if canRecruit or not canBuy then
        self.TxtNumber.text = XDataCenter.ExpeditionManager.GetRecruitNumInfoString()
    else
        local price = XDataCenter.ExpeditionManager.GetBuyDrawInfo()
        local currentCoin = XDataCenter.ItemManager.GetCoinsNum()
        if currentCoin and currentCoin < price then
            self.TxtBuy.text = CS.XTextManager.GetText("ExpeditionCoinNotEnoughBuyDraw", price)
        else
            self.TxtBuy.text = price
        end
    end
    self.TxtTime.gameObject:SetActiveEx(not XDataCenter.ExpeditionManager.GetRecruitTimeFull())
end

function XUiExpeditionRecruit:OnGetEvents()
    return {
        XEventId.EVENT_EXPEDITION_RECRUIT_REFRESH,
        XEventId.EVENT_EXPEDITION_MEMBERLIST_CHANGE,
        XEventId.EVENT_EXPEDITION_RECRUITTIME_REFRESH,
        XEventId.EVENT_ACTIVITY_ON_RESET,
        XEventId.EVENT_EXPEDITION_SELECT_DEFAULT_TEAM_SUCCESS,
        XEventId.EVENT_EXPEDITION_RECRUIT_FASHION_UPDATE,
    }
end

function XUiExpeditionRecruit:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_EXPEDITION_RECRUIT_REFRESH then
        self.Character3DPanel:UpdateData(args[1])
        self:Refresh()
    elseif evt == XEventId.EVENT_EXPEDITION_MEMBERLIST_CHANGE then
        self.CharacterList:UpdateData()
        self.CoreCharacterPanel:UpdateData()
        self.ComboList:UpdateData()
    elseif evt == XEventId.EVENT_EXPEDITION_RECRUITTIME_REFRESH then
        self:Refresh()
        local isRecruitLevelUp = args[1]
        if isRecruitLevelUp then
            XUiManager.TipMsg(CS.XTextManager.GetText("ExpeditionRecruitLevelUp"))
            self.CharacterList:UpdateData()
            self.CoreCharacterPanel:UpdateData()
        end
    elseif evt == XEventId.EVENT_ACTIVITY_ON_RESET then
        if args[1] ~= XDataCenter.FubenManager.StageType.Expedition then return end
        self:StopTimer()
        XLuaUiManager.RunMain()
        XUiManager.TipMsg(CS.XTextManager.GetText("ExpeditionOnClose"))
    elseif evt == XEventId.EVENT_EXPEDITION_SELECT_DEFAULT_TEAM_SUCCESS then
        self:SetRecruitRefreshTimer()
        self:Refresh()
        self.CharacterList:UpdateData()
        self.CoreCharacterPanel:UpdateData()
        self.ComboList:UpdateData()
    elseif evt == XEventId.EVENT_EXPEDITION_RECRUIT_FASHION_UPDATE then
        self.Character3DPanel:UpdateData(false)
    end
end

function XUiExpeditionRecruit:AddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnRefresh, self.OnBtnRefreshClick)
    self:BindHelpBtn(self.BtnHelp, "ExpeditionMainHelp")
    self:RegisterClickEvent(self.BtnRecruitDisplay, self.OnBtnRecruitDisplayClick)
    self:RegisterClickEvent(self.BtnSwitch, self.OnBtnSwitchClick)
end

function XUiExpeditionRecruit:OnBtnBackClick()
    self:Close()
end

function XUiExpeditionRecruit:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiExpeditionRecruit:OnBtnRefreshClick()
    XDataCenter.ExpeditionManager.RefreshRecruit()
end

function XUiExpeditionRecruit:OnBtnRecruitDisplayClick()
    XLuaUiManager.Open("UiExpeditionPublicity")
end
-- 切换核心队伍
function XUiExpeditionRecruit:OnBtnSwitchClick()
    XLuaUiManager.Open("UiExpeditionDefaultTeam")
end

function XUiExpeditionRecruit:SetComboList()
    self.ComboList = XUiExpeditionRecruitComboPanel.New(self.SViewComboList, self)
    self.ComboList:UpdateData()
end

function XUiExpeditionRecruit:SetCharacterList()
    self.CharacterList = XUiExpeditionRecruitMemberPanel.New(self.FetterCharacterList, self)
    self.CharacterList:UpdateData()

    self.CoreCharacterPanel = XUiExpeditionRecruitCoreMemberPanel.New(self.CoreCharacterList, self)
    self.CoreCharacterPanel:UpdateData()
end

function XUiExpeditionRecruit:Set3DCharacter()
    local uiModelRoot = self.UiModelGo.transform
    local models = {
        [1] = XUiPanelRoleModel.New(uiModelRoot:FindTransform("PanelModelCase1"), self.Name, nil, true, nil, true, true),
        [2] = XUiPanelRoleModel.New(uiModelRoot:FindTransform("PanelModelCase2"), self.Name, nil, true, nil, true, true),
        [3] = XUiPanelRoleModel.New(uiModelRoot:FindTransform("PanelModelCase3"), self.Name, nil, true, nil, true, true),
    }
    self.Character3DPanel = XUiExpeditionRecruitShopPanel.New(self.PanelChar, self, models)
    self.Character3DPanel:UpdateData()
end

function XUiExpeditionRecruit:SetRecruitRefreshTimer()
    self:StopTimer()
    self:SetRecruitRefreshTime()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:SetRecruitRefreshTime()
    end, XScheduleManager.SECOND, 0)
end

function XUiExpeditionRecruit:SetRecruitRefreshTime()
    local endTimeSecond = XDataCenter.ExpeditionManager.GetNextRecruitAddTime()
    local now = XTime.GetServerNowTimestamp()
    local leftTime = endTimeSecond - now
    if leftTime < 0 then leftTime = 0 end
    self.TxtTime.text = string.format("%s%s", XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.DEFAULT), CS.XTextManager.GetText("ExpeditionRecruitTimeCountDown"))
end
--停止计时器
function XUiExpeditionRecruit:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiExpeditionRecruit:OpenRoleDetailsPanel(eChara, type, gridIndex, onOpenBefore, onOpenAfter)
    if not XLuaUiManager.IsUiShow(UiExpeditionRoleDetails) then
        self:OpenOneChildUi(UiExpeditionRoleDetails)
    else
        return
    end
    if onOpenBefore then
        onOpenBefore()
    end
    self:FindChildUiObj(UiExpeditionRoleDetails):RefreshData(eChara, type, gridIndex, onOpenAfter)
end