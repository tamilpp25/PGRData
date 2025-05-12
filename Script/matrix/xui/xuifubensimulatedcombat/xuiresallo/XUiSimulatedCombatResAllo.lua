local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridRes =  require("XUi/XUiFubenSimulatedCombat/ChildItem/XUiGridRes")
local XUiPanelCombatMembers = require("XUi/XUiFubenSimulatedCombat/XUiResAllo/XUiPanelCombatMembers")
local XUiPanelCombatAdditions = require("XUi/XUiFubenSimulatedCombat/XUiResAllo/XUiPanelCombatAdditions")

local XUiSimulatedCombatResAllo = XLuaUiManager.Register(XLuaUi, "UiSimulatedCombatResAllo")

local CSXTextManagerGetText = CS.XTextManager.GetText

local PageIndex = {
    Member = 1,
    Addition = 2,
}
local CurrencyType = {
    Base = 1,
    Extra = 2,
}

function XUiSimulatedCombatResAllo:OnAwake()
    self.PayMethod = {
        [PageIndex.Member] = 1,
        [PageIndex.Addition] = 1,
    }
    self.TabBtns = {}
    self.SwitchEffect = {}
end

function XUiSimulatedCombatResAllo:OnEnable()
    XDataCenter.FubenSimulatedCombatManager.UpdateShopMapCache()
    self:Refresh()
end

function XUiSimulatedCombatResAllo:OnStart(stageInterId)
    self.StageInterId = stageInterId
    self.StageInterCfg = XFubenSimulatedCombatConfig.GetStageInterData(stageInterId)
    self.IsChallengeMode = self.StageInterCfg.Type == XFubenSimulatedCombatConfig.StageType.Challenge
    self.ActTemplate = XDataCenter.FubenSimulatedCombatManager.GetCurrentActTemplate()
    self.StageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageInterCfg.StageId)
    self.IsPassed =  self.StageInfo and self.StageInfo.Passed
    XDataCenter.FubenSimulatedCombatManager.SelectStageInter(stageInterId)

    self.ConsumeId1 = XDataCenter.FubenSimulatedCombatManager.GetCurrencyIdByNo(CurrencyType.Base)
    self.ConsumeId2 = XDataCenter.FubenSimulatedCombatManager.GetCurrencyIdByNo(CurrencyType.Extra)

    self:InitUiView()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self, true, nil, nil, true)
    self.AssetActivityPanel:SetQueryFunc(XDataCenter.FubenSimulatedCombatManager.GetCurrencyByItem)
    self.BtnGrpTab:Init({self.BtnMember,self.BtnBuff},function(index) self:SwitchTab(index) end)
    self.BtnGrpTab:SelectIndex(PageIndex.Member, false)
    self:SwitchTab(PageIndex.Member, true)
end

function XUiSimulatedCombatResAllo:OnGetEvents()
    return { XEventId.EVENT_FUBEN_SIMUCOMBAT_UPDATE,
             XEventId.EVENT_ACTIVITY_ON_RESET}
end

function XUiSimulatedCombatResAllo:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_FUBEN_SIMUCOMBAT_UPDATE then
        self:Refresh(...)
    elseif evt == XEventId.EVENT_ACTIVITY_ON_RESET then
        if args[1] ~= XDataCenter.FubenManager.StageType.SimulatedCombat then return end
        XDataCenter.FubenSimulatedCombatManager.OnActivityEnd()
    end
end

