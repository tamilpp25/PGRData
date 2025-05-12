local XBWMapPinData = require("XModule/XBigWorldMap/XData/XBWMapPinData")
local XBWMapQuestPinData = require("XModule/XBigWorldMap/XData/XBWMapQuestPinData")
local XBigWorldMapConfigModel = require("XModule/XBigWorldMap/XBigWorldMapConfigModel")

---@class XBigWorldMapModel : XBigWorldMapConfigModel
local XBigWorldMapModel = XClass(XBigWorldMapConfigModel, "XBigWorldMapModel")
function XBigWorldMapModel:OnInit()
    -- 初始化内部变量
    -- 这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    ---@type table<number, XBWMapPinData[]>
    self._PinDataMap = {}
    ---@type table<number, XBWMapPinData[]>
    self._QuestPinDataMap = {}

    self._CurrentMapPinIdMap = {}
    self._CurrentTrackPins = {}
    self._CurrentAreaId = 0

    self._TrackTemplateQuestIds = {}

    self._LittleMapUiRefCount = 0
    self._IsLittleMapUiShow = false

    self:_InitTableKey()
end

function XBigWorldMapModel:ClearPrivate()
    -- 这里执行内部数据清理
    -- XLog.Error("请对内部数据进行清理")
end

function XBigWorldMapModel:ResetAll()
    -- 这里执行重登数据清理
    -- XLog.Error("重登数据清理")
    self._PinDataMap = {}
    self._QuestPinDataMap = {}

    self._CurrentMapPinIdMap = {}

    self._CurrentTrackPins = {}
    self._CurrentAreaId = 0

    self._LittleMapUiRefCount = 0
    self._IsLittleMapUiShow = false
end

function XBigWorldMapModel:UpdateServerTrackMapPin(data)
    if data and XTool.IsNumberValid(data.TrackPinId) then
        self:TrackPins(data.LevelId, {
            [data.TrackPinId] = true,
        })
    end
end

function XBigWorldMapModel:InitPinData(worldId, levelId)
    local pinDatas = self:GetPinDatasByLevelId(levelId, true)

    if XTool.IsTableEmpty(pinDatas) then
        local maxId = 0
        local pinMap = XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_GET_LEVEL_MAP_PIN_CONFIGS, {
            LevelId = levelId,
        })
        local pinTextConfigs = {}
        
        pinDatas = {}
        XTool.LoopHashSet(pinMap.MapPinTextConfigs, function(value)
            pinTextConfigs[value.Id] = value
        end)
        XTool.LoopHashSet(pinMap.MapPinConfigs, function(value)
            ---@type XBWMapPinData
            local pinData = XBWMapPinData.New()
            local pinId = value.Id

            maxId = math.max(maxId, pinId)
            pinDatas[pinId] = pinData
            pinData:UpdateData(worldId, levelId, value, pinTextConfigs[value.Id])
        end)

        self._PinDataMap[levelId] = pinDatas
        self._CurrentMapPinIdMap[levelId] = maxId
    end
end

---@return table<number, XBWMapPinData>
function XBigWorldMapModel:GetPinDatasByLevelId(levelId, isNoTip)
    local pinDatas = self._PinDataMap[levelId]

    if XTool.IsTableEmpty(pinDatas) then
        if not isNoTip then
            XLog.Error("获取图钉数据失败! LevelId = " .. levelId)
        end

        return nil
    end

    return pinDatas
end

---@return XBWMapPinData
function XBigWorldMapModel:GetPinDataByLevelIdAndPinId(levelId, pinId, isNoTip)
    local pinDatas = self:GetPinDatasByLevelId(levelId, isNoTip)

    if not XTool.IsTableEmpty(pinDatas) then
        return pinDatas[pinId]
    end

    return nil
end

---@return table<number, XBWMapQuestPinData>
function XBigWorldMapModel:GetQuestPinDatasByQuestId(questId, isNoTip)
    local pinDatas = self._QuestPinDataMap[questId]

    if XTool.IsTableEmpty(pinDatas) then
        if not isNoTip then
            XLog.Error("获取任务图钉数据失败! QuestId = " .. questId)
        end

        return nil
    end

    return pinDatas
end

function XBigWorldMapModel:GetPinDataByLevelIdAndPinId(levelId, pinId)
    local pinDatas = self:GetPinDatasByLevelId(levelId)

    if pinDatas then
        return pinDatas[pinId]
    end

    return nil
end

function XBigWorldMapModel:AddQuestMapPin(data)
    local pinDatas = self:GetPinDatasByLevelId(data.LevelId, true)
    local pinId = self:_GetQuestPinIdByLevelId(data.LevelId)
    local questPinDatas = self:GetQuestPinDatasByQuestId(data.QuestId, true)
    ---@type XBWMapQuestPinData
    local pinData = XBWMapQuestPinData.New()

    pinData:UpdateData(pinId, data)
    questPinDatas = questPinDatas or {}
    questPinDatas[pinId] = pinData

    if pinDatas then
        pinDatas[pinId] = pinData
    else
        self._PinDataMap[data.LevelId] = {
            [pinId] = pinData,
        }
    end

    self._QuestPinDataMap[data.QuestId] = questPinDatas

    if self._TrackTemplateQuestIds[data.QuestId] then
        self:_TrackQuestMapPins(questPinDatas)
    end

    return pinId
end

function XBigWorldMapModel:RemoveQuestMapPin(data)
    local questPinDatas = self:GetQuestPinDatasByQuestId(data.QuestId, true)

    if not XTool.IsTableEmpty(questPinDatas) then
        local pinDatas = self:GetPinDatasByLevelId(data.LevelId)

        questPinDatas[data.PinId] = nil
        self:TryCancelQuestTrackPins(data.LevelId, data.PinId)
        if not XTool.IsTableEmpty(pinDatas) then
            pinDatas[data.PinId] = nil
        end
    end
