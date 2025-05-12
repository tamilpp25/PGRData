--######################## XGridSkill 技能格子 ########################
local XGridSkill = XClass(nil, "XGridSkill")

function XGridSkill:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XUiHelper.InitUiClass(self, ui)
    self.AdventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    XUiHelper.RegisterClickEvent(self, self.BtnSubSkillIconBg, self.OnBtnSubSkillIconBgClick)
    
    self.IconBg = XUiHelper.TryGetComponent(self.Transform, "BtnSubSkillIconBg", "Image")
end

function XGridSkill:SetData(skillData)
    self.SkillData = skillData
    --图标
    local icon = skillData.Icon
    if icon then
        self.RImgSubSkillIconNormal:SetRawImage(icon)
    end
    if self.RImgSubSkillIconSelected then
        self.RImgSubSkillIconSelected:SetRawImage(icon)
    end
    --图标颜色
    local color = skillData.IconColor
    if color then
        self.RImgSubSkillIconNormal.color = XUiHelper.Hexcolor2Color(color)
    end
    --图标背景资源
    local iconBgPath = skillData.IconBgPath
    if iconBgPath and self.IconBg then
        self.IconBg:SetSprite(iconBgPath)
    end

    local level = skillData.Level
    local txtLevel = self.TxtLevel or self.TxtSubSkillLevel
    txtLevel.text = level

    self.PanelSkillLock.gameObject:SetActiveEx(not XTool.IsNumberValid(level))

    self.GameObject:SetActiveEx(true)
end

function XGridSkill:OnBtnSubSkillIconBgClick()
    local skillData = self.SkillData
    local skillId = skillData.SkillId
    local level = skillData.Level
    if not skillId or not level then
        return
    end
    local configDes = XMVCA.XCharacter:GetSkillGradeDesWithDetailConfig(skillId, level)
    XLuaUiManager.Open("UiSkillDetailsTips", configDes)
end

--######################## XPanelRoleSkill 技能详细面板 ########################
local BALL_SKILL_COUNT = 3  --信号球数量
local XPanelRoleSkill = XClass(nil, "XPanelRoleSkill")

function XPanelRoleSkill:Ctor(ui, backClickCb, panelIndex)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XUiHelper.InitUiClass(self, ui)

    self.PanelIndex = panelIndex
    self.BackClickCb = backClickCb
    self.AdventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    XUiHelper.RegisterClickEvent(self, self.BtnGoBack, self.OnBtnGoBackClick)
    self:Init()
end

function XPanelRoleSkill:Init()
    local icon = XBiancaTheatreConfigs.GetRoleDetailSkillIcon()
    self.ImgNormalIcon:SetSprite(icon)
    self.ImgPressIcon:SetSprite(icon)

    local descs = XBiancaTheatreConfigs.GetRoleDetailSkillDesc()
    self.TxtNormalName.text = descs[1]
    self.TxtPressName.text = descs[1]
    self.TxtNormalMassage.text = descs[2]
    self.TxtPressMassage.text = descs[2]

    self.SkillGrids = {}
    self.BallSkillGrids = {}
    self.GridActiveSkill.gameObject:SetActiveEx(false)
    self.BasicSkills.gameObject:SetActiveEx(false)
    for i = 2, XEnumConst.CHARACTER.MAX_SHOW_SKILL_POS do
        local panel = self["PanelSkillGroup" .. i]
        local grid = XUiHelper.TryGetComponent(panel, "PanelActiveSkill/GridActiveSkill")
        if grid then
            grid.gameObject:SetActiveEx(false)
        end
    end
end

function XPanelRoleSkill:SetData(adventureRole)
    local skills = adventureRole:GetSkill()
    self:UpdateSkill(skills)
end

