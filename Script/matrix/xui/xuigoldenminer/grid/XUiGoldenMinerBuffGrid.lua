---黄金矿工通用Buff格子
---@class XUiGoldenMinerBuffGrid:XUiNode
---@field _Control XGoldenMinerControl
local XUiGoldenMinerBuffGrid = XClass(XUiNode, "XUiGoldenMinerBuffGrid")

function XUiGoldenMinerBuffGrid:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)

    if self.CountDownText then
        self.CountDownText.gameObject:SetActiveEx(false)
    end
    self.GameObject:SetActiveEx(true)
end

function XUiGoldenMinerBuffGrid:Refresh(buffId)
    self.BuffId = buffId
    local icon = self._Control:GetCfgBuffIcon(buffId)
    if self.RawBuffIcon then
        self.RawBuffIcon:SetRawImage(icon)
    end
end

function XUiGoldenMinerBuffGrid:OnBtnClick()
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_SHOP_OPEN_TIP, self.BuffId, nil, self.Transform.position.x)
end

return XUiGoldenMinerBuffGrid