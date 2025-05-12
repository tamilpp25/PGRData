local XUiGridStrongholdGeneralSkill = XClass(nil, 'XUiGridStrongholdGeneralSkill')

function XUiGridStrongholdGeneralSkill:Ctor(ui, parent)
    self.Parent = parent
    XTool.InitUiObjectByUi(self, ui)
    self.BtnGeneralSkill.CallBack = handler(self,self.OnBtnClickEvent)
    self.BtnGeneralSkillNotactive.CallBack = handler(self, self.OnNoGeneralSkillBtnClickEvent)
end

function XUiGridStrongholdGeneralSkill:Open()
    self.GameObject:SetActiveEx(true)
end

function XUiGridStrongholdGeneralSkill:Refresh()
    ---@type XStrongholdTeam
    local _team = self.Parent:GetTeam()
    
    -- 强制开启一次刷新
    _team:RefreshGeneralSkillOption()
    local hasGeneralSkill = XTool.IsNumberValid(_team:GetCurGeneralSkill()) and true or false
    
    self.BtnGeneralSkill.gameObject:SetActiveEx(hasGeneralSkill)
    self.BtnGeneralSkillNotactive.gameObject:SetActiveEx(not hasGeneralSkill)

    
    if hasGeneralSkill then
        local generalSkillId = _team:GetCurGeneralSkill()
        if XTool.IsNumberValid(generalSkillId) then
            local genralSkillConfig = XMVCA.XCharacter:GetModelCharacterGeneralSkill()[generalSkillId]

            -- 显示有效应图标
            self.BtnGeneralSkill:SetRawImage(genralSkillConfig.IconTranspose)
            self.TxtGenera.text = genralSkillConfig.Name
        else
            -- 默认选择
            self.Parent.Team:AutoSelectGeneralSkill()

            generalSkillId = _team:GetCurGeneralSkill()
            local genralSkillConfig = XMVCA.XCharacter:GetModelCharacterGeneralSkill()[generalSkillId]
            -- 显示有效应图标
            self.BtnGeneralSkill:SetRawImage(genralSkillConfig.IconTranspose)
            self.TxtGenera.text = genralSkillConfig.Name
        end
    end
end

function XUiGridStrongholdGeneralSkill:OnBtnClickEvent()
    local _team = self.Parent:GetTeam()
    local stageId = nil

    if XTool.IsNumberValid(self.Parent.GroupId) then
        stageId = XDataCenter.StrongholdManager.GetCurrentStage(self.Parent.GroupId)
    end
    
    if _team:CheckHasGeneralSkills() then
        XLuaUiManager.OpenWithCloseCallback('UiBattleRoomGeneralSkillSelect', function()
            self:Refresh()
        end, stageId, _team)
    else
        XUiManager.TipText('BattleRoleRoomNoGeneralSkillTips')
    end
end

function XUiGridStrongholdGeneralSkill:OnNoGeneralSkillBtnClickEvent()
    XUiManager.TipText('BattleRoleRoomNoGeneralSkillTips')
end

return XUiGridStrongholdGeneralSkill