local XUiBigWorldMapPin = require("XUi/XUiBigWorld/XMap/BigMap/XUiBigWorldMapPin")
local XUiBigWorldMapSelect = require("XUi/XUiBigWorld/XMap/BigMap/XUiBigWorldMapSelect")
local XUiBigWorldMapTrackPin = require("XUi/XUiBigWorld/XMap/BigMap/XUiBigWorldMapTrackPin")
local XUiBigWorldMapTrackPlayer = require("XUi/XUiBigWorld/XMap/BigMap/XUiBigWorldMapTrackPlayer")

---@class XUiBigWorldMap : XBigWorldUi
---@field MapArea UnityEngine.RectTransform
---@field RImgBase UnityEngine.UI.RawImage
---@field MapName UnityEngine.UI.Text
---@field AreaList XUiButtonGroup
---@field BtnArea XUiComponent.XUiButton
---@field Slider UnityEngine.UI.Slider
---@field BtnClose XUiComponent.XUiButton
---@field MapLevel UnityEngine.RectTransform
---@field MapPin UnityEngine.RectTransform
---@field ImgArea UnityEngine.UI.RawImage
---@field ImgPlayer UnityEngine.RectTransform
---@field TrackPin UnityEngine.RectTransform
---@field PanelPointer UnityEngine.RectTransform
---@field BtnAddSelect XUiComponent.XUiButton
---@field BtnMinusSelect XUiComponent.XUiButton
---@field TxtProgress UnityEngine.UI.Text
---@field ImgView UnityEngine.RectTransform
---@field MapPinTarget UnityEngine.RectTransform
---@field PinTarget UnityEngine.RectTransform
---@field PlayerTarget UnityEngine.RectTransform
---@field PanelPlayer UnityEngine.RectTransform
---@field DragArea UnityEngine.RectTransform
---@field PinNode UnityEngine.RectTransform
---@field PanelPreSelect UnityEngine.RectTransform
---@field BtnDetailClose XUiComponent.XUiButton
---@field BtnSelectClose XUiComponent.XUiButton
---@field _Control XBigWorldMapControl
local XUiBigWorldMap = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldMap")

-- region 生命周期

function XUiBigWorldMap:OnAwake()
    ---@type XUiBigWorldMapPin[]
    self._PinNodeList = {}
    ---@type table<number, XUiBigWorldMapPin>
    self._PinNodeMap = {}
    ---@type XUiBigWorldMapPin
    self._CurrentSelectPin = nil

    ---@type XUiBigWorldMapTrackPin[]
    self._TrackPinList = {}
    ---@type table<number, XUiBigWorldMapTrackPin>
    self._TrackPinMap = {}

    ---@type XUiComponent.XUiButton[]
    self._GroupButtonList = {}
    self._GroupIdList = {}

    self._AreaImageMap = {}

    self._WorldId = 0
    self._LevelId = 0
    self._CurrentGroupIndex = 0
    self._CurrentGroupId = 0

    self._TargetPinId = 0
    self._BindPinId = 0

    self._CurrentScale = 1
    self._MaxScale = 0
    self._MinScale = 0
    self._IsIgnoreSlider = false
    self._IsOnlyOneFloor = false

    ---@type XUiBigWorldMapDetail
    self._DetailUi = false

    self._Gesture = XUiHelper.TryAddComponent(self.MapArea.gameObject,
        typeof(CS.XUiComponent.XGesture.XUiGestureFixedAreaScaleDrag))

    ---@type XUiBigWorldMapSelect
    self._SelectPanel = XUiBigWorldMapSelect.New(self.PanelPreSelect, self)
    self._SelectPanel:Close()

    ---@type XUiBigWorldMapTrackPlayer
    self._PlayerTrack = false

    self.PanelSlider = self.Slider.transform.parent

    self:_InitUi()
    self:_RegisterButtonClicks()
end

function XUiBigWorldMap:OnStart(worldId, levelId, bindPinId, pinId)
    self._WorldId = worldId
    self._LevelId = levelId
    self._BindPinId = bindPinId or 0
    self._TargetPinId = XTool.IsNumberValid(pinId) and 0 or self._BindPinId

    self._MaxScale = self._Control:GetMapMaxScaleByLevelId(levelId)
    self._MinScale = self._Control:GetMapMinScaleByLevelId(levelId)
    self._Control:InitMapData(worldId, levelId)
    self:_InitGesture()
    self:_InitCurrentNpcIcon()
    self:_InitAreaList()
end

