
local XSceneObject = require("XHome/XSceneObject")

---@class XHomeRoomObj : XSceneObject  宿舍房间对象
---@field Data XHomeRoomData
local XHomeRoomObj = XClass(XSceneObject, "XHomeRoomObj")

local ROOM_DEFAULT_SO_PATH = CS.XGame.ClientConfig:GetString("RoomDefaultSoPath")
local DisplaySetType
local WallNum = 4
local NearestCameraWallNum = "1"
local ROOM_FAR_CLIP_PLANE = 25
local Bounds = CS.UnityEngine.Bounds

function XHomeRoomObj:Ctor(data, facadeGo)
    DisplaySetType = XDormConfig.VisitDisplaySetType

    self.Data = data

    if not XTool.UObjIsNil(facadeGo) then
        self.FacadeGo = CS.UnityEngine.GameObject.Instantiate(facadeGo)
        if not XTool.UObjIsNil(self.FacadeGo) then
            self.RoomUnlockGo = self.FacadeGo:Find("@Unlock").gameObject
            self.RoomLockGo = self.FacadeGo:Find("@Lock").gameObject
        end
    end

    self.IsSelected = false
    self.IsCanSave = true
    self.IsFurnitureLoadComplete = false --家具是否全部加载

    self.SurfaceRoot = nil
    self.CharacterRoot = nil
    self.FurnitureRoot = nil

    self.Ground = nil
    self.Wall = nil
    self.Ceiling = nil
    self.CanReachList = {}  -- 构造体可行走区域列表

    self.WallFurnitureList = {}
    self.GroundFurnitureList = {}
    self.WallDithers = {}
    self.CharacterList = {}
    self.UnOwnFurniture = {}
    self.TemplateFurnitureMap = {} --使用模板家具批量替换时,模板家具Id索引对应加载的出来的家具数据
    
    self.OnShowFurnitureAttrCb = handler(self, self.OnShowFurnitureAttr)
    self.OnLoadSingleFurnitureCb = handler(self, self.SingleFurnitureLoadComplete)
end

function XHomeRoomObj:Dispose()
    self:RemoveLastWallEffectDither(self.Wall)
    XHomeRoomObj.Super.Dispose(self)

    if self.WallFurnitureList then
        for k, v in pairs(self.WallFurnitureList) do
            for _, furniture in pairs(v) do
                furniture:Dispose()
            end
        end
    end

    if self.GroundFurnitureList then
        for k, furniture in pairs(self.GroundFurnitureList) do
            furniture:Dispose()
        end
    end

    if self.Ceiling then
        self.Ceiling:Dispose()
    end

    if self.Wall then
        self.Wall:Dispose()
    end


    if self.Ground then
        self.Ground:Dispose()
    end


    self.Ground = nil
    self.Wall = nil
    self.Ceiling = nil
    self.WallFurnitureList = nil
    self.GroundFurnitureList = nil


    if not XTool.UObjIsNil(self.GoInputHandler) then
        self.GoInputHandler:RemoveAllListeners()
    end
    self.GoInputHandler = nil
    self.RoomMap = nil
    self.InteractList = nil
    
    self.IsFurnitureLoading = false
    self.IsFurnitureLoadComplete = false
end

function XHomeRoomObj:OnLoadComplete(loadtype)
    if not XTool.UObjIsNil(self.FacadeGo) then
        self.FacadeGo:SetParent(self.Transform, false)
        self.FacadeGo.localPosition = CS.UnityEngine.Vector3.zero
        self.FacadeGo.localEulerAngles = CS.UnityEngine.Vector3.zero
        self.FacadeGo.localScale = CS.UnityEngine.Vector3.one
    end

    self.SurfaceRoot = self.Transform:Find("@Surface")
    self.CharacterRoot = self.Transform:Find("@Character")
    self.FurnitureRoot = self.Transform:Find("@Furniture")

    self.SurfaceRoot.gameObject:SetActiveEx(false)
    self.FurnitureRoot.gameObject:SetActiveEx(false)
    self.CharacterRoot.gameObject:SetActiveEx(false)

    self.GoInputHandler = self.Transform:GetComponent(typeof(CS.XGoInputHandler))
    if not XTool.UObjIsNil(self.GoInputHandler) then
        self.GoInputHandler:AddPointerClickListener(function() self:OnClick() end)
    end

    self:SetData(self.Data, loadtype)
end

--显示属性标签
function XHomeRoomObj:OnShowFurnitureAttr(evt, args)
    local room = XHomeDormManager.GetRoom(self.Data.Id)
    if room and XHomeDormManager.IsInRoom(self.Data.Id) then
        for _, v in pairs(room.GroundFurnitureList) do
            v:ShowAttrTag(args[0])
        end

        for _, v in pairs(room.WallFurnitureList) do
            for _, furniture in pairs(v) do
                furniture:ShowAttrTag(args[0])
            end
        end
    end
end

--隐藏属性标签
function XHomeRoomObj:OnHideFurnitureAttr()
    if self.GroundFurnitureList then
        for _, v in pairs(self.GroundFurnitureList) do
            v:HideAttrTag()
        end
    end
end

-- 设置房间数据
function XHomeRoomObj:SetData(data, loadtype)
    self.Data = data
    self.CurLoadType = loadtype

    local isUnlock = self.Data:WhetherRoomUnlock()
    if not XTool.UObjIsNil(self.RoomLockGo) then
        local v3 = XDormConfig.GetDormSenceVector(data.Id)
        self.RoomLockGo:SetActiveEx(not isUnlock)
        self.RoomLockGo.transform.localRotation = CS.UnityEngine.Quaternion.Euler(v3.x, v3.y, v3.z)
    end
    if not XTool.UObjIsNil(self.RoomUnlockGo) then
        local v3 = XDormConfig.GetDormSenceVector(data.Id)
        self.RoomUnlockGo:SetActiveEx(isUnlock)
        self.RoomUnlockGo.transform.localRotation = CS.UnityEngine.Quaternion.Euler(v3.x, v3.y, v3.z)
    end

    self:CleanRoom()
    self:CleanCharacter()
    self:LoadFurniture()
    self:LoadCharacter()

    --self:GenerateRoomMap()
