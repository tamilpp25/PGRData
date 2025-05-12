-- 肉鸽模拟经营地图
---@class XRogueSimScene : XControl
---@field private _MainControl XRogueSimControl
---@field private GridDic XRogueSimGrid[]
local XRogueSimScene = XClass(XControl, "XRogueSimScene")
local CSVector3 = CS.UnityEngine.Vector3

-- 初始化参数
function XRogueSimScene:OnInit()
    -- 场景里六边形格子的大小
    self.GRID_SIZE = 0.5
    -- 地图区域解锁的 移动/镜头拉远 时间
    self.AREA_OVERLOOK_TIME = 0.5
    -- 队列间隔时间
    self.SEQUENCE_INTERVAL_TIME = 0.2
    -- 格子周围的6个格子
    self.AROUND_GRIDS_OFFSET0 = { { x = -1, y = 1 }, { x = -1, y = 0 }, { x = 0, y = -1 }, { x = 0, y = 1 }, { x = 1, y = 1 }, { x = 1, y = 0 } }
    self.AROUND_GRIDS_OFFSET1 = { { x = -1, y = -1 }, { x = -1, y = 0 }, { x = 0, y = -1 }, { x = 0, y = 1 }, { x = 1, y = -1 }, { x = 1, y = 0 } }
    -- 地图压黑的的程度 0为最黑 1为原亮度
    self.MAP_DARKEN_VALUE = 0.7
    -- 地图压黑变亮的时间(单位：秒)
    self.MAP_DARK_TO_LIGHT_TIME = 0.5
    -- 地图云雾动画的时间(单位：秒)
    self.MAP_CLOUND_ANIM_TIME = 0.5
    -- 摄像机切换时间
    self.CAMERA_SWITCH_TIME = 0.5
    -- 地形高度
    self.TERRAIN_HEIGHT = 0.25
    -- 点击地块音效Id
    self.CLICK_CUE_ID = 5091
    -- 地形更新音效
    self.TERRAIN_CHANGE_CUE_ID = 5093
    -- 建筑建造音效
    self.BUILD_SUCCESS_CUE_ID = 5089
    -- 区域购买音效
    self.AREA_BUY_CUE_ID = 5090
    
    self.AreaDic = {}            -- 区域Id:区域对象
    self.GridDic = {}            -- 格子Id:格子对象
    self.ChildsDic = {}          -- 格子Id:子格子Id列表
    self.GridPosDic = {}         -- 位置key:格子Id
    self.AroundGridsCache = {}   -- 缓存周围格子偏移
    self.MainGridId = 0          -- 主城格子Id
    self.CityGridIds = {}        -- 城邦格子Id列表
    self.AreaLandmarkGridIdDic = {} -- 区域地标格子Id
    self.GridSelectEffects1 = {} -- 格子选中特效列表(格子未连通)
    self.GridSelectEffects2 = {} -- 格子选中特效列表(格子已连通)
    self.CloudEffects1 = {}      -- 云雾特效(格子探索将会解锁)
    self.SightRange = self._MainControl.ResourceSubControl:GetResourceOwnCount(XEnumConst.RogueSim.ResourceId.SightRange)
    local mapData = self._MainControl.MapSubControl:GetMapData()
    self.AreaIdCanUnlockDic = mapData:GetAreaIdCanUnlockDic()
    self.AreaIdUnlockDic = mapData:GetAreaIdUnlockDic()
    self.LastClickTime = 0

    self.CameraMoveSpeed = tonumber(self._MainControl:GetClientConfig("CameraMoveSpeed"))
    self.CameraMoveMaxTime = tonumber(self._MainControl:GetClientConfig("CameraMoveMaxTime"))
    self.CameraMoveSpeedOverlook = tonumber(self._MainControl:GetClientConfig("CameraMoveSpeedOverlook"))
    self.CameraMoveMaxTimeOverlook = tonumber(self._MainControl:GetClientConfig("CameraMoveMaxTimeOverlook"))
    self.CameraFocusGridOffsetX = tonumber(self._MainControl:GetClientConfig("CameraFocusGridOffsetXWan")) / 10000

    -- 引导支持，C#事件调用
    self.OnCSEventFocusGrid = function(evt, param)
        local gridId = tonumber(param[0])
        self:CameraFocusGrid(gridId)
    end
    self.OnCSEventClickGrid = function(evt, param)
        local gridId = tonumber(param[0])
        local grid = self:GetGrid(gridId)
        self:OnGridClick(grid)
    end
end

-- 场景、格子等全部加载完成时调用
function XRogueSimScene:OnLoadComplete()
    self:StartUpdateTimer()
    self:InitPanelDrag()
    self:InitCameraPos()
    self:InitOldRewardGridIds()
    if self.LoadCompleteCb then
        self.LoadCompleteCb()
    end
end

-- 注册事件
function XRogueSimScene:AddAgencyEvent()
    XEventManager.AddEventListener(XEventId.EVENT_ROGUE_SIM_EXPLORE_GRID, self.OnExploreGrid, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUE_SIM_VISIBLE_GRID, self.OnVisibleGrid, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUE_SIM_CHANGE_GRID, self.OnChangeGrid, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUE_SIM_RESOURCE_CHANGE, self.OnResourceChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUE_SIM_MAIN_LEVEL_UP, self.OnMainLevelUp, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUE_SIM_CITY_CHANGE, self.OnCityLevelUp, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUE_SIM_BUILDING_ADD, self.OnBuildingAdd, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUE_SIM_EVENT_ADD, self.OnEventAdd, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUE_SIM_EVENT_REMOVE, self.OnEventRemove, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUE_SIM_REWARDS_CHANGE, self.OnRewardsChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUE_SIM_TASK_CHANGE, self.OnTaskChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUE_SIM_ADD_DATA_CHANGE, self.OnAddDataChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUE_SIM_TURN_NUMBER_CHANGE, self.OnTurnNumberChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUE_SIM_EVENT_GAMBLE_REMOVE, self.OnEventGambleRemove, self)
    CsXGameEventManager.Instance:RegisterEvent(XEventId.EVENT_ROGUE_SIM_FOCUS_GRID, self.OnCSEventFocusGrid)
    CsXGameEventManager.Instance:RegisterEvent(XEventId.EVENT_ROGUE_SIM_CLICK_GRID, self.OnCSEventClickGrid)
end

-- 释放事件
function XRogueSimScene:RemoveAgencyEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUE_SIM_EXPLORE_GRID, self.OnExploreGrid, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUE_SIM_VISIBLE_GRID, self.OnVisibleGrid, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUE_SIM_CHANGE_GRID, self.OnChangeGrid, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUE_SIM_RESOURCE_CHANGE, self.OnResourceChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUE_SIM_MAIN_LEVEL_UP, self.OnMainLevelUp, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUE_SIM_CITY_CHANGE, self.OnCityLevelUp, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUE_SIM_BUILDING_ADD, self.OnBuildingAdd, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUE_SIM_EVENT_ADD, self.OnEventAdd, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUE_SIM_EVENT_REMOVE, self.OnEventRemove, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUE_SIM_REWARDS_CHANGE, self.OnRewardsChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUE_SIM_TASK_CHANGE, self.OnTaskChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUE_SIM_ADD_DATA_CHANGE, self.OnAddDataChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUE_SIM_TURN_NUMBER_CHANGE, self.OnTurnNumberChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUE_SIM_EVENT_GAMBLE_REMOVE, self.OnEventGambleRemove, self)
    CsXGameEventManager.Instance:RemoveEvent(XEventId.EVENT_ROGUE_SIM_FOCUS_GRID, self.OnCSEventFocusGrid)
    CsXGameEventManager.Instance:RemoveEvent(XEventId.EVENT_ROGUE_SIM_CLICK_GRID, self.OnCSEventClickGrid)
end