function XPanelRoleSkill:UpdateSkill(skills)
    -- 特殊处理
    local ballSkill1 = {}
    local ballSkill2 = {}
    for _, subSkill in pairs(skills[1].subSkills or {}) do
        local skillType = XMVCA.XCharacter:GetSkillType(subSkill.configDes.SkillId)
        if skillType <= BALL_SKILL_COUNT then
            table.insert(ballSkill1, subSkill)
        else
            table.insert(ballSkill2, subSkill)
        end
    end
    self:UpdateBallSkillList(ballSkill1)
    self:UpdateSkillList(ballSkill2, self.GridActiveSkill, self.PanelBasicskills, 1)

    for i = 2, XEnumConst.CHARACTER.MAX_SHOW_SKILL_POS do
        local panel = self["PanelSkillGroup" .. i]
        local parent =  XUiHelper.TryGetComponent(panel, "PanelActiveSkill")
        local grid = XUiHelper.TryGetComponent(panel, "PanelActiveSkill/GridActiveSkill")

        self:UpdateSkillList(skills[i].subSkills, grid, parent, i)
    end
end

function XPanelRoleSkill:UpdateBallSkillList(skills)
    if XTool.IsTableEmpty(skills) then
        self:DisableSkillGrid(self.BallSkillGrids)
        return
    end

    self:RefreshGrid(#skills, skills, self.BallSkillGrids, self.BasicSkills, self.PanelBasicskills)
end

function XPanelRoleSkill:UpdateSkillList(skills, grid, parent, index)
    if XTool.IsTableEmpty(self.SkillGrids[index]) then
        self.SkillGrids[index] = {}
    end
    if XTool.IsTableEmpty(skills) then
        self:DisableSkillGrid(self.SkillGrids[index])
        return
    end

    self:RefreshGrid(#skills, skills, self.SkillGrids[index], grid, parent)
end

function XPanelRoleSkill:DisableSkillGrid(skillGirdList)
    for _, grid in ipairs(skillGirdList) do
        grid.GameObject:SetActiveEx(false)
    end
end

function XPanelRoleSkill:RefreshGrid(length, skills, grids, grid, parent)
    for idx = 1, length do
        local item  = grids[idx]
        if not item then
            local ui = XUiHelper.Instantiate(grid, parent);
            item = XGridSkill.New(ui)
            item.GameObject:SetActiveEx(true)
            grids[idx] = item
        end
        item:SetData({Icon = skills[idx].configDes.Icon, Level = skills[idx].Level, SkillId = skills[idx].configDes.SkillId})
    end

    for i = length + 1, #grids do
        grids[i].GameObject:SetActiveEx(false)
    end
end

function XPanelRoleSkill:OnBtnGoBackClick()
    self.BackClickCb(self.PanelIndex, true)
end

function XPanelRoleSkill:SetBtnGoBackActive(isActive)
    self.BtnGoBack.gameObject:SetActiveEx(isActive)
end

--######################## XPanelSkill 技能简略面板 ########################
local CORE_SKILL_COUNT = 4
local GridSkillIndexs = {
    PassiveSkill = 1, --核心被动
    RedBall = 2,    --红球技能
    YellowBall = 3, --黄球技能
    BlueBall = 4,   --蓝球技能
}
local MAIN_SKILL_INDEX = 1  --主动技能
local PASSIVE_SKILL_INDEX = 2 --被动技能

local XPanelSkill = XClass(nil, "XPanelSkill")

function XPanelSkill:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XUiHelper.InitUiClass(self, ui)
    self.AdventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    self:Init()
end

function XPanelSkill:Init()
    local icon = XBiancaTheatreConfigs.GetRoleDetailSkillIcon()
    self.ImgNormalIcon:SetSprite(icon)
    self.ImgPressIcon:SetSprite(icon)

    local descs = XBiancaTheatreConfigs.GetRoleDetailSkillDesc()
    self.TxtNormalName.text = descs[1]
    self.TxtPressName.text = descs[1]
    self.TxtNormalMassage.text = descs[2]
    self.TxtPressMassage.text = descs[2]

    self.SkillGrids = {}
    self.GridNormalSubSkill.gameObject:SetActiveEx(false)
    self.GridPressSubSkill.gameObject:SetActiveEx(false)

    for i = 1, CORE_SKILL_COUNT do
        local grids = {}
        grids[1] = XGridSkill.New(XUiHelper.Instantiate(self.GridNormalSubSkill, self.PanelNormalAll))
        grids[2] = XGridSkill.New(XUiHelper.Instantiate(self.GridPressSubSkill, self.PanelPressAll))
        self.SkillGrids[i] = grids
    end
end

function XPanelSkill:SetData(adventureRole)
    local skills = adventureRole:GetSkill()
    local mainSkill = skills[MAIN_SKILL_INDEX]
    local passiveSkill = skills[PASSIVE_SKILL_INDEX]
    
    --核心被动
    local data = passiveSkill.subSkills[1]
    for _, grid in ipairs(self.SkillGrids[GridSkillIndexs.PassiveSkill]) do
        grid:SetData({Icon = data.configDes.Icon, Level = data and data.Level or 0})
    end

    --信号球
    local ballIndex = 1
    for gridIndex = GridSkillIndexs.RedBall, GridSkillIndexs.BlueBall do
        data = mainSkill.subSkills[ballIndex]
        for _, grid in ipairs(self.SkillGrids[gridIndex]) do
            grid:SetData({Icon = data.configDes.Icon, 
                          Level = data and data.Level or 0,
                          IconColor = "FFFFFF",
                          IconBgPath = XBiancaTheatreConfigs.GetClientConfig("RoleDetailBallIconBg"),
            })
        end
        ballIndex = ballIndex + 1
    end
end

--######################## XGridAwareness 武器格子 ########################
local XUiGridEquipOther = require("XUi/XUiPlayerInfo/XUiGridEquipOther")
local XGridAwareness = XClass(nil, "XGridAwareness")

function XGridAwareness:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XUiHelper.InitUiClass(self, ui)
    self.AdventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    self.WeaponGrid = XUiGridEquipOther.New(self.GridAwareness, {Parent = rootUi})
end

function XGridAwareness:Refresh(equip)
    if not equip then
        return
    end
    self.TxtNumber.text = equip.Level   --武器等级
    self.WeaponGrid:Refresh(equip)
end

--######################## XGridSuit 意识套装格子 ########################
local XUiGridSuitDetail = require("XUi/XUiEquipAwarenessReplace/XUiGridSuitDetail")
local XGridSuit = XClass(nil, "XGridSuit")

function XGridSuit:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XUiHelper.InitUiClass(self, ui)
    self:InitUi()
end

function XGridSuit:InitUi()
    self.PanelResonance.gameObject:SetActiveEx(false)
    self.LeftUp.gameObject:SetActiveEx(false)
    self.PanelSite.gameObject:SetActiveEx(false)
    self.ImgBreakthrough.gameObject:SetActiveEx(false)
end

--data：XAdventureRole:GetSuitMergeActiveDatas()
function XGridSuit:Refresh(data)
    self.RImgIcon:SetRawImage(data.Icon)

    --意识套装没有质量等级，默认用套装第一个部位的品级
    local suitId = data.SuitId
    if XMVCA.XEquip:IsDefaultSuitId(suitId) then
        self.ImgQuality.gameObject:SetActive(false)
    else
        local ids = XMVCA.XEquip:GetSuitEquipIds(suitId)
        self.ImgQuality:SetSprite(XMVCA.XEquip:GetEquipQualityPath(ids[1]))
        self.ImgQuality.gameObject:SetActive(true)
    end
    -- self.GridSuit:Refresh(data.SuitId)
end

--######################## XPanelSuit 意识套装布局 ########################
local XPanelSuit = XClass(nil, "XPanelSuit")

function XPanelSuit:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XUiHelper.InitUiClass(self, ui)
    self.GridSuit = XGridSuit.New(self.GridAwareness, rootUi)
end

function XPanelSuit:Refresh(data)
    self.TxtNumber.text = data.Level
    self.GridSuit:Refresh(data)
end

--######################## XPanelAwareness 武器和意识简略面板 ########################
local XPanelAwareness = XClass(nil, "XPanelAwareness")

function XPanelAwareness:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XUiHelper.InitUiClass(self, ui)
    self.AdventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    self:Init(rootUi)
end

function XPanelAwareness:Init(rootUi)
    self.RootUi = rootUi
    
    local icon = XBiancaTheatreConfigs.GetRoleDetailEquipIcon()
    self.ImgNormalIcon:SetSprite(icon)
    self.ImgPressIcon:SetSprite(icon)

    local descs = XBiancaTheatreConfigs.GetRoleDetailEquiupDesc()
    self.TxtNormalName.text = descs[1]
    self.TxtPressName.text = descs[1]
    self.TxtNormalMassage.text = descs[2]
    self.TxtPressMassage.text = descs[2]

    self.WeaponGridNormal = XGridAwareness.New(self.PanelNormalWeapon, rootUi)
    self.WeaponGridPress = XGridAwareness.New(self.PanelPressWeapon, rootUi)
    self.SuitGrids = {}
end

function XPanelAwareness:SetData(adventureRole)
    local characterId = adventureRole:GetId()

    --武器
    local weaponEquip = adventureRole:GetWeaponEquip()
    self.WeaponGridNormal:Refresh(weaponEquip)
    self.WeaponGridPress:Refresh(weaponEquip)

    --意识四件套和二件套
    local suitMergeActiveDatas = adventureRole:GetSuitMergeActiveDatas()
    for i, data in ipairs(suitMergeActiveDatas) do
        local suitGrids = self.SuitGrids[i]
        if not suitGrids then
            suitGrids = {}
            suitGrids[1] = XPanelSuit.New(self["PanelNormalAwareness" .. i], self.RootUi)
            suitGrids[2] = XPanelSuit.New(self["PanelPressAwareness" .. i], self.RootUi)
            self.SuitGrids[i] = suitGrids
        end

        for i, suitGrid in ipairs(suitGrids) do
            suitGrid:Refresh(data)
            suitGrid.GameObject:SetActiveEx(true)
            self["PanelNormalAwarenessDisable" .. i].gameObject:SetActiveEx(false)
            self["PanelPressAwarenessDisable" .. i].gameObject:SetActiveEx(false)
            self["PanelNormalAwareness" .. i].gameObject:SetActiveEx(true)
            self["PanelPressAwareness" .. i].gameObject:SetActiveEx(true)
        end
    end

    for i = #suitMergeActiveDatas + 1, 2 do
        local suitGrids = self.SuitGrids[i]
        for _, suitGrid in ipairs(suitGrids or {}) do
            suitGrid.GameObject:SetActiveEx(false)
        end
        self["PanelNormalAwarenessDisable" .. i].gameObject:SetActiveEx(true)
        self["PanelPressAwarenessDisable" .. i].gameObject:SetActiveEx(true)
        self["PanelNormalAwareness" .. i].gameObject:SetActiveEx(false)
        self["PanelPressAwareness" .. i].gameObject:SetActiveEx(false)
    end
end

--######################## XPaneRolelAwareness 武器和意识详情面板 ########################
local XPaneRolelAwareness = XClass(nil, "XPaneRolelAwareness")

function XPaneRolelAwareness:Ctor(ui, backClickCb, rootUi, panelIndex)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XUiHelper.InitUiClass(self, ui)

    self.PanelIndex = panelIndex
    self.BackClickCb = backClickCb
    self.AdventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    XUiHelper.RegisterClickEvent(self, self.BtnGoBack, self.OnBtnGoBackClick)
    self:Init()
end

function XPaneRolelAwareness:Init()
    local icon = XBiancaTheatreConfigs.GetRoleDetailEquipIcon()
    self.ImgNormalIcon:SetSprite(icon)
    self.ImgPressIcon:SetSprite(icon)

    local descs = XBiancaTheatreConfigs.GetRoleDetailEquiupDesc()
    self.TxtNormalName.text = descs[1]
    self.TxtPressName.text = descs[1]
    self.TxtNormalMassage.text = descs[2]
    self.TxtPressMassage.text = descs[2]

    self.GridAwareness.gameObject:SetActiveEx(true)
end

function XPaneRolelAwareness:SetData(adventureRole)
    self.AdventureRole = adventureRole
    local characterId = adventureRole:GetId()
    local rootUi = self.RootUi

    --武器
    local weaponEquip = adventureRole:GetWeaponEquip()
    self.WeaponGrid = self.WeaponGrid or XUiGridEquipOther.New(self.GridAwareness, { Parent = rootUi },  function()
        XLuaUiManager.Open("UiEquipDetailOther", self.AdventureRole:GetWeaponEquip(), self.AdventureRole:GetCharacterViewModel())
    end)
    self.WeaponGrid:Refresh(weaponEquip)

    --意识
    self.WearingAwarenessGrids = self.WearingAwarenessGrids or {}
    for i, equipSite in pairs(XEnumConst.EQUIP.EQUIP_SITE.AWARENESS) do
        local panelAwareness = self["PanelAwareness" .. equipSite]
        local gridAwareness = XUiHelper.TryGetComponent(panelAwareness.transform, "GridAwareness")
        local equip = adventureRole:GetWearingEquipBySite(equipSite)
        self.WearingAwarenessGrids[equipSite] = self.WearingAwarenessGrids[equipSite] or XUiGridEquipOther.New(gridAwareness, { Parent = rootUi }, function()
            XLuaUiManager.Open("UiEquipDetailOther", self.AdventureRole:GetWearingEquipBySite(equipSite), adventureRole:GetCharacterViewModel())
        end)

        if not equip then
            panelAwareness.gameObject:SetActiveEx(false)
            self["PanelAwarenessDisable" .. equipSite].gameObject:SetActiveEx(true)
        else
            self.WearingAwarenessGrids[equipSite]:Refresh(equip)
            panelAwareness.gameObject:SetActiveEx(true)
            self["PanelAwarenessDisable" .. equipSite].gameObject:SetActiveEx(false)
        end
    end
end

function XPaneRolelAwareness:OnBtnGoBackClick()
    self.BackClickCb(self.PanelIndex, true)
end

function XPaneRolelAwareness:SetBtnGoBackActive(isActive)
    self.BtnGoBack.gameObject:SetActiveEx(isActive)
end

--######################## XComboGrid 羁绊格子 ########################
local XComboGrid = XClass(nil, "XComboGrid")

function XComboGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XUiHelper.InitUiClass(self, ui)
    XUiHelper.RegisterClickEvent(self, self.Transform, handler(self, self.OnBtnClick))
end

--combo：XTheatreCombo
--comboLv：XAdventureRole的Level
function XComboGrid:Refresh(combo, comboLv)
    if not combo then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.Combo = combo
    local qualityColor = combo:GetQualityColor()
    
    --羁绊图标
    self.Icon:SetRawImage(combo:GetIconPath())
    --羁绊背景
    if self.Bg and qualityColor then
        self.Bg.color = qualityColor
    end
    --羁绊名
    self.TextName.text = combo:GetName()
    if qualityColor then
        self.TextName.color = qualityColor
    end
    --角色当前羁绊等级
    self.TxtAddStar.text = "+" .. comboLv
    --羁绊总等级
    self.TxtStar.text = combo:GetTotalRank()
    
    self.GameObject:SetActiveEx(true)
end

function XComboGrid:OnBtnClick()
    XLuaUiManager.Open("UiBiancaTheatreComboTips", self.Combo)
end

--######################## XPanelRole 简略角色羁绊面板 ########################
---@class XBiancaTheatrePanelRole
local XPanelRole = XClass(nil, "XPanelRole")

function XPanelRole:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XUiHelper.InitUiClass(self, ui)
    self:Init()
end

function XPanelRole:Init()
    self.AdventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    self.ComboList = XDataCenter.BiancaTheatreManager.GetComboList()
    self.ComboGridList = {}
    self.Grid.gameObject:SetActiveEx(false)
end

function XPanelRole:SetData(adventureRole)
    local childComboIdList = adventureRole:GetCharacterComboIds()
    local comboLv = adventureRole:GetLevel()
    local combo
    local grid
    for i, childComboId in ipairs(childComboIdList) do
        combo = self.ComboList:GetComboByComboId(childComboId)
        grid = self.ComboGridList[i]
        if not grid then
            grid = XComboGrid.New(XUiHelper.Instantiate(self.Grid, self.BtnRole.transform))
            self.ComboGridList[i] = grid
        end
        grid:Refresh(combo, comboLv)
    end
    for i = #childComboIdList + 1, #self.ComboGridList do
        self.ComboGridList[i].GameObject:SetActiveEx(false)
    end

    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.Transform)
end

--######################## XUiTheatreOwnedInfoPanel ########################
local PanelIndex = {
    Role = 1,
    Awareness = 2,
    Skill = 3,
}

local AnimationPanel = {
    [PanelIndex.Role] = "RoleEnterQieHuan",
    [PanelIndex.Awareness] = "RolelAwarenessQieHuan",
    [PanelIndex.Skill] = "RoleSkillQieHuan",
}

--选择的角色详情
---@class XUiBiancaTheatreOwnedInfoPanel
local XUiTheatreOwnedInfoPanel = XClass(nil, "XUiTheatreOwnedInfoPanel")

function XUiTheatreOwnedInfoPanel:Ctor(ui, switchRoleStateCb, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.RootUi = rootUi
    self.SwitchRoleStateCb = switchRoleStateCb
    self.AdventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    self:AddButtonClick()
    self:Init(rootUi)
end

function XUiTheatreOwnedInfoPanel:Init(rootUi)
    local backClickCb = handler(self, self.OnChangePanel)
    ---@type XBiancaTheatrePanelRole
    self.RolePanel = XPanelRole.New(self.PanelRole)
    self.AwarenessPanel = XPanelAwareness.New(self.PanelAwareness, rootUi)
    self.RolelAwarenessPanel = XPaneRolelAwareness.New(self.PaneRolelAwareness, backClickCb, rootUi, PanelIndex.Awareness)
    self.SkillPanel = XPanelSkill.New(self.PanelSkill)
    self.RoleSkillPanel = XPanelRoleSkill.New(self.PanelRoleSkill, backClickCb, PanelIndex.Skill)

    self:InitPanelActiveState()
    self.CurShowPanelIndex = nil
end

function XUiTheatreOwnedInfoPanel:InitPanelActiveState()
    self.PanelAllMassage.gameObject:SetActiveEx(true)
    self.RolelAwarenessPanel.GameObject:SetActiveEx(false)
    self.RoleSkillPanel.GameObject:SetActiveEx(false)
    if self.AnimaPanelIndex then
        self:OnChangePanel(self.AnimaPanelIndex, true)
        self.AnimaPanelIndex = nil
    end
end

function XUiTheatreOwnedInfoPanel:AddButtonClick()
    self.BtnElementDetail.CallBack = function() self:OnBtnElementDetailClick() end
    self.BtnAwareness.CallBack = function() self:OnChangePanel(PanelIndex.Awareness) end
    self.BtnSkill.CallBack = function() self:OnChangePanel(PanelIndex.Skill) end
    XUiHelper.RegisterClickEvent(self, self.BtnCareerTips, self.OnBtnCareerTipsClick)
    XUiHelper.RegisterClickEvent(self, self.BtnGeneralSkill1, function ()
        self:OnBtnGeneralSkillClick(1)
    end)
    XUiHelper.RegisterClickEvent(self, self.BtnGeneralSkill2, function ()
        self:OnBtnGeneralSkillClick(2)
    end)

end

function XUiTheatreOwnedInfoPanel:OnBtnCareerTipsClick()
    XLuaUiManager.Open("UiCharacterAttributeDetail", self.AdventureRole:GetCharacterId())
end

--切换动画，1是切换成详情，2是切换回来，动画自带显隐
function XUiTheatreOwnedInfoPanel:OnChangePanel(panelIndex, isBack)
    local animaName = panelIndex and AnimationPanel[panelIndex]
    if not animaName then
        return
    end
    
    self.RolelAwarenessPanel:SetBtnGoBackActive(true)
    self.RoleSkillPanel:SetBtnGoBackActive(true)

    self.AnimaPanelIndex = panelIndex
    local animaIndex = isBack and 2 or 1
    self.RootUi:PlayAnimationWithMask(animaName .. animaIndex, function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        
        self.RolelAwarenessPanel:SetBtnGoBackActive(not isBack)
        self.RoleSkillPanel:SetBtnGoBackActive(not isBack)
    end)
end

---@param adventureRole XBiancaTheatreAdventureRole
function XUiTheatreOwnedInfoPanel:SetData(adventureRole, entityId)
    if not adventureRole then
        return
    end
    
    self.EntityId = entityId
    self.AdventureRole = adventureRole
    local characterViewModel = adventureRole:GetCharacterViewModel()
    self.CharacterViewModel = characterViewModel
    
    --角色名
    self.TxtName.text = characterViewModel:GetName()
    --职业图标
    local professionIcon = characterViewModel:GetProfessionIcon()
    self.RImgTypeIcon:SetRawImage(professionIcon)
    --星级
    self.TxtStar.text = adventureRole:GetLevel()
    --型号
    self.TxtNameOther.text = characterViewModel:GetTradeName()
    --战力
    self.TxtLv.text = adventureRole:GetAbility()
    --星级战力
    self.TxtStarAbility.text = adventureRole:GetStarAbility()
    --能量元素图标
    local elementIconList = characterViewModel:GetObtainElementIcons()
    for i = 1, 3 do
        local rImg = self["RImgCharElement" .. i]
        local icon = elementIconList[i]
        if icon then
            rImg.gameObject:SetActiveEx(true)
            rImg:SetRawImage(icon)
        else
            rImg.gameObject:SetActiveEx(false)
        end
    end

    -- 机制
    local generalSkillIds = XMVCA.XCharacter:GetCharactersActiveGeneralSkillIdList(adventureRole:GetId())
    for i = 1, self.ListGeneralSkillDetail.childCount, 1 do
        local id = generalSkillIds[i]
        self["BtnGeneralSkill"..i].gameObject:SetActiveEx(id)
        if id then
            local generalSkillConfig = XMVCA.XCharacter:GetModelCharacterGeneralSkill()[id]
            self["BtnGeneralSkill"..i]:SetRawImage(generalSkillConfig.Icon)
        end
    end

    self.RolePanel:SetData(adventureRole)
    self.AwarenessPanel:SetData(adventureRole)
    self.RolelAwarenessPanel:SetData(adventureRole)
    self.SkillPanel:SetData(adventureRole)
    self.RoleSkillPanel:SetData(adventureRole)
end

function XUiTheatreOwnedInfoPanel:OnBtnElementDetailClick()
    XLuaUiManager.Open("UiCharacterAttributeDetail", self.CharacterViewModel:GetId(), XEnumConst.UiCharacterAttributeDetail.BtnTab.Element)
end

function XUiTheatreOwnedInfoPanel:OnBtnGeneralSkillClick(index)
    local characterId = self.AdventureRole:GetId()

    local activeGeneralSkillIds = XMVCA.XCharacter:GetCharactersActiveGeneralSkillIdList(characterId)
    local curId = activeGeneralSkillIds[index]
    local realIndex = XMVCA.XCharacter:GetIndexInCharacterGeneralSkillIdsById(characterId, curId)

    XLuaUiManager.Open("UiCharacterAttributeDetail", characterId, XEnumConst.UiCharacterAttributeDetail.BtnTab.GeneralSkill, realIndex)
end

return XUiTheatreOwnedInfoPanel