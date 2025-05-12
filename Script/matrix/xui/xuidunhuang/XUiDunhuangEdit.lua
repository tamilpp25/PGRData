local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local DunhuangEnum = require("XModule/XDunhuang/Data/XDunhuangEnum")
local XUiDunhuangEditPaintingGrid = require("XUi/XUiDunhuang/XUiDunhuangEditPaintingGrid")
local XUiDunhuangUtil = require("XUi/XUiDunhuang/XUiDunhuangUtil")
local XUiPhotographSDKPanel = require("XUi/XUiPhotograph/XUiPhotographSDKPanel")
local XUiPhotographCapturePanel = require("XUi/XUiPhotograph/XUiPhotographCapturePanel")

---@class XUiDunhuangEdit : XLuaUi
---@field _Control XDunhuangControl
local XUiDunhuangEdit = XLuaUiManager.Register(XLuaUi, "UiDunhuangEdit")

function XUiDunhuangEdit:Ctor()
    self._TempPanelFrame = false
    self._DragOffset = XLuaVector2.New()

    self.UiPaintings = {}
    self.UiPaintingsData = {}

    self._TempTextureToDestroy = {}
end

function XUiDunhuangEdit:OnAwake()
    self:RegisterClickEvent(self.BtnBack, function()
        self:OnClickBack()
    end, nil, true)
    self:RegisterClickEvent(self.BtnDelete, self.OnClickDeselectPainting)
    self:RegisterClickEvent(self.BtnClickEmpty, self.OnClickEmpty)
    self:RegisterClickEvent(self.BtnClear, self.OnClickClear)
    self:RegisterClickEvent(self.BtnHandbook, self.OnClickHangBook)
    self:RegisterClickEvent(self.BtnSave, self.OnClickSave)
    self:RegisterClickEvent(self.BtnOverturn, self.OnClickFlipX)
    self:RegisterClickEvent(self.BtnShare, self.OnClickShare)

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.MuralShareCoin)
    self:BindHelpBtn(self.BtnHelp, "DunhuangHelp")

    self.DynamicTable = XDynamicTableNormal.New(self.ListMaterial.gameObject)
    self.DynamicTable:SetProxy(XUiDunhuangEditPaintingGrid, self)
    self.DynamicTable:SetDelegate(self)
    self.GridMaterial.gameObject:SetActiveEx(false)

    self:AddListenerInput()
    self.ImgMaterial.gameObject:SetActiveEx(false)

    ---@type XUiPhotographCapturePanel
    self.CapturePanel = XUiPhotographCapturePanel.New(self, self.PanelCapture)
    self.SDKPanel = XUiPhotographSDKPanel.New(self, self.PanelSDK)

    ---@type UnityEngine.RectTransform
    local rectTransform = self.PanelFrame
    self._Control:SetPaintingFrameSize(rectTransform.rect.width, rectTransform.rect.height)
    self._Control:SetPaintingListSortEnableIfNewPaintingUnlock()
end

function XUiDunhuangEdit:OnStart()
    self._Control:ClearSelectedPainting()
    self:UpdateFirstReward()
end

function XUiDunhuangEdit:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_DUNHUANG_SELECT_PAINTING, self._OnSelectPainting, self)
    XEventManager.AddEventListener(XEventId.EVENT_DUNHUANG_UPDATE_GAME, self._UpdateGame, self)
    XEventManager.AddEventListener(XEventId.EVENT_PHOTO_SHARE, self._OnShare, self)
    XEventManager.AddEventListener(XEventId.EVENT_DUNHUANG_UPDATE_SHARE_REWARD, self.UpdateRed, self)

    --self:StartTimer()
    self:UpdateByUiState()
    if self._Control:IsPaintingListDirty() then
        self:UpdatePaintingList()
    end
    self:UpdateHangBook()
    self:UpdateRed()
end

function XUiDunhuangEdit:OnDisable()
    --self:StopTimer()
    XEventManager.RemoveEventListener(XEventId.EVENT_DUNHUANG_SELECT_PAINTING, self._OnSelectPainting, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DUNHUANG_UPDATE_GAME, self._UpdateGame, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PHOTO_SHARE, self._OnShare, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DUNHUANG_UPDATE_SHARE_REWARD, self.UpdateRed, self)