end

-- 获取房间数据
function XHomeRoomObj:GetData()
    local roomData = XHomeRoomData.New(self.Data.Id)
    local roomType = self.Data:GetRoomDataType()
    local isTemplate = XDormConfig.IsTemplateRoom(roomType)

    roomData:SetPlayerId(self.Data:GetPlayerId())
    roomData:SetRoomUnlock(self.Data:WhetherRoomUnlock())
    roomData:SetRoomName(self.Data:GetRoomName())
    roomData:SetRoomDataType(roomType)
    
    if self.Wall then
        if isTemplate then
            roomData:AddFurniture(self.Wall.Data.Id, self.Wall.Data.CfgId, 0, 0, 0)
        else
            roomData:AddFurniture(self.Wall.Data.Id, self.Wall.Data.CfgId)
        end
    end

    if self.Ground then
        if isTemplate then
            roomData:AddFurniture(self.Ground.Data.Id, self.Ground.Data.CfgId, 0, 0, 0)
        else
            roomData:AddFurniture(self.Ground.Data.Id, self.Ground.Data.CfgId)
        end
    end

    if self.Ceiling then
        if isTemplate then
            roomData:AddFurniture(self.Ceiling.Data.Id, self.Ceiling.Data.CfgId, 0, 0, 0)
        else
            roomData:AddFurniture(self.Ceiling.Data.Id, self.Ceiling.Data.CfgId)
        end
    end

    for _, furniture in pairs(self.GroundFurnitureList) do
        local x, y, rotate = furniture:GetData()
        roomData:AddFurniture(furniture.Data.Id, furniture.Data.CfgId, x, y, rotate)
    end

    for _, v in pairs(self.WallFurnitureList) do
        for _, furniture in pairs(v) do
            local x, y, rotate = furniture:GetData()
            roomData:AddFurniture(furniture.Data.Id, furniture.Data.CfgId, x, y, rotate)
        end
    end

    return roomData
end

-- 设置房间光照信息
function XHomeRoomObj:SetIllumination()
    if not (self.Ceiling and self.Ceiling.Cfg) then
        return
    end

    local soPath = self.Ceiling.Cfg.IlluminationSO
    soPath = string.IsNilOrEmpty(soPath) and ROOM_DEFAULT_SO_PATH or soPath
    XHomeSceneManager.SetGlobalIllumSO(soPath)
end

-- 重置房间摆设,增加参数，重置完再刷数据
function XHomeRoomObj:RevertRoom()
    self:CleanRoom()
    self:LoadFurniture(true)
    self:SetIllumination()
    --self:GenerateRoomMap()
end

-- 收起房间家具，增加参数，收起完再刷数据，如果有构造体需要回收利用。
function XHomeRoomObj:CleanRoom()
    self:CleanGroundFurniture()
    self:CleanWallFurniture()
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_FURNITURE_CLEAN_ROOM)
    self.IsFurnitureLoadComplete = false
end

function XHomeRoomObj:CleanWallFurniture()
    if self.WallFurnitureList then
        for _, v in pairs(self.WallFurnitureList) do
            for _, furniture in pairs(v) do
                furniture:Storage(false)
            end
        end
    end
    self.WallFurnitureList = {}
end

function XHomeRoomObj:CleanGroundFurniture()
    if self.GroundFurnitureList then
        for _, furniture in pairs(self.GroundFurnitureList) do
            furniture:Storage(false)
        end
    end
    self.GroundFurnitureList = {}
end

function XHomeRoomObj:CleanCharacter()
    self:SetCharacterExit()
end

--- 加载家具,如果家具数量超过限制,未进入房间时不加载家具
---@param isEnter boolean 是否进入房间
--------------------------
function XHomeRoomObj:LoadFurniture(isEnter, allComplete)
    --是否加载家具 -> 首次进入加载 | isEnter
    local isLoadFurniture = XHomeDormManager.CheckLoadFurnitureOnEnter() or isEnter
    
    if not isLoadFurniture then
        return
    end
    self:RemoveWallDither()
    --local furnitureList = self.Data:GetFurnitureDic()
    local furnitureList = self.Data:GetFurnitureList()
    local isAsync = self.Data:IsAsyncLoad()
    
    local loadCount = self.Data.FurnitureCount
    
    local loadCb = function(furniture) 
        self:SingleFurnitureLoadComplete(furniture)
        loadCount = loadCount - 1
        
        if loadCount <= 0 then
            self.IsFurnitureLoadComplete = true
            self:GenerateRoomMap()
            self:UpdateWallListRender()
            self:SetIllumination()

            if allComplete then allComplete() end
        end
    end
    
    for _, data in pairs(furnitureList) do
        local furnitureCfg = XFurnitureConfigs.GetFurnitureTemplateById(data.ConfigId)
        if not furnitureCfg then
            goto continue
        end

        local furnitureData
        if XDormConfig.IsTemplateRoom(self.CurLoadType) then
            furnitureData = {
                Id = data.Id,
                ConfigId = data.ConfigId
            }
        else
            furnitureData = XDataCenter.FurnitureManager.GetFurnitureById(data.Id, self.CurLoadType)
        end
        local placeType = XFurnitureConfigs.GetFurniturePlaceType(furnitureCfg.TypeId)
        local async = isAsync and (placeType == XFurniturePlaceType.OnWall or placeType == XFurniturePlaceType.OnGround)
        XHomeDormManager.CreateFurniture(self.Data.Id, furnitureData, { x = data.GridX, y = data.GridY }, data.RotateAngle, async, loadCb)
        ::continue::
    end
end

