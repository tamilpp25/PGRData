---@class XUiPanelRecommendGeneralSkill
local XUiPanelRecommendGeneralSkill = XClass(XUiNode, "XUiPanelRecommendGeneralSkill")

function XUiPanelRecommendGeneralSkill:Ctor(ui, parent, stageId)
    self.StageId = stageId
    self:InitButton()
    self:RefreshPanel()
    self.BtnGeneralSkill.gameObject:SetActiveEx(false)
end

function XUiPanelRecommendGeneralSkill:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnCloseBubble, self.OnBtnCloseBubbleClick)
end

function XUiPanelRecommendGeneralSkill:RefreshPanel()
    if XTool.IsNumberValid(self.StageId) then
        local generalSkillIds = XMVCA.XFuben:GetGeneralSkillIds(self.StageId)
        
        self:RefreshGeneralSkillIds(generalSkillIds)
    end
end

function XUiPanelRecommendGeneralSkill:RefreshGeneralSkillIds(generalSkillIds)
    if not XTool.IsTableEmpty(generalSkillIds) then
        for k, id in pairs(generalSkillIds) do
            if XTool.IsNumberValid(id) then
                local config = XMVCA.XCharacter:GetModelCharacterGeneralSkill()[id]
                local btn = CS.UnityEngine.Object.Instantiate(self.BtnGeneralSkill, self.BtnGeneralSkill.transform.parent):GetComponent("XUiButton")
                btn:SetRawImage(config.IconTranspose)
                btn.gameObject:SetActiveEx(true)
                
                XUiHelper.RegisterClickEvent(self, btn, function ()
                    self:RefreshBubble(config)
                    self.PanelGeneralSkillBubble.gameObject:SetActiveEx(true)
                    self.BtnCloseBubble.gameObject:SetActiveEx(true)
                end)
            end
        end
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