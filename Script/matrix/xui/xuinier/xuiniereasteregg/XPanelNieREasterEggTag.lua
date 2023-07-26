local XPanelNieREasterEggTag = XClass(nil, "XPanelNieREasterEggTag")
local MAX_BUTTON_NUM = 9
function XPanelNieREasterEggTag:Ctor(ui, rootUi)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)  
    
    self.TagBtnList = {}
    for i = 1, MAX_BUTTON_NUM do
        self.TagBtnList[i] = self["TagBtn"..i]
    end

    self.TagBtnGroup:Init(self.TagBtnList, function(index) self:SelectTagType(index) end)
    
end

function XPanelNieREasterEggTag:Init()
    self.TagList = XNieRConfigs.GetNieREasterEggLabelConfigs()
    local num = #self.TagList
    for index = 1, num do
        local config = self.TagList[index]
        self.TagBtnList[index]:SetNameByGroup(0, config.Label)
    end
    if num < MAX_BUTTON_NUM then
        for i = num + 1, MAX_BUTTON_NUM do
            self.TagBtnList[i].gameObject:SetActiveEx(false)
        end
    end
    self.TagBtnGroup:SelectIndex(1, true)
end

function XPanelNieREasterEggTag:SelectTagType(index)
    self.CurTag = self.TagList[index]
    self.RootUi:SetNieREasterEggTagId(self.CurTag.Id)
end

return XPanelNieREasterEggTag