--- 废墟节点详情界面子面板
---@class XUiPanelRuins: XUiNode
local XUiPanelRuins = XClass(XUiNode, 'XUiPanelRuins')

function XUiPanelRuins:OnStart()
    self.BtnHelp.CallBack = handler(self, self.OnBtnHelpClicked)
    self.Parent.PanelTitle.gameObject:SetActiveEx(false)
end

function XUiPanelRuins:SetData(node)
    self.Parent.UiPanelNodeDetail.GameObject:SetActiveEx(false)
    self.Parent.PanelTitle.gameObject:SetActiveEx(false)
    ---@type XGWNode
    self.Node = node
    if node:GetIsBaseNode() then
        return
    end
    self.TxtName.text = node:GetName()
    local statusType = node:GetStutesType()
    local isShowRebuild = statusType == XGuildWarConfig.NodeStatusType.Revive and node:GetIsSentinelNode()
    self.GameObject:SetActiveEx(not isShowRebuild)

    -- 节点描述
    local desc = self.Node:GetDesc()
    self.TxtAreaDetails.text = desc
end

function XUiPanelRuins:OnBtnHelpClicked()
    XLuaUiManager.Open("UiGuildWarStageTips", self.Node)
end

return XUiPanelRuins