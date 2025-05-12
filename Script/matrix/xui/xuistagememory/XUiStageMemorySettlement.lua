---@class XUiStageMemorySettlement : XLuaUi
---@field _Control XStageMemoryControl
local XUiStageMemorySettlement = XLuaUiManager.Register(XLuaUi, "UiStageMemorySettlement")

function XUiStageMemorySettlement:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnLeave, self.Close)
    self:BindExitBtns()
end

function XUiStageMemorySettlement:OnStart(data)
    local stageName = XFubenConfigs.GetStageName(data.StageId)
    self.TxtStageName.text = stageName
end

return XUiStageMemorySettlement