---@param furniture XHomeFurnitureObj
function XHomeRoomObj:SingleFurnitureLoadComplete(furniture)
    if not furniture then
        return
    end
    local furnitureType = furniture.PlaceType
    if furnitureType == XFurniturePlaceType.Wall then  --墙体
        self:UpdateWallDither(self.Wall, furniture)
        if self.Wall then
            self.Wall:Storage()
        end
        self.Wall = furniture
    elseif furnitureType == XFurniturePlaceType.Ground then --地板
        if self.Ground then
            self.Ground:Storage()
        end

        self.Ground = furniture
    elseif furnitureType == XFurniturePlaceType.Ceiling then --天花板
        if self.Ceiling then
            self.Ceiling:Storage()
        end
        self.Ceiling = furniture
    elseif furnitureType == XFurniturePlaceType.OnWall then --墙上家具
        local dic = self.WallFurnitureList[tostring(furniture.Data.RotateAngle)]
        if not dic then
            dic = {}
            self.WallFurnitureList[tostring(furniture.Data.RotateAngle)] = dic
        end
        dic[furniture.Data.Id] = furniture
    else --地上家具
        self.GroundFurnitureList[furniture.Data.Id] = furniture
    end

    CsXGameEventManager.Instance:Notify(XEventId.EVENT_FURNITURE_ONDRAG_ITEM_CHANGED, false, furniture.Data.Id)
end

function XHomeRoomObj:UpdateFurnitureData(oldFurnitureIds, newFurnitureIds)
    local dict = self:GetAllFurnitureObj()
    --此时房间还未初始化
    if XTool.IsTableEmpty(dict) then
        return
    end
    for _, id in pairs(oldFurnitureIds) do
        local obj = dict[id]
        if obj then
            self:RemoveFurniture(obj)
            --self.Data:RemoveFurniture(obj.Data.Id, obj.CfgId)
        end
    end
    local loadCb = handler(self, self.SingleFurnitureLoadComplete)
    for _, furniture in pairs(newFurnitureIds) do
        local data = XDataCenter.FurnitureManager.GetFurnitureById(furniture.Id)
        XHomeDormManager.CreateFurniture(self.Data.Id, data, { x = furniture.X, y = furniture.Y}, furniture.Angle, false, loadCb)
        --self.Data:AddFurniture(furniture.Id, furniture.ConfigId, furniture.X, furniture.Y, furniture.Angle)
    end
    
    self.IsFurnitureLoadComplete = true

    if self.IsSelected then
        self:GenerateRoomMap()
        self:UpdateWallListRender()
        self:SetIllumination()
    end
end

--获取所有家具
function XHomeRoomObj:GetAllFurnitureConfig()
    local configs = {}
    --天花板
    if self.Ceiling and self.Ceiling.Cfg then
        table.insert(configs, self.Ceiling.Cfg)
    end

    --地板
    if self.Ground and self.Ground.Cfg then
        table.insert(configs, self.Ground.Cfg)
    end

    --墙
    if self.Wall and self.Wall.Cfg then
        table.insert(configs, self.Wall.Cfg)
    end

    --地上家具
    for _, v in pairs(self.GroundFurnitureList) do
        table.insert(configs, v.Cfg)
    end

    --挂饰
    for _, v in pairs(self.WallFurnitureList) do
        for _, furniture in pairs(v) do
            table.insert(configs, furniture.Cfg)
        end
    end

    return configs
end

---@return table<number,XHomeFurnitureObj>
function XHomeRoomObj:GetAllFurnitureObj()
    local dict = {}
    
    local check = function(furnitureObj)
        if furnitureObj and not XTool.UObjIsNil(furnitureObj.GameObject) then
            return true
        end
        return false
    end
    --天花板
    if check(self.Ceiling)then
        dict[self.Ceiling.Data.Id] = self.Ceiling
    end

    --地板
    if check(self.Ground) then
        dict[self.Ground.Data.Id] = self.Ground
    end

    --墙
    if check(self.Wall) then
        dict[self.Wall.Data.Id] = self.Wall
    end

    --地上家具
    for _, v in pairs(self.GroundFurnitureList) do
        if check(v) then
            dict[v.Data.Id] = v
        end
    end

    --挂饰
    for _, v in pairs(self.WallFurnitureList) do
        for _, furniture in pairs(v) do
            if check(furniture) then
                dict[furniture.Data.Id] = furniture
            end
        end
    end
    
    return dict
end

--适用单次查找，多次查找用上面的 GetAllFurnitureObj
function XHomeRoomObj:GetFurnitureObjById(furnitureId)
    local func = function(obj)
        if not obj or not obj.Data then
            return false
        end
       
        if obj.Data.Id == furnitureId then
            return true
        end
        return false
    end

    if func(self.Wall) then
        return self.Wall
    end

    if func(self.Ground) then
        return self.Ground
    end

    if func(self.Ceiling) then
        return self.Ceiling
    end

    for _, furniture in pairs(self.GroundFurnitureList) do
        if func(furniture) then
            return furniture
        end
    end

    for _, v in pairs(self.WallFurnitureList) do
        for _, furniture in pairs(v) do
            if func(furniture) then
                return furniture
            end
        end
    end
end

function XHomeRoomObj:CancelSelectRayCast()
    local cancel = function(obj)
        if not obj or not obj.RayCastSelected then
            return
        end
        obj:RayCastSelected(false)
    end
    cancel(self.Wall)
    cancel(self.Ground)
    cancel(self.Ceiling)
    for _, furniture in pairs(self.GroundFurnitureList) do
        cancel(furniture)
    end
    for _, v in pairs(self.WallFurnitureList) do
        for _, furniture in pairs(v) do
            cancel(furniture)
        end
    end
end

function XHomeRoomObj:CancelNotOwnRayCast()
    local cancel = function(obj)
        if not obj or not obj.RayCastNotOwn then
            return
        end
        obj:RayCastNotOwn(false)
    end
    cancel(self.Wall)
    cancel(self.Ground)
    cancel(self.Ceiling)
    for _, furniture in pairs(self.GroundFurnitureList) do
        cancel(furniture)
    end
    for _, v in pairs(self.WallFurnitureList) do
        for _, furniture in pairs(v) do
            cancel(furniture)
        end
    end
