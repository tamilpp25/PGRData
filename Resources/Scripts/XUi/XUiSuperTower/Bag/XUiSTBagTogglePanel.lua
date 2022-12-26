local ChildPanel = require("XUi/XUiSuperTower/Common/XUiSTChildPanel")
local TOGGLE_TYPE_NAME = {
        [1] = "Bag", --背包
        [2] = "IllustratedBook", --图鉴
    }
--===========================
--超级爬塔背包页签面板
--===========================
local XUiSTBagTogglePanel = XClass(ChildPanel, "XUiSTBagTogglePanel")

function XUiSTBagTogglePanel:InitPanel()
    local toggleGroup = {}
    table.insert(toggleGroup, self.BtnTogBag)
    table.insert(toggleGroup, self.BtnTogIllustratedBook)
    self.BtnGroupToggle:Init(toggleGroup, function(index) self:OnClickToggle(index) end)
end

function XUiSTBagTogglePanel:SelectToggle(index)
    self.BtnGroupToggle:SelectIndex(index)
end

function XUiSTBagTogglePanel:OnClickToggle(index)
    --工厂
    local typeName = TOGGLE_TYPE_NAME[index]
    if not typeName then return end
    local func = self["OnClickBtn" .. TOGGLE_TYPE_NAME[index]]
    if func then func(self) end
end

function XUiSTBagTogglePanel:OnClickBtnBag()
    self.RootUi:ShowPageBag()
end

function XUiSTBagTogglePanel:OnClickBtnIllustratedBook()
    self.RootUi:ShowPageIllustratedBook()
end

return XUiSTBagTogglePanel