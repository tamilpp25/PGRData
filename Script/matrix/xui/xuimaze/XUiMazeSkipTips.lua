---@class XUiMazeSkipTips:XLuaUi
local XUiMazeSkipTips = XLuaUiManager.Register(XLuaUi, "UiMazeSkipTips")

function XUiMazeSkipTips:OnStart()
    self:BindExitBtns(self.BtnSure)
    self:BindExitBtns(self.BtnCancel)
    self:BindExitBtns(self.BtnBack)
    self:BindExitBtns(self.BtnEnter)
    self:Update()
end

function XUiMazeSkipTips:Update()
    self.TxtMessage.text = XUiHelper.ReadTextWithNewLine("MazeQuickPassDesc")
end

return XUiMazeSkipTips