function XUiBigWorldMap:OnEnable()
    self:_RefreshMap()
    self:_RefreshPin()
    self:_RefreshPosition()
    self:_RefreshTrackPin()
    self:_RefreshPlayerTrack()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldMap:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

function XUiBigWorldMap:OnDestroy()
end

-- endregion

-- region 按钮事件

function XUiBigWorldMap:OnSliderValueChanged(value)
    if not self._IsIgnoreSlider then
        local scale = (self._MaxScale - self._MinScale) * value + self._MinScale

        self._CurrentScale = scale
        self._Gesture.Scale = scale
    end

    self._IsIgnoreSlider = false
end

function XUiBigWorldMap:OnGestureScaleValueChanged(value)
    self._IsIgnoreSlider = true
    self.Slider.value = (value - self._MinScale) / (self._MaxScale - self._MinScale)
    self:_RefreshTrackPin()
    self:_RefreshPlayerTrack()
end

function XUiBigWorldMap:OnGestureTranslateValueChanged(value)
    self:_RefreshTrackPin()
    self:_RefreshPlayerTrack()
end

function XUiBigWorldMap:OnBtnCloseClick()
    self:Close()
end

function XUiBigWorldMap:OnBtnAddSelectClick()
    self.Slider.value = self.Slider.value + 0.1
end

function XUiBigWorldMap:OnBtnMinusSelectClick()
    self.Slider.value = self.Slider.value - 0.1
end

function XUiBigWorldMap:OnBtnDetailCloseClick()
    self:_CancelSelectPin()
    self.BtnDetailClose.gameObject:SetActiveEx(false)
    self:_RefreshPinRangeSelectable(true)
    self:CloseChildUi("UiBigWorldMapDetail")
end

function XUiBigWorldMap:OnBtnSelectCloseClick()
    self:_CloseSelectPanel()
end

function XUiBigWorldMap:OnAreaListClick(index)
    local groupId = self._GroupIdList[index]

    self:_CloseSelectPanel()
    if XTool.IsNumberValid(groupId) then
        self:_RefreshLastGroup(self._GroupIdList[self._CurrentGroupIndex])
        self:_RefreshGroup(groupId)
        self._CurrentGroupIndex = index
    end
end

function XUiBigWorldMap:OnPinTrackChange(isTrack)
    self:_RefreshPin()
    self:_RefreshTrackPin()
end

function XUiBigWorldMap:OnPinActive()
    self:_RefreshPin()
end

function XUiBigWorldMap:OnPinBeginTeleport(teleportPosition, teleportEulerAngleY)
    self:CloseChildUi("UiBigWorldMapDetail")
    XMVCA.XBigWorldLoading:OpenBlackMaskLoading(function()
        self._Control:SendTeleportCommand(self._LevelId, teleportPosition.x, teleportPosition.y, teleportPosition.z,
        teleportEulerAngleY)
    end)
end

function XUiBigWorldMap:OnPinEndTeleport()
    XMVCA.XBigWorldUI:Close(self.Name, function()
        XMVCA.XBigWorldUI:SafeClose("UiBigWorldMenu")
        XMVCA.XBigWorldLoading:CloseBlackMaskLoading()
    end)
end

-- endregion

---@param pinData XBWMapPinData
function XUiBigWorldMap:OpenPinDetail(selectPin, levelId, pinData)
    self:_CancelSelectPin()
    self:_CloseSelectPanel()
    self._CurrentSelectPin = selectPin
    self.BtnDetailClose.gameObject:SetActiveEx(true)
    self:_RefreshDeatil(levelId, pinData)
end

---@param pinData XBWMapPinData
function XUiBigWorldMap:OpenSelectPinDetail(levelId, pinData)
    local pinNode = self._PinNodeMap[pinData.PinId]

    if pinNode then
        self:_CloseSelectPanel()
        self:OpenPinDetail(pinNode, levelId, pinData)
        pinNode:SetSelect(true)
    end
end

---@param pinData XBWMapPinData[]
function XUiBigWorldMap:OpenPinSelectList(pinDatas, position)
    if not XTool.IsTableEmpty(pinDatas) and table.nums(pinDatas) > 1 then
        self._SelectPanel:Open()
        self._SelectPanel:Refresh(self._LevelId, pinDatas, position)
        self:_ActiveSlider(false)
        self.BtnSelectClose.gameObject:SetActiveEx(true)
    end
end

