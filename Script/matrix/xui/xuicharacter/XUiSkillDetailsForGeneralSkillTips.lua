--===========================================================================
---@desc 技能预览详情界面
--===========================================================================
local XUiSkillDetailsForGeneralSkillTips = XLuaUiManager.Register(XLuaUi, "UiSkillDetailsForGeneralSkillTips")
local SIGNAL_BAL_MEMBER = 3 --信号球技能（红黄蓝)

function XUiSkillDetailsForGeneralSkillTips:OnAwake()
    self:RegisterUiEvents()
    self.Attribute.gameObject:SetActiveEx(false)
    self.TxtSkillTitle.gameObject:SetActiveEx(false)
    self.TxtSkillSpecific.gameObject:SetActiveEx(false)
end

function XUiSkillDetailsForGeneralSkillTips:OnStart(data, skillLv, syncClickLock, forceHideGotoEnhanceSkillBtn)
    if not data then
        return
    end
    self.Data = data
    -- 技能名称
    self.TxtSkillName.text = data.Name
    -- 技能等级
    self.TxtLvNum.text = skillLv or 1
    -- 技能类型
    self.TxtSkillType.text = data.TypeDes and CSXTextManagerGetText("CharacterSkillTypeText", data.TypeDes) or ""
    -- 技能图标
    local skillType = XMVCA.XCharacter:GetSkillType(data.SkillId)
    local isSignalBal = skillType <= SIGNAL_BAL_MEMBER
    self.ImgSkillPointIcon:SetRawImage(data.Icon)
    self.ImgBlueBall:SetRawImage(data.Icon)
    self.ImgSkillPointIcon.gameObject:SetActiveEx(not isSignalBal)
    self.ImgBlueBall.gameObject:SetActiveEx(isSignalBal)
    -- 技能标签
    for _, tag in pairs(data.Tag or {}) do
        local grid = XUiHelper.Instantiate(self.Attribute, self.PanelAttribute)
        local tagUi = {}
        XTool.InitUiObjectByUi(tagUi, grid)
        tagUi.Name.text = tag
        grid.gameObject:SetActiveEx(true)
    end
    -- 技能详细描述
    for index, specificDes in pairs(data.SpecificDes or {}) do
        local title = data.Title[index]
        if title then
            self:SetTextInfo(self.TxtSkillTitle.gameObject, self.PanelReward, title)
        end
        self:SetTextInfo(self.TxtSkillSpecific.gameObject, self.PanelReward, specificDes)
    end
    -- 独域技能
    local isEnhanceSkill = XMVCA.XCharacter:GetEnhanceSkillGradeDescBySkillIdAndLevel(data.SkillId, 1, true)
    if isEnhanceSkill and data.Intro then
        self.ImgSkillPointIcon.gameObject:SetActiveEx(true)
        self.ImgBlueBall.gameObject:SetActiveEx(false)

        local title = data.Name
        if title then
            self:SetTextInfo(self.TxtSkillTitle.gameObject, self.PanelReward, title)
        end
        self:SetTextInfo(self.TxtSkillSpecific.gameObject, self.PanelReward, data.Intro)
    end

    -- 是否显示跃升跳转按钮
    local isEnhanceSkillLock = true
    local character = nil
    if isEnhanceSkill then
        local characterId = XMVCA.XCharacter:GetCharacterIdByEnhanceSkillId(data.SkillId)
        character = XMVCA.XCharacter:GetCharacter(characterId)
    end

    if character then
        local enhanceSkillList = character.EnhanceSkillList
        for k, v in pairs(enhanceSkillList) do
            if data.SkillId == v.Id then
                isEnhanceSkillLock = false
                break
            end
        end
    end
    
    local isShowBtnGotoEnhanceSkill = character and isEnhanceSkill and syncClickLock and not forceHideGotoEnhanceSkillBtn
    self.BtnGotoEnhanceSkill.gameObject:SetActiveEx(isShowBtnGotoEnhanceSkill)
end

function XUiSkillDetailsForGeneralSkillTips:SetTextInfo(target, parent, info)
    local go = XUiHelper.Instantiate(target, parent)
    go:SetActiveEx(true)
    local goTxt = go:GetComponent("Text")
    goTxt.text = XUiHelper.ConvertLineBreakSymbol(info)
end

function XUiSkillDetailsForGeneralSkillTips:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnGotoEnhanceSkill, self.OnBtnGotoEnhanceSkillClick)
end

function XUiSkillDetailsForGeneralSkillTips:OnBtnCloseClick()
    self:Close()
end

function XUiSkillDetailsForGeneralSkillTips:OnBtnGotoEnhanceSkillClick()
    if not self.Data then
        return
    end

    local characterId = XMVCA.XCharacter:GetCharacterIdByEnhanceSkillId(self.Data.SkillId)
    local index = XMVCA.XCharacter:GetIndexByEnhanceSkillId(self.Data.SkillId)
    XLuaUiManager.PopThenOpen("UiSkillDetailsParentV2P6", characterId, XEnumConst.CHARACTER.SkillDetailsType.Enhance, nil, index)
end

return XUiSkillDetailsForGeneralSkillTips