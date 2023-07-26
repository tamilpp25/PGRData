local XUiPanelSecondarySentinel = XClass(nil, "XUiPanelSecondarySentinel")

function XUiPanelSecondarySentinel:Ctor(ui)
    self.Monster = nil
    XUiHelper.InitUiClass(self, ui)
    self.Node = nil
    
    self.PanelUiDetail01 = {}
    XTool.InitUiObjectByUi(self.PanelUiDetail01,self.PanelDetail01)
end

function XUiPanelSecondarySentinel:SetData(node)
    self.Node = node
    local monster = node:GetBornMonster()
    self.Monster = monster
    if monster == nil then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.GameObject:SetActiveEx(true)
    --小哨塔介绍
    self.TxtAreaDetails.text = XGuildWarConfig.GetNodeDesc(self.Node:GetId())
    
    --休战期或死亡则关闭显示
    if not XDataCenter.GuildWarManager.CheckRoundIsInTime() or 
        not (node:GetStutesType() == XGuildWarConfig.NodeStatusType.Alive) then
        self.PanelUiDetail01.GameObject:SetActiveEx(false)
        return 
    end
    self.PanelUiDetail01.GameObject:SetActiveEx(true)
    self.PanelUiDetail01.RImgEliteIcon:SetRawImage(monster:GetIcon())
    self.PanelUiDetail01.TxtElite.text = monster:GetName()
    self.PanelUiDetail01.TxtDetails.text = XUiHelper.GetText("GuildWarMonsterDetails", monster:GetDamagePercent())
    self:RefreshTimeData()
end

function XUiPanelSecondarySentinel:RefreshTimeData()
    if self.Monster then
        -- self.TxtTime.text = XUiHelper.GetText("GuildWarBornRebuildTimeTip"
        -- , self.Monster:GetBornTimeStr(self.Node:GetEliteMonsterBornInterval()))
        self.PanelUiDetail01.TxtTime.text = XUiHelper.GetText("GuildWarBornRebuildTimeTip"
        , self.Node:GetNextMonsterBornTimeTip())
    end
end

return XUiPanelSecondarySentinel
