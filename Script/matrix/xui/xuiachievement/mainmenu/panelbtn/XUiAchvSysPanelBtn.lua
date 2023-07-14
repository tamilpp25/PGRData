--=============
--功能按钮面板
--=============
local XUiAchvSysPanelBtn = {}

local TempPanel

local function InitBtnStory()
    local btn = TempPanel.BtnStory
    if not btn then return end
    local reviewShowed = XDataCenter.ReviewActivityManager.GetReviewIsShown()
    if not reviewShowed then
        btn.gameObject:SetActiveEx(false)
        return
    end
    btn.CallBack = function()
        XDataCenter.ReviewActivityManager.GetReviewData(function()
                XLuaUiManager.Open("UiReviewActivityAnniversary")
            end)
    end
end

local function InitBtnMedal()
    local btn = TempPanel.BtnMedal
    if not btn then return end
    btn:ShowReddot(XDataCenter.MedalManager.CheckHaveNewMedalByType(XMedalConfigs.ViewType.Medal))
    btn.CallBack = function()
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Medal) then
            XLuaUiManager.Open("UiAchievementMedal")
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
            XLuaUiManager.Open("UiAchievementNameplate")
        end
    end
end

local function InitButtons()
    if not TempPanel then return end
    InitBtnStory()
    InitBtnMedal()
    InitBtnCollection()
    InitBtnNameplate()
end

local function Clear()
    TempPanel = nil
end

XUiAchvSysPanelBtn.OnEnable = function(uiAchvSys)
    TempPanel = {}
    XTool.InitUiObjectByUi(TempPanel, uiAchvSys.PanelBtn)
    InitButtons()
end

XUiAchvSysPanelBtn.OnDisable = function()
    Clear()
end

XUiAchvSysPanelBtn.OnDestroy = function()
    Clear()
end

return XUiAchvSysPanelBtn