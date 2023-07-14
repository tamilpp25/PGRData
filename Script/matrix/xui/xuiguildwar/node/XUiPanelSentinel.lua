local XUiPanelSentinel = XClass(nil, "XUiPanelSentinel")

function XUiPanelSentinel:Ctor(ui)
    self.Monster = nil
    XUiHelper.InitUiClass(self, ui)
    self.Node = nil
end

function XUiPanelSentinel:SetData(node)
    self.Node = node
    local monster = node:GetBornMonster()
    self.Monster = monster
    self.GameObject:SetActiveEx(monster ~= nil)
    if monster == nil then return end
    self.GameObject:SetActiveEx(node:GetStutesType() 
        == XGuildWarConfig.NodeStatusType.Alive)
    self.RImgIcon:SetRawImage(monster:GetIcon())
    self.TxtName.text = monster:GetName()
    self.TxtDetails.text = XUiHelper.GetText("GuildWarMonsterDetails", monster:GetDamagePercent())
    self:RefreshTimeData()
end

function XUiPanelSentinel:RefreshTimeData()
    if self.Monster then
        -- self.TxtTime.text = XUiHelper.GetText("GuildWarBornRebuildTimeTip"
        -- , self.Monster:GetBornTimeStr(self.Node:GetEliteMonsterBornInterval()))
        self.TxtTime.text = XUiHelper.GetText("GuildWarBornRebuildTimeTip"
        , self.Node:GetNextMonsterBornTimeTip())
    end
end

return XUiPanelSentinel