end

function XUiDunhuangEdit:OnDestroy()
    ---@type XGoInputHandler
    local goInputHandler = self.PanelDrag
    goInputHandler:RemoveAllListeners()

    ---@type XGoInputHandler
    local goInputHandlerScale = self.PanelDragScale
    goInputHandlerScale:RemoveAllListeners()

    XDataCenter.PhotographManager.ClearTextureCache()

    self:DestroyShareTexture()
end

function XUiDunhuangEdit:UpdateByUiState()
    local uiState = self._Control:GetUiState()
    if uiState == DunhuangEnum.UiState.None then
        self:HideOperation()
        self.PanelSDK.gameObject:SetActiveEx(false)
        self:UpdateSelectPainting()
        self:UpdateDraw()
    end
end

function XUiDunhuangEdit:UpdatePaintingList()
    self._Control:UpdatePaintingListUnlock()
    local uiData = self._Control:GetUiData()
    local dataSource = uiData.PaintingListUnlock
    self.DynamicTable:SetDataSource(dataSource)
    self.DynamicTable:ReloadDataSync(1)
end

---@param grid XUiDunhuangEditPaintingGrid
function XUiDunhuangEdit:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetIsOnGame(true)
        grid:Update(self.DynamicTable:GetData(index), self, index)
    end
end

function XUiDunhuangEdit:OnClickBack()
    if self._Control:IsPaintingDirty() then
        XUiManager.DialogTip(nil, XUiHelper.GetText("DunhuangSavePainting"), XUiManager.DialogType.Normal, nil, function()
            self._Control:RequestSaveGame()
            self:Close()
        end, nil, function()
            self._Control:ClearGame()
            self:Close()
        end)
        return
    end
    self:Close()
end

function XUiDunhuangEdit:UpdateSelectPainting()
    self._Control:UpdateGameSelectedPainting()
    local uiData = self._Control:GetUiData()
    local data = uiData.PaintingEditingOnGame

    if data then
        self:ShowOperation()
        ---@type UnityEngine.RectTransform
        local rectTransform = self.Operation
        local position = Vector2(data.X, data.Y)
        rectTransform.anchoredPosition = position
        rectTransform:SetSizeDeltaX(data.Width)
        rectTransform:SetSizeDeltaY(data.Height)

        --if data.FlipX == 1 then
        --    local rotation = 180 - data.Rotation
        --    rectTransform.localEulerAngles = Vector3(0, 0, rotation)
        --else
        --end
        rectTransform.localEulerAngles = Vector3(0, 0, data.Rotation)
    else
        self:HideOperation()
    end
end

function XUiDunhuangEdit:_OnSelectPainting()
    self:UpdateSelectPainting()
    self:UpdateDraw()
    self:RefreshGrids()
end

function XUiDunhuangEdit:RefreshGrids()
    self._Control:UpdatePaintingListUnlock()
    local uiData = self._Control:GetUiData()
    local dataSource = uiData.PaintingListUnlock
    self.DynamicTable:SetDataSource(dataSource)

    ---@type XUiDunhuangEditPaintingGrid[]
    local grids = self.DynamicTable:GetGrids()
    for i, grid in pairs(grids) do
        ---@type XDunhuangPaintingData
        local data = self._Control:GetUiData().PaintingListUnlock[i]
        grid:Update(data)
    end
end

function XUiDunhuangEdit:_UpdateGame()
    --local paintings = self._
    --self._Control:UpdateGameSelectedPainting()
end

function XUiDunhuangEdit:OnClickDeselectPainting()
    self._Control:RemoveEditingPainting()
end

function XUiDunhuangEdit:AddListenerInput()
    ---@type XGoInputHandler
    local goInputHandler = self.PanelDrag
    goInputHandler:AddPointerDownListener(function(...)
        self:OnBeginDrag(...)
    end)
    goInputHandler:AddDragListener(function(...)
        self:OnDrag(...)
    end)
    goInputHandler:AddPointerUpListener(function(...)
        self:OnEndDrag(...)
    end)

    ---@type XGoInputHandler
    local goInputHandlerScale = self.PanelDragScale
    goInputHandlerScale:AddPointerDownListener(function(...)
        self:OnBeginDragScale(...)
    end)
    goInputHandlerScale:AddDragListener(function(...)
        self:OnDragScale(...)
    end)
    goInputHandlerScale:AddPointerUpListener(function(...)
        self:OnEndDragScale(...)
    end)
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiDunhuangEdit:OnBeginDrag(eventData)
    local x, y = self:GetPosByEventData(eventData)
    self._DragOffset.x = x
    self._DragOffset.y = y