function XUiSimulatedCombatResAllo:SwitchTab(index, isFromOtherUi)
    if self.CurrentView == index then
        return
    else
        if not isFromOtherUi then
            self:PlayAnimation("QieHuan")
        end
        self.CurrentView = index
        
        self.ResList = XDataCenter.FubenSimulatedCombatManager.GetCurrentResList(self.CurrentView)
        self.DynamicTable:SetDataSource(self.ResList)
        self.DynamicTable:ReloadDataASync(1)

        self.PanelCombatAdditions.gameObject:SetActiveEx(index ~= PageIndex.Addition)
        self.PanelCombatMembers.gameObject:SetActiveEx(index ~= PageIndex.Member)
        if index == PageIndex.Member then
            self.PanelMemberTip.gameObject:SetActiveEx(true)
            self.TxtMemberTip.gameObject:SetActiveEx(not self.IsChallengeMode)
            self.PanelBuffTip.gameObject:SetActiveEx(false)
            self.PanelBuyAddition:UpdateView()
        elseif index == PageIndex.Addition then
            self.PanelMemberTip.gameObject:SetActiveEx(false)
            self.PanelBuffTip.gameObject:SetActiveEx(true)
            self.PanelBuyMember:UpdateView()
        end
        self:Refresh()
    end
end

function XUiSimulatedCombatResAllo:Refresh(isFullReload)
    if isFullReload then
        self.DynamicTable:ReloadDataASync()
    else
        for _, grid in pairs(self.DynamicTable:GetGrids()) do
            grid:ShowPrice()
        end
    end

    local cur, max = XDataCenter.FubenSimulatedCombatManager.GetMemberCount()
    if cur == max or self.IsChallengeMode then
        self.TxtMemberCount.text = CS.XTextManager.GetText("SimulatedCombatMemberSelection", cur, max)
    else
        self.TxtMemberCount.text = CS.XTextManager.GetText("SimulatedCombatMemberSeleNotEnough", cur, max)
    end
    
    local checkEnter = XDataCenter.FubenSimulatedCombatManager.CheckEnterRoom()
    self.BtnEnterRoom:SetButtonState(checkEnter and XUiButtonState.Normal or XUiButtonState.Disable)
    local checkBuy = XDataCenter.FubenSimulatedCombatManager.CheckBuyRes(self.CurrentView)
    self.BtnConfirm:SetButtonState(checkBuy and XUiButtonState.Normal or XUiButtonState.Disable)
    
    self.AssetActivityPanel:Refresh(self.ActTemplate.ConsumeIds)
    self:UpdatePayBill()
end

function XUiSimulatedCombatResAllo:UpdatePayBill()
    local togs = { self.BtnConsume1 }
    local bill = XDataCenter.FubenSimulatedCombatManager.CalcPriceCount(self.CurrentView)
    self.BtnConsume1:SetRawImage(XDataCenter.FubenSimulatedCombatManager.GetCurrencyIcon(CurrencyType.Base))
    local enough1 = XDataCenter.FubenSimulatedCombatManager.GetCurrencyByNo(CurrencyType.Base) >= bill[self.ConsumeId1]
    self.BtnConsume1:SetNameAndColorByGroup(1, bill[self.ConsumeId1], enough1 and XFubenSimulatedCombatConfig.Color.NORMAL or XFubenSimulatedCombatConfig.Color.INSUFFICIENT)
    self.BtnConsume2.gameObject:SetActiveEx(not self.IsChallengeMode)
    self.TxtBuyMethodSplit.gameObject:SetActiveEx(not self.IsChallengeMode)
    if not self.IsChallengeMode then
        table.insert(togs, self.BtnConsume2)
        local enough2 = XDataCenter.FubenSimulatedCombatManager.GetCurrencyByNo(CurrencyType.Extra) >= bill[self.ConsumeId2]
        self.BtnConsume2:SetRawImage(XDataCenter.FubenSimulatedCombatManager.GetCurrencyIcon(CurrencyType.Extra))
        self.BtnConsume2:SetNameAndColorByGroup(1, bill[self.ConsumeId2], enough2 and XFubenSimulatedCombatConfig.Color.NORMAL or XFubenSimulatedCombatConfig.Color.INSUFFICIENT)
    end
    self.BtnGrpConsume:Init(togs, function(index) self:SwitchPayment(index) end)
    self.BtnGrpConsume:SelectIndex(self.PayMethod[self.CurrentView], false)
