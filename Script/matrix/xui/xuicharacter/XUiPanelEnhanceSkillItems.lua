local XUiPanelEnhanceSkillItems = XClass(nil, "XUiPanelEnhanceSkillItems")
local XUiGridEnhanceSkillItem = require("XUi/XUiCharacter/XUiGridEnhanceSkillItem")
local XUiGridSpEnhanceSkillItem = require("XUi/XUiCharacter/XUiGridSpEnhanceSkillItem")

function XUiPanelEnhanceSkillItems:Ctor(ui, anime, IsSelf, selectCallBack)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Anime = anime
    self.IsSelf = IsSelf
    self.SelectCallBack = selectCallBack
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
    self.GridSkillGroupList = {}
end

function XUiPanelEnhanceSkillItems:SetButtonCallBack()

end

function XUiPanelEnhanceSkillItems:ShowPanel(character)
    local skillGroupIdList = character:GetEnhanceSkillGroupIdList() or {}
    for index,skillGroupId in pairs(skillGroupIdList) do
        local skillGroup = character:GetEnhanceSkillGroupData(skillGroupId)
        if skillGroup then
            local gridSkillGroup = self.GridSkillGroupList[index]
            if not gridSkillGroup then
                local characterType = XMVCA.XCharacter:GetCharacterType(character:GetId())
                if characterType == XCharacterConfigs.CharacterType.Normal then
                    gridSkillGroup = XUiGridEnhanceSkillItem.New(self["GridSkillItem"..index], self.SelectCallBack)
                else
                    gridSkillGroup = XUiGridSpEnhanceSkillItem.New(self["GridSkillItem"..index], self.SelectCallBack,self["GridLine"..index])
                end
                self.GridSkillGroupList[index] = gridSkillGroup
            end

            local IsPassCondition,_ = XDataCenter.CharacterManager.GetEnhanceSkillIsPassCondition(skillGroup, character:GetId())
            local IsShowRed = IsPassCondition and XDataCenter.CharacterManager.CheckEnhanceSkillIsCanUnlockOrLevelUp(skillGroup) and self.IsSelf
            
            gridSkillGroup.GameObject:SetActiveEx(true)
            gridSkillGroup:UpdateGrid(skillGroup, character:GetEnhanceSkillPosName(index), IsShowRed)
        end
    end
    
    for index = #skillGroupIdList + 1, #self.GridSkillGroupList do
        self.GridSkillGroupList[index].GameObject:SetActiveEx(false)
    end
    
    self.GameObject:SetActiveEx(true)
    self.Anime.SkillItemsQiehuan:PlayTimelineAnimation()
end

function XUiPanelEnhanceSkillItems:HidePanel()
    self.GameObject:SetActiveEx(false)
end

return XUiPanelEnhanceSkillItems