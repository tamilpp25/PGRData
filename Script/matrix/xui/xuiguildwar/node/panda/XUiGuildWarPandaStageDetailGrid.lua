---@class XUiGuildWarPandaStageDetailGrid
local XUiGuildWarPandaStageDetailGrid = XClass(nil, "XUiGuildWarPandaStageDetailGrid")

function XUiGuildWarPandaStageDetailGrid:Ctor(ui, pandaType, nodeId)
    XTool.InitUiObjectByUi(self, ui)
    self.PandaType = pandaType
    self.NodeId = nodeId
    self:Init()
end

function XUiGuildWarPandaStageDetailGrid:Update()
    self:UpdateWeakness()
    self:UpdateHp()
    self:UpdateName()
end

function XUiGuildWarPandaStageDetailGrid:Init()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnClick)
end

function XUiGuildWarPandaStageDetailGrid:UpdateWeakness()
    local isHasWeakness = XDataCenter.GuildWarManager.IsChildHasWeakness(self.NodeId, self.PandaType)
    self.PanelRuodian.gameObject:SetActiveEx(isHasWeakness)
end

function XUiGuildWarPandaStageDetailGrid:UpdateHp()
    local hp, maxHp = XDataCenter.GuildWarManager.GetChildHp(self.NodeId, self.PandaType)
    self.TxtHP.text = string.format("%.1f", hp / 100) .. "%"
    self.Progress.fillAmount = hp / maxHp
    if hp == 0 then
        -- self.PanelHp.gameObject:SetActiveEx(false)
        self.PanelDeath.gameObject:SetActiveEx(true)
    else
        -- self.PanelHp.gameObject:SetActiveEx(true)
        self.PanelDeath.gameObject:SetActiveEx(false)
    end
end

function XUiGuildWarPandaStageDetailGrid:UpdateName()
    local node = XDataCenter.GuildWarManager.GetChildNode(self.NodeId, self.PandaType)
    self.TxtName.text = node:GetName(false)
end

function XUiGuildWarPandaStageDetailGrid:Unfold()
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_PANDA_UNFOLD_DETAIL, true, self.PandaType)
end

function XUiGuildWarPandaStageDetailGrid:Fold()
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_PANDA_UNFOLD_DETAIL, false)
end

function XUiGuildWarPandaStageDetailGrid:OnClick()
    self:Unfold()
end

return XUiGuildWarPandaStageDetailGrid
