XUiPanelCharSkillOther = XClass(nil, "XUiPanelCharSkillOther")

local XUiPanelSkillLevelDetail = require("XUi/XUiCharacter/XUiPanelSkillLevelDetail")

local MAX_SKILL_COUNT = 5
function XUiPanelCharSkillOther:Ctor(ui, parent, character, equipList, assignChapterRecords)
    self.Parent = parent
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.AssignChapterRecords = assignChapterRecords
    self:InitAutoScript()

    self.NpcData = {Character = character,Equips = equipList}

    self.SkillInfoPanel = XUiPanelSkillInfoOther.New(self.PanelSkillInfo, self, self.Parent, self.NpcData, self.AssignChapterRecords)
    self.LevelDetailPanel = XUiPanelSkillLevelDetail.New(self.PanelSkillDetails)

    self.SkillTeach.gameObject:SetActiveEx(false)
    self.PanelSkillInfo.gameObject:SetActive(false)
    self.PanelSkillDetails.gameObject:SetActive(false)
end

function XUiPanelCharSkillOther:InitAutoScript()
    self:AutoInitUi()
    XTool.InitUiObject(self)
end

function XUiPanelCharSkillOther:AutoInitUi()
    self.PanelSkillItems = self.Transform:Find("PanelSkillItems")

    self.GridSkillItem5 = self.Transform:Find("PanelSkillItems/GridSkillItem5")
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
    self.SkillInfoPanel:HidePanel()
    self.SkillItemsQiehuan:PlayTimelineAnimation()
end

function XUiPanelCharSkillOther:HidePanel()
    self:HideSkillItemPanel()
    self.SkillInfoPanel:HidePanel()
    self.GameObject:SetActive(false)
end

function XUiPanelCharSkillOther:HideSkillItemPanel()
    self.PanelSkillItems.gameObject:SetActive(false)
end

--技能信息格子点击后弹出等级详情
function XUiPanelCharSkillOther:ShowLevelDetail(skillId)
    self.PanelSkillDetails.gameObject:SetActive(true)
    self.LevelDetailPanel:RefreshByNpcData(self.NpcData, skillId, self.AssignChapterRecords)
end

function XUiPanelCharSkillOther:UpdatePanel(character)
    local skills = XCharacterConfigs.GetCharacterSkillsByCharacter(character)

    if (self.SkillGrids and #self.SkillGrids > 0) then
        for i = 1, MAX_SKILL_COUNT do
            self.SkillGrids[i]:UpdateInfo( skills[i])
        end
    else
        self.SkillGrids = {}
        for i = 1, MAX_SKILL_COUNT do
            self.SkillGrids[i] = XUiGridSkillItemOther.New(self.Parent, self["GridSkillItem" .. i], skills[i], character, self.EquipList, self.AssignChapterRecords,
                    function()
                        self:HideSkillItemPanel()
                        self.SkillInfoPanel:ShowPanel(self.CharacterId, skills, i)
                    end)
        end
    end
end