-- 点击格子
---@param grid XRogueSimGrid 格子对象
---@param isFocusAfterSelect boolean 聚焦后打开格子弹窗
function XRogueSimScene:OnGridClick(grid, isFocusAfterSelect)
    -- 点击空白
    if not grid then
        return
    end
    
    if XEnumConst.RogueSim.IsDebug then
        XLog.Warning("<color=#F1D116>RogueSim:</color> 点击格子Id: " .. tostring(grid.Id))
    end

    -- 防止频繁点击
    local now = CS.UnityEngine.Time.realtimeSinceStartup
    if now - self.LastClickTime < 0.1 then
        if XEnumConst.RogueSim.IsDebug then
            XLog.Warning("<color=#F1D116>RogueSim:</color>频繁点击不作响应" )
        end
        return
    end
    self.LastClickTime = CS.UnityEngine.Time.realtimeSinceStartup

    -- 不可点击
    local parentId = grid:GetParentId()
    local parentGrid = self.GridDic[parentId]
    local canClick, tips = parentGrid:IsCanClick()
    if not canClick then
        if not string.IsNilOrEmpty(tips) then
            XUiManager.TipMsg(tips, nil, nil, true)
        end
        return
    end

    -- 聚焦格子
    if isFocusAfterSelect then
        self:CameraFocusGrid(parentId, function()
            self:OnFocusGridCallback(parentId, parentGrid)
        end)
    else
        self:CameraFocusGrid(parentId)
        self:OnFocusGridCallback(parentId, parentGrid)
    end
end

-- 聚焦格子回调
---@param parentId number 父格子Id
---@param parentGrid XRogueSimGrid 格子对象
function XRogueSimScene:OnFocusGridCallback(parentId, parentGrid)
    -- 选中特效
    self:ShowGridSelectEffect(parentId)

    -- 打开格子弹窗
    ---@type XUiRogueSimBattle
    local luaUi = XLuaUiManager.GetTopLuaUi("UiRogueSimBattle")
    if luaUi then
        luaUi:OnGridClick(parentGrid)
    end
end

-- 服务器增量下推已探索格子
function XRogueSimScene:OnExploreGrid(gridIds)
    if self:CheckHasExploreCache() then
        local cacheGridDic = {}
        for _, gId in pairs(self.CacheExploredGridIds) do
            cacheGridDic[gId] = true
        end
        for _, gId in pairs(gridIds) do
            if not cacheGridDic[gId] then
                cacheGridDic[gId] = true
                table.insert(self.CacheExploredGridIds, gId)
            end
        end
    else
        -- 缓存起来，在PlayCacheExploreGrids播放表现
        self.CacheExploredGridIds = gridIds or {}
    end
end

-- 检查是否有探索缓存未处理
function XRogueSimScene:CheckHasExploreCache(gridId)
    if not self.CacheExploredGridIds or #self.CacheExploredGridIds == 0 then
        return false
    end

    -- 指定格子Id
    if gridId then
        for _, id in ipairs(self.CacheExploredGridIds) do
            if id == gridId then
                return true
            end
        end
        return false
    end

    return true
end

-- 播放格子已探索
function XRogueSimScene:PlayCacheExploreGrids(cb)
    local gridIds = self.CacheExploredGridIds
    self.CacheExploredGridIds = nil
    self:SetGridsExplored(gridIds)
    if cb then cb() end
    -- 播放下一个表现
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_LOCAL_GRID_DATA_CHANGE)
    self._MainControl:CheckNeedShowNextPopup()
end

-- 获取摄像机移动聚焦格子的目标位、移动时间
function XRogueSimScene:GetCameraFocusGridPosAndTime(gridId, curPos)
    curPos = curPos or self.CameraFollowPoint.localPosition     -- 当前位置
    local aimPos = self:GetCameraFocusGridLocalPosition(gridId) -- 目标位置
    local distance = CSVector3.Distance(curPos, aimPos)
    local time = math.min(distance / self.CameraMoveSpeed, self.CameraMoveMaxTime)
    return aimPos, time
end

-- 服务器增量下推可见的格子
function XRogueSimScene:OnVisibleGrid(data)
    -- 先缓存，在PlayCacheVisibleGrids播放表现
    self.VisibleCache = self.VisibleCache or {}
    if data.AddType == XEnumConst.RogueSim.AddVisibleGridIdType.ByParent then
        for _, gridId in ipairs(data.GridIds) do
            table.insert(self.VisibleCache, { AddType = data.AddType, GridIds = { gridId } })
        end
    else
        table.insert(self.VisibleCache, data)
    end
end

-- 检查是否有可见缓存未处理
function XRogueSimScene:CheckHasVisibleCache()
    return not XTool.IsTableEmpty(self.VisibleCache)
end

-- 获取可见格子的数量
function XRogueSimScene:GetVisibleGridCount()
    return #self.VisibleCache
end

-- 获取可见视野的类型
function XRogueSimScene:GetVisibleCacheType()
    if self.VisibleCache and #self.VisibleCache > 0 then
        return self.VisibleCache[1].AddType
    end
    return
end

-- 播放格子可见
function XRogueSimScene:PlayCacheVisibleGrids(cb)
    if not self.VisibleCache then
        if cb then cb() end
        -- 播放下一个表现
        self._MainControl:CheckNeedShowNextPopup()
        return
    end

    -- 道具解锁格子列表视野
    local addType = self.VisibleCache[1].AddType
    if addType == XEnumConst.RogueSim.AddVisibleGridIdType.ByArea then
        for _, data in ipairs(self.VisibleCache) do
            self:SetGridsVisibled(data.GridIds)
        end
        self.VisibleCache = nil
        -- 播放下一个表现
        self._MainControl:CheckNeedShowNextPopup()

        -- 灯塔解锁点位
    elseif addType == XEnumConst.RogueSim.AddVisibleGridIdType.ByParent then
        local CsTween = CS.DG.Tweening
        self:ClearCameraSequence()
        self.CameraSequence = CsTween.DOTween.Sequence()

        local originPos = self.CameraFollowPoint.localPosition
        local curPos = self.CameraFollowPoint.localPosition

        -- 点位逐个解锁
        for _, data in ipairs(self.VisibleCache) do
            local aimPos, time = self:GetCameraFocusGridPosAndTime(data.GridIds[1], curPos)
            self.CameraSequence:Append(self.CameraFollowPoint:DOLocalMove(aimPos, time):SetEase(CsTween.Ease.OutQuad):OnComplete(function()
                self:SetGridsVisibled(data.GridIds)
            end))
            self.CameraSequence:AppendInterval(self.MAP_CLOUND_ANIM_TIME + self.SEQUENCE_INTERVAL_TIME)
            curPos = aimPos
        end

        -- 镜头回到最初位置
        local originDistance = CSVector3.Distance(curPos, originPos)
        local backTime = math.min(originDistance / self.CameraMoveSpeed, self.CameraMoveMaxTime)
        self.CameraSequence:Append(self.CameraFollowPoint:DOLocalMove(originPos, backTime):SetEase(CsTween.Ease.OutQuad))
        self.CameraSequence.onComplete = function()
            XLuaUiManager.SetMask(false)
            if cb then cb() end
            -- 播放下一个表现
            self._MainControl:CheckNeedShowNextPopup()
        end

        XLuaUiManager.SetMask(true)
        self.CameraSequence:Play()
        self.VisibleCache = nil
    end
end

-- 服务器增量下推有变化的格子
function XRogueSimScene:OnChangeGrid(gridDatas)
    if not self.CacheChangeGridDatas or #self.CacheChangeGridDatas == 0 then
        self.CacheChangeGridDatas = gridDatas
    else
        for _, gridData in ipairs(gridDatas) do
            table.insert(self.CacheChangeGridDatas, gridData)
        end
    end
end

-- 检查是否有变化格子缓存
function XRogueSimScene:CheckCacheChangeGrid()
    if self.CacheChangeGridDatas and #self.CacheChangeGridDatas > 0 then
        return true
    end
    return false
end

-- 播放缓存变化格子
function XRogueSimScene:PlayCacheChangeGrid()
    for _, gridData in ipairs(self.CacheChangeGridDatas) do
        local grid = self:GetGrid(gridData.Id)
        grid:OnGridChange(gridData)
    end
    self.CacheChangeGridDatas = nil
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_LOCAL_GRID_DATA_CHANGE)
    -- 播放下一个表现
    self._MainControl:CheckNeedShowNextPopup()
end

-- 检查是否有区域变成可解锁
function XRogueSimScene:CheckHasAreaCanUnlock()
    local mapData = self._MainControl.MapSubControl:GetMapData()
    local areaIdCanUnlockDic = mapData:GetAreaIdCanUnlockDic()
    for areaId, canUnlock in pairs(areaIdCanUnlockDic) do
        if not self.AreaIdCanUnlockDic[areaId] and canUnlock then
            return true
        end
    end
    return false
