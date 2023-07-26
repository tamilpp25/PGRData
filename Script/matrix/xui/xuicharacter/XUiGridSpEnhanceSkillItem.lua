local XUiGridSpEnhanceSkillItem = XClass(nil, "XUiGridSpEnhanceSkillItem")
local XUiGridSpSkillLine = require("XUi/XUiCharacter/XUiGridSpSkillLine")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiGridSpEnhanceSkillItem:Ctor(ui, callBack,lineObj)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.CallBack = callBack
    if lineObj then
        self.Line = XUiGridSpSkillLine.New(lineObj)
    end
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
    self:InitPanel()
end

function XUiGridSpEnhanceSkillItem:SetButtonCallBack()
    self.BtnClick.CallBack = function()
        self:OnBtnClick()
    end
end

function XUiGridSpEnhanceSkillItem:InitPanel()
    self.UnlockPanel = {}
    self.CanUnlockPanel = {}
    self.LockPanel = {}
    XTool.InitUiObjectByUi(self.UnlockPanel,self.PanelUnlock)
    XTool.InitUiObjectByUi(self.CanUnlockPanel,self.PanelCanUnlock)
    XTool.InitUiObjectByUi(self.LockPanel,self.PanelLock)
end

function XUiGridSpEnhanceSkillItem:UpdateGrid(skillGroup, posName, IsShowRed)
    self.SkillGroup = skillGroup

    self.UnlockPanel.GameObject:SetActiveEx(not (not skillGroup:GetIsUnLock() and not IsShowRed))
    self.CanUnlockPanel.GameObject:SetActiveEx(not skillGroup:GetIsUnLock() and IsShowRed)
    self.LockPanel.GameObject:SetActiveEx(not skillGroup:GetIsUnLock() and not IsShowRed)
    if self.Line then
        self.Line:SetIsActivation(skillGroup:GetIsUnLock())
    end
    self:UpdatePanel(self.UnlockPanel, skillGroup, posName)
    self:UpdatePanel(self.CanUnlockPanel, skillGroup, posName)
    self:UpdatePanel(self.LockPanel, skillGroup, posName)
    
    self:ShowRedDot(IsShowRed)
end

function XUiGridSpEnhanceSkillItem:UpdatePanel(panel, skillGroup, posName)
    if panel.TxtLevel then
        panel.TxtLevel.text = CSTextManagerGetText("CharacterEnhanceSkillLevel",skillGroup:GetLevel())
    end
    if panel.TxtDesc then
        panel.TxtDesc.text = posName
    end
    if panel.TxtName then
        panel.TxtName.text = skillGroup:GetName()
    end
    if panel.RImgSkillIcon then
        panel.RImgSkillIcon:SetRawImage(skillGroup:GetIcon())
    end
end

function XUiGridSpEnhanceSkillItem:OnBtnClick()
    if self.CallBack then
        self.CallBack(self.SkillGroup:GetPos())
    end
end

function XUiGridSpEnhanceSkillItem:ShowRedDot(IsShow)
    self.BtnClick:ShowReddot(IsShow)
end

return XUiGridSpEnhanceSkillItem