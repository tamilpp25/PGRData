local XUiPanelCharEnhanceSkillSp = XClass(nil, "XUiPanelCharEnhanceSkillSp")
local XUiPanelEnhanceSkillInfo = require("XUi/XUiCharacter/XUiPanelEnhanceSkillInfo")
local XUiPanelEnhanceSkillItems = require("XUi/XUiCharacter/XUiPanelEnhanceSkillItems")

function XUiPanelCharEnhanceSkillSp:Ctor(ui, root, IsSelf)
    self.Root = root
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.IsSelf = IsSelf
    XTool.InitUiObject(self)
    self:InitPanel()
end

function XUiPanelCharEnhanceSkillSp:InitPanel()
    self.Anime = {}
    XTool.InitUiObjectByUi(self.Anime, self.Animation)
    self.InfoPanel = XUiPanelEnhanceSkillInfo.New(self.PanelSkillInfo, self.Root, self.Anime, self.IsSelf, function()
        self:DoSelectPos(self.SelectPos - 1)
        self:ShowPanel()
    end,
            function()
                self:DoSelectPos(self.SelectPos + 1)
                self:ShowPanel()
            end,XEnumConst.CHARACTER.SkillUnLockType.Sp)
    self.ItemsPanel = XUiPanelEnhanceSkillItems.New(self.PanelSkillItems, self.Anime, self.IsSelf, function(skill)
        self:DoSelectPos(skill)
        self:ShowPanel()
    end)
end

function XUiPanelCharEnhanceSkillSp:ShowPanel(character, isReset)
    if character then
        ---@type XCharacter
        self.CharEntity = character
        if type(character) == "number" then
            self.CharEntity = XMVCA.XCharacter:GetCharacter(character)
        end
    end

    if not self.CharEntity then
        return
    end

    self.GameObject:SetActiveEx(true)
    local enhanceSkillGroupDic = self.CharEntity:GetEnhanceSkillGroupDataDic()
    local levelTotal = 0
    for k,v in pairs(enhanceSkillGroupDic) do
        levelTotal = levelTotal + v:GetLevel()
    end
    self.TxtLevel.text = tostring(levelTotal)
    if self.SelectPos and (not isReset) then
        self.InfoPanel:ShowPanel(self.SelectPos, self.CharEntity)
        self.ItemsPanel:HidePanel()
    else
        self.ItemsPanel:ShowPanel(self.CharEntity)
        self.InfoPanel:HidePanel()
    end
end

--人物属性界面统一刷新接口
function XUiPanelCharEnhanceSkillSp:Refresh()
    --刷新跃升/独域技能界面信息
    if self.PanelSkillInfo.gameObject.activeSelf then
        self.InfoPanel:UpdataPanel()
    end
end

function XUiPanelCharEnhanceSkillSp:HidePanel()
    self.GameObject:SetActiveEx(false)
    self:CleatSelectPos()
end

function XUiPanelCharEnhanceSkillSp:DoSelectPos(pos)
    self.SelectPos = pos
end

function XUiPanelCharEnhanceSkillSp:CleatSelectPos()
    self.SelectPos = nil
end

function XUiPanelCharEnhanceSkillSp:IsSelectPos()
    if self.SelectPos then
        return true
    else
        return false
    end
end

return XUiPanelCharEnhanceSkillSp