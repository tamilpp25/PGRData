local XPlanetItem = require("XEntity/XPlanet/Explore/XPlanetItem")

---@class XGridPlanetBattleMainProp@battleMain的道具栏的道具
local XGridPlanetBattleMainProp = XClass(nil, "XGridPlanetBattleMainProp")

function XGridPlanetBattleMainProp:Ctor(ui, rootUi)
    XTool.InitUiObjectByUi(self, ui)
    self.RootUi = rootUi
    self.Camera = self.RootUi.Transform:GetComponent("Canvas").worldCamera
    self.RangeTileIdList = {}
    self.Scene = XDataCenter.PlanetManager.GetPlanetStageScene()
    self:InitButton()
    self._Item = false
end

function XGridPlanetBattleMainProp:InitButton()
    self.XUiWidget:AddBeginDragListener(function(eventData)
        self:OnBeginDrag(eventData)
    end)
    self.XUiWidget:AddEndDragListener(function(eventData)
        self:OnEndDrag(eventData)
    end)
    self.XUiWidget:AddDragListener(function(eventData)
        self:OnDrag(eventData)
    end)
    XUiHelper.RegisterClickEvent(self, self.Item, self._OnClick)
end

function XGridPlanetBattleMainProp:CreateDragObj()
    self.CopyGameObject = CS.UnityEngine.Object.Instantiate(self.GameObject, self.Transform.parent.parent.parent.parent.parent)
    local normalNumObj = XUiHelper.TryGetComponent(self.CopyGameObject.transform, "Item/Normal/PanelTxt")
    local pressNumObj = XUiHelper.TryGetComponent(self.CopyGameObject.transform, "Item/Press/PanelTxt")
    if normalNumObj then
        normalNumObj.gameObject:SetActiveEx(false)
    end
    if pressNumObj then
        pressNumObj.gameObject:SetActiveEx(false)
    end
end

function XGridPlanetBattleMainProp:OnBeginDrag(eventData)
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_PAUSE_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.ITEM)
    self:CreateDragObj()
end

function XGridPlanetBattleMainProp:OnDrag(eventData)
    if XTool.UObjIsNil(self.CopyGameObject) then
        return
    end
    local tile = self.Scene:GetCameraRayTile()
    self.Scene:ClearItemSelectTileList(self.RangeTileIdList)
    if tile then
        self.RangeTileIdList = self.Scene:GetItemRangeTileIdList(self._Item:GetId(), tile.TileId)
        self.Scene:RefreshItemSelectTileList(self.RangeTileIdList)
    end
    self.CopyGameObject.transform.localPosition = XUiHelper.GetScreenClickPosition(self.RootUi.Transform, self.Camera)
end

function XGridPlanetBattleMainProp:OnEndDrag(eventData)
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_RESUME_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.ITEM)
    if XTool.UObjIsNil(self.CopyGameObject) then
        return
    end
    if not XTool.UObjIsNil(self.CopyGameObject) then
        XUiHelper.Destroy(self.CopyGameObject)
    end
    if not self._Item then
        self.RangeTileIdList = {}
        return
    end
    self.Scene:ClearItemSelectTileList(self.RangeTileIdList)
    XDataCenter.PlanetExploreManager.RequestUseItem({
        ItemId = self._Item:GetId(),
        GridList = self.RangeTileIdList
    })
    self.RangeTileIdList = {}
end

function XGridPlanetBattleMainProp:Update(itemData)
    ---@type XPlanetItem
    local item = XPlanetItem.New(itemData.Id)
    self._Item = item
    local icon = item:GetIcon()
    self.Item:SetRawImage(icon)
    -- 数量
    local amout = itemData.Count
    self.Item:SetNameByGroup(0, amout)
end

function XGridPlanetBattleMainProp:_OnClick()
    XLuaUiManager.Open("UiPlanetDetailItem", self._Item)
end

return XGridPlanetBattleMainProp