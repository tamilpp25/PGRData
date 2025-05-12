local XUiGridBagOrganizeFileEditor = XClass(XUiNode, 'XUiGridBagOrganizeFileEditor')

function XUiGridBagOrganizeFileEditor:OnStart()
    self.Btn.CallBack = handler(self, self.OnClickEvent)
    ---@type XEditorBagTileEditControl
    self._EditorControl = self._Control:GetEditorControl()
end

function XUiGridBagOrganizeFileEditor:OnDestroy()
    self._EditorControl = nil
end

function XUiGridBagOrganizeFileEditor:Refresh(fileData, index)
    if self.Btn then
        self.Btn:SetNameByGroup(0, '背包绘制配置 Id:'..tostring(fileData.Id))
    end
    self._FileId = fileData.Id
    self.Index = index

    if self._EditorControl:GetCurrentFileId() == self.Index then
        self.Btn:SetButtonState(CS.UiButtonState.Select)
    else
        self.Btn:SetButtonState(CS.UiButtonState.Normal)
    end
end

function XUiGridBagOrganizeFileEditor:OnClickEvent()
    self.Parent:OnSelectFileEvent(self)
end

function XUiGridBagOrganizeFileEditor:Select()
    self.Btn:SetButtonState(CS.UiButtonState.Select)
    self._EditorControl:SetCurrentFileId(self.Index)
end

function XUiGridBagOrganizeFileEditor:UnSelect()
    self.Btn:SetButtonState(CS.UiButtonState.Normal)
    self._EditorControl:SetCurrentFileId(0)
end

return XUiGridBagOrganizeFileEditor