local XUiGridTheatre4Building = require("XUi/XUiTheatre4/Common/XUiGridTheatre4Building")
---@class XUiGridTheatre4OutpostBossBuffCard : XUiNode
---@field private _Control XTheatre4Control
local XUiGridTheatre4OutpostBossBuffCard = XClass(XUiNode, "XUiGridTheatre4OutpostBossBuffCard")

function XUiGridTheatre4OutpostBossBuffCard:OnStart()
    self.BtnClick.gameObject:SetActive(false)
end

function XUiGridTheatre4OutpostBossBuffCard:Refresh(fightEventId)
    ---@type XTableStageFightEventDetails
    local config = XMVCA.XFuben:GetStageFightEventDetailsByStageFightEventId(fightEventId)
    if not config then
        return
    end
    -- 图标
    self:RefreshGridBuff(config.Icon)
    -- 名称
    self.TxtName.text = config.Name
    -- 描述
    self.TxtDetail.text = config.Description
end

function XUiGridTheatre4OutpostBossBuffCard:RefreshGridBuff(icon)
    if not self.GridBuffUi then
        ---@type XUiGridTheatre4Building
        self.GridBuffUi = XUiGridTheatre4Building.New(self.GridBuilding, self)
    end
    self.GridBuffUi:Open()
    self.GridBuffUi:Refresh({ Icon = icon })
end

return XUiGridTheatre4OutpostBossBuffCard
