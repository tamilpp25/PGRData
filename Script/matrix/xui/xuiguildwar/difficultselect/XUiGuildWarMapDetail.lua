---@class XUiGuildWarMapDetail:XLuaUi
local XUiGuildWarMapDetail = XLuaUiManager.Register(XLuaUi, "UiGuildWarMapDetail")

function XUiGuildWarMapDetail:Ctor()
    self._TextMapName = false
    self._TextDesc = false
    self._ImageBuff = false
end

function XUiGuildWarMapDetail:OnStart(buffId)
    self._TextMapName.text = XGuildWarConfig.GetFightEventName(buffId)
    self._TextDesc.text = XGuildWarConfig.GetFightEventDesc(buffId)
    self._ImageBuff:SetRawImage(XGuildWarConfig.GetFightEventIcon(buffId))
end

return XUiGuildWarMapDetail
