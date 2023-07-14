local XUiGrideNieRCharacterStory = XClass(nil, "XUiGrideNieRCharacterStory")

function XUiGrideNieRCharacterStory:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    
    self.BtnUnLock.CallBack = function() self:OnBtnUnLockClick() end
end

function XUiGrideNieRCharacterStory:Init(parent)
    self.Parent = parent
end

function XUiGrideNieRCharacterStory:ResetData(data)
    self.Data = data
    if data.IsUnLock == XNieRConfigs.NieRChInforStatue.UnLock then
        self.PanelAnimationGroup.gameObject:SetActiveEx(true)
        self.PanelAnimationlock.gameObject:SetActiveEx(false)
        self.RedCanUnLock.gameObject:SetActiveEx(false)
        self.TextTitle.text = data.Config.Title
        self.ContentLable.text = string.gsub(data.Config.Content, "\\n", "\n")
        self.TxtDescEx.text = data.Config.DescEx
    elseif data.IsUnLock == XNieRConfigs.NieRChInforStatue.CanUnLock then
        self.PanelAnimationGroup.gameObject:SetActiveEx(false)
        self.PanelAnimationlock.gameObject:SetActiveEx(true)
        self.TextTitleLock.text = data.Config.Title
        self.ConditionLable.text = string.gsub(data.Desc, "\\n", "\n")
        self.RedCanUnLock.gameObject:SetActiveEx(true)
    else
        self.PanelAnimationGroup.gameObject:SetActiveEx(false)
        self.PanelAnimationlock.gameObject:SetActiveEx(true)
        self.RedCanUnLock.gameObject:SetActiveEx(false)
        self.TextTitleLock.text = data.Config.Title
        self.ConditionLable.text = string.gsub(data.Desc, "\\n", "\n")
    end
end

function XUiGrideNieRCharacterStory:OnBtnUnLockClick()
    if self.Data.IsUnLock == XNieRConfigs.NieRChInforStatue.CanUnLock then
        XDataCenter.NieRManager.CheckCharacterInformationUnlock(self.Data.Config.Id, true)
        self.Parent:UpdateAllInfo()
    end
end

return XUiGrideNieRCharacterStory