end

-- 检查是否有区域变成解锁
function XRogueSimScene:CheckHasAreaUnlock()
    local mapData = self._MainControl.MapSubControl:GetMapData()
    local areaIdUnlockDic = mapData:GetAreaIdUnlockDic()
    for areaId, isUnlock in pairs(areaIdUnlockDic) do
        if not self.AreaIdUnlockDic[areaId] and isUnlock then
            return true
        end
    end
    return false
end

-- 播放区域可解锁
function XRogueSimScene:PlayAreaCanUnlock()
    -- 筛选新的可解锁的区域Id
    local areaIds = {}
    local mapData = self._MainControl.MapSubControl:GetMapData()
    local areaIdCanUnlockDic = mapData:GetAreaIdCanUnlockDic()
    for areaId, isCanUnlock in pairs(areaIdCanUnlockDic) do
        if not self.AreaIdCanUnlockDic[areaId] and isCanUnlock then
            table.insert(areaIds, areaId)
        end
    end

    if #areaIds == 0 then
        return
    end
    self.AreaIdCanUnlockDic = areaIdCanUnlockDic
    self:PlayAreasAnim(areaIds, self.OnAreaCanUnlock)
end

-- 播放区域解锁
function XRogueSimScene:PlayAreaUnlock()
    -- 筛选新解锁的区域Id
    local areaIds = {}
    local mapData = self._MainControl.MapSubControl:GetMapData()
    local areaIdUnlockDic = mapData:GetAreaIdUnlockDic()
    for areaId, isUnlock in pairs(areaIdUnlockDic) do
        if not self.AreaIdUnlockDic[areaId] and isUnlock then
            table.insert(areaIds, areaId)
        end
    end

    if #areaIds == 0 then
        return
    end
    self.AreaIdUnlockDic = areaIdUnlockDic
    self:PlayAreasAnim(areaIds, self.OnAreaUnlock)
end

-- 播放多区域动画
function XRogueSimScene:PlayAreasAnim(areaIds, areaFunc)
    XLuaUiManager.SetMask(true)
    self.IsPlayAreaAnim = true
    local CsTween = CS.DG.Tweening
    self:ClearCameraSequence()
    self.CameraSequence = CsTween.DOTween.Sequence()

    -- 初始化位置
    self.CameraFollowPointOverlook.localPosition = self.CameraFollowPoint.localPosition
    self.CamFarOverlook.localPosition = self.UiFarCamera.transform.localPosition
    self.CamNearOverlook.localPosition = self.UiNearCamera.transform.localPosition
    self.CamUiOverlook.localPosition = self.UiCamera.transform.localPosition

    -- 激活相机镜头拉远
    self.CamFarOverlook.gameObject:SetActiveEx(true)
    self.CamNearOverlook.gameObject:SetActiveEx(true)
    self.CamUiOverlook.gameObject:SetActiveEx(true)
    self.CameraSequence:AppendInterval(self.AREA_OVERLOOK_TIME + self.SEQUENCE_INTERVAL_TIME)

    -- 镜头移动
    local originPos = self.CameraFollowPointOverlook.localPosition
    for _, areaId in ipairs(areaIds) do
        local aimPos = self:GetAreaFocusLocalPosition(areaId)
        local distance = CSVector3.Distance(originPos, aimPos)
        local time = math.min(distance / self.CameraMoveSpeedOverlook, self.CameraMoveMaxTimeOverlook)
        local tempAreaId = areaId
        self.CameraSequence:Append(self.CameraFollowPointOverlook:DOLocalMove(aimPos, time):SetEase(CsTween.Ease.OutQuad):OnComplete(function()
            areaFunc(self, tempAreaId)
        end))
        -- 区域云雾解锁+云雾移除
        self.CameraSequence:AppendInterval(self.MAP_CLOUND_ANIM_TIME + self.MAP_CLOUND_ANIM_TIME + self.SEQUENCE_INTERVAL_TIME)
        originPos = aimPos
    end

    -- 回到最初位置
    self.CameraSequence:AppendCallback(function()
        self.CamFarOverlook.gameObject:SetActiveEx(false)
        self.CamNearOverlook.gameObject:SetActiveEx(false)
        self.CamUiOverlook.gameObject:SetActiveEx(false)
    end)
    self.CameraSequence:AppendInterval(self.CAMERA_SWITCH_TIME)
    
    -- 结束回调
    self.CameraSequence.onComplete = function()
        self.IsPlayAreaAnim = false
        XLuaUiManager.SetMask(false)
        -- 播放下一个表现
        self._MainControl:CheckNeedShowNextPopup()
    end
end

-- 获取聚焦区域的位置
function XRogueSimScene:GetAreaFocusLocalPosition(areaId)
    local gridId = self._MainControl.MapSubControl:GetRogueSimAreaFocusGridId(areaId)
    if gridId == 0 then
        XLog.Error(string.format("请策划老师检查！RogueSimArea.tab表的区域%s未配置FocusGridId！", areaId))
    end
    return self:GetCameraFocusGridLocalPosition(gridId)
end

function XRogueSimScene:ClearCameraSequence()
    if self.CameraSequence then
        self.CameraSequence:Kill()
        self.CameraSequence = nil
    end
end

-- 资源变化
function XRogueSimScene:OnResourceChange()
    -- 刷新主城可升级按钮
    self.GridDic[self.MainGridId]:RefreshMainLevelUp()
    -- 刷新城邦可升级按钮
    for _, cityGridId in ipairs(self.CityGridIds) do
        self.GridDic[cityGridId]:RefreshCityLevelUp()
    end
end

-- 主城升级
function XRogueSimScene:OnMainLevelUp()
    self.GridDic[self.MainGridId]:OnMainLevelUp()
end

-- 城邦升级
function XRogueSimScene:OnCityLevelUp(gridId)
    if XTool.IsNumberValid(gridId) then
        self.GridDic[gridId]:OnCityLevelUp()
    else
        for _, cityGridId in ipairs(self.CityGridIds) do
            self.GridDic[cityGridId]:OnCityLevelUp()
        end
    end
end

-- 缓存升级格子Id
function XRogueSimScene:CacheLevelUpGridId(gridId)
    self.LevelUpGridId = gridId
end

-- 检测格子是否升级
function XRogueSimScene:CheckHasGridLevelUp()
    return self.LevelUpGridId ~= nil
end

-- 播放格子升级特效
function XRogueSimScene:PlaGridLevelUp()
    local grid = self:GetGrid(self.LevelUpGridId)
    grid.Grid3D:LoadLevelUpEffect()
    self.LevelUpGridId = nil
    self._MainControl:CheckNeedShowNextPopup()
end

-- 播放格子建造成功特效
function XRogueSimScene:PlayBuildSuccessEffect(gridId)
    local grid = self:GetGrid(gridId)
    grid.Grid3D:LoadBuildSuccessEffect()
end

-- 点击主城格子
function XRogueSimScene:OnMainGridClick()
    self.GridDic[self.MainGridId]:OnGridClick()
end

-- 解锁区域
function XRogueSimScene:OnAreaCanUnlock(areaId)
    -- 刷新区域
    local area = self:GetArea(areaId)
    area:SetAreaCanUnlock()
    
    -- 刷新格子
    local areaGridsCfg = self._MainControl.MapSubControl:GetRogueSimAreaGridConfigs(areaId)
    local unlockRenders = {}
    local removeCloudRenders = {}
    local darkRenders = {}
    for _, gridCfg in pairs(areaGridsCfg) do
        local grid = self.GridDic[gridCfg.Id]
        grid:SetAreaCanUnlock()

        -- 部分格子可见，直接移除云和压黑
        if grid:GetCanBeSeen() then
            local render = grid:RemoveCloud()
            table.insert(removeCloudRenders, render)
            local terrainRenderer, landformRenderer = grid:RemoveDarken(true)
            table.insert(darkRenders, terrainRenderer)
            table.insert(darkRenders, landformRenderer)
            -- 云变成解锁材质
        else
            local render = grid:UnlockCloud(true)
            if render then
                table.insert(unlockRenders, render)
            end
        end
    end

    -- 移除可见格子的云
    if #removeCloudRenders > 0 then
        self.RogueSimHelper:DissolveCloudRenderers(removeCloudRenders, self.MAP_CLOUND_ANIM_TIME, false)
    end

    -- 移除地块和建筑的压黑效果
    if #darkRenders > 0 then
        self.RogueSimHelper:TurnDarkenRenderersIntoLight(darkRenders, self.MAP_DARK_TO_LIGHT_TIME)
    end
