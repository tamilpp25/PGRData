---@class XUiGridRogueSimCommodity : XUiNode
---@field private _Control XRogueSimControl
local XUiGridRogueSimCommodity = XClass(XUiNode, "XUiGridRogueSimCommodity")

function XUiGridRogueSimCommodity:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnResource, self.OnBtnResourceClick)
end

function XUiGridRogueSimCommodity:Refresh(id)
    self.Id = id
    -- 货物图标
    self.RawImage:SetRawImage(self._Control.ResourceSubControl:GetCommodityIcon(id))
    -- 数量
    self.TxtNum.text = self._Control.ResourceSubControl:GetCommodityOwnCount(id)
    -- 进度条
    local progress, color = self._Control.ResourceSubControl:GetCommodityProgressData(id)
    self.ImgBar.fillAmount = progress
    -- 设置颜色
    self.TxtNum.color = color
    self.ImgBar.color = color
    -- 出售进度条
    local sellProgress = self._Control.ResourceSubControl:GetCommoditySellProgress(id)
    self.ImgSellBar.gameObject:SetActiveEx(sellProgress > 0)
    self.ImgSellBar.fillAmount = sellProgress
end

function XUiGridRogueSimCommodity:OnBtnResourceClick()
    XLuaUiManager.Open("UiRogueSimComponent", XEnumConst.RogueSim.BubbleType.AssetDetail, self.Transform, self.Id)
end

return XUiGridRogueSimCommodity
