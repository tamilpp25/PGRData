local XUiPanelStoryDetailBase = require('XUi/XUiFavorability/StoryPanel/PanelStoryDetail/XUiPanelStoryDetailBase')

---@class XUiPanelFavorabilityStoryDetail: XUiPanelStoryDetailBase
---@field _Control XFavorabilityControl
local XUiPanelFavorabilityStoryDetail = XClass(XUiPanelStoryDetailBase, 'XUiPanelFavorabilityStoryDetail')

local BgType = {
    Default = 1,
    BigImg = 2,
}

---@overload
function XUiPanelFavorabilityStoryDetail:Refresh(cfg)
    XUiPanelStoryDetailBase.Refresh(self, cfg)

    local desc = ''
    local title = ''
    
    if self._IsSimpleStory then
        title = self.Cfg.Name
        desc = self.Cfg.ConditionDescript
        self.BtnEnterStory:SetNameByGroup(0, XUiHelper.GetText('CharacterTrustStoryNoBattleEnterTips'))
    elseif self._IsStage then
        title = XMVCA.XFuben:GetStageName(self.Cfg.StageId)
        desc = XMVCA.XFuben:GetStageDescription(self.Cfg.StageId)

        ---@type XTableStage
        local stageCfg = XMVCA.XFuben:GetStageCfg(self.Cfg.StageId)

        if stageCfg then
            if stageCfg.StageType == XFubenConfigs.STAGETYPE_FIGHT then
                self.BtnEnterStory:SetNameByGroup(0, XUiHelper.GetText('CharacterTrustStoryBattleEnterTips'))
            else
                self.BtnEnterStory:SetNameByGroup(0, XUiHelper.GetText('CharacterTrustStoryNoBattleEnterTips'))
            end
        end
    else
        XLog.Error("好感度剧情没有关卡配置，Id:"..tostring(self.Cfg.Id))
    end

    self.TxtFightName.text = title
    self.TxtFightDec.text = desc
    self.TxtTips.text = self.Cfg.ExtraDescript
    
    --设置图片
    -- 目前类型较少且简单，直接在这里区分
    if self.Cfg.StageDetailType == BgType.Default then
        self.RImgFight:SetRawImage(self.Cfg.Icon)
    elseif self.Cfg.StageDetailType == BgType.BigImg then
        self.RImgFight:SetRawImage(self.Cfg.StageDetailParams[1])
    end
end

return XUiPanelFavorabilityStoryDetail