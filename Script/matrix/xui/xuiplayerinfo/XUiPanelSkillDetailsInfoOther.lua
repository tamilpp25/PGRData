local XUiPanelSkillDetailsInfoOther = XClass(nil, "XUiPanelSkillDetailsInfoOther")

local SIGNAL_BAL_MEMBER = 3 --信号球技能（红黄蓝)
local DescribeType = {
    Title = 1,
    Specific = 2,
}

function XUiPanelSkillDetailsInfoOther:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:RegisterUiEvents()
    self.SubSkillInfo.gameObject:SetActive(false)
    self.PanelMask.gameObject:SetActiveEx(false)
    self.Attribute.gameObject:SetActiveEx(false)
    self.TxtSkillTitle.gameObject:SetActiveEx(false)
    self.TxtSkillSpecific.gameObject:SetActiveEx(false)

    self.SkillTag = {}
    self.TxtSkillTitleGo = {}
    self.TxtSkillSpecificGo = {}
end

function XUiPanelSkillDetailsInfoOther:Refresh(characterId, subSkill, npcData, assignChapterRecords, isDetails)
    self.CharacterId = characterId
    self.SubSkill = subSkill
    self.NpcData = npcData
    self.AssignChapterRecords = assignChapterRecords
    self.IsDetails = isDetails
    self:RefreshSubSkillInfoPanel(subSkill)
end

function XUiPanelSkillDetailsInfoOther:RefreshSubSkillInfoPanel(subSkill)
    self:RefreshSkillLevel(subSkill)
    self:RefreshSkillView()
end

function XUiPanelSkillDetailsInfoOther:RefreshSkillLevel(subSkill)
    self.SubSkillId  = subSkill.SubSkillId
    local levelStr = subSkill.Level

    local addLevel = 0
    local addLevelStr = ""
    local resonanceSkillLevelMap = XMagicSkillManager.GetResonanceSkillLevelMap(self.NpcData)
    local resonanceLevel = resonanceSkillLevelMap[self.SubSkillId] or 0

    local assignLevel = XDataCenter.FubenAssignManager.GetSkillLevelByCharacterData(self.NpcData.Character, self.SubSkillId, self.AssignChapterRecords)

    if (resonanceLevel and resonanceLevel > 0) then
        addLevel = addLevel + resonanceLevel
    end

    if (assignLevel and assignLevel > 0) then
        addLevel = addLevel + assignLevel
    end

    if addLevel ~= 0 then
        addLevelStr = addLevelStr .. CS.XTextManager.GetText("CharacterSkillLevelDetail", addLevel)
        levelStr = levelStr .. addLevelStr
        self.BtnDetails.gameObject:SetActiveEx(true)
    else
        self.BtnDetails.gameObject:SetActiveEx(false)
    end

    self.GradeConfig = XMVCA.XCharacter:GetSkillGradeDesWithDetailConfig(self.SubSkillId, subSkill.Level + addLevel)
    self.TxtSkillLevel.text = levelStr
end

function XUiPanelSkillDetailsInfoOther:RefreshSkillView()
    local configDes = self.GradeConfig
    -- 技能名称
    self.TxtSkillName.text = configDes.Name
    -- 技能类型
    self.TxtSkillType.text = configDes.TypeDes and CSXTextManagerGetText("CharacterSkillTypeText", configDes.TypeDes) or ""
    -- 技能图标
    local skillType = XCharacterConfigs.GetSkillType(self.SubSkillId)
    local isSignalBal = skillType <= SIGNAL_BAL_MEMBER
    self.ImgSkillPointIcon:SetRawImage(configDes.Icon)
    self.ImgBlueBall:SetRawImage(configDes.Icon)
    self.ImgSkillPointIcon.gameObject:SetActiveEx(not isSignalBal)
    self.ImgBlueBall.gameObject:SetActiveEx(isSignalBal)
    -- 技能标签
    for index, tag in pairs(configDes.Tag or {}) do
        local grid = self.SkillTag[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.Attribute, self.PanelAttribute)
            self.SkillTag[index] = grid
        end
        local tagUi = {}
        XTool.InitUiObjectByUi(tagUi, grid)
        tagUi.Name.text = tag
        grid.gameObject:SetActiveEx(true)
    end
    for i = #configDes.Tag + 1, #self.SkillTag do
        self.SkillTag[i].gameObject:SetActiveEx(false)
    end
    -- 技能描述
    self:RefreshSkillDescribe(self.IsDetails)
end

function XUiPanelSkillDetailsInfoOther:RefreshSkillDescribe(isDetails)
    -- 隐藏
    for _, go in pairs(self.TxtSkillTitleGo) do
        go:SetActiveEx(false)
    end
    for _, go in pairs(self.TxtSkillSpecificGo) do
        go:SetActiveEx(false)
    end
    -- 显示
    local messageDes = {}
    if isDetails then
        messageDes = self.GradeConfig.SpecificDes
    else
        messageDes = self.GradeConfig.BriefDes
    end
    for index, message in pairs(messageDes or {}) do
        local title = self.GradeConfig.Title[index]
        if title then
            self:SetTextInfo(DescribeType.Title, index, title)
        end
        self:SetTextInfo(DescribeType.Specific, index, message)
    end
    -- 每次刷新技能描述时，都从最开头进行显示
    if self.GridSkillInfo then
        self.GridSkillInfo.verticalNormalizedPosition = 1
    end
end

function XUiPanelSkillDetailsInfoOther:SetTextInfo(txtType, index, info)
    local txtSkillGo = {}
    local target
    if txtType == DescribeType.Title then
        txtSkillGo = self.TxtSkillTitleGo
        target = self.TxtSkillTitle.gameObject
    else
        txtSkillGo = self.TxtSkillSpecificGo
        target = self.TxtSkillSpecific.gameObject
    end
    local txtGo = txtSkillGo[index]
    if not txtGo then
        txtGo = XUiHelper.Instantiate(target, self.PanelReward)
        txtSkillGo[index] = txtGo
    end
    txtGo:SetActiveEx(true)
    local goTxt = txtGo:GetComponent("Text")
    goTxt.text = XUiHelper.ConvertLineBreakSymbol(info)
    txtGo.transform:SetAsLastSibling()
end

--region 按钮相关

function XUiPanelSkillDetailsInfoOther:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnDetails, self.OnBtnDetails)
end

function XUiPanelSkillDetailsInfoOther:OnBtnDetails()
    self.RootUi:ShowLevelDetail(self.SubSkillId)
end

--endregion

return XUiPanelSkillDetailsInfoOther