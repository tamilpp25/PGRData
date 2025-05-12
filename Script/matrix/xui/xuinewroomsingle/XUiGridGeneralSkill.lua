---这个类是控制编队房间效应按钮的
---@class _XUiPanelGeneralSkill
local XUiGridGeneralSkill = XClass(XUiNode, "XUiGridGeneralSkill")

function XUiGridGeneralSkill:OnStart(stageId)
    self._StageId = stageId
    self.BtnGeneralSkill.CallBack = handler(self,self.OnBtnClickEvent)
    self.BtnGeneralSkillNotactive.CallBack = handler(self, self.OnNoGeneralSkillBtnClickEvent)
    self:Refresh(true)
end

function XUiGridGeneralSkill:Refresh(noForceRefreshGeneralSkills)
    if XTool.IsTableEmpty(self.Parent) then
        if XMain.IsEditorDebug then
            XLog.Error('当前效应选择信息刷新时，父类节点不存在。该节点的状态是否有效：', self:IsValid(), '节点UI是否存在：', XTool.UObjIsNil(self.GameObject), '生命周期状态：', self._StateFlag)
        else
            XLog.CustomReport("GeneralSkillSelect", "Refresh UiNodeIsValid:", self:IsValid(), "GameObjectDestroy", XTool.UObjIsNil(self.GameObject), "UiNodeDestroy", self._StateFlag)
        end
        return
    end
    
    --判断是否需要隐藏背景遮罩(如果当前关卡有推荐效应，则会实例化以下字段名的UI控制器
    local hasRecommend = not XTool.IsTableEmpty(self.Parent.XUiPanelRecommendGeneralSkill) and true or false
    if hasRecommend then
        self.ImgBgRecommendOff1.gameObject:SetActiveEx(not hasRecommend)
        self.ImgBgRecommendOff2.gameObject:SetActiveEx(not hasRecommend)
    end
    
    local teamData = self:GetTeamData()

    if not noForceRefreshGeneralSkills then
        teamData:RefreshGeneralSkills(false, true)
    end
    local hasGeneralSkill = teamData:CheckHasGeneralSkills()
    self.BtnGeneralSkill.gameObject:SetActiveEx(hasGeneralSkill)
    self.BtnGeneralSkillNotactive.gameObject:SetActiveEx(not hasGeneralSkill)
    
    if hasGeneralSkill then
        local generalSkillId = teamData:GetCurGeneralSkill()
        if XTool.IsNumberValid(generalSkillId) then
            local genralSkillConfig = XMVCA.XCharacter:GetModelCharacterGeneralSkill()[generalSkillId]

            -- 显示有效应图标
            self.BtnGeneralSkill:SetRawImage(genralSkillConfig.IconTranspose)
            self.TxtGenera.text = genralSkillConfig.Name
        else
            local stageRecommendGeneralSkills = nil
            if XTool.IsNumberValid(self.Parent.StageId) then
                stageRecommendGeneralSkills = XMVCA.XFuben:GetGeneralSkillIds(self.Parent.StageId)
            end
            -- 默认选择
            self:GetTeamData():AutoSelectGeneralSkill(stageRecommendGeneralSkills)

            generalSkillId = teamData:GetCurGeneralSkill()
            local genralSkillConfig = XMVCA.XCharacter:GetModelCharacterGeneralSkill()[generalSkillId]
            -- 显示有效应图标
            self.BtnGeneralSkill:SetRawImage(genralSkillConfig.IconTranspose)
            self.TxtGenera.text = genralSkillConfig.Name
        end
    end
end

function XUiGridGeneralSkill:OnBtnClickEvent()
    local teamData = self:GetTeamData()
    
    if teamData:CheckHasGeneralSkills() then
        XLuaUiManager.OpenWithCloseCallback('UiBattleRoomGeneralSkillSelect', function() 
            self:Refresh(true)
            if self.Parent and self.Parent.RefreshRoleDetalInfo then
                self.Parent:RefreshRoleDetalInfo()
            end
        end, self.Parent.StageId, teamData)
    else
        XUiManager.TipText('BattleRoleRoomNoGeneralSkillTips')
    end
end

function XUiGridGeneralSkill:OnNoGeneralSkillBtnClickEvent()
    XUiManager.TipText('BattleRoleRoomNoGeneralSkillTips')
end

---@return XTeam 
function XUiGridGeneralSkill:GetTeamData()
    return self.Parent.Team
end

return XUiGridGeneralSkill