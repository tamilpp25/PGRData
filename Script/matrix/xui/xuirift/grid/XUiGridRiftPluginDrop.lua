local XUiRiftPluginGrid = require("XUi/XUiRift/Grid/XUiRiftPluginGrid")

local XUiGridRiftPluginDrop = XClass(nil, "UiGridRiftPluginDrop")

function XUiGridRiftPluginDrop:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    self.PluginGrid = XUiRiftPluginGrid.New(self.GridRiftPlugin)
end

function XUiGridRiftPluginDrop:Refresh(dropData)
    local pluginId = dropData.PluginId
    local isDecompose = dropData.DecomposeCount > 0

    local plugin = XDataCenter.RiftManager.GetPlugin(pluginId)
    self.PluginGrid:Refresh(plugin)
    self.TxtPluginName.text = plugin:GetName()
    self.TxtCoreExplain.text = plugin:GetDesc()
    self.ImgStar:SetSprite(plugin:GetImageDropHead())

    -- 补正类型
    local fixTypeList = plugin:GetAttrFixTypeList()
    for i = 1, XRiftConfig.PluginMaxFixCnt do
        local isShow = #fixTypeList >= i
        self["PanelAddition" .. i].gameObject:SetActiveEx(isShow)
        if isShow then
            self["TxtAddition" .. i].text = fixTypeList[i]
        end
    end

    -- 补正效果
    local attrFixList = plugin:GetEffectStringList()
    for i = 1, XRiftConfig.PluginMaxFixCnt do
        local isShow = #attrFixList >= i
        self["PanelEntry" .. i].gameObject:SetActiveEx(isShow)
        if isShow then
            local attrFix = attrFixList[i]
            self["TxtEntry" .. i].text = attrFix.Name
            self["TxtEntryNum" .. i].text = attrFix.ValueString
        end
    end

    -- 已拥有
    self.PanelOwned.gameObject:SetActiveEx(isDecompose)
    if isDecompose then
        local icon = XItemConfigs.GetItemIconById(XDataCenter.ItemManager.ItemId.RiftGold)
        self.RImgIcon:SetRawImage(icon)
        self.TxtItem.text = dropData.DecomposeCount
    end
end

return XUiGridRiftPluginDrop
