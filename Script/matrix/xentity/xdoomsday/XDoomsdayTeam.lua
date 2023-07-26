local XDoomsdayResource = require("XEntity/XDoomsday/XDoomsdayResource")

local Default = {
    _Id = 0,
    _PlaceId = 0, --当前所处探索地点
    _TargetPlaceId = 0, --目标所处探索地点
    _InhabitantCount = 0, --携带回来的新居民数量
    _ResourceDic = {}, -- 资源
    _State = XDoomsdayConfigs.TEAM_STATE.WAITING --状态
}

--末日生存玩法-探索队伍
local XDoomsdayTeam = XClass(XDataEntityBase, "XDoomsdayTeam")

function XDoomsdayTeam:Ctor()
    self:Init(Default)
end

function XDoomsdayTeam:InitData()
    for _, id in ipairs(XDoomsdayConfigs.GetResourceIds()) do
        self._ResourceDic[id] = XDoomsdayResource.New()
    end
end

function XDoomsdayTeam:IsEmpty()
    return not XTool.IsNumberValid(self._Id)
end

function XDoomsdayTeam:UpdateData(data)
    self:SetProperty("_Id", data.Id)
    self:SetProperty("_PlaceId", data.PlaceId)
    self:SetProperty("_TargetPlaceId", data.NewPlaceId)
    self:SetProperty("_InhabitantCount", data.PeopleDbList and #data.PeopleDbList or 0)

    --资源
    for _, resource in pairs(self._ResourceDic) do
        resource:Reset()
    end
    for _, info in pairs(data.ResourceList) do
        local resource = self:GetResource(info.CfgId)
        if resource then
            resource:UpdateData(info)
        end
    end
end

function XDoomsdayTeam:GetResource(resourceId)
    return self._ResourceDic[resourceId]
end

--开始探索指定地点
function XDoomsdayTeam:Explore(placeId)
    if not XTool.IsNumberValid(placeId) then
        XLog.Error("XDoomsdayTeam:Explore error: placeId illegal, placeId: ", placeId)
        return
    end
    self:SetProperty("_TargetPlaceId", placeId)
end

--行进中
function XDoomsdayTeam:IsMoving()
    return XTool.IsNumberValid(self._PlaceId) and XTool.IsNumberValid(self._TargetPlaceId) and
        self._TargetPlaceId ~= self._PlaceId
end

--事件中（不确定地点是否有未完成事件）
function XDoomsdayTeam:ReachPlace()
    return XTool.IsNumberValid(self._PlaceId) and XTool.IsNumberValid(self._TargetPlaceId) and
        self._TargetPlaceId == self._PlaceId
end

--获取携带居民/资源列表
function XDoomsdayTeam:GetCarryResourceList()
    local infoList = {}

    --居民放到一起展示
    table.insert(
        infoList,
        {
            ResourceId = XDoomsdayConfigs.SPECIAL_RESOURCE_TYPE_INHANBITANT,
            Count = self._InhabitantCount
        }
    )

    for resourceId, resource in pairs(self._ResourceDic) do
        table.insert(
            infoList,
            {
                ResourceId = resourceId,
                Count = resource:GetProperty("_Count")
            }
        )
    end

    return infoList
end

return XDoomsdayTeam
