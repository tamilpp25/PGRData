local BasePluginsGrid = require("XUi/XUiSuperTower/Plugins/XUiSuperTowerPluginGrid")
local LIST_TYPE = {
    Bag = 1, --背包列表
    Decomposion = 2, --分解列表
}
--===========================
--超级爬塔背包芯片控件
--===========================
local XUiSTBagPluginsGrid = XClass(BasePluginsGrid, "XUiSTBagPluginsGrid")

function XUiSTBagPluginsGrid:RefreshData(plugin, index, listType)
    self.Plugin = plugin
    self.RImgIcon:SetRawImage(plugin:GetIcon())
    self.ImgQuality:SetSprite(self.Plugin:GetQualityIcon())
    self.ImgQualityBg:SetSprite(self.Plugin:GetQualityBg())
    self.Index = index
    self.ListType = listType
    self.TxtName.gameObject:SetActiveEx(false)
    self.TxtCapacity.gameObject:SetActiveEx(true)
    self.TxtCapacity.text = CS.XTextManager.GetText("STBagPluginCapacity", plugin:GetCapacity())
    self:SetActiveStatus(false)
    self:SetSelectStatus(false)
end

function XUiSTBagPluginsGrid:SetSelect(isSelect)
    if self.ListType == LIST_TYPE.Bag then
        self:SetActiveStatus(isSelect)
    elseif self.ListType == LIST_TYPE.Decomposion then
        self:SetSelectStatus(isSelect)
    end
end

return XUiSTBagPluginsGrid