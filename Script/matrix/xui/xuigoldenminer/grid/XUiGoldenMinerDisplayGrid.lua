---黄金矿工通用展示格子
---@class XUiGoldenMinerDisplayGrid:XUiNode
---@field _Control XGoldenMinerControl
local XUiGoldenMinerDisplayGrid = XClass(XUiNode, "XUiGoldenMinerDisplayGrid")

function XUiGoldenMinerDisplayGrid:Refresh(iconUrl, desc)
    if self.RImgBuff and not string.IsNilOrEmpty(iconUrl) then
        self.RImgBuff:SetRawImage(iconUrl)
    end
    
    if self.Text then
        self.Text.text = XTool.ReplaceSpaceToNonBreaking(desc)
        self.Text.gameObject:SetActiveEx(true)
    end
end

return XUiGoldenMinerDisplayGrid