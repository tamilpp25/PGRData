
local XUiGridBagOrgnizeTileEditor = XClass(XUiNode, 'XUiGridBagOrgnizeTileEditor')

function XUiGridBagOrgnizeTileEditor:OnStart()
    self.Btn.CallBack = handler(self, self.OnClickEvent)
    self._EditorControl = self._Control:GetEditorControl()
end

function XUiGridBagOrgnizeTileEditor:OnDestroy()
    self._EditorControl = nil
end

function XUiGridBagOrgnizeTileEditor:Refresh(tileData)
    -- 背包编辑器的瓦片没有走配置，因此这里就写死了
    if self.Btn then
        self.Btn:SetNameByGroup(0, '背包格子')
    end
    self._TileId = tileData.Id
end

function XUiGridBagOrgnizeTileEditor:OnClickEvent()
    self.Parent:OnSelectTileEvent(self)
end

function XUiGridBagOrgnizeTileEditor:Select()
    self.Btn:SetButtonState(CS.UiButtonState.Select)
    self._EditorControl:SetCurrentTileId(self._TileId)
end

function XUiGridBagOrgnizeTileEditor:UnSelect()
    self.Btn:SetButtonState(CS.UiButtonState.Normal)
    self._EditorControl:SetCurrentTileId(0)
end

return XUiGridBagOrgnizeTileEditor