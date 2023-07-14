--=============
--公会宿舍房间数据
--=============
---@class XGuildDormRoomData
local XGuildDormRoomData = XClass(nil, "XGuildDormRoomData")

function XGuildDormRoomData:GetId()
    return self.Id
end

function XGuildDormRoomData:GetName()
    return self.Name
end

function XGuildDormRoomData:GetChannelMemberCount()
    return self.ChannelMemberCount or 1
end
--=============
--初始化
--=============
function XGuildDormRoomData:Ctor(cfg)
    self.Id = cfg.Id
    self.PlayerId = XPlayer.Id
    self.EntryPos = cfg.EntryPos
    self.Name = cfg.Name
    self.LastRequestMember = 0 --上次请求公会成员的时间戳，进入成员列表界面有请求间隔时间，见BtnTabMember
    self.CurrentChannel = 1
    self.ChannelMemberCount = cfg.ChannelMemberCount
    self.IsUnlock = false
    self.Index = cfg.Index
    self.FurnitureDic = {}
    self.Character = {}
    self.GroundFurniture = nil
    self.CeillingFurniture = nil
    self.WallFurniture = nil
    self:InitListeners()
end

function XGuildDormRoomData:InitListeners()
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DATA_CHANGED, self.SetGuildData, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DORM_CHANNEL_DATA_REFRESH, self.SetChannelDatas, self)
end

function XGuildDormRoomData:SetChannelDatas()
    --频道数据只对应当前所在房间，不是指定房间不需要更新
    if XDataCenter.GuildDormManager.GetCurrentRoomId() ~= self.Id then return end
    self.Channels = {}
    local ChannelDatas = XDataCenter.GuildDormManager.GetChannelDatas()
    for _, channelData in pairs(ChannelDatas or {}) do
        self.Channels[channelData.ChannelId] = channelData.MemberCount
    end
end

function XGuildDormRoomData:SetGuildData()
    
end
--=============
--追加家具
--=============
function XGuildDormRoomData:AddFurniture(furniture)
    self.FurnitureDic[furniture:GetId()] = furniture
end
--=============
--根据家具Id获取家具控件
--=============
---@return XGuildDormFurniture
function XGuildDormRoomData:GetFurniture(id)
    return self.FurnitureDic and self.FurnitureDic[id]
end
--=============
--获取所有家具
--=============
---@return table<number, XGuildDormFurniture>
function XGuildDormRoomData:GetAllFurnitures()
    return self.FurnitureDic
end
--=============
--设置房间基础装潢(地板，墙壁，天花板)
--=============
function XGuildDormRoomData:SetBaseForm(furnitureModel)
    --[[
    local baseType = XFurnitureConfigs.HomeSurfaceBaseType
    if XFurnitureConfigs.IsFurnitureMatchTypeByConfigId(furnitureModel.ConfigId, baseType.Ground) then
        self.GroundFurniture = furnitureModel
    elseif XFurnitureConfigs.IsFurnitureMatchTypeByConfigId(furnitureModel.ConfigId, baseType.Ceiling) then
        self.CeillingFurniture = furnitureModel
    elseif XFurnitureConfigs.IsFurnitureMatchTypeByConfigId(furnitureModel.ConfigId, baseType.Wall) then
        self.WallFurniture = furnitureModel
    end
    ]]
end

function XGuildDormRoomData:Dispose()
    if self.ChannelListenerId then
        XDataCenter.GuildDormManager.RemoveChannelDatasListener(self.ChannelListenerId)
        self.ChannelListenerId = nil
    end
    if self.FurnitureDic then
        for key, furniture in pairs(self.FurnitureDic) do
            furniture:Dispose()
        end
        self.FurnitureDic = {}
    end
end

return XGuildDormRoomData