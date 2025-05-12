local XUiGridSkillItemOther = require("XUi/XUiPlayerInfo/XUiGridSkillItemOther")
local XUiPanelCharSkillOther = XClass(nil, "XUiPanelCharSkillOther")

function XUiPanelCharSkillOther:Ctor(ui, parent, character, equipList, assignChapterRecords)
    self.Parent = parent
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.AssignChapterRecords = assignChapterRecords
    self:InitAutoScript()

    self.NpcData = {Character = character,Equips = equipList}

    self.SkillTeach.gameObject:SetActiveEx(false)
    self.PanelSkillInfo.gameObject:SetActive(false)
end

function XUiPanelCharSkillOther:InitAutoScript()
    self:AutoInitUi()
    XTool.InitUiObject(self)
end

function XUiPanelCharSkillOther:AutoInitUi()
    self.PanelSkillItems = self.Transform:Find("PanelSkillItems")
    
    self.GridSkillItem4 = self.Transform:Find("PanelSkillItems/GridSkillItem4")
    self.GridSkillItem3 = self.Transform:Find("PanelSkillItems/GridSkillItem3")
    self.GridSkillItem2 = self.Transform:Find("PanelSkillItems/GridSkillItem2")
    self.GridSkillItem1 = self.Transform:Find("PanelSkillItems/GridSkillItem1")

    self.SkillTeach = self.Transform:Find("PanelSkillItems/SkillTeach")
    self.PanelSkillInfo = self.Transform:Find("PanelSkillInfo")
end

function XUiPanelCharSkillOther:ShowPanel(character,equipList)
    self.CharacterId = character.Id
    self.EquipList = equipList
    self.GameObject:SetActiveEx(true)
    self:ShowSkillItemPanel()
    self:UpdatePanel(character)
end

function XUiPanelCharSkillOther:ShowSkillItemPanel()
    self.PanelSkillItems.gameObject:SetActive(true)
    self.SkillItemsQiehuan:PlayTimelineAnimation()
end

function XUiPanelCharSkillOther:HidePanel()
    self:HideSkillItemPanel()
    self.GameObject:SetActive(false)
end

function XUiPanelCharSkillOther:HideSkillItemPanel()
    self.PanelSkillItems.gameObject:SetActive(false)
end

function XUiPanelCharSkillOther:UpdatePanel(character)
    local skills = XMVCA.XCharacter:GetCharacterSkillsByCharacter(character)

    if (self.SkillGrids and #self.SkillGrids > 0) then
        for i = 1, XEnumConst.CHARACTER.MAX_SHOW_SKILL_POS do
            self.SkillGrids[i]:UpdateInfo(skills[i])
        end
    else
        self.SkillGrids = {}
        for i = 1, XEnumConst.CHARACTER.MAX_SHOW_SKILL_POS do
            self.SkillGrids[i] = XUiGridSkillItemOther.New(self.Parent, self["GridSkillItem" .. i], skills[i], character, self.EquipList, self.AssignChapterRecords,
                    function()
                        self:HideSkillItemPanel()
                        XLuaUiManager.Open("UiSkillDetailsOther", self.CharacterId, skills, i ,self.NpcData, self.AssignChapterRecords)
                    end)
        end
    end
end

return XUiPanelCharSkillOther