end

-- 解锁区域
function XRogueSimScene:OnAreaUnlock(areaId)
    -- 刷新区域
    local area = self:GetArea(areaId)
    area:SetAreaUnlock()
    
    -- 刷新格子
    local areaGridsCfg = self._MainControl.MapSubControl:GetRogueSimAreaGridConfigs(areaId)
    local renders = {}
    local darkRenders = {}
    for _, gridCfg in pairs(areaGridsCfg) do
        local grid = self.GridDic[gridCfg.Id]
        grid:SetAreaUnlock()
        local render = grid:RemoveCloud()
        if render then
            table.insert(renders, render)
        end
        local terrainRenderer, landformRenderer = grid:RemoveDarken(true)
        if terrainRenderer then
            table.insert(darkRenders, terrainRenderer)
        end
        if landformRenderer then
            table.insert(darkRenders, landformRenderer)
        end
    end

    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, self.AREA_BUY_CUE_ID)
    -- 移除可见格子的云
    self.RogueSimHelper:DissolveCloudRenderers(renders, self.MAP_CLOUND_ANIM_TIME, false)

    -- 移除地块和建筑的压黑效果
    self.RogueSimHelper:TurnDarkenRenderersIntoLight(darkRenders, self.MAP_DARK_TO_LIGHT_TIME)

    -- 格子数据变化
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_LOCAL_GRID_DATA_CHANGE)
end

function XRogueSimScene:ClearCloudTimer()
    if self.CloudTimer then
        XScheduleManager.UnSchedule(self.CloudTimer)
        self.CloudTimer = nil
    end
end

-- 添加建筑
function XRogueSimScene:OnBuildingAdd(gridId)
    self.GridDic[gridId]:OnBuildingAdd()
end

-- 添加事件
function XRogueSimScene:OnEventAdd(gridId)
    self.GridDic[gridId]:OnEventAdd()
end

-- 移除事件列表
function XRogueSimScene:OnEventRemove(gridIds)
    for _, gridId in ipairs(gridIds) do
        self.GridDic[gridId]:OnEventRemove()
    end
end

-- 初始化已有奖励的格子Id列表
function XRogueSimScene:InitOldRewardGridIds()
    self.OldRewardGridIds = {}
    local rewards = self._MainControl:GetRewardData()
    for _, rewardData in pairs(rewards) do
        local gridId = rewardData:GetGridId()
        table.insert(self.OldRewardGridIds, gridId)
    end
end

-- 有探索奖励的格子列表变化
function XRogueSimScene:OnRewardsChange()
    local ChangeType = { None = 1, Add = 1, Remove = 2 }

    local changeDic = {}
    for _, gridId in ipairs(self.OldRewardGridIds) do
        changeDic[gridId] = ChangeType.Remove
    end

    self.OldRewardGridIds = {}
    local rewards = self._MainControl:GetRewardData()
    for _, rewardData in pairs(rewards) do
        local gridId = rewardData:GetGridId()
        if changeDic[gridId] == ChangeType.Remove then
            -- 之前就存在的奖励
            changeDic[gridId] = ChangeType.None
        else
            -- 新增的奖励
            changeDic[gridId] = ChangeType.Add
        end
        table.insert(self.OldRewardGridIds, gridId)
    end

    for gridId, changeType in pairs(changeDic) do
        -- 指令添加的道具可指定不存在gridId
        if self.GridDic[gridId] then
            if changeType == ChangeType.Add then
                self.GridDic[gridId]:OnRewardAdd()
            elseif changeType == ChangeType.Remove then
                self.GridDic[gridId]:OnRewardRemove()
            end
        end
    end
end

-- 任务变化
function XRogueSimScene:OnTaskChange()
    -- 刷新城邦任务气泡
    for _, gridId in ipairs(self.CityGridIds) do
        self.GridDic[gridId]:RefreshTask()
    end
end

-- 加成数据变更
function XRogueSimScene:OnAddDataChange()
    -- 刷新区域购买价格
    for _, area in pairs(self.AreaDic) do
        area:RefreshPanelUnlock()
    end
end

-- 回合数变化
function XRogueSimScene:OnTurnNumberChange()
    -- 刷新建筑投机气泡
    local eventGambleIds = self._MainControl.MapSubControl:GetCanGetEventGambleIds()
    for _, id in pairs(eventGambleIds) do
        local gridId = self._MainControl.MapSubControl:GetEventGambleGridIdById(id)
        if XTool.IsNumberValid(gridId) then
            self.GridDic[gridId]:RefreshEvent()
        end
    end
end

-- 移除事件投机
function XRogueSimScene:OnEventGambleRemove(gridId)
    if XTool.IsNumberValid(gridId) then
        self.GridDic[gridId]:RefreshEvent()
    end
end

-- 释放
function XRogueSimScene:OnRelease()
    self.GoInputHandler:RemoveAllListeners()
    self.RogueSimHelper:Clear()
    self:ClearLoadGridTimer()
    self:ClearUpdateTimer()
    self:ClearCameraSequence()
    self:ClearCloudTimer()

    for _, grid in pairs(self.GridDic) do
        grid:Release()
    end
    if self.GameObject then
        CS.UnityEngine.GameObject.Destroy(self.GameObject)
        self.GameObject = nil
    end
end

function XRogueSimScene:StartUpdateTimer()
    self:Update()
    self.UpdateTimer = XScheduleManager.ScheduleForever(function()
        self:Update()
    end, 30)
end

function XRogueSimScene:ClearUpdateTimer()
    if self.UpdateTimer then
        XScheduleManager.UnSchedule(self.UpdateTimer)
        self.UpdateTimer = nil
    end
end

function XRogueSimScene:Update()
    -- 隐藏看不见的格子
    if XEnumConst.RogueSim.IsMapOptimization then
        for _, grid in pairs(self.GridDic) do
            local isInView = CS.XUiHelper.IsInView(self.UiFarCamera, grid.Grid3D.Transform.position, -0.3, 1.3, -0.3, 1.3)
            grid:SetShow(isInView)
        end
    end
end

function XRogueSimScene:CameraFocusMainGrid(cb)
    self:CameraFocusGrid(self.MainGridId, cb)
end

-- 镜头聚焦格子
function XRogueSimScene:CameraFocusGrid(gridId, cb)
    local localPos = self:GetCameraFocusGridLocalPosition(gridId)
    self:CameraFocusPos(localPos, cb)
end

-- 镜头聚焦位置
function XRogueSimScene:CameraFocusPos(localPos, cb)
    local distance = CSVector3.Distance(self.CameraFollowPoint.localPosition, localPos)
    if distance < 0.1 then
        if cb then cb() end
        return
    end

    local time = math.min(distance / self.CameraMoveSpeed, self.CameraMoveSpeed)
    XLuaUiManager.SetMask(true)
    local CsTween = CS.DG.Tweening
    self.CameraFollowPoint:DOLocalMove(localPos, time):SetEase(CsTween.Ease.OutQuad):OnComplete(function()
        XLuaUiManager.SetMask(false)
        if cb then cb() end
    end)
end

-- 计算CameraFollowPoint聚焦格子时的localposition
function XRogueSimScene:GetCameraFocusGridLocalPosition(gridId)
    local gridPos = self:GetWorldPosByGridId(gridId)  -- 格子世界坐标
    local linkPos = self.PanelDrag.transform.position -- 挂点世界坐标
    local localPos = CS.UnityEngine.Vector3(gridPos.x - linkPos.x - self.CameraFocusGridOffsetX, gridPos.z - linkPos.z, self.CameraFollowPoint.localPosition.z)
    return localPos
end

-- 保存镜头位置
function XRogueSimScene:SaveLastCameraFollowPointPos()
    self._MainControl.MapSubControl:SaveLastCameraFollowPointPos(self.CameraFollowPoint.localPosition)
end

