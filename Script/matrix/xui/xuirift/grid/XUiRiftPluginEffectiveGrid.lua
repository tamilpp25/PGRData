---@class XUiRiftPluginEffectiveGrid : XUiNode
---@field Parent XUiRiftChoosePlugin
local XUiRiftPluginEffectiveGrid = XClass(XUiNode, "XUiRiftPluginEffectiveGrid")

function XUiRiftPluginEffectiveGrid:OnStart()

end

function XUiRiftPluginEffectiveGrid:Init(role, plugin, isDetailTxt, isBagShow, clickCb)
    ---@type XRiftRole
    self._Role = role
    ---@type XUiRiftPluginGrid
    self._Grid = require("XUi/XUiRift/Grid/XUiRiftPluginGrid").New(self.GridRiftCore, self.Parent)
    self._IsBagShow = isBagShow
    self._ClickCb = clickCb
    self:Refresh(plugin, isDetailTxt)
    XUiHelper.RegisterClickEvent(self, self.Transform, self.OnClick)
end

---@param plugin XRiftPlugin
function XUiRiftPluginEffectiveGrid:Refresh(plugin, isDetailTxt)
    self._Plugin = plugin
    self._Grid:Refresh(plugin)
    self.TxtPluginName.text = plugin:GetName()
    self.TxtLoad.text = plugin.Config.Load
    self.TxtGoldDetail.text = plugin:GetGoldDesc()
    self.TxtPluginEffective.text = plugin:GetDesc(isDetailTxt)
    local isWear = self._Role:CheckHasPlugin(plugin:GetId())
    self._Grid:SetIsWear(isWear) -- 只有总览才需要显示穿戴状态
    local fixTypeList = plugin:GetPropTag()
    XUiHelper.RefreshCustomizedList(self.PanelAddition.parent, self.PanelAddition, #fixTypeList, function(i, go)
        local uiObject = {}
        XTool.InitUiObjectByUi(uiObject, go)
        uiObject.TxtAddition.text = fixTypeList[i]
    end)
    local isSpecial = plugin:IsSpecialQuality()
    self.TxtGoldDetail.gameObject:SetActiveEx(isSpecial)
    if self.ImgNormal then
        self.ImgNormal.gameObject:SetActiveEx(not isSpecial)
    end
    if self.ImgSpecial then
        self.ImgSpecial.gameObject:SetActiveEx(isSpecial)
    end
end

function XUiRiftPluginEffectiveGrid:SetSelected(bo)
    self.PanelSelect.gameObject:SetActiveEx(bo)
end

function XUiRiftPluginEffectiveGrid:OnClick()
    if self._ClickCb then
        self._ClickCb()
    end
end

return XUiRiftPluginEffectiveGrid
