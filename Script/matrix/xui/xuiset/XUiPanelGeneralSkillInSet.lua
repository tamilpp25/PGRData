--======================================XUiGridGeneralSkillInSet==============================
local XUiGridGeneralSkillInSet = XClass(XUiNode, "XUiGridGeneralSkillInSet")

function XUiGridGeneralSkillInSet:OnStart()
    
end

function XUiGridGeneralSkillInSet:Init(characterId, isRobot, skillList, enhanceSkillList, characterSkillPlus)
    self.CharacterId = characterId
    self.IsRobot = isRobot
    self._CharacterSkillPlus = characterSkillPlus
    if not XTool.IsTableEmpty(skillList) then
        self._SkillLevelMap = {}
        for i, v in pairs(skillList) do
            self._SkillLevelMap[v.Id] = v.Level
        end
    end

    if not XTool.IsTableEmpty(enhanceSkillList) then
        self._EnhanceSkillLevelMap = {}
        for i, v in pairs(enhanceSkillList) do
            self._EnhanceSkillLevelMap[v.Id] = v.Level
        end
    end
end

function XUiGridGeneralSkillInSet:GetRobotSkillLevelInFightData(skillId)
    if not XTool.IsTableEmpty(self._SkillLevelMap) then
        local baseLevel = self._SkillLevelMap[skillId] or 0
        return baseLevel + (self._CharacterSkillPlus[skillId] or 0)
    end
    return 0
end

function XUiGridGeneralSkillInSet:GetRobotEnhanceSkillLevelInFightData(skillId)
    if not XTool.IsTableEmpty(self._EnhanceSkillLevelMap) then
        return self._EnhanceSkillLevelMap[skillId] or 0
    end
    return 0
end