function XUiBigWorldMap:AnchorToPin(pinId)
    local pinNode = self._PinNodeMap[pinId]

    self:_CloseSelectPanel()
    if pinNode then
        pinNode:AnchorTo()
    end
end

function XUiBigWorldMap:AnchorToPosition(x, y, isIgnoreTween)
    self:_CloseSelectPanel()
    if not XTool.UObjIsNil(self._Gesture) then
        if isIgnoreTween then
            self._Gesture:WorldPositionAnchorToSceneCenter(x, y)
        else
            self._Gesture:WorldPositionAnchorToSceneCenter(x, y, 0.5, CS.DG.Tweening.Ease.InOutQuart)
        end
    end
end

function XUiBigWorldMap:GetCurrentFloorIndex()
    if XTool.IsNumberValid(self._CurrentGroupId) then
        return self._Control:GetFloorIndexByGroupId(self._CurrentGroupId)
    end

    return 0
end

function XUiBigWorldMap:GetMapObject()
    return self.RImgBase.transform
end

---@type table<number, XUiBigWorldMapPin>
function XUiBigWorldMap:GetPinNodeMap()
    return self._PinNodeMap
end

-- region 私有方法

function XUiBigWorldMap:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick, true)
    self:RegisterClickEvent(self.BtnAddSelect, self.OnBtnAddSelectClick, true)
    self:RegisterClickEvent(self.BtnMinusSelect, self.OnBtnMinusSelectClick, true)
    self:RegisterClickEvent(self.BtnDetailClose, self.OnBtnDetailCloseClick, true)
    self:RegisterClickEvent(self.BtnSelectClose, self.OnBtnSelectCloseClick, true)
    self.Slider.onValueChanged:AddListener(Handler(self, self.OnSliderValueChanged))
end

function XUiBigWorldMap:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldMap:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldMap:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_TRACK_CHANGE, self.OnPinTrackChange,
        self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_SCENE_OBJECT_ACTIVATE, self.OnPinActive, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_BEGIN_TELEPORT,
        self.OnPinBeginTeleport, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_END_TELEPORT, self.OnPinEndTeleport,
        self)
end

function XUiBigWorldMap:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_TRACK_CHANGE,
        self.OnPinTrackChange, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_SCENE_OBJECT_ACTIVATE, self.OnPinActive,
        self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_BEGIN_TELEPORT,
        self.OnPinBeginTeleport, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_END_TELEPORT,
        self.OnPinEndTeleport, self)
end

function XUiBigWorldMap:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldMap:_RefreshPin()
    local pinDatas = self._Control:GetMapPinDatasByLevelId(self._LevelId)
    local index = 1

    self._PinNodeMap = {}
    if not XTool.IsTableEmpty(pinDatas) then
        for _, pinData in pairs(pinDatas) do
            if pinData:IsDisplaying() then
                local pinNode = self._PinNodeList[index]

                if not pinNode then
                    local node = XUiHelper.Instantiate(self.PinNode, self.MapPin)

                    pinNode = XUiBigWorldMapPin.New(node, self, self.PinTarget, self.MapPinTarget)
                    self._PinNodeList[index] = pinNode
                end

                index = index + 1
                pinNode:Open()
                pinNode:Refresh(self._LevelId, pinData)
                pinNode:SetPlayerTagActive(pinData.PinId == self._BindPinId)
                self._PinNodeMap[pinData.PinId] = pinNode
            end
        end
    end
    for i = index, table.nums(self._PinNodeList) do
        self._PinNodeList[i]:Close()
    end
end

function XUiBigWorldMap:_RefreshPlayerTrack()
    if self._PlayerTrack then
        local playerPos = self._Control:GetCurrentNpcPosition()
        local trackPos = self._Control:GetOutScreenTranckPosition(self._LevelId, self:GetMapObject(), playerPos.x, playerPos.z, self._CurrentScale)

        if trackPos then
            local playerTargetPos = self.PlayerTarget.position

            self._PlayerTrack:Open()
            self._PlayerTrack:Refresh(playerTargetPos.x, playerTargetPos.y)
            self._PlayerTrack:SetPosition(trackPos.Position, trackPos.Direction, trackPos.Angle)
        else
            self._PlayerTrack:Close()
        end
    end
end

