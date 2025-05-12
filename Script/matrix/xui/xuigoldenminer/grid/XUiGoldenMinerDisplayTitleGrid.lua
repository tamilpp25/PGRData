---黄金矿工通用展示格子
---@class XUiGoldenMinerDisplayTitleGrid:XUiNode
---@field _Control XGoldenMinerControl
local XUiGoldenMinerDisplayTitleGrid = XClass(XUiNode, "XUiGoldenMinerDisplayTitleGrid")

function XUiGoldenMinerDisplayTitleGrid:OnStart(title1, title2)
    if self.TxtResourcesTitle then
        if string.IsNilOrEmpty(title1) then
            self.TxtResourcesTitle.gameObject:SetActiveEx(false)
        else
            self.TxtResourcesTitle.text = title1
        end
    end

    if self.Text then
        if string.IsNilOrEmpty(title2) then
            self.Text.gameObject:SetActiveEx(false)
        else
            self.Text.text = title2
        end
    end
end

return XUiGoldenMinerDisplayTitleGrid