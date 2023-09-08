local XUiRiftPluginGrid = require("XUi/XUiRift/Grid/XUiRiftPluginGrid")

local XUiRiftPluginShopTips = XLuaUiManager.Register(XLuaUi, "UiRiftPluginShopTips")

function XUiRiftPluginShopTips:OnAwake()
	self:AddListener()
	self.PluginGrid = XUiRiftPluginGrid.New(self.GridRiftPlugin)
end

function XUiRiftPluginShopTips:OnStart(goodData)
    self.Plugin = XDataCenter.RiftManager.GetShopGoodsPlugin(goodData)
    self.PluginGrid:Refresh(self.Plugin)
    self.TxtName.text = self.Plugin:GetName()
    self.TxtDescription.text = self.Plugin:GetDesc()

    local fixTypeList = self.Plugin:GetPropTag()
    for i, v in ipairs(fixTypeList) do
        local grid = i == 1 and self.PanelAddition or XUiHelper.Instantiate(self.PanelAddition, self.PanelAddition.parent)
        local uiObject = {}
        XTool.InitUiObjectByUi(uiObject, grid)
        grid.gameObject:SetActiveEx(true)
        uiObject.TxtAddition.text = v
    end
    if XTool.IsTableEmpty(fixTypeList) then
        self.PanelAddition.gameObject:SetActiveEx(false)
    end
end

function XUiRiftPluginShopTips:AddListener()
	self.BtnBack.CallBack = function()
        self:Close()
    end
	self.BtnOk.CallBack = function()
        self:Close()
    end
end