function XUiBigWorldMap:_RefreshTrackPin()
    local trackPinIds = self._Control:GetOutScreenTranckPins(self._LevelId, self:GetMapObject(), self._CurrentScale)
    local index = 1

    self._TrackPinMap = {}
    if not XTool.IsTableEmpty(trackPinIds) then
        for pinId, pinPos in pairs(trackPinIds) do
            local trackPin = self._TrackPinList[index]

            if not trackPin then
                local trackNode = XUiHelper.Instantiate(self.PanelPointer, self.TrackPin)

                trackPin = XUiBigWorldMapTrackPin.New(trackNode, self)
                self._TrackPinList[index] = trackPin
            end
            index = index + 1

            trackPin:Open()
            trackPin:Refresh(self._LevelId, pinId)
            trackPin:SetPosition(pinPos.Position, pinPos.Direction, pinPos.Angle)
            self._TrackPinMap[pinId] = trackPin
        end
    end
    for i = index, table.nums(self._TrackPinList) do
        self._TrackPinList[i]:Close()
    end
end

function XUiBigWorldMap:_RefreshPosition()
    if not XTool.IsNumberValid(self._TargetPinId) then
        local positionX = self.PlayerTarget.position.x
        local positionY = self.PlayerTarget.position.y

        self:AnchorToPosition(positionX, positionY, true)
    else
        local pinNode = self._PinNodeMap[self._TargetPinId]

        if pinNode then
            pinNode:AnchorTo(true)
        end
    end
end

function XUiBigWorldMap:_RefreshMap()
    local rectTransform = self.RImgBase.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))

    self.TxtProgress.text = self._Control:GetCollectableText(self._WorldId, self._LevelId)
    self.MapName.text = self._Control:GetMapNameByLevelId(self._LevelId)
    self.RImgBase:SetRawImage(self._Control:GetMapImageByLevelId(self._LevelId))

    if not XTool.UObjIsNil(rectTransform) then
        local width = self._Control:GetMapWidthByLevelId(self._LevelId)
        local height = self._Control:GetMapHeightByLevelId(self._LevelId)

        rectTransform.sizeDelta = Vector2(width, height)
    end
end

function XUiBigWorldMap:_RefreshLastGroup(groupId)
    if XTool.IsNumberValid(groupId) then
        local imageList = self._AreaImageMap[groupId]

        if not XTool.IsTableEmpty(imageList) then
            for _, image in pairs(imageList) do
                image.gameObject:SetActiveEx(false)
            end
        end
    end
end

function XUiBigWorldMap:_RefreshGroup(groupId)
    local areaIds = self._Control:GetAreaIdsByGroupId(groupId)

    if not XTool.IsTableEmpty(areaIds) then
        local imageList = self._AreaImageMap[groupId] or {}

        for index, areaId in pairs(areaIds) do
            local areaImage = imageList[index]

            if not areaImage then
                areaImage = XUiHelper.Instantiate(self.ImgArea, self.MapLevel)
                imageList[index] = areaImage
            end

            local rectTransform = areaImage.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))

            if not XTool.UObjIsNil(rectTransform) then
                local posX = self._Control:GetAreaPosXByAreaId(areaId)
                local posZ = self._Control:GetAreaPosZByAreaId(areaId)
                local pixelRatio = self._Control:GetAreaPixelRatioByAreaId(areaId)

                rectTransform.anchoredPosition = self._Control:WorldToMapPosition2D(self._LevelId, posX, posZ,
                    pixelRatio)
            end

            areaImage.gameObject:SetActiveEx(true)
            areaImage:SetRawImage(self._Control:GetAreaImageByAreaId(areaId), function()
                areaImage:SetNativeSize()
            end)
        end
        for i = table.nums(areaIds) + 1, table.nums(imageList) do
            imageList[i].gameObject:SetActiveEx(false)
        end

        self._AreaImageMap[groupId] = imageList
    end
end

function XUiBigWorldMap:_RefreshDeatil(levelId, pinData)
    self:_InitDetailUi()
    self:_RefreshPinRangeSelectable(false)
    self:OpenChildUi("UiBigWorldMapDetail")
    self._DetailUi:Refresh(levelId, pinData)
end

function XUiBigWorldMap:_RefreshPinRangeSelectable(isSelect)
    if not XTool.IsTableEmpty(self._PinNodeList) then
        for _, pinNode in pairs(self._PinNodeList) do
            pinNode:SetRangeSelectable(isSelect)
        end
    end
end

function XUiBigWorldMap:_CancelSelectPin()
    if self._CurrentSelectPin then
        self._CurrentSelectPin:SetSelect(false)
        self._CurrentSelectPin = false
    end
end

function XUiBigWorldMap:_CloseSelectPanel()
    self._SelectPanel:Close()
    self.BtnSelectClose.gameObject:SetActiveEx(false)
    self:_ActiveSlider(true)