end

-----@param eventData UnityEngine.EventSystems.PointerEventData
function XUiDunhuangEdit:OnDrag(eventData)
    local x, y = self:GetPosByEventData(eventData)
    local offsetX = x - self._DragOffset.x
    local offsetY = y - self._DragOffset.y
    self._DragOffset.x = x
    self._DragOffset.y = y
    self._Control:SetEditingPaintingPosition(offsetX, offsetY)
    self:UpdateSelectPainting()
    self:UpdateDraw()
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiDunhuangEdit:OnEndDrag(eventData)
    self._DragOffset.x = 0
    self._DragOffset.y = 0
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiDunhuangEdit:GetPosByEventData(eventData)
    ---@type UnityEngine.RectTransform
    local transform = self.PanelFrame.transform
    --local transform = self.PanelDrag.transform
    local hasValue, point = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(transform, eventData.position, CS.XUiManager.Instance.UiCamera)
    if not hasValue then
        return -99999, -99999
    end
    return point.x, point.y
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiDunhuangEdit:OnBeginDragScale(eventData)
    local x, y = self:GetPosByEventDataScale(eventData)
    self._DragOffset.x = x
    self._DragOffset.y = y
    self._Control:SetEditingPaintingOnScale()
end

-----@param eventData UnityEngine.EventSystems.PointerEventData
function XUiDunhuangEdit:OnDragScale(eventData)
    local x, y = self:GetPosByEventDataScale(eventData)
    local offsetX = x - self._DragOffset.x
    local offsetY = y - self._DragOffset.y
    self._Control:SetEditingPaintingScale(offsetX, offsetY)
    self:UpdateSelectPainting()
    self:UpdateDraw()
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiDunhuangEdit:OnEndDragScale(eventData)
    self._DragOffset.x = 0
    self._DragOffset.y = 0
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiDunhuangEdit:GetPosByEventDataScale(eventData)
    ---@type UnityEngine.RectTransform
    local transform = self.Operation.parent.transform
    local hasValue, point = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(transform, eventData.position, CS.XUiManager.Instance.UiCamera)
    if not hasValue then
        return -99999, -99999
    end
    local x, y = point.x, point.y
    return x, y
end

function XUiDunhuangEdit:OnClickEmpty()
    self._Control:SetSelectedPaintingOnGame(false)
end

function XUiDunhuangEdit:UpdateDraw()
    self._Control:UpdateDraw()
    XUiDunhuangUtil.UpdateDraw(self, self._Control)
end

function XUiDunhuangEdit:OnClickClear()
    if #self._Control:GetUiData().PaintingToDraw > 0 then
        XUiManager.DialogTip(nil, XUiHelper.GetText("DunhuangClear"), XUiManager.DialogType.Normal, nil, function()
            self:ClearPainting()
        end)
    end
end

function XUiDunhuangEdit:ClearPainting()
    self._Control:ClearGamePainting()
    self:UpdatePaintingList()
    self:UpdateByUiState()
    self._Control:RequestSaveGame()
end

function XUiDunhuangEdit:OnClickHangBook()
    self._Control:AutoRequestSaveGame()
    self._Control:ClearSelectedPainting()
    XLuaUiManager.Open("UiDunhuangHandbook")
end

function XUiDunhuangEdit:UpdateHangBook()
    self._Control:UpdatePaintingUnlockProgress()
    local data = self._Control:GetUiData()

    self.BtnHandbook:SetNameByGroup(0, data.PaintingProgress1)
end

function XUiDunhuangEdit:OnClickSave()
    if self._Control:IsPaintingDirty() then
        self._Control:RequestSaveGame()
    end
end

