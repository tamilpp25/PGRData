local XUiSign = XLuaUiManager.Register(XLuaUi, "UiSign")
local XUiSignPrefabContent = require("XUi/XUiSignIn/XUiSignPrefabContent")
local XUiSignFirstRecharge = require("XUi/XUiSignIn/XUiSignFirstRecharge")
local XUiSignCard = require("XUi/XUiSignIn/XUiSignCard")
local XUiWeekChallenge = require("XUi/XUiWeekChallenge/XUiWeekChallenge")
local XUiSClassConstructWelfare = require("XUi/XUiSClassConstructWelfare/XUiSClassConstructWelfare")

function XUiSign:OnAwake()
    self:AddListener()
    self.PrefabList = {}
end

function XUiSign:OnStart(defaultIdx)
    self:InitTabGroup(defaultIdx)
end

function XUiSign:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN, self.RefrshRedHint, self)
    XEventManager.AddEventListener(XEventId.EVENT_VIP_CARD_BUY_SUCCESS, self.OnHandleVipCardBuySuccess, self)

    self:RefrshRedHint()

    if not self.IsFirst then
        self.IsFirst = true
        return
    end

    if self.Index then
        self:SetPrefabInfos(self.Index, true)
    end
end

function XUiSign:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN, self.RefrshRedHint, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_VIP_CARD_BUY_SUCCESS, self.OnHandleVipCardBuySuccess, self)
end

function XUiSign:AddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
end

function XUiSign:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiSign:OnBtnBackClick()
    self:Close()
end

function XUiSign:InitTabGroup(defaultType)
    self.WelfareConfigs = XSignInConfigs.GetWelfareConfigs()
    
    if #self.WelfareConfigs <= 0 then
        self.BtnTab.gameObject:SetActive(false)
        self.PanelNull.gameObject:SetActive(true)
        return
    end
    self.PanelNull.gameObject:SetActive(false)

    local defaultIndex = 1
    self.BtnTab:SetName(self.WelfareConfigs[1].Name)
    self.BtnList = {}
    table.insert(self.BtnList, self.BtnTab)

    for i = 2, #self.WelfareConfigs do
        local btn = CS.UnityEngine.Object.Instantiate(self.BtnTab.gameObject)
        btn.transform:SetParent(self.PanelTabGroup.gameObject.transform, false)
        local xBtn = btn.transform:GetComponent("XUiButton")
        table.insert(self.BtnList, xBtn)
        xBtn:SetName(self.WelfareConfigs[i].Name)
        if defaultType and self.WelfareConfigs[i].WelfareId == defaultType then
            defaultIndex = i
        end
    end

    self.PanelTabGroup:Init(self.BtnList, function(index)
        self:SetPrefabInfos(index)
    end)

    self.PanelTabGroup:SelectIndex(defaultIndex or 1)
end

function XUiSign:SetPrefabInfos(index, forceRefresh)
    if self.Index == index and not forceRefresh then
        return
    end
    self.Index = index
    self:PlayAnimation("QieHuanEnable")

    for _, v in pairs(self.PrefabList) do
        v.SignPrefabContent.GameObject:SetActive(false)
    end

    local config = self.WelfareConfigs[index]
    local signPrefabContent = self.PrefabList[config.PrefabPath] and self.PrefabList[config.PrefabPath].SignPrefabContent or nil
    if not signPrefabContent then
        local resource = CS.XResourceManager.Load(config.PrefabPath)
        local go = CS.UnityEngine.Object.Instantiate(resource.Asset)
        go.transform:SetParent(self.PanelSign, false)
        go.gameObject:SetLayerRecursively(self.PanelSign.gameObject.layer)

        if config.FunctionType == XAutoWindowConfigs.AutoFunctionType.Sign then
            signPrefabContent = XUiSignPrefabContent.New(go, self)
        elseif config.FunctionType == XAutoWindowConfigs.AutoFunctionType.SClassConstructNovice then
            signPrefabContent = XUiSClassConstructWelfare.New(go, self)
        elseif config.FunctionType == XAutoWindowConfigs.AutoFunctionType.FirstRecharge then
            signPrefabContent = XUiSignFirstRecharge.New(go, self)
        elseif config.FunctionType == XAutoWindowConfigs.AutoFunctionType.Card then
            signPrefabContent = XUiSignCard.New(go, self)
        elseif config.FunctionType == XAutoWindowConfigs.AutoFunctionType.WeekChallenge then
            signPrefabContent = XUiWeekChallenge.New(go, self)
        end

        signPrefabContent:OnShow()
        local info = {}
        info.SignPrefabContent = signPrefabContent
        info.Resource = resource
        self.PrefabList[config.PrefabPath] = info
    end

    signPrefabContent:Refresh(config.Id, false)
    signPrefabContent.GameObject:SetActive(true)
end

function XUiSign:RefrshRedHint()
    if not self.BtnList then
        return
    end

    for index, xBtn in pairs(self.BtnList) do
        local config = self.WelfareConfigs[index]
        if config.FunctionType == XAutoWindowConfigs.AutoFunctionType.FirstRecharge then
            xBtn:ShowReddot(not XDataCenter.PayManager.IsGotFirstReCharge())
        elseif config.FunctionType == XAutoWindowConfigs.AutoFunctionType.Card then
            xBtn:ShowReddot(not XDataCenter.PayManager.IsGotCard())
        elseif config.FunctionType == XAutoWindowConfigs.AutoFunctionType.WeekChallenge then
            xBtn:ShowReddot(XDataCenter.WeekChallengeManager.IsAnyRewardCanReceived())
        end
    end
end

function XUiSign:OnDestroy()
    if not self.PrefabList then
        return
    end

    for _, v in pairs(self.PrefabList) do
        if v.Resource then
            v.Resource:Release()
        end

        if v.SignPrefabContent then
            v.SignPrefabContent:OnHide()
            CS.UnityEngine.Object.Destroy(v.SignPrefabContent.GameObject)
        end
    end
end

function XUiSign:OnHandleVipCardBuySuccess()
    if self.Index then
        self:SetPrefabInfos(self.Index, true)
    end
end