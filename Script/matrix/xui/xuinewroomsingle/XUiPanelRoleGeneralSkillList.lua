--===================================XUiGridRoleGeneralSkill======================================
local XUiGridRoleGeneralSkill = XClass(XUiNode, 'XUiGridRoleGeneralSkill')

function XUiGridRoleGeneralSkill:Init(skillId,isActive)
    local generalSkillConfig = XMVCA.XCharacter:GetModelCharacterGeneralSkill()[skillId]
    if generalSkillConfig then
        self.RImgGeneralSkill.gameObject:SetActiveEx(isActive)
        self.RImgGeneralSkillNotactive.gameObject:SetActiveEx(not isActive)

        if isActive then
            self.RImgGeneralSkill:SetRawImage(generalSkillConfig.Icon)
        else
            self.RImgGeneralSkillNotactive:SetRawImage(generalSkillConfig.Icon)
        end
    end
end

--===================================XUiPanelRoleGeneralSkillList==================================
---@class XUiPanelRoleGeneralSkillList
---@field _usingQueue XQueue
---@field _generalSkillIconPool XObjectPool
local XUiPanelRoleGeneralSkillList = XClass(XUiNode, 'XUiPanelRoleGeneralSkillList')

function XUiPanelRoleGeneralSkillList:OnStart(enableGeneralSkill)
    self._EnableGeneralSkill = enableGeneralSkill
    if not self._EnableGeneralSkill then
        return
    end
    self._usingQueue = XQueue.New()
    self._generalSkillIconPool = XObjectPool.New(function() 
        local obj = CS.UnityEngine.GameObject.Instantiate(self.PanelGeneralSkill, self.PanelGeneralSkill.transform.parent)
        local grid = XUiGridRoleGeneralSkill.New(obj, self)
        return grid
    end)
end

function XUiPanelRoleGeneralSkillList:UpdateCharacterId(characterId)
    self._CharacterId = characterId
end

function XUiPanelRoleGeneralSkillList:ClearData()
    self._CharacterId = nil
    self:ResetDisplay()
end

--显示所有的效应图标，并区分当前激活和未激活的效应
function XUiPanelRoleGeneralSkillList:RefreshGeneralSkillIcons()
    if not self._EnableGeneralSkill then
        return
    end
    
    if XTool.IsNumberValid(self._CharacterId) then
        self:ResetDisplay()

        local generalSkillIds = XMVCA.XCharacter:GetCharacterGeneralSkillIds(self._CharacterId)
        local selectedSkillId = self.Parent.Team:GetCurGeneralSkill()

        if not XTool.IsTableEmpty(generalSkillIds) then
            for i, skillId in ipairs(generalSkillIds) do
                local grid = self._generalSkillIconPool:Create(skillId, selectedSkillId == skillId)
                grid:Open()
                self._usingQueue:Enqueue(grid)
            end
        end
    else
        self:ClearData()
    end
end

function XUiPanelRoleGeneralSkillList:ShowActiveGeneralSkillIcon()
    if not self._EnableGeneralSkill then
        return
    end
    
    if XTool.IsNumberValid(self._CharacterId) then
        self:ResetDisplay()

        local generalSkillIds = XMVCA.XCharacter:GetCharacterGeneralSkillIds(self._CharacterId)
        local selectedSkillId = self.Parent.Team:GetCurGeneralSkill()

        if not XTool.IsTableEmpty(generalSkillIds) then
            for i, skillId in ipairs(generalSkillIds) do
                local isActiveOne = selectedSkillId == skillId

                if isActiveOne then
                    local grid = self._generalSkillIconPool:Create(skillId, isActiveOne)
                    grid:Open()
                    self._usingQueue:Enqueue(grid)
                    break
                end
            end
        end
    else
        self:ClearData()
    end
end

--回收所有显示的图标
function XUiPanelRoleGeneralSkillList:ResetDisplay()
    if not self._EnableGeneralSkill then
        return
    end
    
    while self._usingQueue:IsEmpty() == false do
        local grid = self._usingQueue:Dequeue()
        if grid then
            grid:Close()
            self._generalSkillIconPool:Recycle(grid)
        end
    end
end

return XUiPanelRoleGeneralSkillList