function XUiDunhuangEdit:OnClickFlipX()
    self._Control:OnClickFlipX()
    self:UpdateDraw()
    self:UpdateSelectPainting()
end

function XUiDunhuangEdit:UpdateRed()
    local isFirstShare = self._Control:IsFirstShare()
    self.BtnShare:ShowReddot(isFirstShare)
    self.UiDunhuangBubble.gameObject:SetActiveEx(isFirstShare)
end

function XUiDunhuangEdit:OnClickShare()
    local paintings = self._Control:GetUiData().PaintingToDraw
    if #paintings == 0 then
        XUiManager.TipText("DunhuangPaintingEmpty")
        return
    end
    self._Control:AutoRequestSaveGame()

    self:HideOperation()

    -- 把画复制到另一个画布上
    if self._TempPanelFrame then
        CS.UnityEngine.GameObject.Destroy(self._TempPanelFrame)
    end

    --local panelTop = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelTop", "RectTransform")
    self._TempPanelFrame = CS.UnityEngine.Object.Instantiate(self.PanelFrame.gameObject, self.ImagePhoto2)
    self._TempPanelFrame.transform.localPosition = Vector3.zero

    self:DestroyShareTexture()

    self.CapturePanel.BtnClose.gameObject:SetActiveEx(true)

    ---@type UnityEngine.RectTransform
    --local rectTransform = self.ImgPicture.transform
    --
    --local positionBottomLeft = rectTransform.localToWorldMatrix:MultiplyPoint(Vector3(rectTransform.rect.xMin, rectTransform.rect.yMin))
    --local screenBottomLeft = CS.XUiManager.Instance.UiCamera:WorldToScreenPoint(positionBottomLeft)
    --
    --local positionUpRight = rectTransform.localToWorldMatrix:MultiplyPoint(Vector3(rectTransform.rect.xMax, rectTransform.rect.yMax))
    --local screenTopRight = CS.XUiManager.Instance.UiCamera:WorldToScreenPoint(positionUpRight)
    --
    --local x = screenBottomLeft.x
    --local y = screenBottomLeft.y
    --local width = screenTopRight.x - screenBottomLeft.x
    --local height = screenTopRight.y - screenBottomLeft.y

    CsXUiManager.Instance:ChangeCanvasTypeCamera(CsXUiType.Normal, self.CameraCupture)

    -- 再次截图
    XCameraHelper.ScreenShotNewNoImage(self.CameraCupture, function(shot)
        CsXUiManager.Instance:ChangeCanvasTypeCamera(CsXUiType.Normal, CS.XUiManager.Instance.UiCamera)

        self._TempTextureToDestroy[#self._TempTextureToDestroy + 1] = shot

        -- 把合成后的图片渲染到游戏UI中的照片展示(最终要分享的图片)
        self.ShareTexture = shot
        self.PhotoName = "[" .. tostring(XPlayer.Id) .. "]" .. XTime.GetServerNowTimestamp()

        local x, y, width, height = self:GetRectTransform(self.ImgPicture.rectTransform, self.PanelLogoCamera)
        local shareTexture = XCameraHelper.CutPixelsFromTexture(x, y, width, height, shot)
        self.ShareTexture = shareTexture
        self._TempTextureToDestroy[#self._TempTextureToDestroy + 1] = shareTexture

        ---@type UnityEngine.RectTransform
        local tempPanelFrame = self._TempPanelFrame.transform
        tempPanelFrame.transform:SetParent(self.ImagePhoto.transform)
        tempPanelFrame.transform.localPosition = Vector3.zero

        -- 因为 CapturePanel里写死了要移除ImagePhoto的texture, 但是我并没有赋值
        self.CapturePanel.ImagePhoto.sprite = nil
        self.CapturePanel:Show()

        ---@type Spine.Unity.SkeletonAnimation
        local spineComponent = XUiHelper.TryGetComponent(self.Transform, "FullScreenBackground/PanelCapture/UiDunhuangMainBg", "SkeletonAnimation")
        if spineComponent then
            if spineComponent.AnimationState then
                spineComponent.AnimationState:SetAnimation(0, "Enable2", false)
            else
                XLog.Error("[XUiDunhuangEdit] spineComponent不存在AnimationState")
            end
        end
        self:PlayAnimation("Photo", function()
        end, function()
        end)
        self:ChangeState(XPhotographConfigs.PhotographViewState.SDK)

    end, function()
        CsXUiManager.Instance:ChangeCanvasTypeCamera(CsXUiType.Normal, self.CameraCupture)
    end)
end

function XUiDunhuangEdit:ChangeState(state)
    if state == XPhotographConfigs.PhotographViewState.Normal then
        self.CapturePanel:Hide()
        self.SDKPanel:Hide()
        --self.PanelFrame.gameObject:SetActiveEx(true)
    elseif state == XPhotographConfigs.PhotographViewState.Capture then
        self.CapturePanel:Show()
        self.SDKPanel:Hide()
        --self.PanelFrame.gameObject:SetActiveEx(false)
    elseif state == XPhotographConfigs.PhotographViewState.SDK then
        self.CapturePanel:Show()
        self.SDKPanel:Show()
        --self.PanelFrame.gameObject:SetActiveEx(false)
    end
end

function XUiDunhuangEdit:_OnShare()
    self._Control:SetNotFirstShare()
    self:UpdateRed()
end

function XUiDunhuangEdit:ShowOperation()
    self.Operation.gameObject:SetActiveEx(true)
    self.BtnClickEmpty.gameObject:SetActiveEx(true)
end

function XUiDunhuangEdit:HideOperation()
    self.Operation.gameObject:SetActiveEx(false)
    self.BtnClickEmpty.gameObject:SetActiveEx(false)
end

function XUiDunhuangEdit:UpdateFirstReward()
    if not self.TxtNumFirstShare then
        return
    end
    local reward = self._Control:GetFirstShareReward()
    local icon = XDataCenter.ItemManager.GetItemIcon(reward.TemplateId)
    self.TxtNumFirstShare.text = reward.Count
    self.IconFirstShare:SetRawImage(icon)

    self.TxtNumFirstShare2.text = reward.Count
    self.IconFirstShare2:SetRawImage(icon)
end

function XUiDunhuangEdit:DestroyShareTexture()
    if #self._TempTextureToDestroy > 0 then
        for i = 1, #self._TempTextureToDestroy do
            local texture = self._TempTextureToDestroy[i]
            CS.UnityEngine.Object.Destroy(texture)
        end
        self._TempTextureToDestroy = {}
    end

    if self.ShareTexture then
        self.ShareTexture = false
    end
end

---@param rectTransform UnityEngine.RectTransform
---@param parentTransform UnityEngine.RectTransform
function XUiDunhuangEdit:GetRectTransform(rectTransform, parentTransform)
    ---@type UnityEngine.Camera
    local camera = self.CameraCupture

    local positionBottomLeft = rectTransform.localToWorldMatrix:MultiplyPoint(Vector3(rectTransform.rect.xMin, rectTransform.rect.yMin))
    local screenBottomLeft = camera:WorldToScreenPoint(positionBottomLeft)

    local positionUpRight = rectTransform.localToWorldMatrix:MultiplyPoint(Vector3(rectTransform.rect.xMax, rectTransform.rect.yMax))
    local screenTopRight = camera:WorldToScreenPoint(positionUpRight)

    local parentPositionBottomLeft = parentTransform.localToWorldMatrix:MultiplyPoint(Vector3(parentTransform.rect.xMin, parentTransform.rect.yMin))
    local parentScreenBottomLeft = camera:WorldToScreenPoint(parentPositionBottomLeft)

    local y = screenBottomLeft.y - parentScreenBottomLeft.y
    local x = screenBottomLeft.x - parentScreenBottomLeft.x

    --local positionUpRight = rectTransform.localToWorldMatrix:MultiplyPoint(Vector3(rectTransform.rect.xMax, rectTransform.rect.yMax))
    --local screenTopRight = CS.XUiManager.Instance.UiCamera:WorldToScreenPoint(positionUpRight)

    --local x = screenBottomLeft.x
    --local y = screenBottomLeft.y
    local width = screenTopRight.x - screenBottomLeft.x
    local height = screenTopRight.y - screenBottomLeft.y
    return x, y, width, height
end

return XUiDunhuangEdit