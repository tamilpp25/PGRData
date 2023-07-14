local XUiSkillDetails = XLuaUiManager.Register(XLuaUi, "UiSkillDetails")
local XUiPanelSkillDetailsInfo = require("XUi/XUiCharacter/XUiPanelSkillDetailsInfo")
local XUiPanelSkillLevelDetail = require("XUi/XUiCharacter/XUiPanelSkillLevelDetail")

local RESONANCE_GRID_TEXT_COLOR = {
    [true] = XUiHelper.Hexcolor2Color("fee82aff"),
    [false] = XUiHelper.Hexcolor2Color("ffffffff"),
}
local SIGNAL_BAL_MEMBER = 3 --信号球技能（红黄蓝)

function XUiSkillDetails:OnAwake()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.SkillPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:RegisterUiEvents()
    self.BtnTog.gameObject:SetActiveEx(false)     --信号球技能（红黄蓝)
    self.BtnSpecial.gameObject:SetActiveEx(false)
    self.SkillBtnGroups = {}  
    self.SkillBtnSpecialGroups = {}               --信号球技能（红黄蓝)
    self.IsDetails = false
end

function XUiSkillDetails:OnStart(characterId, skills, pos, gridIndex)
    -- self.CharacterId = characterId or self.CharacterId
    -- self.Skills = skills
    -- self.Pos = pos
    -- self.Skill = skills[pos]
    -- 默认显示第一个
    -- self.CurrentSkillSelect = gridIndex or 1
    self:RefreshDataByChangePage(characterId, skills, pos, gridIndex)

    self.SkillInfoPanel = XUiPanelSkillDetailsInfo.New(self.PanelSkillInfo, self)

    self.LevelDetailPanel = XUiPanelSkillLevelDetail.New(self.PanelSkillDetails)
    self.LevelDetailPanel.GameObject:SetActive(false)

    self:InitModelRoot()
    self:InitSkillBtn()

    XEventManager.AddEventListener(XEventId.EVENT_ITEM_FAST_TRADING, self.RefreshSkillDataByFastBuy, self)
end

function XUiSkillDetails:RefreshDataByChangePage(characterId, skills, pos, gridIndex)
    self.CharacterId = characterId or self.CharacterId
    self.Skills = skills
    self.Pos = pos
    self.Skill = skills[pos]
    -- 默认显示第一个
    self.CurrentSkillSelect = gridIndex or 1
end

function XUiSkillDetails:OnEnable()
    -- 改用统一的gotoskill刷新界面
    self:GotoSkill(self.Pos)
    -- 详情默认值
    self.Toggle.isOn = XUiPanelCharSkill.BUTTON_SKILL_DETAILS_ACTIVE
    self:OnToggle()
end

function XUiSkillDetails:OnGetEvents()
    return {
        XEventId.EVENT_ITEM_USE,
    }
end

function XUiSkillDetails:OnNotify(event, ...)
    if event == XEventId.EVENT_ITEM_USE then
        self:RefreshSkillInfo()    
    end
end

function XUiSkillDetails:OnDisable()
    self.SkillInfoPanel:OnDisable()
end

function XUiSkillDetails:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_ITEM_FAST_TRADING, self.RefreshSkillDataByFastBuy, self)
end

function XUiSkillDetails:Close()
    XDataCenter.FavorabilityManager.ResetLastPlaySkillCvTime()
    self.Super.Close(self)
end

function XUiSkillDetails:InitModelRoot()
    local root = self.ParentUi.UiModelGo
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.EffectHuanren1 = root:FindTransform("ImgEffectHuanren1")
    self.EffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.EffectHuanren.gameObject:SetActiveEx(false)
    self.EffectHuanren1.gameObject:SetActiveEx(false)
end

function XUiSkillDetails:InitSkillBtn()
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

function XUiSkillDetails:RefreshViewData()
    -- 技能模块名称
    self.TxtName.text = self.Skill.Name
    self.TxtNameEn.text = self.Skill.EnName
    self.SkillIcon:SetRawImage(self.Skill.Icon)
end

function XUiSkillDetails:RefreshSkillInfo()
    for index, subSkill in pairs(self.Skill.subSkills) do
        local btn = self:GetSkillBtn(index, subSkill)
        self:SetBtnInfo(btn, subSkill)
    end
    self.PanelTagGroup:SelectIndex(self.CurrentSkillSelect)
end

function XUiSkillDetails:HideAllSkillBtn()
    -- 隐藏所以按钮
    for _, btn in pairs(self.SkillBtnGroups) do
        btn.gameObject:SetActiveEx(false)
    end
    for _, btn in pairs(self.SkillBtnSpecialGroups) do
        btn.gameObject:SetActiveEx(false)
    end
end

function XUiSkillDetails:GetSkillBtn(index, subSkill)
    local skillType = XCharacterConfigs.GetSkillType(subSkill.SubSkillId)
    if skillType <= SIGNAL_BAL_MEMBER then
        return self.SkillBtnSpecialGroups[index]
    else
        return self.SkillBtnGroups[index]
    end
end

function XUiSkillDetails:GetSkillBtnGameObject(subSkill)
    local skillType = XCharacterConfigs.GetSkillType(subSkill.SubSkillId)
    if skillType <= SIGNAL_BAL_MEMBER then
        return self.BtnTog
    else
        return self.BtnSpecial
    end
end

function XUiSkillDetails:SetSkillBtn(index, subSkill, btn)
    local skillType = XCharacterConfigs.GetSkillType(subSkill.SubSkillId)
    if skillType <= SIGNAL_BAL_MEMBER then
        self.SkillBtnSpecialGroups[index] = btn
    else
        self.SkillBtnGroups[index] = btn
    end
end