end

function XUiSimulatedCombatResAllo:SwitchPayment(index)
    self.PayMethod[self.CurrentView] = index
end

function XUiSimulatedCombatResAllo:InitUiView()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGridRes)
    self.DynamicTable:SetDelegate(self)
    
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self.BtnEnterRoom.CallBack = function() self:OnBtnEnterRoomClick() end
    self.BtnConfirm.CallBack = function() self:OnBtnConfirmClick() end
    self:BindHelpBtn(self.BtnHelp, "SimulatedCombat")

    self.TxtTitle.text = XDataCenter.FubenManager.GetStageName(self.StageInterCfg.StageId)
    self.TxtMode.text = self.IsChallengeMode and CS.XTextManager.GetText("SimulatedCombatHardMode") or CS.XTextManager.GetText("SimulatedCombatNormalMode")
    self.TxtBackOrFailTip.text = CS.XTextManager.GetText("SimulatedCombatBackOrFailTip")
    self.TxtChallengeLevel.gameObject:SetActiveEx(self.IsChallengeMode)
    local _, clgStar = XDataCenter.FubenSimulatedCombatManager.GetClgMap(self.StageInterCfg.StageId)
    self.TxtChallengeLevel.text = CS.XTextManager.GetText("SimulatedCombatStarChallenge", clgStar)
    self.TxtMemberTip.text = CS.XTextManager.GetText("SimulatedCombatChallengeMemberTip")
    self.BtnMember:SetNameByGroup(0, CS.XTextManager.GetText("SimulatedCombatChallengeBuyMember"))
    self.BtnBuff:SetNameByGroup(0, CS.XTextManager.GetText("SimulatedCombatChallengeBuyBuff"))
    self.PanelBuyAddition = XUiPanelCombatAdditions.New(self.PanelCombatAdditions, self)
    self.PanelBuyMember = XUiPanelCombatMembers.New(self.PanelCombatMembers, self)
    self.GridShop.gameObject:SetActiveEx(false)
end

--动态列表事件
function XUiSimulatedCombatResAllo:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.RootUi, self.IsChallengeMode, self.IsPassed, self.StageInterId)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ResList[index]
        if not data then return end
        grid:Refresh(data)
    end
end

function XUiSimulatedCombatResAllo:OnBtnBackClick()
    local title = CSXTextManagerGetText("TipTitle")
    local content = CSXTextManagerGetText("SimulatedCombatBackConfirm")
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal,nil, function()
        self:Close()
    end)
end

function XUiSimulatedCombatResAllo:OnBtnMainUiClick()
    local title = CSXTextManagerGetText("TipTitle")
    local content = CSXTextManagerGetText("SimulatedCombatBackConfirm")
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal,nil, function()
        XLuaUiManager.RunMain()
    end)
end

function XUiSimulatedCombatResAllo:OnBtnEnterRoomClick()
    if not XDataCenter.FubenSimulatedCombatManager.CheckEnterRoom() then
        if self.IsChallengeMode then
            XUiManager.TipText("SimulatedCombatHardModeMinChar")
        else
            XUiManager.TipText("SimulatedCombatNormalModeMinChar")
        end
        return
    end
    XDataCenter.FubenSimulatedCombatManager.SaveShopMap()
    XDataCenter.FubenSimulatedCombatManager.SendPreFightRequest(function()
        XLuaUiManager.Open("UiBattleRoleRoom", self.StageInterCfg.StageId)
    end)
end

function XUiSimulatedCombatResAllo:OnBtnConfirmClick()
    local result, desc = XDataCenter.FubenSimulatedCombatManager.BuySelectedGridRes(self.CurrentView, self.PayMethod[self.CurrentView])
    if result then
        XUiManager.TipText("SimulatedCombatBuySucc")
    else
        XUiManager.TipMsg(desc)
    end
end