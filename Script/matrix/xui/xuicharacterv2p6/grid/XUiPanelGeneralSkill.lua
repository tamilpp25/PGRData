---@class XUiPanelGeneralSkill
local XUiPanelGeneralSkill = XClass(XUiNode, "XUiPanelGeneralSkill")

function XUiPanelGeneralSkill:Ctor(ui, parent, characterId, generalSkillIndex)
    self.CharacterId = characterId
    self.GeneralSkillIds = XMVCA.XCharacter:GetCharacterGeneralSkillIds(characterId)

    local btns = { self.BtnGeneralSkill1, self.BtnGeneralSkill2 }
    self.ButtonGroup:Init(btns, function(index)
        self:OnSelectTab(index)
    end)

    -- 自动选择
    self.ButtonGroup:SelectIndex(generalSkillIndex or 1)
    self:RefreshTop()
end

function XUiPanelGeneralSkill:OnSelectTab(index)
    self.CurSelectIndex = index
    self.CurGeneralSkillId = self.GeneralSkillIds[index]
    self:RefreshCurInfo()
end

function XUiPanelGeneralSkill:RefreshTop()
    if not self.CurGeneralSkillId then
        return
    end
    
    -- 顶部机制按钮
    for i = 1, self.ButtonGroup.TabBtnList.Count, 1 do
        local id = self.GeneralSkillIds[i]
        local btn = self.ButtonGroup.TabBtnList[i-1]
        btn.gameObject:SetActiveEx(id)
        if id then
            local genralSkillConfig = XMVCA.XCharacter:GetModelCharacterGeneralSkill()[id]
            btn:SetNameByGroup(0, genralSkillConfig.Name)
            btn:SetRawImage(genralSkillConfig.IconTranspose)
        end
    end

    -- 角色头像
    self.StandIcon:SetRawImage(XMVCA.XCharacter:GetCharRoundnessHeadIcon(self.CharacterId))
end

