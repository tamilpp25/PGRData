
local XUiGridBagOrignizeBlockEditor = XClass(XUiNode, 'XUiGridBagOrignizeBlockEditor')

function XUiGridBagOrignizeBlockEditor:OnStart(blockData)
    self._EditorControl = self._Control:GetEditorControl()
    self._Data = blockData
    
    self.UiPointerCom = self.GameObject:AddComponent(typeof(CS.XUguiEventListener))
    if self.UiPointerCom then
        self.UiPointerCom.OnClick = handler(self, self.OnPointClick)
        self.UiPointerCom.OnDown = handler(self, self.OnPointDown)
        self.UiPointerCom.OnUp = handler(self, self.OnPointUp)
        self.UiPointerCom.OnEnter = handler(self, self.OnPointEnter)
    end
    
    self:Refresh()
end

function XUiGridBagOrignizeBlockEditor:OnDestroy()
    self._EditorControl = nil
end

function XUiGridBagOrignizeBlockEditor:Refresh(blockData)
    if not XTool.IsTableEmpty(blockData) then
        self._Data = blockData
    end
    
    self.Img.color = self.Parent._EditorControl:GetTileColor(self._Data:GetFillTile())
end

function XUiGridBagOrignizeBlockEditor:OnPointClick(eventData)
    if not self.Parent:IsPaintMode() then
        return
    end
    
    if eventData.button == CS.UnityEngine.EventSystems.PointerEventData.InputButton.Left then
        self._Data:FillTile(self.Parent._EditorControl:GetCurrentTileId())
    else
        self._Data:FillTile(0)
    end

    self:Refresh()
end

function XUiGridBagOrignizeBlockEditor:OnPointDown(eventData)
    self.Parent._IsFilling = true
    if eventData.button == CS.UnityEngine.EventSystems.PointerEventData.InputButton.Left then
        self.Parent._Filling = true
    else
        self.Parent._Filling = false
    end
    self:DoFilling()
    self:Refresh()
end

function XUiGridBagOrignizeBlockEditor:OnPointUp(eventData)
    self.Parent._IsFilling = false
end

function XUiGridBagOrignizeBlockEditor:OnPointEnter(eventData)
    if self.Parent._IsFilling then
        self:DoFilling()
        self:Refresh()
    end
end

function XUiGridBagOrignizeBlockEditor:DoFilling()
    if not self.Parent:IsPaintMode() then
        return
    end
    
    if self.Parent._Filling then
        self._Data:FillTile(self.Parent._EditorControl:GetCurrentTileId())
    else
        self._Data:FillTile(0)
    end
    
    self.Parent._EditorControl:MarkDataState(true)
    self.Parent:OnMapChanged()
end

return XUiGridBagOrignizeBlockEditor