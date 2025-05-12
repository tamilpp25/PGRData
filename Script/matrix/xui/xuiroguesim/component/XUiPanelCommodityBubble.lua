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
    self.TxtName.text = self._Control.ResourceSubControl:GetCommodityRewardName(self.Id)
    -- 数量
    local count = self._Control.ResourceSubControl:GetCommodityOwnCount(self.Id)
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
    -- 货物评分
    local score, bgColor = self._Control.ResourceSubControl:GetCommodityProduceScoreAndColor(self.Id)
    self.TxtScore.text = score
    self.ImgBgUp.color = bgColor
end

return XUiPanelCommodityBubble
