---@class XUiBigWorldLittleMap : XBigWorldUi
---@field PlayerPos UnityEngine.RectTransform
---@field BtnMessage XUiComponent.XUiButton
---@field BtnBigMap XUiComponent.XUiButton
---@field MapPin UnityEngine.RectTransform
---@field ImgPin UiObject
---@field MapLevel UnityEngine.RectTransform
---@field ImgLevelMap UnityEngine.UI.Image
---@field ImgMapBase UnityEngine.UI.Image
---@field ImgView UnityEngine.RectTransform
---@field MapPinTarget UnityEngine.RectTransform
---@field PinTarget UnityEngine.RectTransform
---@field PanelTrack UnityEngine.RectTransform
---@field ImgTrackPin UiObject
---@field _Control XBigWorldMapControl
local XUiBigWorldLittleMap = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldLittleMap")

-- region 生命周期

function XUiBigWorldLittleMap:OnAwake()
    self._PinList = {}
    self._PinMap = {}
    self._PinTargetList = {}
    self._AreaImageMap = {}

    self._LastGroupId = 0
    self._Scale = 1

    self._AutoTransform = nil

    self._IsEmpty = false

    self:_RegisterButtonClicks()
    self:_InitUi()
end

function XUiBigWorldLittleMap:OnStart()
    self:_InitMap(XMVCA.XBigWorldGamePlay:GetCurrentLevelId())
end

function XUiBigWorldLittleMap:OnEnable()
    self:_RefreshContent()
    -- self:_RefreshGroup()
    self:_RefreshMessage()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldLittleMap:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

function XUiBigWorldLittleMap:OnDestroy()

end

-- endregion

-- region 按钮事件

function XUiBigWorldLittleMap:OnBtnMessageClick()
    XMVCA.XBigWorldMessage:OpenUnReadMessageUi()
end

function XUiBigWorldLittleMap:OnBtnBigMapClick()
    XMVCA.XBigWorldMap:OpenBigWorldMapUi()
end

function XUiBigWorldLittleMap:OnPinStateChange()
    if not self._IsEmpty then
        self:_RefreshPin()
    end
end

function XUiBigWorldLittleMap:OnMessageNotify()
    self:_RefreshMessage()
end

function XUiBigWorldLittleMap:OnLevelUpdate(levelId)
    self:_InitMap(levelId)
    self:_RefreshContent()
end

-- endregion

-- region 私有方法

function XUiBigWorldLittleMap:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:RegisterClickEvent(self.BtnMessage, self.OnBtnMessageClick, true)
    self:RegisterClickEvent(self.BtnBigMap, self.OnBtnBigMapClick, true)
end

function XUiBigWorldLittleMap:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldLittleMap:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldLittleMap:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_SCENE_OBJECT_ACTIVATE, self.OnPinStateChange,
        self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_TRACK_CHANGE, self.OnPinStateChange,
        self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_ADD, self.OnPinStateChange, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_REMOVE, self.OnPinStateChange, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MESSAGE_FINISH_NOTIFY, self.OnMessageNotify,
        self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_RECEIVE_MESSAGE_NOTIFY, self.OnMessageNotify,
        self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_FIGHT_LEVEL_BEGIN_UPDATE, self.OnLevelUpdate,
        self)
end

function XUiBigWorldLittleMap:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_SCENE_OBJECT_ACTIVATE,
        self.OnPinStateChange, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_TRACK_CHANGE,
        self.OnPinStateChange, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_ADD, self.OnPinStateChange, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_REMOVE, self.OnPinStateChange,
        self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MESSAGE_FINISH_NOTIFY,
        self.OnMessageNotify, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_RECEIVE_MESSAGE_NOTIFY,
        self.OnMessageNotify, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_FIGHT_LEVEL_BEGIN_UPDATE,
        self.OnLevelUpdate, self)
end

function XUiBigWorldLittleMap:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldLittleMap:_InitUi()
    self.ImgPin.gameObject:SetActiveEx(false)
    self.ImgLevelMap.gameObject:SetActiveEx(false)
