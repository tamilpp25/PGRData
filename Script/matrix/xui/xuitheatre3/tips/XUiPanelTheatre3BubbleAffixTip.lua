---@class XUiPanelTheatre3BubbleAffixTip : XUiNode
---@field _Control XTheatre3Control
local XUiPanelTheatre3BubbleAffixTip = XClass(XUiNode, "XUiPanelTheatre3BubbleAffixTip")

function XUiPanelTheatre3BubbleAffixTip:OnStart()
    self.GridAffixList = {}
end

---@param config XTableTheatre3Equip | XTableTheatre3EquipSuit
function XUiPanelTheatre3BubbleAffixTip:Refresh(config)
    for index, name in ipairs(config.TraitName) do
        if not string.IsNilOrEmpty(name) then
            local grid = self.GridAffixList[index]
            if not grid then
                local go = index == 1 and self.ImgBubbleBg or XUiHelper.Instantiate(self.ImgBubbleBg, self.BubbleAffix)
                grid = XTool.InitUiObjectByUi({}, go)
                self.GridAffixList[index] = grid
            end
            grid.TxtTitle.text = name
            grid.TxtInformation.text = XUiHelper.ReplaceUnicodeSpace(config.TraitDesc[index])
        end
    end
end

return XUiPanelTheatre3BubbleAffixTip