--=============
--功能按钮面板
--=============
local XUiAchvSysPanelBtn = {}

local TempPanel

local function InitBtnMedal()
    local btn = TempPanel.BtnMedal
    if not btn then return end
    btn:ShowReddot(XDataCenter.MedalManager.CheckHaveNewMedalByType(XMedalConfigs.ViewType.Medal))
    btn.CallBack = function()
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Medal) then
            XLuaUiManager.Open('UiPlayerPersonalizedSetting', XHeadPortraitConfigs.HeadType.Medal)
        end
    end
end

local function InitBtnCollection()
    local btn = TempPanel.BtnCollection
    if not btn then return end
    btn:ShowReddot(XDataCenter.MedalManager.CheckHasScoreTitleNew())
    btn.CallBack = function()
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Collection) then
            XLuaUiManager.Open("UiAchievementCollection")
        end
    end
end

local function InitBtnNameplate()
    local btn = TempPanel.BtnNameplate
    if not btn then return end
    btn:ShowReddot(XDataCenter.MedalManager.CkeckHaveNewNameplate())
    btn.CallBack = function()
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Nameplate) then
            XLuaUiManager.Open('UiPlayerPersonalizedSetting', XHeadPortraitConfigs.HeadType.Nameplate)
        end
    end
end

local function InitButtons()
    if not TempPanel then return end
    InitBtnMedal()
    InitBtnCollection()
    InitBtnNameplate()
end

local function Clear()
    TempPanel = nil
end

local function RefreshBtnMedalReddot()
    local btn = TempPanel.BtnMedal
    if not btn then return end
    btn:ShowReddot(XDataCenter.MedalManager.CheckHaveNewMedalByType(XMedalConfigs.ViewType.Medal))
end

local function RefreshBtnNameplateReddot()
    local btn = TempPanel.BtnNameplate
    if not btn then return end
    btn:ShowReddot(XDataCenter.MedalManager.CkeckHaveNewNameplate())
end

XUiAchvSysPanelBtn.OnEnable = function(uiAchvSys)
    TempPanel = {}
    XTool.InitUiObjectByUi(TempPanel, uiAchvSys.PanelBtn)
    InitButtons()
    XEventManager.AddEventListener(XEventId.EVENT_MEDAL_REDPOINT_CHANGE, RefreshBtnMedalReddot)
    XEventManager.AddEventListener(XEventId.EVENT_NAMEPLATE_CHANGE, RefreshBtnNameplateReddot)
end

XUiAchvSysPanelBtn.OnDisable = function()
    XEventManager.RemoveEventListener(XEventId.EVENT_MEDAL_REDPOINT_CHANGE, RefreshBtnMedalReddot)
    XEventManager.RemoveEventListener(XEventId.EVENT_NAMEPLATE_CHANGE, RefreshBtnNameplateReddot)
    Clear()
end

XUiAchvSysPanelBtn.OnDestroy = function()
    Clear()
end

return XUiAchvSysPanelBtn