function XUiPanelGeneralSkill:RefreshCurInfo()
    if not self.CurGeneralSkillId then
        return
    end
    local isOwnChar = XMVCA.XCharacter:IsOwnCharacter(self.CharacterId)

    -- 机制详情
    local curGenralSkillConfig = XMVCA.XCharacter:GetModelCharacterGeneralSkill()[self.CurGeneralSkillId]
    self.TxtDescribe.text = curGenralSkillConfig.Desc

    -- 相关技能
    local lineMaxCount = 7 -- 每行最多的格子
    local maxListCount = 3 -- 提前预设计好的3个技能列表
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
                    local uiObj = grid:GetComponent("UiObject")
                    uiObj:GetObject("RImgSubSkillIconNormal"):SetRawImage(cfg.Icon)
                    if isOwnChar then
                        local character = XMVCA.XCharacter:GetCharacter(self.CharacterId)
                        level = character:GetSkillLevelBySkillId(skillId) or 1

                        local addLevel = XMVCA.XCharacter:GetSkillPlusLevel(self.CharacterId, skillId) or 0
                        level = level + addLevel

                        uiObj:GetObject("TxtLevel").text = XTool.IsNumberValid(level) and level or 1
                    else
                        uiObj:GetObject("TxtLevel").text = 1
                    end

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
                    if isOwnChar then
                        local character = XMVCA.XCharacter:GetCharacter(self.CharacterId)
                        local enhanceSkillGroupId = character:EnhanceSkillIdToGroupId(skillId)
                        local enhanceSkillGroup = character:GetEnhanceSkillGroupData(enhanceSkillGroupId)
                        level = enhanceSkillGroup:GetLevel() or 1
                        uiObj:GetObject("TxtLevel").text = XTool.IsNumberValid(level) and level or 1
                    else
                        uiObj:GetObject("TxtLevel").text = 1
                    end
            
                    local btn = uiObj:GetObject("Button")
                    XUiHelper.RegisterClickEvent(self, btn, function()
                        self:OnGridRelatedSkillClick(cfg, level)
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

    -- 相关角色
    local relatedChars = XMVCA.XCharacter:GetCharactersListByGeneralSkillId(self.CurGeneralSkillId)
    local filterConfig = XMVCA.XCharacter:GetModelCharacterFilterController()[self.Parent.Name]
    local sortFunList = filterConfig and filterConfig.SortTagList
    -- 用筛选器配置表排序
    local sortRes = relatedChars
    if sortFunList then
        local overrideTable = self:GetOverrideSortTable()
        sortRes = XMVCA.XCommonCharacterFilter:DoSortFilterV2P6(relatedChars, sortFunList, nil, overrideTable)
    end

    XUiHelper.RefreshCustomizedList(self.GridPlayerInfoCharacter.parent, self.GridPlayerInfoCharacter, #sortRes, function (index, grid)
        local uiObj = grid:GetComponent("UiObject")
        local charId = sortRes[index].Id

        -- 是否解锁
        local isOwnChar = XMVCA.XCharacter:IsOwnCharacter(charId)

        uiObj:GetObject("RImgHeadIcon"):SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(charId))
        uiObj:GetObject("RImgQuality"):SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(XMVCA.XCharacter:GetCharacterQuality(charId)))
        uiObj:GetObject("RImgGrade"):SetRawImage(XMVCA.XCharacter:GetCharGradeIcon(charId, (XMVCA.XCharacter:GetCharacterGrade(charId))))
        uiObj:GetObject("TxtLevel").text = XMVCA.XCharacter:GetCharacterLevel(charId)

        uiObj:GetObject("PanelGrade").gameObject:SetActiveEx(isOwnChar)
        uiObj:GetObject("PanelLevel").gameObject:SetActiveEx(isOwnChar)
        uiObj:GetObject("PanelLock").gameObject:SetActiveEx(not isOwnChar)
        uiObj:GetObject("PanelCurrent").gameObject:SetActiveEx(index == 1)

        local btn = uiObj:GetObject("BtnCharacter")
        XUiHelper.RegisterClickEvent(self, btn, function()
            self:OnGridPlayerInfoCharacterClick(charId)
        end)
    end)
end

function XUiPanelGeneralSkill:GetOverrideSortTable()
    local curSeleCharId = self.CharacterId
    local sortOverride = {
        CheckFunList = {
            [CharacterSortFunType.Custom1] = function(idA, idB)
                local isA = curSeleCharId == idA
                local isB = curSeleCharId == idB
                if isA or isB then
                    return true
                end
            end
        },
        SortFunList = {
            [CharacterSortFunType.Custom1] = function(idA, idB)
                local isA = curSeleCharId == idA
                local isB = curSeleCharId == idB
                if isA ~= isB then
                    return isA
                end
                return false
            end
        }
    }
    return sortOverride
end

function XUiPanelGeneralSkill:OnGridRelatedSkillClick(config, skillLv)
    XLuaUiManager.Open("UiSkillDetailsTips", config, skillLv)
end

function XUiPanelGeneralSkill:OnGridPlayerInfoCharacterClick(charId)
    local filterGo = CS.UnityEngine.GameObject.Find("UiPanelCommonCharacterFilterV2P6(Clone)")
    if filterGo and filterGo.activeInHierarchy then
        local filterProxy = XMVCA.XCommonCharacterFilter:GetFilterProxyByTransfrom(filterGo.transform)
        if filterProxy.Parent and filterProxy.Parent.Name == XModelManager.MODEL_UINAME.XUiCharacterV2P6 then
            filterProxy:DoSelectTag(XEnumConst.Filter.TagName.BtnAll, nil, charId)
            self.Parent:Close()
            return
        end
    end

    XLuaUiManager.Open("UiCharacterSystemV2P6", charId)
end

return XUiPanelGeneralSkill