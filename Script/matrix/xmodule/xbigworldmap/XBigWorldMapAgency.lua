---@class XBigWorldMapAgency : XAgency
---@field private _Model XBigWorldMapModel
local XBigWorldMapAgency = XClass(XAgency, "XBigWorldMapAgency")

function XBigWorldMapAgency:OnInit()
    -- 初始化一些变量
    XMVCA.XBigWorldUI:AddFightUiCb("UiBigWorldLittleMap", handler(self, self.OpenBigWorldLittleMapUi), 
            handler(self, self.CloseBigWorldLittleMapUi))
end

function XBigWorldMapAgency:InitRpc()
    -- 实现服务器事件注册
    -- XRpc.XXX
end

function XBigWorldMapAgency:InitEvent()
    -- 实现跨Agency事件注册
    -- self:AddAgencyEvent()
end

function XBigWorldMapAgency:InitMapPinData(worldId)
    if XTool.IsNumberValid(worldId) then
        local levelIds = CS.StatusSyncFight.XFightClient.GetWorldLevelIds(worldId)

        XTool.LoopCollection(levelIds, function(levelId)
            self._Model:InitPinData(worldId, levelId)
        end)
    end
end

function XBigWorldMapAgency:OnAddQuestMapPin(data)
    local pinId = self._Model:AddQuestMapPin(data)

    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_ADD)

    return {
        PinId = pinId,
    }
end

function XBigWorldMapAgency:OnRemoveQuestMapPin(data)
    self._Model:RemoveQuestMapPin(data)
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_REMOVE)
end

function XBigWorldMapAgency:OnRemoveQuestAllMapPins(data)
    self._Model:RemoveQuestAllMapPin(data.QuestId)
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_REMOVE)
end

function XBigWorldMapAgency:OnTrackQuestMapPin(data)
    self._Model:TrackQuestMapPins(data.QuestId)
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_TRACK_CHANGE, true)
end

function XBigWorldMapAgency:OnTeleportComplete()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_END_TELEPORT)
end

function XBigWorldMapAgency:OnCancelTrackQuestMapPin(data)
    self._Model:CancelTrackQuestMapPins(data.QuestId)
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_TRACK_CHANGE, false)
end

function XBigWorldMapAgency:OnDisplayMapPins(data)
    self._Model:DisplayMapPin(data)
end

function XBigWorldMapAgency:OnCancelTrackMapPin(data)
    local levelId = data.LevelId

    self:RequestCancelTrackMapPin(levelId, function()
        self._Model:CancelTrackPins(levelId)
    end)
end

function XBigWorldMapAgency:OnPlayerEnterArea(data)
    self._Model:SetCurrentAreaId(data.RegionId)
end

function XBigWorldMapAgency:OnPlayerExitArea(data)
    local currentAreaId = self._Model:GetCurrentAreaId()

    if currentAreaId == data.RegionId then
        self._Model:RemoveCurrentAreaId()
    end
end

function XBigWorldMapAgency:OpenBigWorldMapUiAnchorQuest(questId)
    local levelId = XMVCA.XBigWorldGamePlay:GetCurrentLevelId()
    local targetLevelId = levelId
    local questPinDatas = self._Model:GetQuestPinDatasByQuestId(questId, true)
    local pinId = math.maxinteger

    if self:CheckLevelLinkOther(levelId) then
        targetLevelId = self._Model:GetBigWorldMapLinkLinkLevelIdByLevelId(levelId)
    end

    if not XTool.IsTableEmpty(questPinDatas) then
        for _, questPinData in pairs(questPinDatas) do
            if questPinData:IsDisplaying() and questPinData.LevelId == targetLevelId then
                pinId = math.min(pinId, questPinData.PinId)
            end
        end
    end

    if pinId ~= math.maxinteger then
        local worldId = XMVCA.XBigWorldGamePlay:GetCurrentWorldId()

        self:TryOpenBigWorldMapUi(worldId, levelId, pinId)
    else
        XUiManager.TipMsg(XMVCA.XBigWorldService:GetText("MapAnchorQuestTip"))
    end
end

function XBigWorldMapAgency:OpenBigWorldMapUi()
    local levelId = XMVCA.XBigWorldGamePlay:GetCurrentLevelId()
    local worldId = XMVCA.XBigWorldGamePlay:GetCurrentWorldId()

    self:TryOpenBigWorldMapUi(worldId, levelId)
end

