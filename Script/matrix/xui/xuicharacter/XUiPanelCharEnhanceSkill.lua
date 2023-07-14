XUiPanelCharEnhanceSkill = XClass(nil, "XUiPanelCharEnhanceSkill")
local XUiPanelEnhanceSkillInfo = require("XUi/XUiCharacter/XUiPanelEnhanceSkillInfo")
local XUiPanelEnhanceSkillItems = require("XUi/XUiCharacter/XUiPanelEnhanceSkillItems")

function XUiPanelCharEnhanceSkill:Ctor(ui, root, IsSelf)
    self.Root = root
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.IsSelf = IsSelf
    XTool.InitUiObject(self)
    self:InitPanel()
end

function XUiPanelCharEnhanceSkill:InitPanel()
    self.Anime = {}
    XTool.InitUiObjectByUi(self.Anime, self.Animation)
    self.InfoPanel = XUiPanelEnhanceSkillInfo.New(self.PanelSkillInfo, self.Root, self.Anime, self.IsSelf, function()
            self:DoSelectPos(self.SelectPos - 1)
            self:ShowPanel()
        end,
        function ()
            self:DoSelectPos(self.SelectPos + 1)
            self:ShowPanel()
        end,XCharacterConfigs.SkillUnLockType.Enhance)
    self.ItemsPanel = XUiPanelEnhanceSkillItems.New(self.PanelSkillItems, self.Anime, self.IsSelf, function(skill)
            self:DoSelectPos(skill)
            self:ShowPanel()
        end)
end

function XUiPanelCharEnhanceSkill:ShowPanel(character, isReset)
    if character then
        self.CharEntity = character
        if type(character) == "number" then
            self.CharEntity = XDataCenter.CharacterManager.GetCharacter(character)
        end
    end

    if not self.CharEntity then
        return
    end

    self.GameObject:SetActiveEx(true)

    if self.SelectPos and (not isReset) then
        self.InfoPanel:ShowPanel(self.SelectPos, self.CharEntity)
        self.ItemsPanel:HidePanel()
    else
        self.ItemsPanel:ShowPanel(self.CharEntity)
        self.InfoPanel:HidePanel()
    end
end

--人物属性界面统一刷新接口
function XUiPanelCharEnhanceSkill:Refresh()
    --刷新跃升技能界面信息
    if self.PanelSkillInfo.gameObject.activeSelf then
        self.InfoPanel:UpdataPanel()
    end
end

function XUiPanelCharEnhanceSkill:HidePanel()
    self.GameObject:SetActiveEx(false)
    self:CleatSelectPos()
end

function XUiPanelCharEnhanceSkill:DoSelectPos(pos)
    self.SelectPos = pos
end

function XUiPanelCharEnhanceSkill:CleatSelectPos()
    self.SelectPos = nil
end

function XUiPanelCharEnhanceSkill:IsSelectPos()
    if self.SelectPos then
        return true
    else
        return false
    end
end