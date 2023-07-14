local XUiGridMentorLabel = XClass(nil, "XUiGridMentorLabel")
local Select = CS.UiButtonState.Select
local Normal = CS.UiButtonState.Normal
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiGridMentorLabel:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)
    
    self:SetButtonCallBack()
end

function XUiGridMentorLabel:SetButtonCallBack()
    self.BtnLabel.CallBack = function()
        self:OnBtnLabelClick()
    end
end

function XUiGridMentorLabel:OnBtnLabelClick()
    local IsIdInList = self.Base:CheckLabelIdInList(self.Data.Id, self.Type)
    if IsIdInList then
        self.Base:RemoveLabelId(self.Data.Id, self.Type)
    else
        if self.Base:CheckLabelCount(self.Type) then
            self.Base:AddLabelId(self.Data.Id, self.Type)
        else
            XUiManager.TipText("MentorLabelMaxText")
        end
    end
    self.Base:UpdateLabelCount()
    self:CheckSelect()
end

function XUiGridMentorLabel:SetLabelInfo(data, type)
    self.Data = data
    self.Type = type
    if data then
        self.BtnLabel:SetName(data.Tab)
        self.BtnLabel:SetSprite(data.Bg)
        --self.BgTest:SetSprite(data.Bg)
        self:CheckSelect()
    end
end

function XUiGridMentorLabel:CheckSelect()
    local IsIdInList = self.Base:CheckLabelIdInList(self.Data.Id, self.Type)
    self.BtnLabel:SetButtonState(IsIdInList and Select or Normal)
end

return XUiGridMentorLabel