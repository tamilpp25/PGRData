local XUiGridEnhanceSkillItem = XClass(nil, "XUiGridEnhanceSkillItem")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiGridEnhanceSkillItem:Ctor(ui, callBack)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.CallBack = callBack
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
    self:InitPanel()
end

function XUiGridEnhanceSkillItem:SetButtonCallBack()
    self.BtnClick.CallBack = function()
        self:OnBtnClick()
    end
end

function XUiGridEnhanceSkillItem:InitPanel()
    self.UnlockPanel = {}
    self.CanUnlockPanel = {}
    self.LockPanel = {}
    XTool.InitUiObjectByUi(self.UnlockPanel,self.PanelUnlock)
    XTool.InitUiObjectByUi(self.CanUnlockPanel,self.PanelCanUnlock)
    XTool.InitUiObjectByUi(self.LockPanel,self.PanelLock)
end

function XUiGridEnhanceSkillItem:UpdateGrid(skillGroup, posName, IsShowRed)
    self.SkillGroup = skillGroup
    
    self.UnlockPanel.GameObject:SetActiveEx(skillGroup:GetIsUnLock())
    self.CanUnlockPanel.GameObject:SetActiveEx(not skillGroup:GetIsUnLock() and IsShowRed)
    self.LockPanel.GameObject:SetActiveEx(not skillGroup:GetIsUnLock() and not IsShowRed)
    
    self:UpdatePanel(self.UnlockPanel, skillGroup, posName)
    self:UpdatePanel(self.CanUnlockPanel, skillGroup, posName)
    self:UpdatePanel(self.LockPanel, skillGroup, posName)
    
    self:ShowRedDot(IsShowRed)
end

function XUiGridEnhanceSkillItem:UpdatePanel(panel, skillGroup, posName)
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

function XUiGridEnhanceSkillItem:OnBtnClick()
    if self.CallBack then
        self.CallBack(self.SkillGroup:GetPos())
    end
end

function XUiGridEnhanceSkillItem:ShowRedDot(IsShow)
    self.BtnClick:ShowReddot(IsShow)
end

return XUiGridEnhanceSkillItem