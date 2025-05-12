-- 实体详细页，作为基类
-- 实体除了常规的节点实体外，还包括伏兵、援军等。此前的伏兵逻辑与常规节点详细逻辑过于耦合。对于需要单独展示其他实体详情时并不方便
-- 因此单独抽出一个基类，目前用于单独显示援军。后续需单独显示其他实体时可扩展
-- 因为目前仅有援军有这个需求。暂时无法设计出比较有效的基类处理. 等后面扩展数量多了，再根据实际情况逐步抽出通用的部分放在基类
local XUiGuildWarEntityDetail = XLuaUiManager.Register(XLuaUi, "UiGuildWarEntityDetail")

function XUiGuildWarEntityDetail:OnAwake()
    -- 先隐藏所有子界面
    -- PanelList/...
    if self.PanelNormal then
        self.PanelNormal.gameObject:SetActiveEx(false)
    end

    if self.PanelSentinel then
        self.PanelSentinel.gameObject:SetActiveEx(false)
    end

    if self.PanelLittleSentinel then
        self.PanelLittleSentinel.gameObject:SetActiveEx(false)
    end

    if self.PanelGuard then
        self.PanelGuard.gameObject:SetActiveEx(false)
    end

    if self.PanelBuff then
        self.PanelBuff.gameObject:SetActiveEx(false)
    end

    if self.PanelInfect then
        self.PanelInfect.gameObject:SetActiveEx(false)
    end

    if self.PanelEliteMonsterDetail then
        self.PanelEliteMonsterDetail.gameObject:SetActiveEx(false)
    end

    if self.PanelBoss then
        self.PanelBoss.gameObject:SetActiveEx(false)
    end

    if self.PanelReward then
        self.PanelReward.gameObject:SetActiveEx(false)
    end

    if self.PanelBlock then
        self.PanelBlock.gameObject:SetActiveEx(false)
    end

    if self.PanelBossTerm4 then
        self.PanelBossTerm4.gameObject:SetActiveEx(false)
    end
    
    --PanelFight/..
    if self.PanelResource then
        self.PanelResource.gameObject:SetActiveEx(false)
    end

    if self.PanelEliteMonster then
        self.PanelEliteMonster.gameObject:SetActiveEx(false)
    end

    if self.PanelRebuild then
        self.PanelRebuild.gameObject:SetActiveEx(false)
    end

    if self.PanelHome then
        self.PanelHome.gameObject:SetActiveEx(false)
    end

    if self.PanelCommonEffect then
        self.PanelCommonEffect.gameObject:SetActiveEx(false)
    end
end

return XUiGuildWarEntityDetail