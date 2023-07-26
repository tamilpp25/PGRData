--######################## XUiPanelNodeDetail ########################
local XUiPanelRebuildDetaile = require("XUi/XUiGuildWar/Node/XUiPanelRebuildDetaile")
local XUiPanelNodeDetail = XClass(XSignalData, "XUiPanelNodeDetail")

function XUiPanelNodeDetail:Ctor(ui, rootUi)
    self.Node = nil
    XUiHelper.InitUiClass(self, ui)
    XUiHelper.RegisterClickEvent(self, self.BtnChange, self.OnBtnChangeClicked)
    self.UiPanelRebuildDetaile = XUiPanelRebuildDetaile.New(rootUi.PanelRebuild, self)
end

function XUiPanelNodeDetail:SetData(node)
    ---@type XGWNode
    self.Node = node
    if node:GetIsBaseNode() then
        return
    end
    self.RImgIcon:SetRawImage(node:GetShowMonsterIcon())
    self.TxtName.text = node:GetShowMonsterName()
    if self.Node:GetIsLastNode() and self.Node:GetIsDead() then
        self.TxtHP.gameObject:SetActiveEx(false)
    else
        self.TxtHP.gameObject:SetActiveEx(true)
    end
    self.TxtHP.text = node:GetPercentageHP()
    self.TxtMyDamage.text = XUiHelper.GetText("GuildWarMaxDamageTip"
        , getRoundingValue((node:GetMaxDamage() / node:GetMaxHP()) * 100, 2))
    self.PrograssHP.fillAmount = node:GetHP() / node:GetMaxHP()
    self.BtnChange.gameObject:SetActiveEx(#node:GetEliteMonsters() > 0)
    local statusType = node:GetStutesType()
    self.PanelKilled.gameObject:SetActiveEx(statusType == XGuildWarConfig.NodeStatusType.Die)
    local isShowRebuild = statusType == XGuildWarConfig.NodeStatusType.Revive and node:GetIsSentinelNode()
    self.GameObject:SetActiveEx(not isShowRebuild)
    self.UiPanelRebuildDetaile.GameObject:SetActiveEx(isShowRebuild)
    if isShowRebuild then
        self.UiPanelRebuildDetaile:SetData(node)
    end
    -- 设置按钮名称
    self.BtnChange:SetNameByGroup(0, XUiHelper.GetText("GuildWarChangeMonster"))

    if node:GetIsPandaRootNode() then
        self.RImgIconAolajiang.gameObject:SetActiveEx(true)
    end
end

function XUiPanelNodeDetail:RefreshTimeData()
    if self.Node:GetNodeType() == XGuildWarConfig.NodeType.Sentinel
       and self.Node:GetStutesType() == XGuildWarConfig.NodeStatusType.Revive  then
        self.UiPanelRebuildDetaile:RefreshTimeData()
    end
end

function XUiPanelNodeDetail:OnBtnChangeClicked()
    self:EmitSignal("ChangeTopDetailStatus", true)
end

return XUiPanelNodeDetail