end

function XBigWorldMapModel:RemoveQuestAllMapPin(questId)
    local questPinDatas = self:GetQuestPinDatasByQuestId(questId, true)

    self._TrackTemplateQuestIds[questId] = nil
    if not XTool.IsTableEmpty(questPinDatas) then
        for _, pinData in pairs(questPinDatas) do
            local pinDatas = self:GetPinDatasByLevelId(pinData.LevelId)

            self:TryCancelQuestTrackPins(pinData.LevelId, pinData.PinId)
            if not XTool.IsTableEmpty(pinDatas) then
                pinDatas[pinData.PinId] = nil
            end
        end

        self._QuestPinDataMap[questId] = nil
    end
end

function XBigWorldMapModel:TrackQuestMapPins(questId)
    local questPinDatas = self:GetQuestPinDatasByQuestId(questId, true)

    self._TrackTemplateQuestIds[questId] = true
    if not XTool.IsTableEmpty(questPinDatas) then
        self:_TrackQuestMapPins(questPinDatas)
    end
end

function XBigWorldMapModel:CancelTrackQuestMapPins(questId)
    local questPinDatas = self:GetQuestPinDatasByQuestId(questId, true)

    self._TrackTemplateQuestIds[questId] = nil
    if not XTool.IsTableEmpty(questPinDatas) then
        for _, pinData in pairs(questPinDatas) do
            pinData:UpdateDisplay(false)
            self:TryCancelQuestTrackPins(pinData.LevelId, pinData.PinId)
        end
    end
end

function XBigWorldMapModel:DisplayMapPin(data)
    local levelId = data.LevelId
    local mapPinId = data.MapPinId
    local pinData = self:GetPinDataByLevelIdAndPinId(levelId, mapPinId)

    if pinData then
        pinData:UpdateDisplay(data.Visible)
    end
end

function XBigWorldMapModel:TrackPins(levelId, pinIdMap, trackType)
    trackType = trackType or XEnumConst.BWMap.TrackType.Normal

    if not self._CurrentTrackPins[levelId] then
        self._CurrentTrackPins[levelId] = {}
    end

    self._CurrentTrackPins[levelId][trackType] = pinIdMap
end

function XBigWorldMapModel:CancelTrackPins(levelId, trackType)
    self:TrackPins(levelId, nil, trackType)
end

function XBigWorldMapModel:TryCancelQuestTrackPins(levelId, pinId)
    local currrentPinIds = self:GetTrackPinsByLevelIdAndType(levelId, XEnumConst.BWMap.TrackType.Quest)

    if not XTool.IsTableEmpty(currrentPinIds) then
        currrentPinIds[pinId] = nil
    end
end

function XBigWorldMapModel:GetAllTrackPinsByLevelId(levelId)
    local result = {}

    if not XTool.IsTableEmpty(self._CurrentTrackPins[levelId]) then
        for _, trackPins in pairs(self._CurrentTrackPins[levelId]) do
            if not XTool.IsTableEmpty(trackPins) then
                for pinId, _ in pairs(trackPins) do
                    result[pinId] = true
                end
            end
        end
    end
    
    return result
end

function XBigWorldMapModel:GetTrackPinsByLevelIdAndType(levelId, trackType)
    if self._CurrentTrackPins[levelId] then
        return self._CurrentTrackPins[levelId][trackType]
    end

    return nil
end

function XBigWorldMapModel:SetCurrentAreaId(value)
    self._CurrentAreaId = value
end

function XBigWorldMapModel:GetCurrentAreaId()
    return self._CurrentAreaId
end

function XBigWorldMapModel:RemoveCurrentAreaId()
    self:SetCurrentAreaId(0)
end

function XBigWorldMapModel:AddLittleMapUiRefCount()
    self._LittleMapUiRefCount = self._LittleMapUiRefCount + 1
end

function XBigWorldMapModel:SubLittleMapUiRefCount()
    self._LittleMapUiRefCount = self._LittleMapUiRefCount - 1
end

function XBigWorldMapModel:ResetLittleMapUiRefCount()
    self._LittleMapUiRefCount = 0
end

function XBigWorldMapModel:CheckLittleMapUiShow()
    return self._LittleMapUiRefCount > 0
end

function XBigWorldMapModel:IsLittleMapShow()
    return self._IsLittleMapUiShow
end

function XBigWorldMapModel:ShowLittleMap(isShow)
    if self._IsLittleMapUiShow ~= isShow then
        if self._IsLittleMapUiShow then
            XMVCA.XBigWorldUI:SafeClose("UiBigWorldLittleMap")
        else
            XMVCA.XBigWorldUI:Open("UiBigWorldLittleMap")
        end
        self._IsLittleMapUiShow = isShow
    end
end

function XBigWorldMapModel:_GetQuestPinIdByLevelId(levelId)
    local pinId = self._CurrentMapPinIdMap[levelId] or 0

    pinId = pinId + 1
    self._CurrentMapPinIdMap[levelId] = pinId

    return pinId
end

function XBigWorldMapModel:_TrackQuestMapPins(questPinDatas)
    if not XTool.IsTableEmpty(questPinDatas) then
        local trackPinIdMap = {}

        for _, pinData in pairs(questPinDatas) do
            trackPinIdMap[pinData.LevelId] = trackPinIdMap[pinData.LevelId] or {}
            trackPinIdMap[pinData.LevelId][pinData.PinId] = true
            pinData:UpdateDisplay(true)
        end
        for levelId, pinIdMap in pairs(trackPinIdMap) do
            self:TrackPins(levelId, pinIdMap, XEnumConst.BWMap.TrackType.Quest)
        end
    end
end

return XBigWorldMapModel
