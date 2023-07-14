XHomeRoomData = XClass(nil, "XHomeRoomData")

function XHomeRoomData:Ctor(id)
    self.Id = id or 0
    self.PlayerId = XPlayer.Id
    self.Name = nil
    self.IsUnlock = false
    self.RoomDataType = XDormConfig.DormDataType.Self
    self.Order = 0
    self.CreateTieme = 0
    self.PicturePath = nil
    self.ConnectDormId = 0
    self.ShareId = nil  -- 分享ID
    self.FurnitureCount = 0

    self.FurnitureDic = {}
    self.Character = {}
    self.FurnitureConfigDic = {}   -- 家具config表{k:configId,  v:{ids}}

    self.GroundFurniture = nil
    self.CeillingFurniture = nil
    self.WallFurniture = nil
end

-- 判断数据是自己还是其他人的
function XHomeRoomData:IsSelfData()
    return self.PlayerId == XPlayer.Id
end

function XHomeRoomData:SetPlayerId(id)
    self.PlayerId = id
end

function XHomeRoomData:GetPlayerId()
    return self.PlayerId
end

function XHomeRoomData:GetRoomId()
    return self.Id
end

function XHomeRoomData:SetRoomName(name)
    self.Name = name
end

function XHomeRoomData:GetRoomName()
    return self.Name
end

function XHomeRoomData:SetShareId(id)
    self.ShareId = id
end

function XHomeRoomData:GetShareId()
    return self.ShareId
end

function XHomeRoomData:SetRoomUnlock(isUnlock)
    self.IsUnlock = isUnlock
end

function XHomeRoomData:WhetherRoomUnlock()
    return self.IsUnlock
end

function XHomeRoomData:AddFurniture(instId, cfgId, x, y, rotateAngle)
    local furniture = {}
    furniture.Id = instId or 0
    furniture.ConfigId = cfgId
    furniture.GridX = x
    furniture.GridY = y
    furniture.RotateAngle = rotateAngle

    self.FurnitureDic[instId] = furniture
    self:SetBaseData(furniture)

    if not self.FurnitureConfigDic[cfgId] then
        self.FurnitureConfigDic[cfgId] = {}
    end

    self.FurnitureCount = self.FurnitureCount + 1
    table.insert(self.FurnitureConfigDic[cfgId], instId)
end

-- 设置地板，天花板，墙
function XHomeRoomData:SetBaseData(furniture)
    local baseType = XFurnitureConfigs.HomeSurfaceBaseType
    if XFurnitureConfigs.IsFurnitureMatchTypeByConfigId(furniture.ConfigId, baseType.Ground) then
        self.GroundFurniture = furniture
    elseif XFurnitureConfigs.IsFurnitureMatchTypeByConfigId(furniture.ConfigId, baseType.Ceiling) then
        self.CeillingFurniture = furniture
    elseif XFurnitureConfigs.IsFurnitureMatchTypeByConfigId(furniture.ConfigId, baseType.Wall) then
        self.WallFurniture = furniture
    end
end

-- 获取地板
function XHomeRoomData:GetGroundFurniture()
    return self.GroundFurniture
end

-- 获取天花板
function XHomeRoomData:GetCeillingFurniture()
    return self.CeillingFurniture
end

-- 获取墙
function XHomeRoomData:GetWallFurniture()
    return self.WallFurniture
end

function XHomeRoomData:SetFurnitureDic(furnitureDic)
    if not furnitureDic then
        return
    end

    self.FurnitureDic = furnitureDic
    self:SetFurnitureConfigDic()
end

function XHomeRoomData:ClearFruniture()
    self.FurnitureCount = 0
    self.FurnitureDic = {}
    self.FurnitureConfigDic = {}
end

function XHomeRoomData:GetFurnitureDic()
    return self.FurnitureDic
end

function XHomeRoomData:SetFurnitureConfigDic()
    self.FurnitureConfigDic = {}
    self.FurnitureCount = 0
    for _, v in pairs(self.FurnitureDic) do
        self:SetBaseData(v)

        if not self.FurnitureConfigDic[v.ConfigId] then
            self.FurnitureConfigDic[v.ConfigId] = {}
        end

        self.FurnitureCount = self.FurnitureCount + 1
        table.insert(self.FurnitureConfigDic[v.ConfigId], v.Id)
    end
end

function XHomeRoomData:GetFurnitureConfigDic()
    return self.FurnitureConfigDic
end

function XHomeRoomData:GetFurnitureConfigByConfigId(configId)
    return self.FurnitureConfigDic[configId] or {}
end

--添加角色
function XHomeRoomData:AddCharacter(character)
    table.insert(self.Character, character)
end

--移除角色
function XHomeRoomData:RemoveCharacter(id)
    if self.Character == nil then
        return
    end

    local index = -1
    for i, v in ipairs(self.Character) do
        if v.CharacterId == id then
            index = i
            break
        end
    end

    if index > 0 then
        table.remove(self.Character, index)
    end
