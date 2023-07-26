local CsXTextManagerGetText = CsXTextManagerGetText

--关卡详情的词缀详情弹窗（预制使用UiStrongholdSkillDetails）
local XUiCoupleCombatStageSkillTips = XLuaUiManager.Register(XLuaUi, "UiCoupleCombatStageSkillTips")

function XUiCoupleCombatStageSkillTips:OnAwake()
    self:AutoAddListener()
end

function XUiCoupleCombatStageSkillTips:OnStart(showFightEventId)
    local cfg = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(showFightEventId)

    if self.RImgIcon then
        self.RImgIcon:SetRawImage(cfg.Icon)
    end

    if self.TxtName then
        self.TxtName.text = cfg.Name
    end
    
    if self.TxtDesc then
        self.TxtDesc.text = cfg.Description
    end

    if self.PanelRequirement then
        self.PanelRequirement.gameObject:SetActiveEx(false)
    end
end

function XUiCoupleCombatStageSkillTips:AutoAddListener()
    if self.BtnTanchuangClose then
        self.BtnTanchuangClose.CallBack = function() self:Close() end
    end
end