-- 获取地图点位传闻列表 -- TODO 待删除
function XRogueSimScene:GetGridTipList()
    local curTurnNumber = self._MainControl:GetCurTurnNumber()
    local grids = {} -- 触发传闻的格子
    local citys = {} -- 所有陈邦

    for _, grid in pairs(self.GridDic) do
        if grid.LandformId ~= 0 then
            local landCfg = self._MainControl.MapSubControl:GetRogueSimLandformConfig(grid.LandformId)
            -- 记录当前回合触发传闻的点位
            if not grid:GetIsExplored() and landCfg.TipId ~= 0 and landCfg.TipTurnNumber ~= 0 and curTurnNumber % landCfg.TipTurnNumber == 0 then
                table.insert(grids, grid)
            end

            -- 记录城邦点位
            if landCfg.LandType == XEnumConst.RogueSim.LandformType.City then
                table.insert(citys, grid)
            end
        end
    end

    local tipList = {}
    for _, grid in ipairs(grids) do
        local gridPos = grid.Grid3D.Transform.position
        local city = nil
        local distance = nil
        for _, tempCity in ipairs(citys) do
            local tempPos = tempCity.Grid3D.Transform.position
            local tempDistance = (tempPos.x - gridPos.x) * (tempPos.x - gridPos.x) + (tempPos.z - gridPos.z) * (tempPos.z - gridPos.z)
            if city == nil or tempDistance < distance then
                city = tempCity
                distance = tempDistance
            end
        end

        local gridLandCfg = self._MainControl.MapSubControl:GetRogueSimLandformConfig(grid.LandformId)
        local tipContent = self._MainControl:GetTipContent(gridLandCfg.TipId)
        local direction = self:GetDirection(city, grid)
        local msg = string.format(tipContent, city:GetName(), direction, grid:GetName())
        --local tips = {Id = gridLandCfg.TipId, Msg = msg }
        table.insert(tipList, msg)
    end
    return tipList
end

-- 获取方向
function XRogueSimScene:GetDirection(baseGrid, compareGrid)
    if not baseGrid or not compareGrid then
        return ""
    end

    -- 南/北/东/西方向
    if baseGrid.PosX == compareGrid.PosX then
        if compareGrid.PosY > baseGrid.PosY then
            return self._MainControl:GetClientConfig("North")
        else
            return self._MainControl:GetClientConfig("South")
        end
    elseif baseGrid.PosY == compareGrid.PosY then
        if math.abs(compareGrid.PosX - baseGrid.PosX) % 2 == 0 then
            if compareGrid.PosX > baseGrid.PosX then
                return self._MainControl:GetClientConfig("East")
            else
                return self._MainControl:GetClientConfig("West")
            end
        end
    end

    -- 东北/东南/西北/西南方向
    local basePos = baseGrid.Grid3D.Transform.position
    local comparePos = compareGrid.Grid3D.Transform.position
    if comparePos.x > basePos.x then
        if comparePos.z > basePos.z then
            return self._MainControl:GetClientConfig("Northeast")
        else
            return self._MainControl:GetClientConfig("Southeast")
        end
    else
        if comparePos.z > basePos.z then
            return self._MainControl:GetClientConfig("Northwest")
        else
            return self._MainControl:GetClientConfig("Southwest")
        end
    end
end

-- 获取区域对象
function XRogueSimScene:GetArea(areaId)
    return self.AreaDic[areaId]
end

-- 获取格子对象
function XRogueSimScene:GetGrid(gridId)
    return self.GridDic[gridId]
end

-- 根据地貌类型获取所有格子Id
---@param landformType number 地貌类型
function XRogueSimScene:GetGridIdsByLandformType(landformType)
    if landformType == XEnumConst.RogueSim.LandformType.Main then
        return { self.MainGridId }
    elseif landformType == XEnumConst.RogueSim.LandformType.City then
        return self.CityGridIds
    end

    local gridIds = {}
    for _, grid in pairs(self.GridDic) do
        if grid:GetLandType() == landformType and grid:GetCanBeSeen() then
            table.insert(gridIds, grid.Id)
        end
    end
    return gridIds
end

-- 获取可探索给子
function XRogueSimScene:GetCanExploreGridIds()
    -- 优先级：宝箱>资源>事件
    local orderDic = {}
    orderDic[XEnumConst.RogueSim.LandformType.Prop] = 1
    orderDic[XEnumConst.RogueSim.LandformType.Resource] = 2
    orderDic[XEnumConst.RogueSim.LandformType.Event] = 3
    
    local gridIds = {}
    for _, grid in pairs(self.GridDic) do
        if grid:GetCanExplore() and orderDic[grid:GetLandType()] then
            table.insert(gridIds, grid.Id)
        end
    end
    
    -- 排序
    table.sort(gridIds, function(a, b)
        local gridA = self:GetGrid(a)
        local gridB = self:GetGrid(b)
        local orderA = orderDic[gridA:GetLandType()]
        local orderB = orderDic[gridB:GetLandType()]
        if orderA ~= orderB then
            return orderA < orderB
        else
            return gridA.Id < gridB.Id
        end
    end)
    return gridIds
end

-- 获取区域的地标格子Id
function XRogueSimScene:GetAreaLandmarkGridId(areaId)
    return self.AreaLandmarkGridIdDic[areaId]
end

--region 加载场景
-- 异步加载场景
function XRogueSimScene:LoadSceneAsync(loadCompleteCb)
    self.LoadCompleteCb = loadCompleteCb -- 加载完成回调
    local sceneAssetUrl = self._MainControl:GetClientConfig("ScenePath", 1)
    self:GetLoader():LoadAsync(sceneAssetUrl, function(asset)
        if not asset then
            XLog.Error("XRogueSimScene LoadSceneAsync error, instantiate error, name: " .. sceneAssetUrl)
            return
        end
        self.GameObject = CS.UnityEngine.Object.Instantiate(asset)
        self:OnLoadSceneComplete()
    end)
end

