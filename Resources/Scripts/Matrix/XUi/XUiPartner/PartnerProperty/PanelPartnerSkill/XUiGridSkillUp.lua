local XUiGridSkillUp = XClass(nil, "XUiGridSkillUp")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiGridSkillUp:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.IsLock = false
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiGridSkillUp:SetButtonCallBack()
    self.BtnSkill.CallBack = function()
        self:OnBtnSkillClick()
    end
end

function XUiGridSkillUp:OnBtnSkillClick()
    self.Base:PlaySelectAnime(self.Data:GetActiveSkillId(), function ()
            if self:IsMainSkill() then
                XLuaUiManager.Open("UiPartnerSkillPreview", self.DataList, XPartnerConfigs.SkillType.MainSkill)
            elseif self:IsPassiveSkill() then
                XLuaUiManager.Open("UiPartnerSkillPreview", {self.Data}, XPartnerConfigs.SkillType.PassiveSkill)
            end
    end)
end

function XUiGridSkillUp:UpdateGrid(data, dataList, type)
    self.Data = data
    self.DataList = dataList
    self.Type = type
    if data then
        local level = data:GetLevelStr()
        self.TxtLv.text = CSTextManagerGetText("PartnerSkillLevelEN",level)
        self.SkillIcon:SetRawImage(data:GetSkillIcon())
    end
end

function XUiGridSkillUp:IsMainSkill()
    return self.Type == XPartnerConfigs.SkillType.MainSkill
end

function XUiGridSkillUp:IsPassiveSkill()
    return self.Type == XPartnerConfigs.SkillType.PassiveSkill
end

return XUiGridSkillUp