end

-- 设置家具交互点Go
function XHomeRoomObj:SetInteractInfoGo()
    for _, v in pairs(self.GroundFurnitureList) do
        if v then
            v:SetInteractInfoGo()
        end
    end
end

-- 隐藏家具交互点Go
function XHomeRoomObj:HideInteractInfoGo()
    for _, v in pairs(self.GroundFurnitureList) do
        if v then
            v:HideInteractInfoGo()
        end
    end
end

-- 获取地表配置id
function XHomeRoomObj:GetPlatId(homePlatType)
    if (homePlatType == CS.XHomePlatType.Ground and not self.Ground) or
    (homePlatType == CS.XHomePlatType.Wall and not self.Wall) then
        return XDataCenter.DormManager.GetRoomPlatId(self.Data.Id, homePlatType)
    elseif homePlatType == CS.XHomePlatType.Ground then
        return self.Ground.CfgId
    elseif homePlatType == CS.XHomePlatType.Wall then
        return self.Wall.CfgId
    else
        return 0
    end
end

-- 加载构造体
function XHomeRoomObj:LoadCharacter()
    local characterList = self.Data:GetCharacter()

    for _, data in ipairs(characterList) do
        XHomeCharManager.PreLoadHomeCharacterById(data.CharacterId)
    end
end

-- 更换基础装修
function XHomeRoomObj:ReplaceSurface(furniture)
    if not furniture then
        return
    end
    if furniture.PlaceType == XFurniturePlaceType.Wall then
        self:RemoveWallDither()
        if self.Wall then
            self.Wall:Storage()
        end
        self:UpdateWallDither(self.Wall, furniture)
        self.Wall = furniture
        self:GenerateRoomMap()

        for _, v in pairs(self.WallFurnitureList) do
            for _, data in pairs(v) do
                local cfg = XFurnitureConfigs.GetFurnitureTemplateById(data.Data.CfgId)
                if cfg then
                    local homePlatType = XFurnitureConfigs.LocateTypeToXHomePlatType(cfg.LocateType)
                    if homePlatType == nil then
                        return
                    end

                    -- 检测是否有家具阻挡
                    local x, y, rot = data:GetData()
                    if self:CheckFurnitureBlock(data.Data.Id, x, y, cfg.Width, cfg.Height, homePlatType, rot) then
                        data:Storage()
                    end
                end
            end
        end

        self:UpdateWallListRender()

    elseif furniture.PlaceType == XFurniturePlaceType.Ground then
        if self.Ground then
            self.Ground:Storage()
        end
        self.Ground = furniture
        self:GenerateRoomMap()
        for _, data in pairs(self.GroundFurnitureList) do
            local cfg = XFurnitureConfigs.GetFurnitureTemplateById(data.Data.CfgId)
            if cfg then
                local homePlatType = XFurnitureConfigs.LocateTypeToXHomePlatType(cfg.LocateType)
                if homePlatType == nil then
                    return
                end

                -- 检测是否有家具阻挡
                local x, y, rot = data:GetData()
                if self:CheckFurnitureBlock(data.Data.Id, x, y, cfg.Width, cfg.Height, homePlatType, rot) then
                    --self.IsCanSave = false
                    data:Storage()
                    break
                end
            end
        end
    elseif furniture.PlaceType == XFurniturePlaceType.Ceiling then
        if self.Ceiling then
            self.Ceiling:Storage()
        end
        self.Ceiling = furniture
        self:SetIllumination()
    end

    CsXGameEventManager.Instance:Notify(XEventId.EVENT_FURNITURE_ONDRAG_ITEM_CHANGED, false, furniture.Data.Id)
end

-- 检测类型数量限制
function XHomeRoomObj:CheckFurnitureCountReachLimit(furniture)
    if furniture.Cfg.PutNumType <= 0 then
        -- 无类型，不限制
        return false
    end
    local PutNumCfg = XFurnitureConfigs.GetFurniturePutNumCfg(furniture.Cfg.PutNumType)
    if PutNumCfg.PutCount <= 0 then
        -- 不限制数量
        return false
    end

    local count = 0
    for _, v in pairs(self.GroundFurnitureList) do
        if v.Cfg.PutNumType == furniture.Cfg.PutNumType then
            count = count + 1
        end
    end

    if count < PutNumCfg.PutCount then
        -- 未达到限制数量
        return false
    end

    return true
end

-- 检测类型数量限制
function XHomeRoomObj:CheckFurnitureCountReachLimitByPutNumType(putNumType)
    if putNumType <= 0 then
        -- 无类型，不限制
        return false
    end
    local PutNumCfg = XFurnitureConfigs.GetFurniturePutNumCfg(putNumType)
    if PutNumCfg.PutCount <= 0 then
        -- 不限制数量
        return false
    end

    local count = 0
    for _, v in pairs(self.GroundFurnitureList) do
        if v.Cfg.PutNumType == putNumType then
            count = count + 1
        end
    end

    if count < PutNumCfg.PutCount then
        -- 未达到限制数量
        return false
    end

    return true
end

-- 添加家具
function XHomeRoomObj:AddFurniture(furniture)
    local old
    if furniture.PlaceType == XFurniturePlaceType.OnGround then
        old = self.GroundFurnitureList[furniture.Data.Id]
        if not old then
            self.GroundFurnitureList[furniture.Data.Id] = furniture
        end
    elseif furniture.PlaceType == XFurniturePlaceType.OnWall then
        for _, v in pairs(self.WallFurnitureList) do
            old = v[furniture.Data.Id]
            if old then
                local _, _, rot = old:GetData()
                self.WallDithers[tostring(rot)]:AddRenderer(furniture.GameObject)
                self.WallDithers[tostring(rot)]:AddStateChangeListener(furniture.GameObject, handler(furniture, furniture.OnStateChange))
                break
            end
        end

        if not old then
            local _, _, rot = furniture:GetData()
            local temp = self.WallFurnitureList[tostring(rot)]
            if not temp then
                temp = {}
                self.WallFurnitureList[tostring(rot)] = temp
            end

            temp[furniture.Data.Id] = furniture
            self.WallDithers[tostring(rot)]:AddRenderer(furniture.GameObject)
            self.WallDithers[tostring(rot)]:AddStateChangeListener(furniture.GameObject, handler(furniture, furniture.OnStateChange))
        end
    end