function XUiSkillDetails:SetBtnInfo(btn, subSkillInfo)
    if subSkillInfo.configDes and (subSkillInfo.configDes.Icon and subSkillInfo.configDes.Icon ~= "") then
        -- 技能Icon
        btn:SetSprite(subSkillInfo.configDes.Icon)
    else
        XLog.Warning("sub skill config icon is null. id = " .. subSkillInfo.SubSkillId)
    end

    local addLevel = XDataCenter.CharacterManager.GetSkillPlusLevel(self.CharacterId, subSkillInfo.SubSkillId)
    local totalLevel = subSkillInfo.Level + addLevel
    local curLevel = totalLevel == 0 and '' or CS.XTextManager.GetText("HostelDeviceLevel") .. ':' .. totalLevel
    -- 技能等级
    btn:SetNameAndColorByGroup(0, curLevel, RESONANCE_GRID_TEXT_COLOR[addLevel > 0])
    
    local ImgLocks = {
        btn.transform:Find("Normal/ImgLcok"),
        btn.transform:Find("Press/ImgLcok"),
        btn.transform:Find("Select/ImgLcok"),
    }
    local min_max = XCharacterConfigs.GetSubSkillMinMaxLevel(subSkillInfo.SubSkillId)
    if (subSkillInfo.Level >= min_max.Max) then
        self:ActiveImageLock(ImgLocks, false)
        btn:ShowReddot(false)
    else
        self:ActiveImageLock(ImgLocks, subSkillInfo.Level <= 0)
        btn:ShowReddot(XDataCenter.CharacterManager.CheckCanUpdateSkill(self.CharacterId, subSkillInfo.SubSkillId, subSkillInfo.Level))
    end
end

function XUiSkillDetails:ActiveImageLock(ImgLock, active)
    for _, lock in pairs(ImgLock) do
        if lock then
            lock.gameObject:SetActiveEx(active)
        end
    end
end

function XUiSkillDetails:OnClickTabCallBack(tabIndex)
    self.CurrentSkillSelect = tabIndex
    self:HideLevelDetail()
    self.SkillInfoPanel:Refresh(self.CharacterId, self.Skill.subSkills[tabIndex], self.IsDetails)
    self:PlayAnimation("QieHuan2")
    --XEventManager.DispatchEvent(XEventId.EVENT_GUIDE_STEP_OPEN_EVENT) -- TODO 引导
end

function XUiSkillDetails:GotoSkill(index)
    self.Pos = index
    self.Skill = self.Skills[index]
    -- 默认显示第一个
    self.CurrentSkillSelect = 1
    self:InitSkillBtn()
    self:RefreshSkillInfo()
    self:RefreshViewData()
    self:PlayAnimation("QieHuan1")
end

function XUiSkillDetails:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.BtnNext, self.OnBtnNext)
    XUiHelper.RegisterClickEvent(self, self.BtnLast, self.OnBtnLast)
    XUiHelper.RegisterClickEvent(self, self.Toggle, self.OnToggle)
end
--region 按钮相关

function XUiSkillDetails:OnBtnBackClick()
    self.ParentUi:Close()
end

function XUiSkillDetails:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end
-- 下一个
function XUiSkillDetails:OnBtnNext()
    if self.Pos then
        local nextPos = self.Pos + 1
        if nextPos > XCharacterConfigs.MAX_SHOW_SKILL_POS then
            self.ParentUi:SetSkillPos(nextPos)
            nextPos = 1
        else
            self.ParentUi:SetSkillPos(nextPos)
        end
        self:GotoSkill(nextPos)
    end
end
-- 上一个
function XUiSkillDetails:OnBtnLast()
    if self.Pos then
        local lastPos = self.Pos - 1
        if lastPos < 1 then
            self.ParentUi:SetSkillPos(XCharacterConfigs.MAX_SHOW_SKILL_POS + 1)
            lastPos = XCharacterConfigs.MAX_SHOW_SKILL_POS
        else
            self.ParentUi:SetSkillPos(lastPos)
        end
        self:GotoSkill(lastPos)
    end
end

function XUiSkillDetails:OnToggle()
    self.IsDetails = self.Toggle.isOn
    XUiPanelCharSkill.BUTTON_SKILL_DETAILS_ACTIVE = self.IsDetails
    self.SkillInfoPanel:RefreshSkillDescribe(self.IsDetails)
    self:PlayAnimation("QieHuan3")
end

--endregion

function XUiSkillDetails:RefreshData(clientLevel, subSkill)
    local characterId = self.CharacterId
    if not characterId then
        return
    end

    self.Skills = XCharacterConfigs.GetCharacterSkills(characterId, clientLevel, subSkill)

    self.Skill = self.Skills[self.Skill.config.Pos]
    self:RefreshSkillData()
end

function XUiSkillDetails:RefreshSkillData()
    for index, subSkill in pairs(self.Skill.subSkills) do
        local btn = self:GetSkillBtn(index, subSkill)
        self:SetBtnInfo(btn, subSkill)
    end

    self:HideLevelDetail()
    self.SkillInfoPanel:Refresh(self.CharacterId, self.Skill.subSkills[self.CurrentSkillSelect], self.IsDetails)
end

function XUiSkillDetails:RefreshSkillDataByFastBuy()
    self.SkillInfoPanel:Refresh(self.CharacterId, self.Skill.subSkills[self.CurrentSkillSelect], self.IsDetails)
end

function XUiSkillDetails:ShowLevelDetail(skillId)
    local characterId = self.CharacterId
    self.LevelDetailPanel:Refresh(characterId, skillId)
    self.LevelDetailPanel.GameObject:SetActiveEx(true)
end

function XUiSkillDetails:HideLevelDetail()
    self.LevelDetailPanel.GameObject:SetActiveEx(false)
end 

return XUiSkillDetails