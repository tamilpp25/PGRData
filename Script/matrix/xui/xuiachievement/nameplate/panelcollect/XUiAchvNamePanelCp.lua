--=============
--铭牌页面进度控件
--=============
local XUiAchvNamePanelCp = {}

local TempPanel

local function Refresh()
    if not TempPanel then return end
    if TempPanel.TxtAchvGetCount then
        local group = XDataCenter.MedalManager.GetNameplateGroupList()
        local count = 0
        for _, _ in pairs(group or {}) do
            count = count + 1
        end
        TempPanel.TxtAchvGetCount.text = count
    end
end

local function Clear()
    TempPanel = nil
end

XUiAchvNamePanelCp.OnEnable = function(uiNameplate)
    TempPanel = {}
    XTool.InitUiObjectByUi(TempPanel, uiNameplate.PanelCollectProgress)
    Refresh()
end

XUiAchvNamePanelCp.OnDisable = function()
    Clear()
end

XUiAchvNamePanelCp.OnDestroy = function()
    Clear()
end

return XUiAchvNamePanelCp