end

function XUiBigWorldLittleMap:_InitMap(levelId)
    self._LevelId = levelId
    self._IsEmpty = not XMVCA.XBigWorldMap:CheckLevelHasMap(levelId)
    self._AutoTransform = self.GameObject:GetComponent(typeof(CS.XLittleMapAutoTransform))

    if XTool.UObjIsNil(self._AutoTransform) then
        self._AutoTransform = self.GameObject:AddComponent(typeof(CS.XLittleMapAutoTransform))
    end
    if not self._IsEmpty then
        self._Scale = self._Control:GetLittleMapScaleByLevelId(levelId)
    end
end

function XUiBigWorldLittleMap:_RefreshContent()
    if self._IsEmpty then
        self:_RefreshEmptyMap()
    else
        self:_RefreshMap()
        self:_RefreshPin()
    end
end

function XUiBigWorldLittleMap:_RefreshMessage()
    self.BtnMessage.gameObject:SetActiveEx(XMVCA.XBigWorldMessage:CheckUnReadMessage())
end

function XUiBigWorldLittleMap:_RefreshMap()
    local rectTransform = self.ImgMapBase.transform

    self.ImgMapBase:SetSprite(self._Control:GetMapImageByLevelId(self._LevelId))
    self.ImgMapBase.gameObject:SetActiveEx(true)
    if not XTool.UObjIsNil(rectTransform) then
        local width = self._Control:GetMapWidthByLevelId(self._LevelId)
        local height = self._Control:GetMapHeightByLevelId(self._LevelId)

        rectTransform.sizeDelta = Vector2(width, height)
    end

    if not XTool.UObjIsNil(self._AutoTransform) then
        local posX = self._Control:GetMapPosXByLevelId(self._LevelId)
        local posZ = self._Control:GetMapPosZByLevelId(self._LevelId)
        local pixelRatio = self._Control:GetMapPixelRatioByLevelId(self._LevelId)

        self._AutoTransform:SetTarget(self.ImgMapBase.transform, posX, posZ, pixelRatio, self._Scale)
        self._AutoTransform:SetCursor(self.PlayerPos.transform, self.ImgView.transform)
        self._AutoTransform:SetTrack(self.PanelTrack, self.ImgTrackPin)
        self._AutoTransform:SetCheckHandle(Handler(self, self._CheckHasTrackPin))
        self._AutoTransform:SetTrackHandle(Handler(self, self._GetTrackPinIds))
        self._AutoTransform:SetPositionHandle(Handler(self, self._GetPinPositionX), Handler(self, self._GetPinPositionZ))
        self._AutoTransform:SetRefreshPinHandle(Handler(self, self._RefreshTrackPin))
        self._AutoTransform:SetTrackPinActiveHandle(Handler(self, self._SetPinActive))
    end
end

function XUiBigWorldLittleMap:_RefreshEmptyMap()
    self.ImgMapBase.gameObject:SetActiveEx(false)

    if not XTool.UObjIsNil(self._AutoTransform) then
        self._AutoTransform:SetTarget(self.ImgMapBase.transform, 0, 0, 0, 1)
        self._AutoTransform:SetCursor(self.PlayerPos.transform, self.ImgView.transform)
    end
end

function XUiBigWorldLittleMap:_RefreshPin()
    local pinDatas = self._Control:GetMapPinDatasByLevelId(self._LevelId)

    self._PinMap = {}
    if not XTool.IsTableEmpty(pinDatas) then
        local index = 1

        for pinId, pinData in pairs(pinDatas) do
            if pinData:IsDisplaying() then
                local imgPin = self._PinList[index]
                local imgTarget = self._PinTargetList[index]

                if not imgPin then
                    imgPin = XUiHelper.Instantiate(self.ImgPin, self.MapPin)

                    self._PinList[index] = imgPin
                end
                if not imgTarget then
                    imgTarget = XUiHelper.Instantiate(self.PinTarget, self.MapPinTarget)

                    self._PinTargetList[index] = imgTarget
                end

                index = index + 1
                self._PinMap[pinId] = imgPin
                self:_RefreshPinImage(imgPin, imgTarget, pinData)
            end
        end
        for i = index, table.nums(self._PinList) do
            self._PinList[i].gameObject:SetActiveEx(false)
        end
    end
