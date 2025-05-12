local XUiPanelEvoSkillTips = XClass(XUiNode, "XUiPanelEvoSkillTips")

function XUiPanelEvoSkillTips:Ctor(ui, parent)
    XUiHelper.RegisterClickEvent(self, self.Btn, self.OnBtnClick)
end

function XUiPanelEvoSkillTips:OnEnable()
    self.FirstEnable = true
end

-- 存在已激活的品质，且有进化技能，且技能未解锁
function XUiPanelEvoSkillTips:CheckShow(characterId)
    if not characterId then
        return
    end
    self.CharacterId = characterId

    local res, curApartSkillId, curSkillId, curLevel, skillCount = XMVCA.XCharacter:CheckCharEvoSkillTipsShow(self.CharacterId)
    self.CurSkillApartId = curApartSkillId             
    self.CurSkillId = curSkillId  
    self.CurLevel = curLevel
    self.SkillCount = skillCount

    if res then
        self:Open()
    else
        self:Close()
    end

    self:Refresh()
end

function XUiPanelEvoSkillTips:CheckRedPoint()
    if not self.CurSkillId then
        return false
    end
    return XMVCA.XCharacter:CheckCanUpdateSkill(self.CharacterId, self.CurSkillId, self.CurLevel)
end

function XUiPanelEvoSkillTips:Refresh()
    if not self.CurSkillApartId then
        return
    end

    local skillName = XMVCA.XCharacter:GetCharSkillQualityApartName(self.CurSkillApartId)
    local skillLevel = XMVCA.XCharacter:GetCharSkillQualityApartLevel(self.CurSkillApartId)
    local skillNameText = skillName .. "Lv" .. skillLevel
    self.Btn:SetNameByGroup(0, skillNameText)

    -- 蓝点
    local isRed = self:CheckRedPoint()
    self.Btn:ShowReddot(isRed)

    -- 省略号
    local isShowEllipsis = self.SkillCount and self.SkillCount > 1
    self.Text2.gameObject:SetActiveEx(isShowEllipsis)
end

function XUiPanelEvoSkillTips:OnBtnClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.CharacterSkill) then
        return
    end
    local characterId = self.CharacterId
    local skillId = XMVCA.XCharacter:GetCharSkillQualityApartSkillId(self.CurSkillApartId)

    local skillGroupId, index = XMVCA.XCharacter:GetSkillGroupIdAndIndex(skillId)
    local skillPosToGroupIdDic = XMVCA.XCharacter:GetChracterSkillPosToGroupIdDic(characterId)
    for pos, group in ipairs(skillPosToGroupIdDic) do
        for gridIndex, id in ipairs(group) do
            if id == skillGroupId then
                XLuaUiManager.Open("UiSkillDetailsParentV2P6", characterId, XEnumConst.CHARACTER.SkillDetailsType.Normal, pos, gridIndex)
                self.QualityToSkill = true
                return
            end
        end
    end
end

return XUiPanelEvoSkillTips