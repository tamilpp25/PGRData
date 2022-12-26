local XPanelNieREasterEggChatList = XClass(nil, "XPanelNieREasterEggChatList")
local XGridNieREasterEggChatList = require("XUi/XUiNieR/XUiNieREasterEgg/XGridNieREasterEggChatList")

function XPanelNieREasterEggChatList:Ctor(ui, rootUi)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskActivityList)
    self.DynamicTable:SetProxy(XGridNieREasterEggChatList)
    self.DynamicTable:SetDelegate(self)
end

function XPanelNieREasterEggChatList:Init()
    self.TagList = XNieRConfigs.GetNieREasterEggMessageConfigs()
    self:SelNieREasterEggMessage(1)
    self.DynamicTable:SetDataSource(self.TagList)
    self.DynamicTable:ReloadDataASync()

    
end

--动态列表事件
function XPanelNieREasterEggChatList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refesh(self.TagList[index])
        if index == self.CurSelIndex then
            grid:IsSelect(true)
        else
            grid:IsSelect(false)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if self.CurSelIndex == index then return end
        local lastGrid = self.DynamicTable:GetGridByIndex(self.CurSelIndex)
        if lastGrid then
            lastGrid:IsSelect(false)
        end
        
        grid:IsSelect(true)
        self:SelNieREasterEggMessage(index)
    end
end

function XPanelNieREasterEggChatList:SelNieREasterEggMessage(index)
    self.CurSelIndex = index
    self.RootUi:SetNieREasterEggMessageId(self.TagList[index].Id)
end
return XPanelNieREasterEggChatList