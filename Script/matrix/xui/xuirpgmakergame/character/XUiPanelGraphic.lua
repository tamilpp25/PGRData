--------------图示格子节点 begin --------------------
local XUiGridGraphic = XClass(nil, "XUiGridGraphic")

function XUiGridGraphic:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.RootUi = rootUi
end

function XUiGridGraphic:Refresh(beforeIcon, afterIcon)
    self.RootUi:SetUiSprite(self.ImgBefore, beforeIcon)
    self.RootUi:SetUiSprite(self.ImgAfter, afterIcon)
end
--------------图示格子节点 end ----------------------


--图示面板
local XUiPanelGraphic = XClass(nil, "XUiPanelGraphic")

function XUiPanelGraphic:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.RootUi = rootUi

    self:InitDynamicTable()
end

function XUiPanelGraphic:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewGraphicList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridGraphic, self.RootUi)
    self.GridGraphic.gameObject:SetActiveEx(false)
end

--roleId：RpgMakerGameRole表的Id
function XUiPanelGraphic:Refresh(roleId)
    self.GraphicBeforeList = XRpgMakerGameConfigs.GetRoleGraphicBefore(roleId)
    self.GraphicAfterList = XRpgMakerGameConfigs.GetRoleGraphicAfter(roleId)
    self.DynamicTable:SetDataSource(self.GraphicBeforeList)
    self.DynamicTable:ReloadDataSync()
end

function XUiPanelGraphic:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local beforeIcon = self.GraphicBeforeList[index]
        local afterIcon = self.GraphicAfterList[index]
        grid:Refresh(beforeIcon, afterIcon)
    end
end

return XUiPanelGraphic