function XBigWorldMapAgency:TryOpenBigWorldMapUi(worldId, levelId, targetPinId)
    if self:CheckLevelLinkOther(levelId) then
        local linkLevelId = self._Model:GetBigWorldMapLinkLinkLevelIdByLevelId(levelId)
        local linkWorldId = self._Model:GetBigWorldMapLinkLinkWorldIdByLevelId(levelId)
        local bindPinId = self._Model:GetBigWorldMapLinkBindPinIdByLevelId(levelId)

        XMVCA.XBigWorldUI:Open("UiBigWorldMap", linkWorldId, linkLevelId, bindPinId, targetPinId)
    elseif self:CheckLevelHasMap(levelId) then
        XMVCA.XBigWorldUI:Open("UiBigWorldMap", worldId, levelId, 0, targetPinId)
    end
end

function XBigWorldMapAgency:ChangeLittleMapRefCount(isOpen)
    if isOpen then
        self._Model:AddLittleMapUiRefCount()
    else
        self._Model:SubLittleMapUiRefCount()
    end
end

function XBigWorldMapAgency:TryOpenLittleMapUi()
    self._Model:ShowLittleMap(self._Model:CheckLittleMapUiShow())
end

function XBigWorldMapAgency:OpenBigWorldLittleMapUi()
    self:ChangeLittleMapRefCount(true)
    self:TryOpenLittleMapUi()
end

function XBigWorldMapAgency:CloseBigWorldLittleMapUi()
    self:ChangeLittleMapRefCount(false)
    self:TryOpenLittleMapUi()
end

function XBigWorldMapAgency:ForceCloseBigWorldLittleMapUi()
    self._Model:ResetLittleMapUiRefCount()
    self._Model:ShowLittleMap(false)
end

function XBigWorldMapAgency:GetQuestPinStyleIdByQuestId(questId)
    return self._Model:GetBigWorldMapQuestPinStyleIdByQuestId(questId)
end

function XBigWorldMapAgency:UpdateTrackMapPin(data)
    self._Model:UpdateServerTrackMapPin(data)
end

function XBigWorldMapAgency:SendCurrentTrackCommand()
    local levelId = XMVCA.XBigWorldGamePlay:GetCurrentLevelId()
    local pinIds = self._Model:GetTrackPinsByLevelIdAndType(levelId, XEnumConst.BWMap.TrackType.Normal)
    local pinId = 0

    if not XTool.IsTableEmpty(pinIds) then
        for id, _ in pairs(pinIds) do
            pinId = id
        end
    end
    if XTool.IsNumberValid(pinId) then
        XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_START_TRACK_MAP_PIN, {
            LevelId = levelId,
            MapPinId = pinId,
        })
    end
end

function XBigWorldMapAgency:CheckLevelHasMap(levelId)
    local configs = self._Model:GetBigWorldMapConfigs()

    return configs[levelId] ~= nil
end

function XBigWorldMapAgency:CheckLevelLinkOther(levelId)
    local configs = self._Model:GetBigWorldMapLinkConfigs()

    return configs[levelId] ~= nil
end

function XBigWorldMapAgency:CheckNpcMapPinDefalutDisplay(levelId, npcPlaceId)
    return self:SendGetNpcMapPinDefaultVisible(levelId, npcPlaceId)
end

function XBigWorldMapAgency:CheckSceneObjectMapPinDefalutDisplay(levelId, sceneObjectPlaceId)
    return self:SendGetSceneObjectMapPinDefaultVisible(levelId, sceneObjectPlaceId)
end

function XBigWorldMapAgency:RequestCancelTrackMapPin(levelId, callback)
    XNetwork.Call("BigWorldSetTrackMapPinIdRequest", {
        MapTrackPinData = {
            WorldId = XMVCA.XBigWorldGamePlay:GetCurrentWorldId(),
            LevelId = levelId,
            TrackPinId = 0,
        },
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        if callback then
            callback()
        end

        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_TRACK_CHANGE, false)
    end)
end

function XBigWorldMapAgency:SendGetNpcMapPinDefaultVisible(levelId, npcPlaceId)
    local value = XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_GET_MAP_PIN_DEFAULT_VISIBLE_BY_NPC, {
        LevelId = levelId,
        NpcPlaceId = npcPlaceId,
    })

    return value.Visible or false
end

function XBigWorldMapAgency:SendGetSceneObjectMapPinDefaultVisible(levelId, sceneObjectPlaceId)
    local value = XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_GET_MAP_PIN_DEFAULT_VISIBLE_BY_SCENE_OBJECT, {
        LevelId = levelId,
        SceneObjectPlaceId = sceneObjectPlaceId,
    })

    return value and value.Visible or false
end

function XBigWorldMapAgency:SendTeleportCommand(levelId, posX, posY, posZ, eulerAngleY)
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_TELEPORT_PLAYER, {
        LevelId = levelId,
        PositionX = posX,
        PositionY = posY,
        PositionZ = posZ,
        EulerAngleX = 0,
        EulerAngleY = eulerAngleY or 0,
        EulerAngleZ = 0,
    })
end

return XBigWorldMapAgency
