-- 白情活动地点管理器
local XWhiteValentinePlaceManager = XClass(nil, "XWhiteValentinePlaceManager")

function XWhiteValentinePlaceManager:Ctor(Game)
    self.Game = Game
    self:InitPlaces()
end
--==================
--初始化地点
--==================
function XWhiteValentinePlaceManager:InitPlaces()
    self.Places = {}
    local PlaceObj = require("XEntity/XMiniGame/WhiteValentine2021/XWhiteValentinePlace")
    local AllPlaces = XWhiteValentineConfig.GetAllWhiteValentinePlace()
    for placeId, _ in pairs(AllPlaces) do
        local newPlace = PlaceObj.New(self.Game, placeId)
        self.Places[placeId] = newPlace
    end
end
--==================
--刷新数据
--@param PlaceDb:PlaceData集合。PlaceData = {int Id //地点ID，int RoleId //在该地点派遣的角色Id, int EventCfgId //事件Id，
--                  long EventEndTime //结束时间戳,0 表示未派遣角色
--                  int EventFinishCount //此地点的完成事件计数}
--==================
function XWhiteValentinePlaceManager:RefreshData(PlaceDb)
    if not PlaceDb then return end
    for _, placeData in pairs(PlaceDb) do
        local place = self.Places[placeData.Id]
        if place then place:RefreshData(placeData) end
    end
end
--==================
--刷新地点数据
--@param PlaceData = {int Id //地点ID，int RoleId //在该地点派遣的角色Id, int EventCfgId //事件Id，
--                  long EventEndTime //结束时间戳,0 表示未派遣角色
--                  int EventFinishCount //此地点的完成事件计数}
--==================
function XWhiteValentinePlaceManager:RefreshPlace(PlaceData)
    local place = self.Places[PlaceData.Id]
    if place then place:RefreshData(PlaceData) end
end
--==================
--批量刷新地点数据
--@param PlaceDatas:PlaceData集合。PlaceData = {int Id //地点ID，int RoleId //在该地点派遣的角色Id, int EventCfgId //事件Id，
--                  long EventEndTime //结束时间戳,0 表示未派遣角色
--                  int EventFinishCount //此地点的完成事件计数}
--==================
function XWhiteValentinePlaceManager:RefreshPlaceRange(PlaceDatas)
    if not PlaceDatas then return end
    for _, placeData in pairs(PlaceDatas) do
        self:RefreshPlace(placeData)
    end
end
--==================
--获取地点列表
--==================
function XWhiteValentinePlaceManager:GetPlaceList()
    return self.Places
end
--==================
--根据ID获取地点
--@param placeId:地点ID
--==================
function XWhiteValentinePlaceManager:GetPlaceByPlaceId(placeId)
    return self.Places[placeId]
end
--==================
--检查是否有事件已经结束
--==================
function XWhiteValentinePlaceManager:CheckCanFinishEvent()
    for _, place in pairs(self.Places) do
        if place:CheckCanFinishEvent() then
            return true
        end
    end
    return false
end
return XWhiteValentinePlaceManager