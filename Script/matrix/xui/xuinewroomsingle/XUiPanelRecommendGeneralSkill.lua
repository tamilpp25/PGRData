---@class XUiPanelRecommendGeneralSkill
local XUiPanelRecommendGeneralSkill = XClass(XUiNode, "XUiPanelRecommendGeneralSkill")

function XUiPanelRecommendGeneralSkill:Ctor(ui, parent, stageId)
    self.StageId = stageId
    self:InitButton()
    self:RefreshPanel()
end

function XUiPanelRecommendGeneralSkill:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnCloseBubble, self.OnBtnCloseBubbleClick)
end

function XUiPanelRecommendGeneralSkill:RefreshPanel()
    local generalSkillIds = XMVCA.XFuben:GetGeneralSkillIds(self.StageId)
    for k, id in pairs(generalSkillIds) do
        local config = XMVCA.XCharacter:GetModelCharacterGeneralSkill()[id]
        local btn = CS.UnityEngine.Object.Instantiate(self.BtnGeneralSkill, self.BtnGeneralSkill.transform.parent):GetComponent("XUiButton")
        btn:SetRawImage(config.Icon)
        btn.gameObject:SetActiveEx(true)

        XUiHelper.RegisterClickEvent(self, btn, function ()
            self:RefreshBubble(config)
            self.PanelGeneralSkillBubble.gameObject:SetActiveEx(true)
            self.BtnCloseBubble.gameObject:SetActiveEx(true)
        end)
    end
end

function XUiPanelRecommendGeneralSkill:RefreshBubble(config)
    self.TxtGeneralSKillName.text = config.Name
    self.TxtGeneralSKillDesc.text = config.Desc
end

function XUiPanelRecommendGeneralSkill:OnBtnCloseBubbleClick()
    self.PanelGeneralSkillBubble.gameObject:SetActiveEx(false)
    self.BtnCloseBubble.gameObject:SetActiveEx(false)
end

return XUiPanelRecommendGeneralSkill