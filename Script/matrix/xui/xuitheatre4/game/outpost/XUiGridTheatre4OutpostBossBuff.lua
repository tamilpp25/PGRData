---@class XUiGridTheatre4OutpostBossBuff : XUiNode
---@field private _Control XTheatre4Control
---@field Parent XUiPanelTheatre4OutpostBoss
local XUiGridTheatre4OutpostBossBuff = XClass(XUiNode, "XUiGridTheatre4OutpostBossBuff")

function XUiGridTheatre4OutpostBossBuff:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
end

function XUiGridTheatre4OutpostBossBuff:Refresh(fightEventId)
    self.FightEventId = fightEventId
    ---@type XTableStageFightEventDetails
    local config = XMVCA.XFuben:GetStageFightEventDetailsByStageFightEventId(fightEventId)
    if not config then
        return
    end
    local icon = config.Icon
    if icon then
        self.RImgIcon:SetRawImage(icon)
    end
end

function XUiGridTheatre4OutpostBossBuff:OnBtnClick()
    self.Parent:SelectBuff(self.FightEventId)
end

return XUiGridTheatre4OutpostBossBuff
