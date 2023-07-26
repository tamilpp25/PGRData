--===========================
--选择关卡地图列表项控件
--===========================
local XUiSSBPanelMapGrid = XClass(nil, "XUiSSBPanelMapGrid")

function XUiSSBPanelMapGrid:Ctor(grid, mapCfg, rootUi)
    self.RootUi = rootUi
    XTool.InitUiObjectByUi(self, grid)
    self.BtnMap.CallBack = function() self:OnClick() end
    self:Refresh(mapCfg)
end
--==============
--刷新
--==============
function XUiSSBPanelMapGrid:Refresh(mapCfg)
    self.SceneCfg = mapCfg
    self.BtnMap:SetRawImage(self.SceneCfg.ThumbnailPath)
end
--==============
--获取UiButton组件
--==============
function XUiSSBPanelMapGrid:GetButton()
    return self.BtnMap
end
--==============
--点击时
--==============
function XUiSSBPanelMapGrid:OnSelect(value)
    if value then self.RootUi:SetSelectScene(self.SceneCfg) end
end

return XUiSSBPanelMapGrid