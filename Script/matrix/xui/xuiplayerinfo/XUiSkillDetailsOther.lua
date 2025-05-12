local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiSkillDetailsOther = XLuaUiManager.Register(XLuaUi, "UiSkillDetailsOther")
local XUiPanelSkillDetailsInfoOther = require("XUi/XUiPlayerInfo/XUiPanelSkillDetailsInfoOther")
local XUiPanelSkillLevelDetail = require("XUi/XUiCharacter/XUiPanelSkillLevelDetail")

local RESONANCE_GRID_TEXT_COLOR = {
    [true] = XUiHelper.Hexcolor2Color("fee82aff"),
    [false] = XUiHelper.Hexcolor2Color("ffffffff"),
}
local SIGNAL_BAL_MEMBER = 3 --信号球技能（红黄蓝)

function XUiSkillDetailsOther:OnAwake()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.SkillPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:RegisterUiEvents()
    self.BtnTog.gameObject:SetActiveEx(false)     --信号球技能（红黄蓝)
    self.BtnSpecial.gameObject:SetActiveEx(false)
    self.SkillBtnGroups = {}
    self.SkillBtnSpecialGroups = {}               --信号球技能（红黄蓝)
    self.IsDetails = false
end

function XUiSkillDetailsOther:OnStart(characterId, skills, pos, npcData, assignChapterRecords)
    self.CharacterId = characterId or self.CharacterId
    self.Skills = skills
    self.Pos = pos
    self.Skill = skills[pos]
    self.NpcData = npcData
    self.AssignChapterRecords = assignChapterRecords
    -- 默认显示第一个
    self.CurrentSkillSelect = 1

    self.SkillInfoPanel = XUiPanelSkillDetailsInfoOther.New(self.PanelSkillInfo, self)

    self.LevelDetailPanel = XUiPanelSkillLevelDetail.New(self.PanelSkillDetails)
    self.LevelDetailPanel.GameObject:SetActive(false)

    self:InitModelRoot()
    self:InitSkillBtn()
end

function XUiSkillDetailsOther:OnEnable()
    if self.AssetPanel then
        self.AssetPanel.GameObject:SetActiveEx(false)
    end
    
    self:RefreshViewData()
    self:RefreshSkillInfo()
    -- 详情默认值
    self.Toggle.isOn = XEnumConst.CHARACTER.BUTTON_SKILL_DETAILS_ACTIVE
    self:OnToggle()
end

function XUiSkillDetailsOther:InitModelRoot()
    local root = self.UiModelGo
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.EffectHuanren1 = root:FindTransform("ImgEffectHuanren1")
    self.EffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.EffectHuanren.gameObject:SetActiveEx(false)
    self.EffectHuanren1.gameObject:SetActiveEx(false)
end

function XUiSkillDetailsOther:InitSkillBtn()
    self:HideAllSkillBtn()
    local tabGroup = {}
    for index, subSkill in pairs(self.Skill.subSkills) do
        local btn = self:GetSkillBtn(index, subSkill)
        if not btn then
            local btnGo = XUiHelper.Instantiate(self:GetSkillBtnGameObject(subSkill), self.PanelTagGroup.transform)
            btn = btnGo:GetComponent("XUiButton")
            self:SetSkillBtn(index, subSkill, btn)
        end
        btn.gameObject:SetActiveEx(true)
        btn.transform:SetAsLastSibling()
        tabGroup[index] = btn
    end
    self.PanelTagGroup:Init(tabGroup, function(tabIndex)
        self:OnClickTabCallBack(tabIndex)
    end)
end

function XUiSkillDetailsOther:RefreshViewData()
    -- 技能模块名称
    self.TxtName.text = self.Skill.Name
end

function XUiSkillDetailsOther:RefreshSkillInfo()
    for index, subSkill in pairs(self.Skill.subSkills) do
        local btn = self:GetSkillBtn(index, subSkill)
        self:SetBtnInfo(btn, subSkill)
    end
    self.PanelTagGroup:SelectIndex(self.CurrentSkillSelect)
end

function XUiSkillDetailsOther:HideAllSkillBtn()
    -- 隐藏所以按钮
    for _, btn in pairs(self.SkillBtnGroups) do
        btn.gameObject:SetActiveEx(false)
    end
    for _, btn in pairs(self.SkillBtnSpecialGroups) do
        btn.gameObject:SetActiveEx(false)
    end
end

function XUiSkillDetailsOther:GetSkillBtn(index, subSkill)
    local skillType = XMVCA.XCharacter:GetSkillType(subSkill.SubSkillId)
    if skillType <= SIGNAL_BAL_MEMBER then
        return self.SkillBtnSpecialGroups[index]
    else
        return self.SkillBtnGroups[index]
    end
end

function XUiSkillDetailsOther:GetSkillBtnGameObject(subSkill)
    local skillType = XMVCA.XCharacter:GetSkillType(subSkill.SubSkillId)
    if skillType <= SIGNAL_BAL_MEMBER then
        return self.BtnTog
    else
        return self.BtnSpecial
    end