-- 场景加载完毕回调
function XRogueSimScene:OnLoadSceneComplete()
    if XEnumConst.RogueSim.IsDebug then
        local mapData = self._MainControl.MapSubControl:GetMapData()
        local areaDatas = mapData:GetAreaDatas()
        XLog.Warning("<color=#F1D116>RogueSim:</color> 当前区域为: " .. XLog.Dump(areaDatas))
    end

    local sceneRoot = self.GameObject.transform:FindTransform("UiRogueSim").transform
    self.RogueSimHelper = sceneRoot.gameObject:AddComponent(typeof(CS.XRogueSimHelper))
    self.RogueSimHelper:SetDarkenValue(self.MAP_DARKEN_VALUE)

    self.SceneGridList = sceneRoot:Find("UiFarRoot/SceneGridList")
    self.SceneGrid = self.SceneGridList:Find("SceneGrid")
    self.SceneGrid.gameObject:SetActiveEx(false)
    self.UiAreaList = sceneRoot:Find("UiNearRoot/UiCanvas/UiAreaList")
    self.UiArea = self.UiAreaList:Find("UiArea")
    self.UiArea.gameObject:SetActiveEx(false)
    self.UiGridList = sceneRoot:Find("UiNearRoot/UiCanvas/UiGridList")
    self.UiGrid = self.UiGridList:Find("UiGrid")
    self.UiGrid.gameObject:SetActiveEx(false)

    self.EffectLink = sceneRoot:Find("UiFarRoot/SceneGridList/EffectLink")
    self.CloudEffect1 = self.EffectLink:Find("CloudEffect1")
    self.CloudEffect1.gameObject:SetActiveEx(false)
    self.GridSelectEffect1 = self.EffectLink:Find("GridSelectEffect1")
    self.GridSelectEffect1.gameObject:SetActiveEx(false)
    self.GridSelectEffect2 = self.EffectLink:Find("GridSelectEffect2")
    self.GridSelectEffect2.gameObject:SetActiveEx(false)

    -- 区域未解锁时云的材质
    self.Cloud = self.EffectLink:Find("RogueSim_CloudHex01")

    -- 修改虚拟摄像机参数
    local enumStage = CS.Cinemachine.CinemachineCore.Stage.Body
    local typeFramingTransposer = typeof(CS.Cinemachine.CinemachineFramingTransposer)
    local virtuaUiFarCamera = sceneRoot:Find("UiFarRoot/VirtuaUiFarCamera"):GetComponent("CinemachineVirtualCamera")
    local camFarOverlook = sceneRoot:Find("UiFarRoot/CamFarOverlook"):GetComponent("CinemachineVirtualCamera")
    self.farCamBody = virtuaUiFarCamera:GetCinemachineComponent(enumStage, typeFramingTransposer)
    self.farCamOverlookBody = camFarOverlook:GetCinemachineComponent(enumStage, typeFramingTransposer)

    local virtuaUiNearCamera = sceneRoot:Find("UiNearRoot/VirtuaUiNearCamera"):GetComponent("CinemachineVirtualCamera")
    local camNearOverlook = sceneRoot:Find("UiNearRoot/CamNearOverlook"):GetComponent("CinemachineVirtualCamera")
    self.neraCamBody = virtuaUiNearCamera:GetCinemachineComponent(enumStage, typeFramingTransposer)
    self.neraCamOverlookBody = camNearOverlook:GetCinemachineComponent(enumStage, typeFramingTransposer)

    local virtuaUiCamera = sceneRoot:Find("UiNearRoot/VirtuaUiCamera"):GetComponent("CinemachineVirtualCamera")
    local camUiOverlook = sceneRoot:Find("UiNearRoot/CamUiOverlook"):GetComponent("CinemachineVirtualCamera")
    self.uiCamBody = virtuaUiCamera:GetCinemachineComponent(enumStage, typeFramingTransposer)
    self.uiCamOverlookBody = camUiOverlook:GetCinemachineComponent(enumStage, typeFramingTransposer)

    -- 摄像机高度
    local cameraDistance = self._MainControl:GetClientConfig("CameraDistance")
    self:SetCameraDistance(tonumber(cameraDistance))
    -- 摄像机X方向旋转角度
    local cameraRotationX = self._MainControl:GetClientConfig("CameraRotationX")
    cameraRotationX = tonumber(cameraRotationX)
    virtuaUiFarCamera.transform.localEulerAngles = CS.UnityEngine.Vector3(cameraRotationX, 0, 0)
    camFarOverlook.transform.localEulerAngles = CS.UnityEngine.Vector3(cameraRotationX, 0, 0)
    virtuaUiNearCamera.transform.localEulerAngles = CS.UnityEngine.Vector3(cameraRotationX, 0, 0)
    camNearOverlook.transform.localEulerAngles = CS.UnityEngine.Vector3(cameraRotationX, 0, 0)
    virtuaUiCamera.transform.localEulerAngles = CS.UnityEngine.Vector3(cameraRotationX, 0, 0)
    camUiOverlook.transform.localEulerAngles = CS.UnityEngine.Vector3(cameraRotationX, 0, 0)

    self.UiFarCamera = sceneRoot:Find("UiFarRoot/UiFarCamera"):GetComponent("Camera")
    self.UiNearCamera = sceneRoot:Find("UiNearRoot/UiNearCamera"):GetComponent("Camera")
    self.UiCamera = sceneRoot:Find("UiNearRoot/UiCamera"):GetComponent("Camera")
    self.PanelDrag = sceneRoot:Find("UiNearRoot/UiCanvas/PanelDrag"):GetComponent("XDragMove")
    self.CameraFollowPoint = self.PanelDrag.transform:Find("CameraFollowPoint"):GetComponent("RectTransform")
    self.CameraFollowPointOverlook = self.PanelDrag.transform:Find("CameraFollowPointOverlook"):GetComponent("RectTransform")

    self.CamFarOverlook = sceneRoot:Find("UiFarRoot/CamFarOverlook")
    self.CamNearOverlook = sceneRoot:Find("UiNearRoot/CamNearOverlook")
    self.CamUiOverlook = sceneRoot:Find("UiNearRoot/CamUiOverlook")

    -- 场景拖拽事件
    self.GoInputHandler = sceneRoot:Find("UiFarRoot/ColiderPanel"):GetComponent(typeof(CS.XGoInputHandler))
    self.GoInputHandler:AddDragListener(function(eventData) self:OnSceneDrag(eventData) end)
    self.GoInputHandler:AddPointerClickListener(function(eventData) self:OnSceneClick(eventData) end)
    -- 监听pc滚轮
    self.GoInputHandler.IsMidButtonEventEnable = true
    self.GoInputHandler:AddMidButtonScrollUpListener(function(val)
        XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_MID_BUTTON_SCROLL_UP, val)
    end)
    self.GoInputHandler:AddMidButtonScrollDownListener(function(val)
        XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_MID_BUTTON_SCROLL_DOWN, val)
    end)

    self:GenerateAreaList()
    self:GenerateGridList()
    self:LoadGridAsync()
end

-- 点击场景
function XRogueSimScene:OnSceneClick(eventData)
    local position = eventData.pointerCurrentRaycast.worldPosition
    if XEnumConst.RogueSim.IsDebug then
        XLog.Warning("<color=#F1D116>RogueSim:</color> 点击位置: " .. XLog.Dump(position))
    end
    local gridPos = self:GetGridPosByWorldPos(position)
    local grid = self:GetGridByGridPos(gridPos.x, gridPos.y)
    if grid then
        self:OnGridClick(grid)
    else
        if XEnumConst.RogueSim.IsDebug then
            XLog.Warning(string.format("<color=#F1D116>RogueSim:</color> 点击格子位置(%s, %s) ", tostring(gridPos.x), tostring(gridPos.y)))
        end
    end
end

-- 拖拽场景
function XRogueSimScene:OnSceneDrag(eventData)
    self.PanelDrag:OnDrag(eventData)
end

-- 设置摄像机高度
function XRogueSimScene:SetCameraDistance(distance)
    self.CameraDistance = distance

    self.farCamBody.m_CameraDistance = distance
    self.farCamOverlookBody.m_CameraDistance = distance
    self.neraCamBody.m_CameraDistance = distance
    self.neraCamOverlookBody.m_CameraDistance = distance
    self.uiCamBody.m_CameraDistance = distance
    self.uiCamOverlookBody.m_CameraDistance = distance
end

function XRogueSimScene:GetCameraDistance()
    return self.CameraDistance
end

-- 生成区域列表
function XRogueSimScene:GenerateAreaList()
    local mapData = self._MainControl.MapSubControl:GetMapData()
    local areaDatas = mapData:GetAreaDatas()
    local XRogueSimArea = require("XModule/XRogueSim/XEntity/Scene/XRogueSimArea")
    for _, areaData in ipairs(areaDatas) do
        local areaId = areaData.Id
        local isUnlock = self.AreaIdUnlockDic[areaId] == true
        local canUnlock = self.AreaIdCanUnlockDic[areaId] == true
        local area = XRogueSimArea.New(self, areaId, isUnlock, canUnlock)
        self.AreaDic[areaId] = area
    end
end

-- 生成格子列表
function XRogueSimScene:GenerateGridList()
    -- TODO 优化格子创建
    -- 创建格子，记录子格子
    local mapData = self._MainControl.MapSubControl:GetMapData()
    local areaDatas = mapData:GetAreaDatas()
    local XRogueSimGrid = require("XModule/XRogueSim/XEntity/Scene/XRogueSimGrid")
    for _, areaData in ipairs(areaDatas) do
        local areaId = areaData.Id
        local areaIsUnlock = self.AreaIdUnlockDic[areaId] == true
        local sreaCanUnlock = self.AreaIdCanUnlockDic[areaId] == true
        local areaGridsCfg = self._MainControl.MapSubControl:GetRogueSimAreaGridConfigs(areaId)
        for _, gridCfg in pairs(areaGridsCfg) do
            local grid = XRogueSimGrid.New(self, gridCfg, areaIsUnlock, sreaCanUnlock)
            self.GridDic[grid.Id] = grid
            self:RecordChild(grid.ParentId, grid.Id)
            self:SaveGridPosToGridId(gridCfg.PosX, gridCfg.PosY, gridCfg.Id)
        end
    end

    -- 根据Landform表是否配置IsPreview，确定格子是否可预览
    -- 记录特殊点位
    local curTokenId = self._MainControl:GetCurTokenId()
    local isShowPreview = self._MainControl:GetTokenIsShowCity(curTokenId)
    for _, grid in pairs(self.GridDic) do
        if grid.LandformId ~= 0 then
            local landCfg = self._MainControl.MapSubControl:GetRogueSimLandformConfig(grid.LandformId)
            if landCfg.IsPreview and isShowPreview then
                grid:SetIsPreview()
                local childIds = self:GetChilds(grid.Id)
                for _, childId in ipairs(childIds or {}) do
                    self.GridDic[childId]:SetIsPreview()
                end
            end

            -- 记录主城格子Id
            if landCfg.LandType == XEnumConst.RogueSim.LandformType.Main then
                self.MainGridId = grid.Id
                self.AreaLandmarkGridIdDic[grid.AreaId] = grid.Id
            elseif landCfg.LandType == XEnumConst.RogueSim.LandformType.City then
                table.insert(self.CityGridIds, grid.Id)
                self.AreaLandmarkGridIdDic[grid.AreaId] = grid.Id
            end
        end
    end

    -- 记录服务器下发格已探索格子
    local exploredIds = self._MainControl.MapSubControl:GetExploredGridIds()
    self:SetGridsExplored(exploredIds)

    -- 记录服务器下发的额外开放视野的格子
    local visibleIds = self._MainControl.MapSubControl:GetVisibleGridIds()
    self:SetGridsVisibled(visibleIds)
