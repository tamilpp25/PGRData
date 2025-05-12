local XUiGridGeneralSkillSelect = XClass(XUiNode, 'XUiGridGeneralSkillSelect')

function XUiGridGeneralSkillSelect:OnStart()
    self.Btn.CallBack = handler(self,self.OnSelectEvent)
end

function XUiGridGeneralSkillSelect:Refresh(data)
    local genralSkillConfig = XMVCA.XCharacter:GetModelCharacterGeneralSkill()[data.Id]
    --设置效应基本信息
    self.GeneralSkillIcon:SetRawImage(genralSkillConfig.Icon)
    self.GeneralSkillTxt.text = genralSkillConfig.Name
    self.GeneralSkillDesc.text = genralSkillConfig.Desc
    
    self._Id = data.Id
    --设置关联角色头像
    local characters = {}
    for id, v in pairs(data.Characters) do
        table.insert(characters, id)
    end
    
    for i = 1, 10 do
        if self['Char'..i] then
            local hasCharacter = XTool.IsNumberValid(characters[i])
            self['Char'..i].gameObject:SetActiveEx(hasCharacter and true or false)

            if hasCharacter then
                local isNotSelf = not XMVCA.XCharacter:IsOwnCharacter(characters[i])
                local headFashionId, headFashionType = XMVCA.XCharacter:GetCharacterFashionHeadInfo(characters[i], isNotSelf)
                local icon = XMVCA.XCharacter:GetCharSmallHeadIcon(characters[i], isNotSelf, headFashionId, headFashionType)
                self['Char'..i]:SetRawImage(icon)
            end
            
        end
    end
    
    --设置是否为推荐
    local isRecommand = XTool.IsNumberValid(self.Parent._StageId) and table.contains(XMVCA.XFuben:GetGeneralSkillIds(self.Parent._StageId), data.Id) or false
    self.RecommandTag.gameObject:SetActiveEx(isRecommand)
    
    --设置是否为当前选择
    self._Selecting = self.Parent._Team:GetCurGeneralSkill() == data.Id
    self.Btn:SetButtonState(self._Selecting and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiGridGeneralSkillSelect:OnSelectEvent()
    if self._Selecting then
        self.Btn:SetButtonState(CS.UiButtonState.Select)
    else
        self.Parent._Team:UpdateSelectGeneralSkill(self._Id)
        self.Parent:RefreshList()
    end
end

return XUiGridGeneralSkillSelect