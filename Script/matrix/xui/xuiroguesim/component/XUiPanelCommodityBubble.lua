local XUiPanelRogueSimBaseBubble = require("XUi/XUiRogueSim/Component/XUiPanelRogueSimBaseBubble")
---@class XUiPanelCommodityBubble : XUiPanelRogueSimBaseBubble
---@field private _Control XRogueSimControl
local XUiPanelCommodityBubble = XClass(XUiPanelRogueSimBaseBubble, "XUiPanelCommodityBubble")

function XUiPanelCommodityBubble:OnStart()
    self.CurAlignment = XEnumConst.RogueSim.Alignment.CT
    self.Offset = CS.UnityEngine.Vector2(0, -10)
    self:SetAnchorAndPivot()
end

function XUiPanelCommodityBubble:Refresh(targetTransform, id)
    self:SetTransform(targetTransform)
    self.Id = id
    -- 货物图标
    self.RImgResource:SetRawImage(self._Control.ResourceSubControl:GetCommodityIcon(self.Id))
    -- 名称
    self.TxtName.text = self._Control.ResourceSubControl:GetCommodityName(self.Id)
    -- 数量
    local count = self._Control.ResourceSubControl:GetCommodityActualCount(self.Id)
    local limit = self._Control.ResourceSubControl:GetCommodityTotalLimit(self.Id)
    self.TxtNum.text = string.format("%d/%d", count, limit)
    -- 进度条
    local progress, color, desc = self._Control.ResourceSubControl:GetCommodityProgressData(self.Id)
    self.ImgBar.fillAmount = progress
    self.TxtState.text = desc
    -- 设置颜色
    self.TxtNum.color = color
    self.TxtState.color = color
    self.ImgBar.color = color
end

return XUiPanelCommodityBubble