end

---@param pinData XBWMapPinData
function XUiBigWorldLittleMap:_RefreshPinImage(imgPin, imgTarget, pinData)
    local transformBind = XUiHelper.TryAddComponent(imgPin.gameObject, typeof(CS.XTransformBind))

    imgPin.gameObject:SetActiveEx(true)
    self:_RefreshPinObject(imgPin, pinData)
    imgTarget.anchoredPosition = self._Control:WorldToMapPosition2D(pinData.LevelId, pinData.WorldPosition.x,
        pinData.WorldPosition.z)

    transformBind:SetTarget(imgTarget)
end

function XUiBigWorldLittleMap:_RefreshPinStyle(imgPin, styleId, isActive)
    local image = imgPin:GetObject("ImgPin")
    local icon = self._Control:GetPinIconByStyleId(styleId, isActive)

    image:SetSprite(icon)
end

---@param pinData XBWMapPinData
function XUiBigWorldLittleMap:_RefreshPinObject(imgPin, pinData)
    local tag = imgPin:GetObject("Tag")

    tag.gameObject:SetActiveEx(self._Control:CheckCurrentTrackPin(self._LevelId, pinData.PinId))
    self:_RefreshPinStyle(imgPin, pinData.StyleId, pinData:IsActive())
end

function XUiBigWorldLittleMap:_RefreshGroup()
    local groupId = self._Control:GetCurrentAreaGroupId()
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
            areaImage:SetSprite(self._Control:GetAreaImageByAreaId(areaId))
        end
        for i = table.nums(areaIds) + 1, table.nums(imageList) do
            imageList[i].gameObject:SetActiveEx(false)
        end

        self._AreaImageMap[groupId] = imageList
        self._LastGroupId = groupId
    end
end

function XUiBigWorldLittleMap:_RefreshLastGroup()
    local groupId = self._LastGroupId

    if XTool.IsNumberValid(groupId) then
        local imageList = self._AreaImageMap[groupId]

        if not XTool.IsTableEmpty(imageList) then
            for _, image in pairs(imageList) do
                image.gameObject:SetActiveEx(false)
            end
        end
    end
end

function XUiBigWorldLittleMap:_CheckHasTrackPin()
    return self._Control:CheckHasTrackPin(self._LevelId)
end

function XUiBigWorldLittleMap:_GetTrackPinIds()
    if self:_CheckHasTrackPin() then
        local trackPins = self._Control:GetCurrentTrackPins(self._LevelId)
        local result = {}

        for pinId, _ in pairs(trackPins) do
            table.insert(result, pinId)
        end

        return result
    end

    return {}
end

function XUiBigWorldLittleMap:_GetPinPositionX(pinId)
    local pinData = self._Control:GetPinDataByLevelIdAndPinId(self._LevelId, pinId)

    if pinData then
        return pinData.WorldPosition.x
    end

    return 0
end

function XUiBigWorldLittleMap:_GetPinPositionZ(pinId)
    local pinData = self._Control:GetPinDataByLevelIdAndPinId(self._LevelId, pinId)

    if pinData then
        return pinData.WorldPosition.z
    end

    return 0
end

function XUiBigWorldLittleMap:_RefreshTrackPin(imgPin, pinId)
    local pinData = self._Control:GetPinDataByLevelIdAndPinId(self._LevelId, pinId)

    if pinData then
        self:_RefreshPinObject(imgPin, pinData)
    end
end

function XUiBigWorldLittleMap:_SetPinActive(pinId, isActive)
    local pin = self._PinMap[pinId]

    if pin then
        local canvasGroup = pin:GetObject("CanvasGroup")

        if canvasGroup then
            canvasGroup.alpha = isActive and 1 or 0
        end
    end
end

-- endregion

return XUiBigWorldLittleMap
