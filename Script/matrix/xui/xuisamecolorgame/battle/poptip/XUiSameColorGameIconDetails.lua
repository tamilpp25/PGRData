---@class XUiSameColorGameIconDetails : XLuaUi 道具说明弹框
local XUiSameColorGameIconDetails = XLuaUiManager.Register(XLuaUi, "UiSameColorGameIconDetails")

function XUiSameColorGameIconDetails:OnAwake()
    self:RegisterClickEvent(self.BtnBg, self.Close)
    self:RegisterClickEvent(self.BtnClose, self.Close)
end

---@param role XSCRole
function XUiSameColorGameIconDetails:OnStart(role)
    local items = role.Config.PropBallIds
    XUiHelper.RefreshCustomizedList(self.PanelContent, self.GridBuff, #items, function(index, grid)
        local config = XSameColorGameConfigs.GetBallConfig(items[index])
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, grid)
        uiObject.TxtName.text = config.Name
        uiObject.TxtDesc.text = XUiHelper.ReplaceTextNewLine(config.Desc)
        uiObject.RimgIcon:SetRawImage(config.Icon)
    end)
end

return XUiSameColorGameIconDetails