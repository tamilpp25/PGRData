
---@class XUiPanelWorkBase
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field AreaType number
---@field Index number
local XUiPanelWorkBase = XClass(nil, "XUiPanelWorkBase")

function XUiPanelWorkBase:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    
    self:InitUi()
    self:InitCb()
end

function XUiPanelWorkBase:InitUi()
    
end

function XUiPanelWorkBase:InitCb()
    
end

function XUiPanelWorkBase:Show(areaType, index, ...)
    self.GameObject:SetActiveEx(true)
    self.AreaType = areaType
    self.Index = index
    
    self:RefreshView()
end

function XUiPanelWorkBase:Hide()
    self.GameObject:SetActiveEx(false)
    self:ClearCache()
end

function XUiPanelWorkBase:RefreshView()
end

function XUiPanelWorkBase:ClearCache()
end

return XUiPanelWorkBase