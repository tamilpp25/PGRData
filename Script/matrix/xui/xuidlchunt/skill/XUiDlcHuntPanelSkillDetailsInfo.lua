local XUiPanelSkillDetailsInfo = XClass(nil, "XUiPanelSkillDetailsInfo")

-- 触发拖拽前的延时
local LONG_CLICK_OFFSET = 0.2
local LONG_PRESS_PARAMS = 500
local SIGNAL_BAL_MEMBER = 3 --信号球技能（红黄蓝)
local DescribeType = {
    Title = 1,
    Specific = 2,
}

function XUiPanelSkillDetailsInfo:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self.Attribute.gameObject:SetActiveEx(false)
    self.TxtSkillTitle.gameObject:SetActiveEx(false)
    self.TxtSkillSpecific.gameObject:SetActiveEx(false)
    
    self.SkillTag = {}
    self.TxtSkillTitleGo = {}
    self.TxtSkillSpecificGo = {}
end

function XUiPanelSkillDetailsInfo:Refresh(characterId, subSkill, isDetails)
    self.CharacterId = characterId
    self.SubSkill = subSkill
    self.IsDetails = isDetails
    self:RefreshSubSkillInfoPanel(subSkill)
end

function XUiPanelSkillDetailsInfo:RefreshSubSkillInfoPanel()
    self:RefreshSkillView()
end

function XUiPanelSkillDetailsInfo:RefreshSkillView()
    local configDes = self.SubSkill
    -- 技能名称
    self.TxtSkillName.text = configDes.Name
    -- 技能类型
    self.TxtSkillType.text = configDes.TypeDes and CSXTextManagerGetText("CharacterSkillTypeText", configDes.TypeDes) or ""
    -- 技能图标
    local skillType = XMVCA.XCharacter:GetSkillType(self.SubSkillId)
    local isSignalBal = skillType <= SIGNAL_BAL_MEMBER
    self.ImgSkillPointIcon:SetRawImage(configDes.Icon)
    self.ImgBlueBall:SetRawImage(configDes.Icon)
    self.ImgSkillPointIcon.gameObject:SetActiveEx(not isSignalBal)
    self.ImgBlueBall.gameObject:SetActiveEx(isSignalBal)
    -- 技能标签
    --for index, tag in pairs(configDes.Tag or {}) do
    --    local grid = self.SkillTag[index]
    --    if not grid then
    --        grid = XUiHelper.Instantiate(self.Attribute, self.PanelAttribute)
    --        self.SkillTag[index] = grid
    --    end
    --    local tagUi = {}
    --    XTool.InitUiObjectByUi(tagUi, grid)
    --    tagUi.Name.text = tag
    --    grid.gameObject:SetActiveEx(true)
    --end
    --for i = #configDes.Tag + 1, #self.SkillTag do
    --    self.SkillTag[i].gameObject:SetActiveEx(false)
    --end
    -- 技能描述
    self:RefreshSkillDescribe(self.IsDetails)
end

function XUiPanelSkillDetailsInfo:RefreshSkillDescribe(isDetails)
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
        messageDes = self.SubSkill.SpecificDes
    else
        messageDes = self.SubSkill.BriefDes
    end
    for index, message in pairs(messageDes or {}) do
        local title = self.SubSkill.Title[index]
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

function XUiPanelSkillDetailsInfo:SetTextInfo(txtType, index, info)
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

return XUiPanelSkillDetailsInfo