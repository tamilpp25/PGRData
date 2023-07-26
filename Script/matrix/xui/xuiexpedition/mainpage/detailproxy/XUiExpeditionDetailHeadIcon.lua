--虚像地平线关卡详细界面头像控件
local XUiExpeditionDetailHeadIcon = XClass(nil, "XUiExpeditionDetailHeadIcon")

function XUiExpeditionDetailHeadIcon:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiExpeditionDetailHeadIcon:RefreshData(teamData)
    if not teamData then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.GameObject:SetActiveEx(true)
    --这里使用查表方式展示，因为通关人员可能因为重置而导致eChara重置
    local cfg = XExpeditionConfig.GetBaseCharacterCfgById(teamData.BaseId)
    local fashionId = XCharacterConfigs.GetCharacterTemplate(cfg.CharacterId).DefaultNpcFashtionId
    local head = XDataCenter.FashionManager.GetFashionBigHeadIcon(fashionId)
    self.RImgIcon:SetRawImage(head)
    self.TxtLevel.text = teamData.Rank
    local tradeName = XCharacterConfigs.GetCharacterTradeName(cfg.CharacterId)
    self.TxtName.text = tradeName or "UnNamed"
end

return XUiExpeditionDetailHeadIcon