end

-- 移除家具
function XHomeRoomObj:RemoveFurniture(furniture)
    if furniture.PlaceType == XFurniturePlaceType.OnGround then
        self.GroundFurnitureList[furniture.Data.Id] = nil
    elseif furniture.PlaceType == XFurniturePlaceType.OnWall then
        local _, _, rot = furniture:GetData()
        local temp = self.WallFurnitureList[tostring(rot)]
        if temp then
            if temp[furniture.Data.Id] then
                self.WallDithers[tostring(rot)]:RemoveRenderer(temp[furniture.Data.Id].GameObject)
                self.WallDithers[tostring(rot)]:RemoveStateChangeListener(temp[furniture.Data.Id].GameObject)

            end
            temp[furniture.Data.Id] = nil
        end
    end
end

-- 选中房间
function XHomeRoomObj:SetSelected(isSelected, shouldProcessOutside, onFinishEnterRoom)
    self.IsSelected = isSelected
    if isSelected then
        self.GameObject:SetActiveEx(true)
    end
    
    local cb = function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end

        local roomType = self.Data:GetRoomDataType()
        local isTemplate = XDormConfig.IsTemplateRoom(roomType)
        self.SurfaceRoot.gameObject:SetActiveEx(isSelected or isTemplate)
        self.FurnitureRoot.gameObject:SetActiveEx(isSelected or isTemplate)
        self.CharacterRoot.gameObject:SetActiveEx(isSelected or isTemplate)

        if not XTool.UObjIsNil(self.FacadeGo) then
            self.FacadeGo.gameObject:SetActiveEx(not isSelected)
        end
        
        if shouldProcessOutside then
            XHomeDormManager.ShowOrHideOutsideRoom(self.Data.Id, not isSelected)
        end

        if onFinishEnterRoom then
            onFinishEnterRoom()
        end
    end

    if isSelected then
        self:OnEnterRoom(cb)
    else
        XScheduleManager.ScheduleOnce(function()
            cb()
        end, 150)
        self:SetCharacterExit()
        self:CancelSelectRayCast()
        self:CancelNotOwnRayCast()

        CsXGameEventManager.Instance:RemoveEvent(XEventId.EVENT_DORM_FURNITURE_ATTR_TAG, self.OnShowFurnitureAttrCb)

        self:OnHideFurnitureAttr()
        self:StorageTemplateFurniture()
    end
end

function XHomeRoomObj:OnEnterRoom(onEnterCb)
    local initAsync = false
    --家具全部加载完成回调
    local allLoad = function()
        
        local camera = XHomeSceneManager.GetSceneCamera()
        if not XTool.UObjIsNil(camera) then
            camera.farClipPlane = ROOM_FAR_CLIP_PLANE
        end
        
        --生产角色
        XScheduleManager.ScheduleOnce(function()
            self:SetCharacterBorn()
        end, 1)
        self:SetIllumination()
        
        if onEnterCb then onEnterCb() end
        
        initAsync = true
    end
    
    if self.IsFurnitureLoadComplete then
        allLoad()
    else
        self:LoadFurniture(true, function()
            if initAsync then
                return
            end
            allLoad()
        end)
    end
    -- 墙-地板-天花板 采用同步加载
    local dither = self.WallDithers[NearestCameraWallNum]
    if dither then
        --避免镜头先渲染后隐藏，露馅
        dither:SetRendererState(false)
    end

    -- 镜头黑幕界面
    XHomeSceneManager.SafeOpenBlack(self.Transform, true, "Room", function()
        XHomeSceneManager.ChangeView(HomeSceneViewType.RoomView)
        if not initAsync and self.IsFurnitureLoadComplete then
            allLoad()
        end
    end)

    XEventManager.DispatchEvent(XEventId.EVENT_DORM_ROOM, self.Data.Id)
    CsXGameEventManager.Instance:RegisterEvent(XEventId.EVENT_DORM_FURNITURE_ATTR_TAG, self.OnShowFurnitureAttrCb)
    -- 更新缓存
    XHomeDormManager.UpdateRoomCache(self)
end

-- 收纳模板宿舍中的家具
function XHomeRoomObj:StorageTemplateFurniture()
    if not XDormConfig.IsTemplateRoom(self.CurLoadType) then
        return
    end

    if self.Ceiling then
        self.Ceiling:Storage()
        self.Ceiling = nil
    end

    if self.Ground then
        self.Ground:Storage()
        self.Ground = nil
    end

    if self.Wall then
        self.Wall:Storage()
        self.Wall = nil
    end

    for _, furniture in pairs(self.GroundFurnitureList) do
        furniture:Storage()
    end
    self.GroundFurnitureList = {}

    for _, v in pairs(self.WallFurnitureList) do
        for _, furniture in pairs(v) do
            furniture:Storage()
        end
    end
    self.WallFurnitureList = {}
    self.IsFurnitureLoadComplete = false
end

--进入房间角色出生
function XHomeRoomObj:SetCharacterBorn()
    if not self.IsSelected then
        return
    end

    self:ResetCharacterList()
end