end

function XUiBigWorldMap:_ActiveSlider(isActive)
    self.PanelSlider.gameObject:SetActiveEx(isActive)
    self._Gesture.WheelSensitivity = isActive and 0.1 or 0
end

function XUiBigWorldMap:_InitDetailUi()
    if not self._DetailUi then
        self._DetailUi = self:FindChildUiObj("UiBigWorldMapDetail")
    end
end

function XUiBigWorldMap:_InitAreaList()
    local groupIds = self._Control:GetMapGroupIdsByLevelId(self._LevelId)

    if not XTool.IsTableEmpty(groupIds) then
        local currentGroupId = self._Control:GetCurrentAreaGroupId()

        self._CurrentGroupIndex = 1
        for index, groupId in pairs(groupIds) do
            local button = XUiHelper.Instantiate(self.BtnArea, self.AreaList.transform)

            button:ShowTag(currentGroupId == groupId)
            button:SetNameByGroup(0, self._Control:GetMapAreaGroupNameByGroupId(groupId))
            self._GroupButtonList[index] = button
            self._GroupIdList[index] = groupId

            if currentGroupId == groupId then
                self._CurrentGroupId = groupId
                self._CurrentGroupIndex = index
            end
        end

        self._IsOnlyOneFloor = table.nums(groupIds) == 1
        self.BtnArea.gameObject:SetActiveEx(false)
        self.AreaList:Init(self._GroupButtonList, Handler(self, self.OnAreaListClick))
        self.AreaList:SelectIndex(self._CurrentGroupIndex)
        self.AreaList.gameObject:SetActiveEx(not self._IsOnlyOneFloor)
    else
        self.BtnArea.gameObject:SetActiveEx(false)
        self.MapLevel.gameObject:SetActiveEx(false)
        self.AreaList.gameObject:SetActiveEx(false)
    end
end

function XUiBigWorldMap:_InitCurrentNpcIcon()
    if XTool.IsNumberValid(self._BindPinId) then
        self.PanelPlayer.gameObject:SetActiveEx(false)
    else
        local npcTransform = self._Control:GetCurrentNpcTransform()
        local rotation = npcTransform.eulerAngles
        local position = npcTransform.position
        local cameraTransform = self._Control:GetCurrentCameraTransform()
        local transformBind = self.PanelPlayer.gameObject:GetComponent(typeof(CS.XTransformBind))

        if XTool.UObjIsNil(transformBind) then
            transformBind = self.PanelPlayer.gameObject:AddComponent(typeof(CS.XTransformBind))
        end

        self.PlayerTarget.anchoredPosition = self._Control:WorldToMapPosition2D(self._LevelId, position.x, position.z)
        self.ImgPlayer.rotation = CS.UnityEngine.Quaternion.Euler(0, 0, -rotation.y)

        transformBind:SetTarget(self.PlayerTarget)
        if cameraTransform then
            rotation = cameraTransform.eulerAngles

            self.ImgView.localRotation = CS.UnityEngine.Quaternion.Euler(0, 0, -rotation.y)
        else
            self.ImgView.gameObject:SetActiveEx(false)
        end

        self._PlayerTrack = XUiBigWorldMapTrackPlayer.New(self.PanelPointer, self)
        self._PlayerTrack:Close()
    end
end

function XUiBigWorldMap:_InitUi()
    self.TrackPin.gameObject:SetActiveEx(true)
    self.PinNode.gameObject:SetActiveEx(false)
    self.ImgArea.gameObject:SetActiveEx(false)
    self.BtnDetailClose.gameObject:SetActiveEx(false)
    self.BtnSelectClose.gameObject:SetActiveEx(false)
    self.PanelPointer.gameObject:SetActiveEx(false)
end

function XUiBigWorldMap:_InitGesture()
    if not XTool.UObjIsNil(self._Gesture) then
        self._Gesture.FixedArea = self.DragArea
        self._Gesture.WheelSensitivity = 0.1
        self._Gesture.MaxScale = self._MaxScale
        self._Gesture.MinScale = self._MinScale
        self._Gesture.Target = self.RImgBase.transform
        self._Gesture.IsIgnoreStartedOverGui = true
        self._Gesture:AddScaleValueChangedListener(Handler(self, self.OnGestureScaleValueChanged))
        self._Gesture:AddTranslateValueChangedListener(Handler(self, self.OnGestureTranslateValueChanged))
    end
end

-- endregion

return XUiBigWorldMap