end

function XUiSkillDetailsOther:SetSkillBtn(index, subSkill, btn)
    local skillType = XMVCA.XCharacter:GetSkillType(subSkill.SubSkillId)
    if skillType <= SIGNAL_BAL_MEMBER then
        self.SkillBtnSpecialGroups[index] = btn
    else
        self.SkillBtnGroups[index] = btn
    end
end

function XUiSkillDetailsOther:SetBtnInfo(btn, subSkillInfo)
    if (subSkillInfo.configDes.Icon and subSkillInfo.configDes.Icon ~= "") then
        -- 技能Icon
        btn:SetSprite(subSkillInfo.configDes.Icon)
    else
        XLog.Warning("sub skill config icon is null. id = " .. subSkillInfo.SubSkillId)
    end

    local addLevel = 0
    local resonanceSkillLevelMap = XMagicSkillManager.GetResonanceSkillLevelMap(self.NpcData)
    local resonanceSkillLevel = resonanceSkillLevelMap[subSkillInfo.SubSkillId] or 0
    addLevel = addLevel + resonanceSkillLevel + XDataCenter.FubenAssignManager.GetSkillLevelByCharacterData(self.NpcData.Character, subSkillInfo.SubSkillId, self.AssignChapterRecords)

    local totalLevel = subSkillInfo.Level + addLevel
    local curLevel = totalLevel == 0 and '' or CS.XTextManager.GetText("HostelDeviceLevel") .. ':' .. totalLevel
    -- 技能等级
    btn:SetNameAndColorByGroup(0, curLevel, RESONANCE_GRID_TEXT_COLOR[addLevel > 0])

    local ImgLocks = {
        btn.transform:Find("Normal/ImgLcok"),
        btn.transform:Find("Press/ImgLcok"),
        btn.transform:Find("Select/ImgLcok"),
    }
    btn:ShowReddot(false)
    local min_max = XMVCA.XCharacter:GetSubSkillMinMaxLevel(subSkillInfo.SubSkillId)
    if (subSkillInfo.Level >= min_max.Max) then
        self:ActiveImageLock(ImgLocks, false)
    else
        self:ActiveImageLock(ImgLocks, subSkillInfo.Level <= 0)
    end
end

function XUiSkillDetailsOther:ActiveImageLock(ImgLock, active)
    for _, lock in pairs(ImgLock) do
        if lock then
            lock.gameObject:SetActiveEx(active)
        end
    end
end

function XUiSkillDetailsOther:OnClickTabCallBack(tabIndex)
    self.CurrentSkillSelect = tabIndex
    self:HideLevelDetail()
    self.SkillInfoPanel:Refresh(self.CharacterId, self.Skill.subSkills[tabIndex], self.NpcData, self.AssignChapterRecords, self.IsDetails)
    self:PlayAnimation("QieHuan2")
end

function XUiSkillDetailsOther:GotoSkill(index)
    self.Pos = index
    self.Skill = self.Skills[index]
    -- 默认显示第一个
    self.CurrentSkillSelect = 1
    self:InitSkillBtn()
    self:RefreshSkillInfo()
    self:RefreshViewData()
    self:PlayAnimation("QieHuan1")
end

function XUiSkillDetailsOther:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.BtnNext, self.OnBtnNext)
    XUiHelper.RegisterClickEvent(self, self.BtnLast, self.OnBtnLast)
    XUiHelper.RegisterClickEvent(self, self.Toggle, self.OnToggle)
end
--region 按钮相关

function XUiSkillDetailsOther:OnBtnBackClick()
    self:Close()
end

function XUiSkillDetailsOther:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end
-- 下一个
function XUiSkillDetailsOther:OnBtnNext()
    if self.Pos then
        local nextPos = self.Pos + 1
        if nextPos > XEnumConst.CHARACTER.MAX_SHOW_SKILL_POS then
            nextPos = 1
        end
        self:GotoSkill(nextPos)
    end
end
-- 上一个
function XUiSkillDetailsOther:OnBtnLast()
    if self.Pos then
        local lastPos = self.Pos - 1
        if lastPos < 1 then
            lastPos = XEnumConst.CHARACTER.MAX_SHOW_SKILL_POS
        end
        self:GotoSkill(lastPos)
    end
end

function XUiSkillDetailsOther:OnToggle()
    self.IsDetails = self.Toggle.isOn
    XEnumConst.CHARACTER.BUTTON_SKILL_DETAILS_ACTIVE = self.IsDetails
    self.SkillInfoPanel:RefreshSkillDescribe(self.IsDetails)
    self:PlayAnimation("QieHuan3")
end

--endregion

function XUiSkillDetailsOther:ShowLevelDetail(skillId)
    self.LevelDetailPanel.GameObject:SetActiveEx(true)
    self.LevelDetailPanel:RefreshByNpcData(self.NpcData, skillId, self.AssignChapterRecords)
end

function XUiSkillDetailsOther:HideLevelDetail()
    self.LevelDetailPanel.GameObject:SetActiveEx(false)
end

return XUiSkillDetailsOther