function XHomeRoomObj:ResetCharacterList()
    -- 清空已有的角色
    self:CleanCharacter()
    -- 获取房间的角色列表
    local characterList = self.Data:GetCharacter()
    if characterList == nil then
        return
    end

    for _, data in ipairs(characterList) do
        if data and data.CharacterId then
            local isSelf = self.Data:IsSelfData()
            local isWorking = XDataCenter.DormManager.IsWorking(data.CharacterId)
            if (not self.Data:IsSelfData()) or (not XDataCenter.DormManager.IsWorking(data.CharacterId)) then
                -- 生成角色
                local charObj = XHomeCharManager.SpawnHomeCharacter(data.CharacterId, self.CharacterRoot)
                -- 设置角色数据
                charObj:SetData(data, self.Data:IsSelfData())
                charObj:Born(self.RoomMap, self)
                table.insert(self.CharacterList, charObj)
            end
        end
    end
    
    for _, furniture in pairs(self.GroundFurnitureList) do
        for _, char in ipairs(self.CharacterList) do
            furniture:RippleAddChar(char.Transform)
        end
    end
end

--退出房间
function XHomeRoomObj:SetCharacterExit()
    if self.CharacterList == nil then
        return
    end

    for _, v in ipairs(self.CharacterList) do
        v:ExitRoom()
    end

    self.CharacterList = {}
    for _, furniture in pairs(self.GroundFurnitureList) do
        furniture:RippleClearChar()
    end
end

--添加构造体
function XHomeRoomObj:AddCharacter(dormtoryId, characterId)
    if dormtoryId ~= self.Data.Id then
        return
    end

    local data = self.Data:GetCharacterById(characterId)
    if (not self.Data:IsSelfData()) or (not XDataCenter.DormManager.IsWorking(data.CharacterId)) then
        local charObj = XHomeCharManager.SpawnHomeCharacter(characterId, self.CharacterRoot)
        charObj:SetData(data, self.Data:IsSelfData())

        if self.IsSelected then
            table.insert(self.CharacterList, charObj)
            charObj:Born(self.RoomMap, self)
        end

        for _, furniture in pairs(self.GroundFurnitureList) do
            furniture:RippleAddChar(charObj.Transform)
        end
    end
end

--移除构造体
function XHomeRoomObj:RemoveCharacter(dormtoryId, characterId)
    if dormtoryId ~= self.Data.Id then
        return
    end

    if not self.IsSelected then
        return
    end

    local charObj = nil
    local index = -1
    for k, v in ipairs(self.CharacterList) do

        if v.Id == characterId then
            charObj = v
            index = k
            break
        end
    end

    if not charObj then
        return
    end

    for _, furniture in pairs(self.GroundFurnitureList) do
        furniture:RippleRemoveChar(charObj.Transform)
    end

    charObj:ExitRoom()
    table.remove(self.CharacterList, index)
end

function XHomeRoomObj:Reform(isBegin)
    for _, furniture in pairs(self.GroundFurnitureList) do
        if isBegin then
            furniture:RippleClearChar()
        else
            for _, char in ipairs(self.CharacterList) do
                furniture:RippleAddChar(char.Transform)
            end
        end
    end
end

function XHomeRoomObj:ClearFurnitureAnimation()
    for _, furniture in pairs(self.GroundFurnitureList) do
        furniture:DoReleaseAllEffects()
    end
end

-- 点击房间
function XHomeRoomObj:OnClick()
    if not self.Data:WhetherRoomUnlock() then
        --未解锁，先激活
        local cfg = XDormConfig.GetDormitoryCfgById(self.Data.Id)
        local name = XDataCenter.ItemManager.GetItemName(cfg.ConsumeItemId)
        local title = CS.XTextManager.GetText("TipTitle")
        local count = cfg.ConsumeItemCount
        local des = CS.XTextManager.GetText("DormActiveTips", count, name)
        XUiManager.DialogTip(title, des, XUiManager.DialogType.Normal, nil, function() XDataCenter.DormManager.RequestDormitoryActive(self.Data.Id) end)
        return
    end

    -- 已激活，进入房间
    if XLuaUiManager.IsUiShow("UiDormSecond") then
        return
    end
    XLuaUiManager.Open("UiDormSecond", DisplaySetType.MySelf, self.Data.Id)
    XHomeDormManager.SetSelectedRoom(self.Data.Id, true)
end

-- 设置可行走区域列表
function XHomeRoomObj:SetCanReachList()
    if not self.RoomMap then
        return
    end

    self.CanReachList = {}
    for x = 0, CS.XHomeMapManager.Inst.MapSize.x - 1 do
        for y = 0, CS.XHomeMapManager.Inst.MapSize.y - 1 do
            local gridInfo = self.RoomMap:GetGridInfo(x, y)
            local gridMask = CS.XRoomMapInfo.GetMapGridMask(gridInfo, CS.XRoomBlockType.Furniture)
            if gridMask <= 0 then
                local info = { x = x, y = y }
                table.insert(self.CanReachList, info)
            end
        end
    end

    if #self.CanReachList <= 0 then
        XLog.Error("XHomeRoomObj SetCanReachList Error, Can reach patch is zero!")
    end
end

-- 获取可行走区域列表
function XHomeRoomObj:GetCanReachList()
    return self.CanReachList
end

