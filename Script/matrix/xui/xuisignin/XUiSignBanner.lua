local XUiSignBanner = XLuaUiManager.Register(XLuaUi, "UiSignBanner")
local XUiSignPrefabContent = require("XUi/XUiSignIn/XUiSignPrefabContent")
local XUiSClassConstructWelfare = require("XUi/XUiSClassConstructWelfare/XUiSClassConstructWelfare")
local XUiSignFirstRecharge = require("XUi/XUiSignIn/XUiSignFirstRecharge")
local XUiSignCard = require("XUi/XUiSignIn/XUiSignCard")
local XUiWeekChallenge = require("XUi/XUiWeekChallenge/XUiWeekChallenge")
local XUiSignWeekCard = require("XUi/XUiSignIn/XUiSignWeekCard")

function XUiSignBanner:OnAwake()
    self:AddListener()
    XEventManager.AddEventListener(XEventId.EVENT_SING_IN_OPEN_BTN, self.SetBtnActive, self)
end

function XUiSignBanner:OnStart(configId, forceInteractive)
    self.Config = XSignInConfigs.GetWelfareConfig(configId)
    self.ForceInteractive = forceInteractive
    if forceInteractive then
        self:SetBtnActive(true)
    else
        self:SetBtnActive(false)
    end
    self:SetInfo(configId)
end

function XUiSignBanner:OnEnable()
    if self.SignPrefabContent and self.Config.FunctionType == XAutoWindowConfigs.AutoFunctionType.WeekChallenge then
        self.SignPrefabContent:OnShow()
    end

    if not self.IsFirst then
        self.IsFirst = true
        return
    end

    if self.SignPrefabContent and self.Config.FunctionType == XAutoWindowConfigs.AutoFunctionType.Sign then
        self.SignPrefabContent:Refresh(self.Config.SubConfigId, true)
    end
end

function XUiSignBanner:OnDisable()
    if self.SignPrefabContent and self.Config.FunctionType == XAutoWindowConfigs.AutoFunctionType.WeekChallenge then
        self.SignPrefabContent:OnHide()
    end
end

function XUiSignBanner:AddListener()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
end

function XUiSignBanner:PcClose()
    if not self.BtnClose.gameObject.activeSelf then
        return
    end
    self:OnBtnCloseClick()
end

function XUiSignBanner:OnBtnCloseClick()
    self:Close()
    XDataCenter.AutoWindowManager.NextAutoWindow()
end

function XUiSignBanner:SetInfo(configId)
    local path = XSignInConfigs.GetPrefabPath(configId)
    if not path then
        XLog.Error("找不到预置体路径，检查Welfare表是否正确配置FunctionType，id", configId)
        return
    end

    local prefab = self.PanelSigGrid:LoadPrefab(path, false)
    if not prefab then
        self:Close()
        return
    end
    
    prefab.gameObject:SetLayerRecursively(self.PanelSigGrid.gameObject.layer)

    if self.Config.FunctionType == XAutoWindowConfigs.AutoFunctionType.Sign then
        self.SignPrefabContent = XUiSignPrefabContent.New(prefab, self)
    elseif self.Config.FunctionType == XAutoWindowConfigs.AutoFunctionType.SClassConstructNovice then
        self.SignPrefabContent = XUiSClassConstructWelfare.New(prefab, self)
    elseif self.Config.FunctionType == XAutoWindowConfigs.AutoFunctionType.FirstRecharge then
        self.SignPrefabContent = XUiSignFirstRecharge.New(prefab, self)
    elseif self.Config.FunctionType == XAutoWindowConfigs.AutoFunctionType.Card then
        self.SignPrefabContent = XUiSignCard.New(prefab, self)
    elseif self.Config.FunctionType == XAutoWindowConfigs.AutoFunctionType.WeekChallenge then
        self.SignPrefabContent = XUiWeekChallenge.New(prefab, self)
    elseif self.Config.FunctionType == XAutoWindowConfigs.AutoFunctionType.WeekCard then
        self.SignPrefabContent = XUiSignWeekCard.New(prefab, self)
    end

    self.SignPrefabContent:Refresh(self.Config.SubConfigId, true)
end

function XUiSignBanner:SetBtnActive(active, dayRewardConfig)
    if dayRewardConfig and self.SignPrefabContent then
        self.SignPrefabContent:SetTomorrowOpen(dayRewardConfig)
    end

    if self.Config.FunctionType == XAutoWindowConfigs.AutoFunctionType.Sign
        or self.Config.FunctionType == XAutoWindowConfigs.AutoFunctionType.WeekCard
    then
        self.PanelMask.gameObject:SetActive(not active)
    else
        self.PanelMask.gameObject:SetActive(false)
    end

    self.BtnClose.gameObject:SetActive(active)
    self.PanelCloseDesc.gameObject:SetActive(active)
end

function XUiSignBanner:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_SING_IN_OPEN_BTN, self.SetBtnActive, self)

    if self.SignPrefabContent then
        CS.UnityEngine.Object.Destroy(self.SignPrefabContent.GameObject)
    end
end