end

function XHomeRoomData:GetCharacterById(CharacterId)
    for _, v in ipairs(self.Character) do
        if v.CharacterId == CharacterId then
            return v
        end
    end

    return nil
end

function XHomeRoomData:GetCharacter()
    return self.Character
end

function XHomeRoomData:GetCharacterIds()
    local ids = {}
    if not self.Character or #self.Character <= 0 then
        return ids
    end

    for _, data in ipairs(self.Character) do
        table.insert(ids, data.CharacterId)
    end

    return ids
end

function XHomeRoomData:SetRoomDataType(roomType)
    self.RoomDataType = roomType
end

function XHomeRoomData:GetRoomDataType()
    return self.RoomDataType
end

function XHomeRoomData:SetRoomOrder(order)
    self.Order = order
end

function XHomeRoomData:GetRoomOrder()
    return self.Order
end

function XHomeRoomData:SetRoomCreateTime(createTime)
    self.CreateTieme = createTime
end

function XHomeRoomData:GetRoomCreateTime()
    return self.CreateTieme
end

function XHomeRoomData:SetRoomPicturePath(picturePath)
    self.PicturePath = picturePath
end

function XHomeRoomData:GetRoomPicturePath()
    return self.PicturePath
end

function XHomeRoomData:SetConnectDormId(connectDormId)
    self.ConnectDormId = connectDormId
end

function XHomeRoomData:GetConnectDormId()
    return self.ConnectDormId
end

function XHomeRoomData:GetRoomPicture(cb)
    local fileName = tostring(XPlayer.Id) .. tostring(self.Id)
    local textureCache = XDataCenter.DormManager.GetLocalCaptureCache(fileName)
    if textureCache then
        if cb then
            cb(textureCache)
        end

        return
    end

    CS.XTool.LoadLocalCaptureImg(fileName, function(textrue)
        XDataCenter.DormManager.SetLocalCaptureCache(fileName, textrue)
        if cb then
            cb(textrue)
        end
    end)
end

local FurnitrueSortFunc = function(a, b)
    if a.MinorType ~= b.MinorType then
        return a.MinorType < b.MinorType
    end

    return a.ConfigId < b.ConfigId
end

-- 获取对标宿舍足够的家具
function XHomeRoomData:GetEnoughFurnitures()
    local list = {}
    if self.ConnectDormId <= 0 then
        return list
    end

    for k, v in pairs(self.FurnitureConfigDic) do
        local myCount = #v
        local roomType = XDormConfig.DormDataType.Self
        local targetCount = XDataCenter.DormManager.GetFunritureCountInDorm(self.ConnectDormId, roomType, k, true)
        if targetCount >= myCount then
            local data = {}
            data.ConfigId = k
            data.Count = myCount
            data.TargetCount = targetCount
            data.ConnectDormId = self.ConnectDormId
            table.insert(list, data)
        end
    end

    table.sort(list, FurnitrueSortFunc)
    return list
end

-- 获取对标宿舍不足够的家具
function XHomeRoomData:GetNotEnoughFurnitures()
    local list = {}
    if self.ConnectDormId <= 0 then
        return list
    end

    for k, v in pairs(self.FurnitureConfigDic) do
        local myCount = #v
        local roomType = XDormConfig.DormDataType.Self
        local targetCount = XDataCenter.DormManager.GetFunritureCountInDorm(self.ConnectDormId, roomType, k, true)
        if targetCount < myCount then
            local data = {}
            data.ConfigId = k
            data.Count = myCount
            data.TargetCount = targetCount
            data.ConnectDormId = self.ConnectDormId
            table.insert(list, data)
        end
    end

    table.sort(list, FurnitrueSortFunc)
    return list
end

-- 获取宿舍所有家具
function XHomeRoomData:GetAllFurnitures()
    if self.ConnectDormId > 0 then
        local list = {}
        for k, v in pairs(self.FurnitureConfigDic) do
            local myCount = #v
            local roomType = XDormConfig.DormDataType.Self
            local targetCount = XDataCenter.DormManager.GetFunritureCountInDorm(self.ConnectDormId, roomType, k, true)
            local data = {}
            data.ConfigId = k
            data.Count = myCount
            data.TargetCount = targetCount
            data.ConnectDormId = self.ConnectDormId
            table.insert(list, data)
        end

        table.sort(list, FurnitrueSortFunc)
        return list
    else
        local list = {}
        for k, v in pairs(self.FurnitureConfigDic) do
            local data = {}
            data.ConfigId = k
            data.Count = #v
            data.ConnectDormId = self.ConnectDormId
            table.insert(list, data)
        end

        table.sort(list, FurnitrueSortFunc)
        return list
    end
end