end

-- 记录格子是否已探索
function XRogueSimScene:SetGridsExplored(exploredIds)
    for _, gridId in ipairs(exploredIds) do
        local grid = self.GridDic[gridId]
        if not grid then
            local mapData = self._MainControl.MapSubControl:GetMapData()
            local areaDatas = mapData:GetAreaDatas()
            XLog.Error(string.format("服务器下发的已探索格子格子Id=%s不存在 ，当前地图由以下区域组成%s", gridId, XLog.Dump(areaDatas)))
            goto CONTINUE
        end

        grid:SetIsExplored()
        :: CONTINUE ::
    end
end

-- 设置格子可见
function XRogueSimScene:SetGridsVisibled(visibleGridIds, cb)
    for _, gridId in ipairs(visibleGridIds) do
        self.GridDic[gridId]:SetIsPreview()
        local childIds = self:GetChilds(gridId)
        for _, childId in ipairs(childIds or {}) do
            self.GridDic[childId]:SetIsPreview()
        end
    end
end

-- 格子异步加载
function XRogueSimScene:LoadGridAsync()
    -- 区域加载
    for _, area in pairs(self.AreaDic) do
        area:Load()
    end
    
    local gridList = {}
    for _, grid in pairs(self.GridDic) do
        table.insert(gridList, grid)
    end

    local loadSpeed = self._MainControl:GetClientConfig("SceneLoadGridSpeed", 1)
    local loadIndex = 0
    self:ClearLoadGridTimer()
    self.LoadGridTimer = XScheduleManager.ScheduleForever(function()
        for i = 1, loadSpeed do
            if loadIndex < #gridList then
                loadIndex = loadIndex + 1
                gridList[loadIndex]:Load()
            else
                self:ClearLoadGridTimer()
                self:OnLoadComplete()
                return
            end
        end
    end, 20)
end

function XRogueSimScene:ClearLoadGridTimer()
    if self.LoadGridTimer then
        XScheduleManager.UnSchedule(self.LoadGridTimer)
        self.LoadGridTimer = nil
    end
end

-- 初始化拖拽区域
function XRogueSimScene:InitPanelDrag()
    local minPosX, maxPosX, minPosY, maxPosY
    for _, grid in pairs(self.GridDic) do
        if not minPosX or minPosX > grid.PosX then
            minPosX = grid.PosX
        end
        if not maxPosX or maxPosX < grid.PosX then
            maxPosX = grid.PosX
        end
        if not minPosY or minPosY > grid.PosY then
            minPosY = grid.PosY
        end
        if not maxPosY or maxPosY < grid.PosY then
            maxPosY = grid.PosY
        end
    end

    local minWorldPos = self:GetWorldPosByGridPos(minPosX, minPosY)
    local maxWorldPos = self:GetWorldPosByGridPos(maxPosX, maxPosY)
    local offset = self._MainControl:GetClientConfigParams("CameraPanelDragSizeOffset")
    local offsetX = tonumber(offset[1] or 0)
    local offsetY = tonumber(offset[2] or 0)
    local width = maxWorldPos.x - minWorldPos.x + offsetX
    local height = maxWorldPos.z - minWorldPos.z + offsetY
    local startPosX = minWorldPos.x - offsetX / 2
    local startPosY = minWorldPos.z - offsetY / 2
    local rect = self.PanelDrag.transform:GetComponent("RectTransform")
    rect.sizeDelta = CS.UnityEngine.Vector2(width, height)
    rect.localPosition = CS.UnityEngine.Vector3(startPosX, startPosY, 0)
    
    -- XDragMove是在Awake()进行计算XOffset和YOffset，修正数值
    local dragMinPosX = 0
    local dragMaxPosX = maxWorldPos.x + offsetX
    local dragMinPosY = 0
    local dragMaxPosY = maxWorldPos.z + offsetY
    self.PanelDrag.XOffset = CS.UnityEngine.Vector2(dragMinPosX, dragMaxPosX) 
    self.PanelDrag.YOffset = CS.UnityEngine.Vector2(dragMinPosY, dragMaxPosY)
end

-- 初始化摄像机位置
function XRogueSimScene:InitCameraPos()
    local pos = self._MainControl.MapSubControl:GetLastCameraFollowPointPos()
    if not pos then
        pos = self:GetCameraFocusGridLocalPosition(self.MainGridId)
    end
    self.CameraFollowPoint.localPosition = pos
end

--endregion



--region 快速获取子格子列表
-- 记录子格子
function XRogueSimScene:RecordChild(gridId, childId)
    if gridId == nil or gridId == 0 then
        return
    end

    local childs = self.ChildsDic[gridId]
    if not childs then
        childs = {}
        self.ChildsDic[gridId] = childs
    end
    table.insert(childs, childId)
end

-- 获取子格子列表
function XRogueSimScene:GetChilds(gridId)
    return self.ChildsDic[gridId]
end

-- 清除子格子列表
function XRogueSimScene:CleraChild(gridId)
    if self.ChildsDic[gridId] then
        self.ChildsDic[gridId] = nil
    end
end

--endregion



--region 格子坐标计算
-- 格子Id转换世界坐标
function XRogueSimScene:GetWorldPosByGridId(gridId)
    local posX = 0
    local posY = 0
    local grid = self.GridDic[gridId]
    if grid then
        posX = grid.PosX
        posY = grid.PosY
    else
        posX = math.floor(gridId / 1000 % 1000)
        posY = math.floor(gridId % 1000)
    end
    return self:GetWorldPosByGridPos(posX, posY)
end

-- 获取子格子组的中心坐标
function XRogueSimScene:GetGridChildsCenterWorldPos(gridId)
    local worldPos = self:GetWorldPosByGridId(gridId)
    
    -- 有子格子，需要计算中心点
    local childs = self:GetChilds(gridId)
    if childs then
        local gridCnt = #childs + 1 -- 该地貌的总占格
        for _, childId in ipairs(childs) do
            local childWolrdPos = self:GetWorldPosByGridId(childId)
            worldPos = worldPos + childWolrdPos
        end
        worldPos = CS.UnityEngine.Vector3(worldPos.x / gridCnt, worldPos.y / gridCnt, worldPos.z / gridCnt)
    end
    return worldPos
end

-- 格子坐标转换为世界坐标
function XRogueSimScene:GetWorldPosByGridPos(posX, posY)
    local cos30 = 0.866
    local gridSize = self.GRID_SIZE
    local x = posX * 1.5 * gridSize
    local y = (2 * posY - posX % 2) * cos30 * gridSize
    return CS.UnityEngine.Vector3(x, 0, y)
end

