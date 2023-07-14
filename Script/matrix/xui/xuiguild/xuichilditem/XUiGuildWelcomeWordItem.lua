local XUiGuildWelcomeWordItem = XClass(nil, "XUiGuildWelcomeWordItem")
local Select = CS.UiButtonState.Select
local Normal = CS.UiButtonState.Normal

function XUiGuildWelcomeWordItem:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:Init(parent)
end

function XUiGuildWelcomeWordItem:Init(parent)
    self.Parent = parent
end

-- 更新数据
function XUiGuildWelcomeWordItem:OnRefresh(data)
    self.InputField.text = data.WelcomeWord or ""
    self.BtnSelect:SetButtonState(data.Select and Select or Normal)
end

-- 话术
function XUiGuildWelcomeWordItem:GetInitPutText()
    local text = self.InputField.text
    return text
end

-- 勾选状态
function XUiGuildWelcomeWordItem:GetSelect()
    return self.BtnSelect:GetToggleState()
end

function XUiGuildWelcomeWordItem:SetSelect(bool)
    return self.BtnSelect:SetButtonState(bool and Select or Normal)
end

return XUiGuildWelcomeWordItem