-- 生成地图信息及家具交互点信息
function XHomeRoomObj:GenerateRoomMap()
    if not self.Ground then
        return
    end

    --房间动态地图信息
    self.RoomMap = CS.XRoomMapInfo.GenerateMap(self.Ground.Data.CfgId)
    --先将HomeDormManager节点转到对应房间里再计算网格点里的数据，不然会有误差
    XHomeDormManager.AttachSurfaceToRoom(self.Data.Id)

    if self.GroundFurnitureList then
        for _, furniture in pairs(self.GroundFurnitureList) do
            if furniture.Cfg then
                local x, y, rotate = furniture:GetData()
                -- 家具
                self.RoomMap:SetFurnitureInfo(x, y, furniture.Cfg.Width, furniture.Cfg.Height, rotate)
            end
        end
    end
    self:SetCanReachList()

    --有效交互点列表
    self.InteractList = {}
    if self.GroundFurnitureList then
        for _, furniture in pairs(self.GroundFurnitureList) do
            if furniture.Cfg then
                local list = furniture:GenerateInteractInfo(self.RoomMap)
                for _, info in ipairs(list) do
                    if (info.UsedType & XFurnitureInteractUsedType.Block) <= 0 then
                        local interactInfo = {}
                        interactInfo.GridPos = info.GridPos
                        interactInfo.StayPosGo = info.StayPos
                        interactInfo.InteractPosGo = info.InteractPos
                        interactInfo.Furniture = furniture
                        table.insert(self.InteractList, interactInfo)
                    end

                    -- 交互点
                    if info.GridPos then
                        --从格子坐标转换回以前配置表的坐标，为了兼容以前的写法，避免去改C#
                        local x, y, rotate = furniture:GetData()
                        local configX = info.GridPos.x - x
                        local configY = info.GridPos.y - y
                        self.RoomMap:SetFurnitureInteractionInfo(x, y, furniture.Cfg.Width, furniture.Cfg.Height, configX, configY, rotate)
                    end
                end
            end
        end
    end

    --等上面处理完后重新隐藏
    XHomeDormManager.AttachSurfaceToRoom()
end

-- 检测家具阻挡
function XHomeRoomObj:CheckFurnitureBlock(furnitureId, x, y, width, height, type, rotate)
    local isBlock = false

    for _, furniture in pairs(self.GroundFurnitureList) do
        if furnitureId ~= furniture.Data.Id and furniture:CheckCanLocate() and
        furniture:CheckFurnitureCollision(x, y, width, height, type, rotate) then
            isBlock = true
            break
        end
    end

    if not isBlock then
        for _, v in pairs(self.WallFurnitureList) do
            for _, furniture in pairs(v) do
                if furnitureId ~= furniture.Data.Id and furniture:CheckCanLocate() and
                furniture:CheckFurnitureCollision(x, y, width, height, type, rotate) then
                    isBlock = true
                    break
                end
            end

            if isBlock then
                break
            end
        end
    end

    local blockCfgId = 0
    if type == CS.XHomePlatType.Ground and self.Ground then
        blockCfgId = self.Ground.Data.CfgId
    elseif type == CS.XHomePlatType.Wall and self.Wall then
        blockCfgId = self.Wall.Data.CfgId
    end

    local block, pos = XHomeDormManager.CheckMultiBlock(blockCfgId, x, y, width, height, type, rotate)
    if not isBlock then
        isBlock = block
    end

    return isBlock, pos
end

-- 移除所有墙饰的dither
function XHomeRoomObj:RemoveWallDither()
    if self.Wall and self.WallDithers then
        for rotate, v in pairs(self.WallFurnitureList) do
            local wallDitherIndex = tostring(rotate)
            for _, furniture in pairs(v) do
                if self.WallDithers[wallDitherIndex] then
                    self.WallDithers[wallDitherIndex]:RemoveRenderer(furniture.GameObject)
                    self.WallDithers[wallDitherIndex]:RemoveStateChangeListener(furniture.GameObject)
                end
            end
        end
    end
end

-- 更新dither
function XHomeRoomObj:UpdateWallDither(lastWall, curWall)
    self:RemoveLastWallEffectDither(lastWall)
    if curWall then
        for i = 1, WallNum do
            local ditherKey = tostring(i - 1)
            self.WallDithers[ditherKey] = curWall.Transform:Find(ditherKey):GetComponent(typeof(CS.XRoomWallDither))
            local wallEffects = curWall:GetWallEffectsByRot(ditherKey)
            if wallEffects then
                for j = 1, #wallEffects do
                    local wallEffectObj = wallEffects[j].gameObject
                    if not XTool.UObjIsNil(wallEffectObj) then
                        self.WallDithers[ditherKey]:AddStateChangeListener(wallEffectObj, function(state)
                            self:OnWallEffectDitherChange(state, wallEffectObj)
                        end)
                    end
                end
            end

        end
    end
end

function XHomeRoomObj:RemoveLastWallEffectDither(wall)
    if not wall then return end
    for i = 1, WallNum do
        local ditherKey = tostring(i - 1)

        if self.WallDithers[ditherKey] then
            local wallEffects = wall:GetWallEffectsByRot(ditherKey)
            if wallEffects then
                for j = 1, #wallEffects do
                    local wallEffectObj = wallEffects[j].gameObject
                    if not XTool.UObjIsNil(wallEffectObj) then
                        self.WallDithers[ditherKey]:RemoveStateChangeListener(wallEffectObj)
                    end
                end
            end
        end
    end
end

-- 墙特效
function XHomeRoomObj:OnWallEffectDitherChange(state, effectObj)
    if state == "Enter" then
        effectObj:SetActiveEx(true)
    else
        effectObj:SetActiveEx(false)
    end
end

-- 给所有墙饰添加render,换墙操作
function XHomeRoomObj:UpdateWallListRender()
    if self.WallFurnitureList then
        for rotate, v in pairs(self.WallFurnitureList) do
            local wallDitherIndex = tostring(rotate)
            for _, furniture in pairs(v) do
                if self.WallDithers[wallDitherIndex] then
                    self.WallDithers[wallDitherIndex]:AddStateChangeListener(furniture.GameObject, handler(furniture, furniture.OnStateChange))
                    self.WallDithers[wallDitherIndex]:AddRenderer(furniture.GameObject)
                end
            end
        end
    end
end

