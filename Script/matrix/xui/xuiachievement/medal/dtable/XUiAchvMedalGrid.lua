--================
--勋章页面动态列表项
--================
local XUiAchvMedalGrid = XClass(nil, "XUiAchvMedalGrid")

function XUiAchvMedalGrid:Ctor(uiPrefab)
    self:Init(uiPrefab)
end

function XUiAchvMedalGrid:Init(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
end

function XUiAchvMedalGrid:Refresh()
    
end

return XUiAchvMedalGrid