local XUiInstruction = require('XUi/XUiSet/XUiInstruction')
---@class XUiInstructionMechanism
---@field private _Control XMechanismActivityControl
local XUiInstructionMechanism = XClass(XUiInstruction,'XUiInstructionMechanism')
local XUiPanelMechanismInSet = require('XUi/XUiSet/XUiPanelMechanismInSet')

local TabType={
    Skill = 1,
    Mechanism = 2,
}

---@overload
function XUiInstructionMechanism:OnStart()
    self.Super.OnStart(self)
    self.TabBtnGroup:InitBtns(self.TabBtnGroup.TabBtnList:ToArray(),handler(self,self.OnBtnGroupClick))
    self:InitMechanismPanel()
    self.TabBtnGroup:SelectIndex(1)
end

function XUiInstructionMechanism:InitMechanismPanel()
    local chapterId = XMVCA.XMechanismActivity:GetMechanismCurChapterIdInFight()
    if XTool.IsNumberValid(chapterId) then
        self._PanelMechanism = XUiPanelMechanismInSet.New(self.PanelMechanism, self)
        self._PanelMechanism:Close()
    else
        self.PanelMechanism.gameObject:SetActiveEx(false)
    end
end

function XUiInstructionMechanism:OnBtnGroupClick(index)
    self.PanelSkill.gameObject:SetActiveEx(index == TabType.Skill)

    if index == TabType.Skill then
        self._PanelMechanism:Close()
    elseif index == TabType.Mechanism then
        self._PanelMechanism:Open()
    end
end

return XUiInstructionMechanism