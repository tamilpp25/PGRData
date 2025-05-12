
---@class XUiPanelWorkBase : XUiNode
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field AreaType number
---@field Index number
---@field _Control XRestaurantControl
local XUiPanelWorkBase = XClass(XUiNode, "XUiPanelWorkBase")

function XUiPanelWorkBase:OnStart()
    self:InitUi()
    self:InitCb()
end

function XUiPanelWorkBase:InitUi()
    
end

function XUiPanelWorkBase:InitCb()
    
end

function XUiPanelWorkBase:Show(areaType, index, ...)
    self:Open()
    self.AreaType = areaType
    self.Index = index
    
    self:RefreshView()
end

function XUiPanelWorkBase:Hide()
    self:Close()
    self:ClearCache()
end

function XUiPanelWorkBase:RefreshView()
end

function XUiPanelWorkBase:ClearCache()
end

return XUiPanelWorkBase