-- 世界坐标转格子坐标
function XRogueSimScene:GetGridPosByWorldPos(worldPos)
    local cos30 = 0.866
    local gridSize = self.GRID_SIZE
    local CSVector2 = CS.UnityEngine.Vector2
    worldPos = CSVector2(worldPos.x, worldPos.z)

    -- 取到附近的格子
    local gridX = math.floor(worldPos.x / (1.5 * gridSize))
    local gridY = math.floor(worldPos.y / (2 * cos30 * gridSize))
    if gridX % 2 == 1 then
        gridY = gridY + 1

        -- 判断是否在格子矩形内
        local gridWorldPos = self:GetWorldPosByGridPos(gridX, gridY)
        gridWorldPos = CSVector2(gridWorldPos.x, gridWorldPos.z)
        if (worldPos.x - gridWorldPos.x) < (0.5 * gridSize) then
            return { x = gridX, y = gridY }
        end

        -- 判断是否在格子三角形区域内
        local direction = CSVector2(worldPos.x - gridWorldPos.x, worldPos.y - gridWorldPos.y)
        local distance = CSVector2.Distance(worldPos, gridWorldPos)
        local angle = CSVector2.Angle(direction, CSVector2.right) -- 点击的点与格子中心点夹角
        if angle > 90 then
            angle = 180 - angle                                   -- 120°=60°
        end
        local centerToSideAngle = math.abs(angle - 30)            -- 20°=10°, 51°=21°
        local centerToAngleSideDistance = gridSize * math.cos(centerToSideAngle * math.pi / 180)
        if distance <= centerToAngleSideDistance then
            return { x = gridX, y = gridY }
        end

        -- 判断隔壁的2个六边形
        if worldPos.y >= gridWorldPos.y then
            return { x = gridX + 1, y = gridY }
        else
            return { x = gridX + 1, y = gridY - 1 }
        end
    else
        local gridWorldPos = self:GetWorldPosByGridPos(gridX, gridY)
        gridWorldPos = CSVector2(gridWorldPos.x, gridWorldPos.z)
        local direction = CSVector2(worldPos.x - gridWorldPos.x, worldPos.y - gridWorldPos.y)
        local angle = CSVector2.Angle(direction, CSVector2.right) -- 点击的点与格子中心点夹角
        if angle > 90 then
            angle = 180 - angle                                   -- 120°=60°
        end
        if angle <= 60 then
            local distance = CSVector2.Distance(worldPos, gridWorldPos)
            local centerToSideAngle = math.abs(angle - 30) -- 20°=10°, 51°=21°
            local centerToAngleSideDistance = gridSize * math.cos(centerToSideAngle * math.pi / 180)
            if distance >= centerToAngleSideDistance then
                return { x = gridX + 1, y = gridY + 1 }
            else
                return { x = gridX, y = gridY }
            end
        else
            if (worldPos.y - gridWorldPos.y) >= (cos30 * gridSize) then
                return { x = gridX, y = gridY + 1 }
            else
                return { x = gridX, y = gridY }
            end
        end
    end
end

-- 获取两个格子的距离
function XRogueSimScene:GetGridDistance(gridId1, gridId2)
    local CSVector2 = CS.UnityEngine.Vector2
    local grid1 = self:GetGrid(gridId1)
    local grid2 = self:GetGrid(gridId2)
    local gridWorldPos1 = self:GetWorldPosByGridPos(grid1.PosX, grid1.PosY)
    gridWorldPos1 = CSVector2(gridWorldPos1.x, gridWorldPos1.z)
    local gridWorldPos2 = self:GetWorldPosByGridPos(grid2.PosX, grid2.PosY)
    gridWorldPos2 = CSVector2(gridWorldPos2.x, gridWorldPos2.z)
    local distance = CSVector2.Distance(gridWorldPos1, gridWorldPos2)
    return distance
end

--endregion



--region 支持通过位置获取格子、周围格子
-- 格子位置转换为唯一key
function XRogueSimScene:GridPosToKey(posX, posY)
    return posX * 1000 + posY
end

-- 保存key为格子位置，value为格子id的表
function XRogueSimScene:SaveGridPosToGridId(posX, posY, gridId)
    local posKey = self:GridPosToKey(posX, posY)
    if self.GridPosDic[posKey] then
        local tips = string.format("出现相同坐标的格子，请策划老师检查%s和%s", tostring(self.GridPosDic[posKey]), gridId)
        XLog.Error(tips)
    end
    self.GridPosDic[posKey] = gridId
end

-- 通过格子位置取格子
function XRogueSimScene:GetGridByGridPos(posX, posY)
    local posKey = self:GridPosToKey(posX, posY)
    local gridId = self.GridPosDic[posKey]
    if gridId then
        return self.GridDic[gridId]
    end
    return nil
end

-- 获取周围格子的偏移
function XRogueSimScene:GetAroundGridsOffset(gridId, distance)
    local gridPosX = self:GetGrid(gridId).PosX
    local remainder = gridPosX % 2 -- 余数
    if distance == 1 then
        return remainder == 0 and self.AROUND_GRIDS_OFFSET0 or self.AROUND_GRIDS_OFFSET1
    end

    local saveKey = tostring(distance) .. tostring(remainder)
    local grids = self.AroundGridsCache[saveKey]
    if grids then
        return grids
    end

    local GetPosKey = function(pos)
        return tostring(pos.x) .. tostring(pos.y)
    end

    grids = {}
    local centerPos = { x = 0, y = 0 }
    local finishGridDic = {}
    finishGridDic[GetPosKey(centerPos)] = true

    local tempGrids = { centerPos }
    while (distance > 0) do
        local newGrids = {}
        for _, grid in ipairs(tempGrids) do
            local gridRemainder = (grid.x + gridPosX) % 2
            local offsets = gridRemainder == 0 and self.AROUND_GRIDS_OFFSET0 or self.AROUND_GRIDS_OFFSET1
            for _, offset in ipairs(offsets) do
                local pos = { x = grid.x + offset.x, y = grid.y + offset.y }
                local posKey = GetPosKey(pos)
                if not finishGridDic[posKey] then
                    table.insert(grids, pos)
                    table.insert(newGrids, pos)
                    finishGridDic[posKey] = true
                end
            end
        end

        tempGrids = newGrids
        distance = distance - 1
    end

    self.AroundGridsCache[saveKey] = grids
    return grids
end

--endregion


--region 格子选中特效

-- 显示格子选中特效
function XRogueSimScene:ShowGridSelectEffect(gridId)
    self:ClearGridSelectEffect()

    local grid = self.GridDic[gridId]
    local canExplore = grid:GetCanExplore()

    -- 选中地貌包含的所有格子
    local gridIds = { gridId }
    local childIds = self:GetChilds(gridId)
    for _, childId in ipairs(childIds or {}) do
        table.insert(gridIds, childId)
    end

    -- 显示选中特效
    local cloneGo = canExplore and self.GridSelectEffect2 or self.GridSelectEffect1
    local effects = canExplore and self.GridSelectEffects2 or self.GridSelectEffects1
    for i, id in ipairs(gridIds) do
        local effectGo = self:GetGridEffect(id, effects, i, cloneGo)
        effectGo.gameObject:SetActiveEx(true)
        local pos = self:GetWorldPosByGridId(id)
        local tempGrid = self:GetGrid(id)
        local posY = tempGrid.Grid3D.TerrainLink.localScale.y * self.TERRAIN_HEIGHT
        effectGo.position = CS.UnityEngine.Vector3(pos.x, posY, pos.z)
    end

    -- 计算探索后即将解锁视野的格子，显示云雾特效
    local visibleIdDic = {}
    for i, id in ipairs(gridIds) do
        local seenOffsets = self:GetAroundGridsOffset(id, self.SightRange)
        local tempGrid = self:GetGrid(id)
        for _, offset in ipairs(seenOffsets) do
            local aroundGrid = self:GetGridByGridPos(tempGrid.PosX + offset.x, tempGrid.PosY + offset.y)
            if aroundGrid then
                visibleIdDic[aroundGrid:GetId()] = true
            end
        end
    end
    local visibleIds = {}
    local index = 1
    for id, _ in pairs(visibleIdDic) do
        local vGrid = self:GetGrid(id)
        if not vGrid:GetCanBeSeen() and vGrid:GetAreaIsUnlock() then
            local effectGo = self:GetGridEffect(id, self.CloudEffects1, index, self.CloudEffect1)
            effectGo.gameObject:SetActiveEx(true)
            effectGo.position = self:GetWorldPosByGridId(id)
            index = index + 1
        end
    end
end

function XRogueSimScene:GetGridEffect(gridId, effects, index, cloneGo)
    if #effects > index then
        return effects[index]
    end

    local CSInstantiate = CS.UnityEngine.Object.Instantiate
    local effectGo = CSInstantiate(cloneGo, self.EffectLink)
    table.insert(effects, effectGo)
    return effectGo
end

-- 清除格子选中特效
function XRogueSimScene:ClearGridSelectEffect()
    for _, effect in ipairs(self.GridSelectEffects1 or {}) do
        effect.gameObject:SetActiveEx(false)
    end
    for _, effect in ipairs(self.GridSelectEffects2 or {}) do
        effect.gameObject:SetActiveEx(false)
    end
    for _, effect in ipairs(self.CloudEffects1 or {}) do
        effect.gameObject:SetActiveEx(false)
    end
end

--endregion


return XRogueSimScene
