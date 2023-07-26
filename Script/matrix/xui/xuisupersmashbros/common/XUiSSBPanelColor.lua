--==============
--超限乱斗颜色面板控件
--==============
local XUiSSBPanelColor = XClass(nil, "XUiSSBPanelColor")

function XUiSSBPanelColor:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
end
--==============
--显示对应颜色
--color : 颜色类型 XSuperSmashBrosConfig.PanelColorType
--==============
function XUiSSBPanelColor:ShowColor(color)
    if not color or color == XSuperSmashBrosConfig.PanelColorType.None then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.GameObject:SetActiveEx(true)
    local colorTypeDic = XSuperSmashBrosConfig.PanelColorType
    for _, colorType in pairs(colorTypeDic) do
        if self[colorType] then self[colorType].gameObject:SetActiveEx(color == colorType) end
    end
end
--==============
--显示面板
--==============
function XUiSSBPanelColor:ShowPanel()
    self.GameObject:SetActiveEx(true)
end
--==============
--隐藏面板
--==============
function XUiSSBPanelColor:HidePanel()
    self.GameObject:SetActiveEx(false)
end

return XUiSSBPanelColor