function XUiGridGeneralSkillInSet:Refresh(characterId, generalSkillId)
    self.CharacterId = characterId
    self.CurGeneralSkillId = generalSkillId
    
    -- 角色头像
    local isNotSelf = not XMVCA.XCharacter:IsOwnCharacter(characterId)
    local headFashionId, headFashionType = XMVCA.XCharacter:GetCharacterFashionHeadInfo(characterId, isNotSelf)
    local icon = XMVCA.XCharacter:GetCharSmallHeadIcon(characterId, isNotSelf, headFashionId, headFashionType)
    self.StandIcon:SetSprite(icon)

    local isOwnChar = XMVCA.XCharacter:IsOwnCharacter(self.CharacterId)

    -- 相关技能
    local lineMaxCount = 5 -- 每行最多的格子
    local maxListCount = 1 -- 提前预设计好的3个技能列表
    local relatedSkillIds, relatedEnhanceSkillIds = XMVCA.XCharacter:GetCharacterGeneralSkillRelatedSkillIds(self.CharacterId, self.CurGeneralSkillId)
    local totalCount = #relatedSkillIds + #relatedEnhanceSkillIds
    local activeListCount = math.ceil(totalCount / lineMaxCount) -- 向上取整

    for i = 1, maxListCount, 1 do
        local listTrans = self["ListSkill"..i]
        local active = i <= activeListCount
        listTrans.gameObject:SetActiveEx(active)

        if active then
            local gridCount = totalCount > (lineMaxCount * i) and lineMaxCount or (totalCount - (lineMaxCount * (i - 1)))
            local gridTempalte = self["GridRelatedSkill"..i]
            XUiHelper.RefreshCustomizedList(gridTempalte.parent, gridTempalte, gridCount, function (index, grid)
                local curIndexInTotal = (i - 1) * lineMaxCount + index
                if curIndexInTotal <= #relatedSkillIds then
                    -- 普通技能
                    local skillId = relatedSkillIds[curIndexInTotal]
                    local level = nil
                    local cfg = XMVCA.XCharacter:GetSkillGradeDesWithDetailConfig(skillId, 1)
                    if not cfg then return end
                    local isSkillLock = false
                    local uiObj = grid:GetComponent("UiObject")
                    uiObj:GetObject("RImgSubSkillIconNormal"):SetRawImage(cfg.Icon)
                    if self.IsRobot then
                        level = self:GetRobotSkillLevelInFightData(skillId)
                        isSkillLock = level < 1
                    elseif isOwnChar then
                        local character = XMVCA.XCharacter:GetCharacter(self.CharacterId)
                        level = character:GetSkillLevelBySkillId(skillId) or 1

                        local addLevel = XMVCA.XCharacter:GetSkillPlusLevel(self.CharacterId, skillId) or 0
                        level = level + addLevel
                        isSkillLock = level < 1
                    else
                        isSkillLock = true
                    end
                    uiObj:GetObject("TxtLevel").text = XTool.IsNumberValid(level) and level or 1
                    uiObj:GetObject("PanelSkillLock").gameObject:SetActiveEx(isSkillLock)

                    local btn = uiObj:GetObject("Button")
                    XUiHelper.RegisterClickEvent(self, btn, function()
                        self:OnGridRelatedSkillClick(cfg, level)
                    end)
                else
                    -- 跃升技能
                    local indexForEnhance = curIndexInTotal - #relatedSkillIds
                    local skillId = relatedEnhanceSkillIds[indexForEnhance]
                    local level = nil
                    local cfg = XMVCA.XCharacter:GetEnhanceSkillGradeDescBySkillIdAndLevel(skillId, 1)
                    if not cfg then return end
                    local uiObj = grid:GetComponent("UiObject")
                    uiObj:GetObject("RImgSubSkillIconNormal"):SetRawImage(cfg.Icon)
                    if self.IsRobot then
                        level = self:GetRobotEnhanceSkillLevelInFightData(skillId)
                    elseif isOwnChar then
                        local character = XMVCA.XCharacter:GetCharacter(self.CharacterId)
                        local enhanceSkillGroupId = character:EnhanceSkillIdToGroupId(skillId)
                        local enhanceSkillGroup = character:GetEnhanceSkillGroupData(enhanceSkillGroupId)
                        level = enhanceSkillGroup:GetLevel() or 1
                    else
                        level = 0
                    end
                    uiObj:GetObject("TxtLevel").text = XTool.IsNumberValid(level) and level or 1
                    
                    local isSkillLock = true
                    local values = XMVCA.XCharacter:GetModelEnhanceSkillIdGeneralSkillIdsDic()[skillId]
                    for k, v in pairs(values) do
                        if v.GeneralSkillId == self.CurGeneralSkillId and level >= v.NeedLevel then
                            isSkillLock = false
                            break
                        end
                    end
                    
                    uiObj:GetObject("PanelSkillLock").gameObject:SetActiveEx(isSkillLock)

                    local btn = uiObj:GetObject("Button")
                    XUiHelper.RegisterClickEvent(self, btn, function()
                        self:OnGridRelatedSkillClick(cfg, level, isSkillLock)
                    end)
                end
            end)
        end
    end

    -- 全技能标签
    local activeFullTag = false
    local skills = XMVCA.XCharacter:GetChracterSkillPosToGroupIdDic(self.CharacterId)
    if not XTool.IsTableEmpty(skills) then
        local pos1 = 1 -- 只需要基础技能和特殊技能全部有就显示
        local pos2 = 2
        local needCount = (#(skills[pos1]) + #(skills[pos2]))
        activeFullTag = #relatedSkillIds >= needCount
    end
    self.PanelFullSkillTag.gameObject:SetActiveEx(activeFullTag)
end

function XUiGridGeneralSkillInSet:OnGridRelatedSkillClick(config, skillLv, isSkillLock)
    XLuaUiManager.Open("UiSkillDetailsForGeneralSkillTips", config, skillLv, isSkillLock, true)
end

--=======================================XUiPanelGeneralSkillInSet============================
local XUiPanelGeneralSkillInSet = XClass(XUiNode, "XUiPanelGeneralSkillInSet")

function XUiPanelGeneralSkillInSet:OnStart()
    self:Init()
    self:Refresh()
end

function XUiPanelGeneralSkillInSet:Init()
    self._CharacterSkillGrid = {}
    for i = 1, 10 do
        local skillObj = self['CharacterSkill'..i]
        if skillObj then
            local grid = XUiGridGeneralSkillInSet.New(skillObj, self)
            table.insert(self._CharacterSkillGrid, grid)
            grid:Close()
            self._GridSkillObj = skillObj
        end
    end
end

function XUiPanelGeneralSkillInSet:Refresh()
    local fightData = XMVCA.XFuben:GetFightBeginData().FightData
    
    for index, v in ipairs(fightData.EventIds) do
        for id, generalSkillCfg in pairs(XMVCA.XCharacter:GetModelCharacterGeneralSkill()) do
            if generalSkillCfg.FightEventId ==  v then
                self._GeneralSkillId = generalSkillCfg.Id
                break
            end
        end
    end
    --显示效应基本信息
    local generalSkillCfg = XMVCA.XCharacter:GetModelCharacterGeneralSkill()[self._GeneralSkillId]
    if generalSkillCfg then
        self.SkillIcon:SetRawImage(generalSkillCfg.Icon)
        self.Name.text = generalSkillCfg.Name
        self.Desc.text = generalSkillCfg.Desc
    end
    
    --显示激活角色的关联技能
    for i, v in ipairs(self._CharacterSkillGrid) do
        v:Close()
    end
    
    local index = 1
    for i, v in pairs(fightData.RoleData) do
        if v.Id == XPlayer.Id then
            for key, value in pairs(v.NpcData) do
                local characterId = value.Character.Id
                if table.contains(XMVCA.XCharacter:GetCharacterGeneralSkillIds(characterId), self._GeneralSkillId) then
                    if not self._CharacterSkillGrid[index] then
                        if not self._GridSkillObj then
                            return
                        end
                        local cloneObj = CS.UnityEngine.GameObject.Instantiate(self._GridSkillObj, self._GridSkillObj.transform.parent)
                        cloneObj.gameObject:SetActiveEx(false)
                        local grid = XUiGridGeneralSkillInSet.New(cloneObj, self)
                        table.insert(self._CharacterSkillGrid, grid)
                    end

                    self._CharacterSkillGrid[index]:Init(characterId, value.IsRobot, value.Character.SkillList, value.Character.EnhanceSkillList, value.CharacterSkillPlus)
                    self._CharacterSkillGrid[index]:Open()
                    self._CharacterSkillGrid[index]:Refresh(characterId, self._GeneralSkillId)
                    

                    index = index + 1
                end
            end
            
            break
        end
    end
end

return XUiPanelGeneralSkillInSet