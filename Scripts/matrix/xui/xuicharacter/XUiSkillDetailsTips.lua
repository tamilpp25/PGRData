--===========================================================================
---@desc 技能预览详情界面
--===========================================================================
local XUiSkillDetailsTips = XLuaUiManager.Register(XLuaUi, "UiSkillDetailsTips")
local SIGNAL_BAL_MEMBER = 3 --信号球技能（红黄蓝)

function XUiSkillDetailsTips:OnAwake()
    self:RegisterUiEvents()
    self.Attribute.gameObject:SetActiveEx(false)
    self.TxtSkillTitle.gameObject:SetActiveEx(false)
    self.TxtSkillSpecific.gameObject:SetActiveEx(false)
end

function XUiSkillDetailsTips:OnStart(data)
    if not data then
        return
    end
    -- 技能名称
    self.TxtSkillName.text = data.Name
    -- 技能类型
    self.TxtSkillType.text = data.TypeDes and CSXTextManagerGetText("CharacterSkillTypeText", data.TypeDes) or ""
    -- 技能图标
    local skillType = XCharacterConfigs.GetSkillType(data.SkillId)
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
end

function XUiSkillDetailsTips:SetTextInfo(target, parent, info)
    local go = XUiHelper.Instantiate(target, parent)
    go:SetActiveEx(true)
    local goTxt = go:GetComponent("Text")
    goTxt.text = XUiHelper.ConvertLineBreakSymbol(info)
end

function XUiSkillDetailsTips:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
end

function XUiSkillDetailsTips:OnBtnCloseClick()
    self:Close()
end

return XUiSkillDetailsTips