---@class XUiBigWorldTeachGrid : XUiNode
---@field BtnFirst XUiComponent.XUiButton
---@field TeachRed UnityEngine.RectTransform
---@field Parent XUiBigWorldTeachMain
---@field _Control XBigWorldTeachControl
local XUiBigWorldTeachGrid = XClass(XUiNode, "XUiBigWorldTeachGrid")

function XUiBigWorldTeachGrid:OnStart()
    self._Id = 0
    self._Index = 0

    self:_RegisterButtonClicks()
end

---@param config XTableBigWorldHelpCourse
function XUiBigWorldTeachGrid:Refresh(config, index, isSelect, searchKey)
    local name = self._Control:GetSearchTeachName(config.Name, searchKey)

    self.BtnFirst:SetNameByGroup(0, name)

    self._Index = index
    self._Id = config.Id

    self:SetIsSelect(isSelect)
    self:_ShowReddot(not isSelect and not self._Control:CheckTeachIsRead(self._Id))

    if isSelect then
        self.Parent:ChangeSelect(index, self._Id)
    end
end

function XUiBigWorldTeachGrid:SetIsSelect(isSelect)
    if isSelect then
        self.BtnFirst:SetButtonState(CS.UiButtonState.Select)
        self._Control:ReadTeach(self._Id)
    else
        self.BtnFirst:SetButtonState(CS.UiButtonState.Normal)
    end
end

function XUiBigWorldTeachGrid:OnBtnFirstClick()
    self:SetIsSelect(true)
    self:_ShowReddot(false)
    self.Parent:ChangeSelect(self._Index, self._Id)
end

function XUiBigWorldTeachGrid:_RegisterButtonClicks()
    self.BtnFirst.CallBack = Handler(self, self.OnBtnFirstClick)
end

function XUiBigWorldTeachGrid:_ShowReddot(isActive)
    self.TeachRed.gameObject:SetActiveEx(isActive)
end

return XUiBigWorldTeachGrid
