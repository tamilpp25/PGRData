XUiPanelCharSkill = XClass(nil, "XUiPanelCharSkill")

XUiPanelCharSkill.BUTTON_SKILL_TEACH_ACTIVE = false -- 角色详情界面的教学按钮显示状态
XUiPanelCharSkill.BUTTON_SKILL_DETAILS_ACTIVE = true -- 角色技能详情按钮状态

function XUiPanelCharSkill:Ctor(ui, parent)
    self.Parent = parent
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self:InitAutoScript()
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelCharSkill:InitAutoScript()
    self:AutoInitUi()
    XTool.InitUiObject(self)
    self:AutoAddListener()
end

function XUiPanelCharSkill:AutoInitUi()
    self.PanelSkillItems = self.Transform:Find("PanelSkillItems")
    self.GridSkillItem4 = self.Transform:Find("PanelSkillItems/GridSkillItem4")
    self.GridSkillItem3 = self.Transform:Find("PanelSkillItems/GridSkillItem3")
    self.GridSkillItem2 = self.Transform:Find("PanelSkillItems/GridSkillItem2")
    self.GridSkillItem1 = self.Transform:Find("PanelSkillItems/GridSkillItem1")
    self.BtnSkillTeach = self.Transform:Find("PanelSkillItems/SkillTeach/BtnSkillTeach"):GetComponent("Button")
    self.PanelSkillInfo = self.Transform:Find("PanelSkillInfo")
end

function XUiPanelCharSkill:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelCharSkill:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelCharSkill:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelCharSkill:AutoAddListener()
    self:RegisterClickEvent(self.BtnSkillTeach, self.OnBtnSkillTeachClick)
end
-- auto
function XUiPanelCharSkill:OnBtnSkillTeachClick()
    XLuaUiManager.Open("UiPanelSkillTeach", self.Parent.CharacterId)
end

function XUiPanelCharSkill:ShowPanel(characterId)
    self.CharacterId = characterId or self.CharacterId
    self.BtnSkillTeach.gameObject:SetActive(XUiPanelCharSkill.BUTTON_SKILL_TEACH_ACTIVE)
    self.IsShow = true
    self.GameObject:SetActive(true)
    self:ShowSkillItemPanel()
    self:UpdateSkill()
end

function XUiPanelCharSkill:UpdateSkill()
    local characterId = self.CharacterId

    -- local character = XDataCenter.CharacterManager.GetCharacter(characterId)
    local skills = XCharacterConfigs.GetCharacterSkills(characterId)
    if (self.SkillGrids and #self.SkillGrids > 0) then
        for i = 1, XCharacterConfigs.MAX_SHOW_SKILL_POS do
            self.SkillGrids[i]:SetClickCallback(
            function()
                self:HideSkillItemPanel()
                self.BtnSkillTeach.gameObject:SetActive(false)
                XLuaUiManager.Open("UiSkillDetailsParentV2P6", self.CharacterId, XCharacterConfigs.SkillDetailsType.Normal, i)
            end)
            self.SkillGrids[i]:UpdateInfo(characterId, skills[i])
        end
    else
        self.SkillGrids = {}
        for i = 1, XCharacterConfigs.MAX_SHOW_SKILL_POS do
            self.SkillGrids[i] = XUiGridSkillItem.New(self.Parent, self["GridSkillItem" .. i], skills[i], characterId,
            function()
                self:HideSkillItemPanel()
                self.BtnSkillTeach.gameObject:SetActive(false)
                XLuaUiManager.Open("UiSkillDetailsParentV2P6", self.CharacterId, XCharacterConfigs.SkillDetailsType.Normal, i)
            end
            )
        end
    end
end

function XUiPanelCharSkill:HidePanel()
    self.BtnSkillTeach.gameObject:SetActive(XUiPanelCharSkill.BUTTON_SKILL_TEACH_ACTIVE)
    self.IsShow = false
    self.GameObject:SetActive(false)
    self:HideSkillItemPanel()
end

function XUiPanelCharSkill:HideSkillItemPanel()
    self.PanelSkillItems.gameObject:SetActive(false)
end

function XUiPanelCharSkill:ShowSkillItemPanel()
    self.PanelSkillItems.gameObject:SetActive(true)
    self.PanelSkillInfo.gameObject:SetActive(false)
    self.BtnSkillTeach.gameObject:SetActive(XUiPanelCharSkill.BUTTON_SKILL_TEACH_ACTIVE)
    self.SkillItemsQiehuan:PlayTimelineAnimation()
end