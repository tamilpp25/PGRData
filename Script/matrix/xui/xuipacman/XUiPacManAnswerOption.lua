---@class XUiPacManAnswerOption : XUiNode
---@field _Control XPacManControl
local XUiPacManAnswerOption = XClass(XUiNode, "XUiPacManAnswerOption")

function XUiPacManAnswerOption:OnStart()
    XUiHelper.RegisterClickEvent(self, self.Button, self.OnClick)
end

---@param data XUiPacManAnswerOptionData
function XUiPacManAnswerOption:Update(data)
    self.TxtAnswer.text = data.Text
    self:SetSelected(data.Selected)
end

function XUiPacManAnswerOption:SetSelected(value)
    self.ImgPick.gameObject:SetActiveEx(value)
end

function XUiPacManAnswerOption:OnClick()
    XEventManager.DispatchEvent(XEventId.EVENT_PACMAN_STORY_NEXT)
end

return XUiPacManAnswerOption