-- 家具碰撞检测
function XHomeRoomObj:CheckFurnituresCollider(checkFurniture)
    if not checkFurniture then
        return false
    end

    for _, collider in pairs(checkFurniture.Colliders) do
        if not XTool.UObjIsNil(collider) then
            for _, furniture in pairs(self.GroundFurnitureList or {}) do
                if furniture ~= checkFurniture then
                    for _, furnitureCollider in pairs(furniture.Colliders or {}) do
                        if collider ~= furnitureCollider and collider.bounds:Intersects(furnitureCollider.bounds) then
                            return true
                        end
                    end
                end
            end

            for _, furnitureList in pairs(self.WallFurnitureList or {}) do
                for _, furniture in pairs(furnitureList) do
                    if furniture ~= checkFurniture then
                        for _, furnitureCollider in pairs(furniture.Colliders or {}) do
                            if collider ~= furnitureCollider and collider.bounds:Intersects(furnitureCollider.bounds) then
                                return true
                            end
                        end
                    end
                end
            end

            if self.Ceiling then
                if checkFurniture ~= self.Ceiling then
                    for _, furnitureCollider in pairs(self.Ceiling.Colliders or {}) do
                        if collider ~= furnitureCollider and collider.bounds:Intersects(furnitureCollider.bounds) then
                            return true
                        end
                    end
                end
            end
        end
    end

    return false
end

function XHomeRoomObj:CheckColliderIntersectByBounds(colliderSrc, colliderDsc)
    local boundSrc = Bounds(colliderSrc.center + colliderSrc.transform.position, colliderSrc.size)
    local boundDsc = Bounds(colliderDsc.center + colliderDsc.transform.position, colliderDsc.size)
    return boundSrc:Intersects(boundDsc)
end

--- 批量替换家具
---@param homeRoomData XHomeRoomData
--------------------------
function XHomeRoomObj:ReplaceFurniture(homeRoomData)
    if not homeRoomData or self.CurLoadType ~= XDormConfig.DormDataType.Self then
        return
    end
    self:CleanRoom()
    self.UnOwnFurniture = {}
    self.TemplateFurnitureMap = {}
    
    local furnitureDict = homeRoomData:GetFurnitureDic()
    local roomFurniture = self.Data:GetFurnitureConfigDic()
    local bagFurniture = XDataCenter.FurnitureManager.GetUnUseFurniture()
    
    local map = {}
    local readMap = {}
    local exist = false
    local loadCb = function(furniture)
        if not furniture then
            return
        end
        furniture:RayCastNotOwn(not exist)
        self:SingleFurnitureLoadComplete(furniture)
        if not exist then
            table.insert(self.UnOwnFurniture, furniture)
        end
    end
    XHomeSceneManager.SafeOpenBlack(self.Transform, true, "Room")
    for _, data in pairs(furnitureDict) do
        local template = XFurnitureConfigs.GetFurnitureTemplateById(data.ConfigId)
        if not template then
            goto continue
        end
        local configId = data.ConfigId
        if not map[configId] then
            local list = {}
            list = appendArray(list, roomFurniture[configId] or {})
            list = appendArray(list, bagFurniture[configId] or {})

            map[configId] = list
        end
        local list = map[configId]
        local readIndex = readMap[configId] or 1
        
        local furnitureData
        if list[readIndex] then
            furnitureData = XDataCenter.FurnitureManager.GetFurnitureById(list[readIndex], self.CurLoadType)
            readIndex = readIndex + 1
            readMap[configId] = readIndex
            exist = true
        else
            furnitureData = {
                Id = data.Id,
                ConfigId = configId
            }
            exist = false
        end
        self.TemplateFurnitureMap[data.Id] = furnitureData.Id
        XHomeDormManager.CreateFurniture(self.Data.Id, furnitureData, {x = data.GridX, y = data.GridY }, data.RotateAngle, false, loadCb)
        ::continue::
    end
    
    self.IsFurnitureLoadComplete = true
    if self.IsSelected then
        self:GenerateRoomMap()
        self:UpdateWallListRender()
        self:SetIllumination()
    end
end

-- 剔除未拥有家具
function XHomeRoomObj:RejectUnOwn()
    if XTool.IsTableEmpty(self.UnOwnFurniture) then
        return
    end
    local replaceHandler = handler(self, self.ReplaceSurface)
    for _, tempFurniture in ipairs(self.UnOwnFurniture) do
        local furnitureType = tempFurniture.PlaceType
        if furnitureType == XFurniturePlaceType.Wall then
            local furniture = self.Data:GetWallFurniture()
            local furnitureData = XDataCenter.FurnitureManager.GetFurnitureById(furniture.Id, self.CurLoadType)
            XHomeDormManager.CreateFurniture(self.Data.Id, furnitureData, {x = furniture.GridX, y = furniture.GridY },
                    furniture.RotateAngle, false, replaceHandler)
        elseif furnitureType == XFurniturePlaceType.Ceiling then
            local furniture = self.Data:GetCeillingFurniture()
            local furnitureData = XDataCenter.FurnitureManager.GetFurnitureById(furniture.Id, self.CurLoadType)
            XHomeDormManager.CreateFurniture(self.Data.Id, furnitureData, {x = furniture.GridX, y = furniture.GridY },
                    furniture.RotateAngle, false, replaceHandler)
        elseif furnitureType == XFurniturePlaceType.Ground then
            local furniture = self.Data:GetGroundFurniture()
            local furnitureData = XDataCenter.FurnitureManager.GetFurnitureById(furniture.Id, self.CurLoadType)
            XHomeDormManager.CreateFurniture(self.Data.Id, furnitureData, {x = furniture.GridX, y = furniture.GridY },
                    furniture.RotateAngle, false, replaceHandler)
        elseif furnitureType == XFurniturePlaceType.OnWall then
            tempFurniture:Storage()
            if self.WallFurnitureList[tostring(tempFurniture.Data.RotateAngle)] then
                self.WallFurnitureList[tostring(tempFurniture.Data.RotateAngle)][tempFurniture.Data.Id] = nil
            end
        else
            tempFurniture:Storage()
            self.GroundFurnitureList[tempFurniture.Data.Id] = nil
        end
    end

    self.IsFurnitureLoadComplete = true
    self.UnOwnFurniture = nil
    if self.IsSelected then
        self:GenerateRoomMap()
        self:UpdateWallListRender()
        self:SetIllumination()
    end
end

function XHomeRoomObj:GetIdByTemplateFurnitureId(templateFurnitureId)
    return self.TemplateFurnitureMap[templateFurnitureId]
end

return XHomeRoomObj