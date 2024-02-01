local XUiGridStage = require("XUi/XUiGuildWar/Map/XUiGridStage/XUiGridStage")

local XUiGridStageResource = XClass(XUiGridStage, "XUiGridStageResource")

function XUiGridStageResource:Ctor()
    self._EffectExplode = self.Transform.parent:Find('EffectExplode')
    self._EffectShield = self.Transform.parent:Find('EffectShield')
    
    self._EffectExplode.gameObject:SetActiveEx(false)
    self._EffectShield.gameObject:SetActiveEx(false)

end

function XUiGridStageResource:UpdateGrid(nodeEntity, IsPathEdit, IsActionPlaying, isPathEditOver)
    self.Super.UpdateGrid(self,nodeEntity, IsPathEdit, IsActionPlaying, isPathEditOver)
    self.BtnStage:SetRawImage(nodeEntity:GetIcon())
    self:RefreshGarrison() 
    self:RefreshRebuildState()
    self:RefreshNormalIcon()
end

function XUiGridStageResource:RefreshGarrison()
    --更新资源点的驻守百分比
    if self.DefendPercentText then
        self.DefendPercentText.transform.parent.gameObject:SetActiveEx(true)
        self.DefendPercentText.text = string.format("%d",math.floor(XDataCenter.GuildWarManager.GetDefensePlayerPercentById(self.StageNode._Id)*100))..'%'
    end
    if self.Garrison then
        self._IsDefend = XDataCenter.GuildWarManager.CheckDefensePointIsPlayerInById(self.StageNode._Id)
        self.Garrison.gameObject:SetActiveEx(self._IsDefend)
        self.PanelMe.gameObject:SetActiveEx(self._IsDefend)
    end
end

function XUiGridStageResource:RefreshRebuildState()
    --更新重建显示
    if self.Rebuild then
        self._IsRebuild = XDataCenter.GuildWarManager.IsDefensePointRebuilding(self.StageNode._Id)
        self.Rebuild.gameObject:SetActiveEx(self._IsRebuild)
        if self.GarrisonBg then
            self.GarrisonBg.gameObject:SetActiveEx(not self._IsRebuild)
        end

        if self._IsRebuild then
            local icons = XGuildWarConfig.GetClientConfigValues('ResNodeRebuildIcons')
            self.BtnStage:SetRawImage(icons[self.StageNode.Config.StageIndex])
        else
            self.BtnStage:SetRawImage(self.StageNode:GetIcon())
        end
    end
end

function XUiGridStageResource:RefreshNormalIcon()
    self.Normal.gameObject:SetActiveEx(not self._IsRebuild and not self._IsDefend)
end

function XUiGridStageResource:UpdateNodeData()
    local latestNode = XDataCenter.GuildWarManager.GetLatestResourceNodeId(self.StageNode._Id)
    if latestNode then
        self.StageNode:UpdateWithServerData(latestNode)
    end
end

function XUiGridStageResource:ShowEffectShield(enable)
    self._EffectShield.gameObject:SetActiveEx(enable)
end

function XUiGridStageResource:ShowEffectExplode(enable)
    self._EffectExplode.gameObject:SetActiveEx(enable)
end

---炮击动画期间隐藏重建、驻守标记以及百分比
function XUiGridStageResource:SetDisplayWithAttackAnimation(isAnimation)
    if isAnimation then
        self.Normal.gameObject:SetActiveEx(true)
        self.Rebuild.gameObject:SetActiveEx(false)
        self.Garrison.gameObject:SetActiveEx(false)
        self.PanelMe.gameObject:SetActiveEx(false)
        self.DefendPercentText.transform.parent.gameObject:SetActiveEx(false)
    else
        self:RefreshGarrison()
        self:RefreshRebuildState()
        self:RefreshNormalIcon()
    end
end

return XUiGridStageResource