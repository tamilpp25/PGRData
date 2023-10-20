-- 肉鸽模拟经营地图
---@class XRogueSimScene
---@field private _MainControl XRogueSimControl
---@field private GridDic XRogueSimGrid[]
local XRogueSimScene = XClass(XControl, "XRogueSimScene")
local CsTween = CS.DG.Tweening
local CSVector3 = CS.UnityEngine.Vector3

-- 初始化参数
function XRogueSimScene:OnInit()
    self.ClickGridCb = nil
    self.GridDic = {}                       -- 格子Id:格子对象
    self.ChildsDic = {}                     -- 格子Id:子格子Id列表
    self.GridPosDic = {}                    -- 位置key:格子Id
    self.AroundGridsCache = {}              -- 缓存周围格子偏移
    self.MainGridId = 0                     -- 主城格子Id
    self.CityGridIds = {}                   -- 城邦格子Id列表
    self.GridSelectEffects1 = {}            -- 格子选中特效列表(格子未连通)
    self.GridSelectEffects2 = {}            -- 格子选中特效列表(格子已连通)
    self.CloudEffects1 = {}                 -- 云雾特效(格子探索将会解锁)
    self.SightRange = self._MainControl.ResourceSubControl:GetResourceOwnCount(XEnumConst.RogueSim.ResourceId.SightRange)
end

-- 设置点击格子回调函数
function XRogueSimScene:SetClickGridCb(clickGridCb)
    self.ClickGridCb = clickGridCb
end

-- 场景、格子等全部加载完成时调用
function XRogueSimScene:OnLoadComplete()
    if self.LoadCompleteCb then
        self.LoadCompleteCb()
    end
    -- 引导支持，C#事件调用
    self.OnCSEventFocusGrid = function(evt, param)
        local gridId = tonumber(param[0])
        self:CameraFocusGrid(gridId)
    end
    self:StartUpdateTimer()
    self:InitPanelDrag()
    self:InitCameraPos()
    self:InitOldRewardGridIds()
end

-- 注册事件
function XRogueSimScene:AddAgencyEvent()
    XEventManager.AddEventListener(XEventId.EVENT_ROGUE_SIM_EXPLORE_GRID, self.OnExploreGrid, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUE_SIM_VISIBLE_GRID, self.OnVisibleGrid, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUE_SIM_RESOURCE_CHANGE, self.OnResourceChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUE_SIM_MAIN_LEVEL_UP, self.OnMainLevelUp, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUE_SIM_BUILDING_ADD, self.OnBuildingAdd, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUE_SIM_BUILDING_BUY, self.OnBuildingBuy, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUE_SIM_EVENT_ADD, self.OnEventAdd, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUE_SIM_EVENT_REMOVE, self.OnEventRemove, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUE_SIM_REWARDS_CHANGE, self.OnRewardsChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUE_SIM_TASK_CHANGE, self.OnTaskChange, self)
    CsXGameEventManager.Instance:RegisterEvent(XEventId.EVENT_ROGUE_SIM_FOCUS_GRID, self.OnCSEventFocusGrid)
end

-- 释放事件
function XRogueSimScene:RemoveAgencyEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUE_SIM_EXPLORE_GRID, self.OnExploreGrid, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUE_SIM_VISIBLE_GRID, self.OnVisibleGrid, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUE_SIM_RESOURCE_CHANGE, self.OnResourceChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUE_SIM_MAIN_LEVEL_UP, self.OnMainLevelUp, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUE_SIM_BUILDING_ADD, self.OnBuildingAdd, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUE_SIM_BUILDING_BUY, self.OnBuildingBuy, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUE_SIM_EVENT_ADD, self.OnEventAdd, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUE_SIM_EVENT_REMOVE, self.OnEventRemove, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUE_SIM_REWARDS_CHANGE, self.OnRewardsChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUE_SIM_TASK_CHANGE, self.OnTaskChange, self)
    CsXGameEventManager.Instance:RemoveEvent(XEventId.EVENT_ROGUE_SIM_FOCUS_GRID, self.OnCSEventFocusGrid)
end

-- 点击格子
function XRogueSimScene:OnGridClick(grid)
    if grid and XEnumConst.RogueSim.IsDebug then
        XLog.Warning("点击格子Id：" .. tostring(grid.Id))
    end

    -- 点击空白
    if not grid then
        return
    end

    -- 不可点击
    local parentId = grid:GetParentId()
    local parentGrid = self.GridDic[parentId]
    if parentGrid:GetIsUnClick() then
        local tips = parentGrid:GetUnClickTips()
        if tips then
            XUiManager.TipMsg(tips, nil, nil, true)
        end
        return
    end

    -- 聚焦格子
    self:CameraFocusGrid(parentId)

    -- 选中特效
    self:ShowGridSelectEffect(parentId)

    -- 打开格子详情气泡
    ---@type XUiRogueSimBattle
    local luaUi = XLuaUiManager.GetTopLuaUi("UiRogueSimBattle")
    if luaUi then
        luaUi:OpenLandBubble(parentGrid)
    end
end

-- 服务器增量下推已探索格子
function XRogueSimScene:OnExploreGrid(data)
    if self:CheckHasExploreCache() then
        XLog.Error("请客户端检查，存在格子未播从 未探索-已探索 的表现 " .. XLog.Dump(self.ExploreCache))
        self:PlayCacheExploreGrids()
    end

    -- 缓存起来，在PlayCacheExploreGrids播放表现
    self.ExploreCache = data
end

-- 检查是否有探索缓存未处理
function XRogueSimScene:CheckHasExploreCache(gridId)
    if XTool.IsTableEmpty(self.ExploreCache) then
        return false
    end

    -- 指定格子Id
    if gridId then
        for _, id in ipairs(self.ExploreCache.GridIds) do
            if id == gridId then
                return true
            end
        end
        return false
    end

    return true
end

-- 播放格子已探索
function XRogueSimScene:PlayCacheExploreGrids(gridId, cb)
    local gridIds = self.ExploreCache.GridIds
    gridId = gridId or gridIds[1]
    local localPos = self:GetCameraFollowPointLocalPosition(gridId)
    local distance = CSVector3.Distance(self.CameraFollowPoint.localPosition, localPos)
    local time = math.min(distance / XEnumConst.RogueSim.CameraMoveSpeed, 1) -- 最长为1s

    self:ClearCameraSequence()
    self.CameraSequence = CsTween.DOTween.Sequence()
    self.CameraSequence:Append(self.CameraFollowPoint:DOLocalMove(localPos, time):SetEase(CsTween.Ease.OutQuad):OnComplete(function()
        self:SetGridsExplored(gridIds)
    end))
    self.CameraSequence:AppendInterval(XEnumConst.RogueSim.MapCloudAnimTime + 0.2)
    self.CameraSequence.onComplete = function()
        XLuaUiManager.SetMask(false)
        if cb then cb() end
    end

    XLuaUiManager.SetMask(true)
    self.CameraSequence:Play()
    self.ExploreCache = nil
end

-- 服务器增量下推可见的格子
function XRogueSimScene:OnVisibleGrid(data)
    -- 先缓存，在PlayCacheVisibleGrids播放表现
    self.VisibleCache = self.VisibleCache or {}
    if data.AddType == XEnumConst.RogueSim.AddVisibleGridIdType.ByParent then
        for _, gridId in ipairs(data.GridIds) do
            table.insert(self.VisibleCache, {AddType = data.AddType, GridIds = {gridId}})
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

-- 播放格子可见
function XRogueSimScene:PlayCacheVisibleGrids(cb)
    if not self.VisibleCache then
        if cb then cb() end
        return
    end

    self:ClearCameraSequence()
    self.CameraSequence = CsTween.DOTween.Sequence()

    -- 道具解锁整个区域
    local addType = self.VisibleCache[1].AddType
    if addType == XEnumConst.RogueSim.AddVisibleGridIdType.ByArea then
        for _, data in ipairs(self.VisibleCache) do
            self:SetGridsVisibled(data.GridIds)
        end
        -- TODO 镜头表现
        self.VisibleCache = nil

    -- 灯塔解锁点位
    elseif addType == XEnumConst.RogueSim.AddVisibleGridIdType.ByParent then
        local originPointPos = self.CameraFollowPoint.localPosition
        local pointPos = self.CameraFollowPoint.localPosition

        -- 点位逐个解锁
        for _, data in ipairs(self.VisibleCache) do
            local localPos = self:GetCameraFollowPointLocalPosition(data.GridIds[1])
            local distance = CSVector3.Distance(pointPos, localPos)
            local time = math.min(distance / XEnumConst.RogueSim.CameraMoveSpeed, 1) -- 最长为1s
            self.CameraSequence:Append(self.CameraFollowPoint:DOLocalMove(localPos, time):SetEase(CsTween.Ease.OutQuad):OnComplete(function()
                self:SetGridsVisibled(data.GridIds)
            end))
            self.CameraSequence:AppendInterval(XEnumConst.RogueSim.MapCloudAnimTime + 0.2)
            pointPos = localPos
        end

        -- 镜头回到最初位置
        local originDistance = CSVector3.Distance(pointPos, originPointPos)
        local backTime = math.min(originDistance / XEnumConst.RogueSim.CameraMoveSpeed, 1) -- 最长为1s
        self.CameraSequence:Append(self.CameraFollowPoint:DOLocalMove(originPointPos, backTime):SetEase(CsTween.Ease.OutQuad))
        self.CameraSequence.onComplete = function()
            XLuaUiManager.SetMask(false)
            if cb then cb() end
        end

        XLuaUiManager.SetMask(true)
        self.CameraSequence:Play()
        self.VisibleCache = nil
    end
end

function XRogueSimScene:ClearCameraSequence()
    if self.CameraSequence then
        self.CameraSequence:Kill()
        self.CameraSequence = nil
    end
end

-- 资源变化
function XRogueSimScene:OnResourceChange()
    -- 视野范围变化
    local sightRange = self._MainControl.ResourceSubControl:GetResourceOwnCount(XEnumConst.RogueSim.ResourceId.SightRange)
    if self.SightRange ~= sightRange then
        self.SightRange = sightRange
        self:OnSightRangeChange()
    end

    -- 刷新主城可升级按钮
    self.GridDic[self.MainGridId]:RefreshMainLevelUp()
end

-- 视野范围变化
function XRogueSimScene:OnSightRangeChange()
    local exploredIds = self._MainControl.MapSubControl:GetExploredGridIds()
    for _, gridId in ipairs(exploredIds) do
        self:SetGridAroundCanBeSeen(gridId, self.SightRange)
    end
end

-- 主城升级
function XRogueSimScene:OnMainLevelUp()
    self.GridDic[self.MainGridId]:OnMainLevelUp()

    -- 区域解锁
    local mainLv = self._MainControl:GetCurMainLevel()
    local id = self._MainControl:GetMainLevelConfigId(mainLv)
    local areaIdx = self._MainControl:GetMainLevelUnlockAreaIdx(id)
    local areaIds = self._MainControl.MapSubControl:GetAreaIds()
    local areaId = areaIds[areaIdx]
    if areaId then
        self:OnUnlockArea(areaId)
    end
end

-- 解锁区域
function XRogueSimScene:OnUnlockArea(areaId)
    local areaGridsCfg = self._MainControl.MapSubControl:GetRogueSimAreaGridConfigs(areaId)
    for _, gridCfg in pairs(areaGridsCfg) do
        local grid = self.GridDic[gridCfg.Id]
        grid:SetAreaUnlock()
    end
end

-- 添加建筑
function XRogueSimScene:OnBuildingAdd(gridId)
    self.GridDic[gridId]:OnBuildingAdd()
end

-- 建筑购买
function XRogueSimScene:OnBuildingBuy(gridId)
    self.GridDic[gridId]:OnBuildingBuy()
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
    local ChangeType = {None = 1, Add = 1, Remove = 2}

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

-- 释放
function XRogueSimScene:OnRelease()
    self.GoInputHandler:RemoveAllListeners()
    self.RogueSimHelper:Clear()
    self:ClearLoadGridTimer()
    self:ClearUpdateTimer()
    self:ClearCameraSequence()

    for _, grid in pairs(self.GridDic) do
        grid:Release()
    end
    if self.GameObject then
        CS.UnityEngine.GameObject.Destroy(self.GameObject)
        self.GameObject = nil
    end
    if self.Resource then
        self.Resource:Release()
        self.Resource = nil
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
            local isInView = CS.XUiHelper.IsInView(self.UiNearCamera, grid.Grid3D.Transform.position, -0.3, 1.3, -0.3, 1.3)
            grid:SetShow(isInView)
        end
    end
end

function XRogueSimScene:CameraFocusMainGrid(cb)
    self:CameraFocusGrid(self.MainGridId, cb)
end

-- 镜头聚焦格子
function XRogueSimScene:CameraFocusGrid(gridId, cb)
    local localPos = self:GetCameraFollowPointLocalPosition(gridId)
    self:CameraFocusPos(localPos, cb)
end

-- 镜头聚焦位置
function XRogueSimScene:CameraFocusPos(localPos, cb)
    local distance = CSVector3.Distance(self.CameraFollowPoint.localPosition, localPos)
    if distance < 0.1 then
        if cb then cb() end
        return
    end

    local time = math.min(distance / XEnumConst.RogueSim.CameraMoveSpeed, 1) -- 最长为1s
    XLuaUiManager.SetMask(true)
    self.CameraFollowPoint:DOLocalMove(localPos, time):SetEase(CsTween.Ease.OutQuad):OnComplete(function()
        XLuaUiManager.SetMask(false)
        if cb then cb() end
    end)
end

-- 计算格子对应CameraFollowPoint的localposition
function XRogueSimScene:GetCameraFollowPointLocalPosition(gridId)
    local gridPos = self:GetWorldPosByGridId(gridId) -- 格子世界坐标
    local linkPos = self.PanelDrag.transform.position -- 挂点世界坐标
    local localPos = CS.UnityEngine.Vector3(gridPos.x - linkPos.x, gridPos.z - linkPos.z, self.CameraFollowPoint.localPosition.z)
    return localPos
end

-- 保存镜头位置
function XRogueSimScene:SaveLastCameraFollowPointPos()
    self._MainControl.MapSubControl:SaveLastCameraFollowPointPos(self.CameraFollowPoint.localPosition)
end


-- 获取地图点位传闻列表
function XRogueSimScene:GetGridTipList()
    local curTurnNumber = self._MainControl:GetCurTurnNumber()
    local grids = {} -- 触发传闻的格子
    local citys = {} -- 所有陈邦

    for _, grid in pairs(self.GridDic) do
        if grid.LandformId ~= 0 then
            local landCfg = self._MainControl.MapSubControl:GetRogueSimLandformConfig(grid.LandformId)
            -- 记录当前回合触发传闻的点位
            if not grid.IsExplored and landCfg.TipId ~= 0 and landCfg.TipTurnNumber ~= 0 and curTurnNumber % landCfg.TipTurnNumber == 0 then
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

-- 获取云雾未解锁材质
function XRogueSimScene:GetCloudUnlockMaterial(areaId)
    if not self.CloudMatDic then
        self.CloudMatDic = {}
        local areaIds = self._MainControl.MapSubControl:GetAreaIds()
        for i, aid in ipairs(areaIds) do
            -- 第一个区域无未解锁材质
            if i ~= 1 then
                local meshRender = self["Cloud"..tostring(i)]:GetComponent(typeof(CS.UnityEngine.MeshRenderer))
                self.CloudMatDic[aid] = meshRender.material
            end
        end
    end
    return self.CloudMatDic[areaId]
end

function XRogueSimScene:GetGrid(gridId)
    return self.GridDic[gridId]
end


--region 加载场景
-- 异步加载场景
function XRogueSimScene:LoadSceneAsync(loadCompleteCb)
    self.LoadCompleteCb = loadCompleteCb    -- 加载完成回调
    local sceneAssetUrl = self._MainControl:GetClientConfig("ScenePath", 1)
    self.Resource = CS.XResourceManager.LoadAsync(sceneAssetUrl)
    CS.XTool.WaitCoroutine(self.Resource, function()
        if not self.Resource.Asset then
            XLog.Error("XRogueSimScene LoadSceneAsync error, instantiate error, name: " .. sceneAssetUrl)
            return
        end
        self.GameObject = CS.UnityEngine.Object.Instantiate(self.Resource.Asset)
        self:OnLoadSceneComplete()
    end)
end

-- 场景加载完毕回调
function XRogueSimScene:OnLoadSceneComplete()
    local sceneRoot = self.GameObject.transform:FindTransform("UiRogueSim").transform
    self.RogueSimHelper = sceneRoot.gameObject:AddComponent(typeof(CS.XRogueSimHelper))
    self.RogueSimHelper:SetDarkenValue(XEnumConst.RogueSim.MapDarkenValue)

    self.SceneGridList = sceneRoot:FindTransform("SceneGridList")
    self.SceneGrid = sceneRoot:FindTransform("SceneGrid")
    self.SceneGrid.gameObject:SetActiveEx(false)
    self.UiGridCanvas = sceneRoot:FindTransform("UiGridCanvas")
    self.UiGridCanvas.gameObject:SetActiveEx(false)

    self.EffectLink = sceneRoot:FindTransform("EffectLink")
    self.CloudEffect1 = sceneRoot:FindTransform("CloudEffect1")
    self.CloudEffect1.gameObject:SetActiveEx(false)
    self.GridSelectEffect1 = sceneRoot:FindTransform("GridSelectEffect1")
    self.GridSelectEffect1.gameObject:SetActiveEx(false)
    self.GridSelectEffect2 = sceneRoot:FindTransform("GridSelectEffect2")
    self.GridSelectEffect2.gameObject:SetActiveEx(false)

    self.Cloud1 = sceneRoot:FindTransform("RogueSim_CloudHex01")
    self.Cloud1.gameObject:SetActiveEx(false)
    self.Cloud2 = sceneRoot:FindTransform("RogueSim_CloudHex02")
    self.Cloud2.gameObject:SetActiveEx(false)
    self.Cloud3 = sceneRoot:FindTransform("RogueSim_CloudHex03")
    self.Cloud3.gameObject:SetActiveEx(false)

    self.UiNearCamera = sceneRoot:FindTransform("UiNearCamera"):GetComponent("Camera")
    self.PanelDrag = sceneRoot:FindTransform("PanelDrag"):GetComponent("XDragMove")
    self.CameraFollowPoint = sceneRoot:FindTransform("CameraFollowPoint"):GetComponent("RectTransform")

    -- 点击格子
    self.GoInputHandler = sceneRoot:FindTransform("ColiderPanel"):GetComponent(typeof(CS.XGoInputHandler))
    self.GoInputHandler:AddPointerClickListener(function(eventData)
        local position = eventData.pointerCurrentRaycast.worldPosition
        local gridPos = self:GetGridPosByWorldPos(position)
        local grid = self:GetGridByGridPos(gridPos.x, gridPos.y)
        self:OnGridClick(grid)
    end)
    -- 拖拽时相机
    self.GoInputHandler:AddDragListener(function(eventData)
        self.PanelDrag:OnDrag(eventData)
    end)

    self:GenerateGridList()
    self:LoadGridAsync()
end

-- 生成格子列表
function XRogueSimScene:GenerateGridList()
    -- 计算解锁区域
    local unlockAreaIdx = {}
    local mainLv = self._MainControl:GetCurMainLevel()
    for lv = 1, mainLv do
        local id = self._MainControl:GetMainLevelConfigId(lv)
        local areaIdx = self._MainControl:GetMainLevelUnlockAreaIdx(id)
        if areaIdx ~= 0 then
            unlockAreaIdx[areaIdx] = true
        end
    end

    -- 创建格子，记录子格子
    local areaIds = self._MainControl.MapSubControl:GetAreaIds()
	local XRogueSimGrid = require("XModule/XRogueSim/XEntity/Scene/XRogueSimGrid")
    for i, areaId in ipairs(areaIds) do
        local isAreaUnlock = unlockAreaIdx[i] == true
        local areaGridsCfg = self._MainControl.MapSubControl:GetRogueSimAreaGridConfigs(areaId)
        for _, gridCfg in pairs(areaGridsCfg) do
            local grid = XRogueSimGrid.New(self, gridCfg, isAreaUnlock)
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
            elseif landCfg.LandType == XEnumConst.RogueSim.LandformType.City then
                table.insert(self.CityGridIds, grid.Id)
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
            local areaIds = self._MainControl.MapSubControl:GetAreaIds()
            XLog.Error(string.format("服务器下发的已探索格子格子Id=%s不存在 ，当前地图由以下区域组成%s", gridId, XLog.Dump(areaIds)))
            goto CONTINUE
        end

        grid:SetExplored()
        grid:SetCanExplore()
        grid:SetCanBeSeen()

        -- 根据已探索格子周围1格，确定格子是否可探索
        local exploreOffsets = self:GetAroundGridsOffset(gridId, 1)
        for _, offset in ipairs(exploreOffsets) do
            local aroundGrid = self:GetGridByGridPos(grid.PosX + offset.x, grid.PosY + offset.y)
            if aroundGrid then
                -- 占多格建筑则一并可探索
                local parentId = aroundGrid:GetParentId()
                self.GridDic[parentId]:SetCanExplore()
                local childIds = self:GetChilds(parentId)
                for _, childId in ipairs(childIds or {}) do
                    self.GridDic[childId]:SetCanExplore()
                end
            end
        end

        -- 根据已探索格子和视距，确定格子是否可见
        self:SetGridAroundCanBeSeen(gridId, self.SightRange)

        :: CONTINUE ::
    end
end

-- 设置格子周围的格子可见
function XRogueSimScene:SetGridAroundCanBeSeen(gridId, range)
    local grid = self:GetGrid(gridId)
    local seenOffsets = self:GetAroundGridsOffset(gridId, range)
    for _, offset in ipairs(seenOffsets) do
        local aroundGrid = self:GetGridByGridPos(grid.PosX + offset.x, grid.PosY + offset.y)
        if aroundGrid then
            -- 占多格建筑则一并可见
            local parentId = aroundGrid:GetParentId()
            self.GridDic[parentId]:SetCanBeSeen()
            local childIds = self:GetChilds(parentId)
            for _, childId in ipairs(childIds or {}) do
                self.GridDic[childId]:SetCanBeSeen()
            end
        end
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

    if cb then
        self:ClearVisibleTimer()
        XLuaUiManager.SetMask(true)
        self.VisibleTimer = XScheduleManager.ScheduleOnce(function()
            XLuaUiManager.SetMask(false)
            self.VisibleTimer = nil
            cb()
        end, XEnumConst.RogueSim.MapCloudAnimTime * 1000)
    end
end

function XRogueSimScene:ClearVisibleTimer()
    if self.VisibleTimer then
        XScheduleManager.UnSchedule(self.VisibleTimer)
        self.VisibleTimer = nil
    end
end

-- 格子异步加载
function XRogueSimScene:LoadGridAsync()
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

    local worldPos = self:GetWorldPosByGridPos(maxPosX, maxPosY)
    local offset = self._MainControl:GetClientConfigParams("CameraPanelDragSizeOffset")
    local width = worldPos.x + tonumber(offset[1] or 0)
    local height = worldPos.z + tonumber(offset[2] or 0)
    local posX = worldPos.x / 2
    local posY = worldPos.z / 2
    local rect = self.PanelDrag.transform:GetComponent("RectTransform")
    rect.sizeDelta = CS.UnityEngine.Vector2(width, height)
    rect.localPosition = CS.UnityEngine.Vector3(posX, posY)
end

-- 初始化摄像机位置
function XRogueSimScene:InitCameraPos()
    local pos = self._MainControl.MapSubControl:GetLastCameraFollowPointPos()
    if not pos then 
        pos = self:GetCameraFollowPointLocalPosition(self.MainGridId)
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
    local grid = self.GridDic[gridId]
    return self:GetWorldPosByGridPos(grid.PosX, grid.PosY)
end

-- 格子坐标转换为世界坐标
function XRogueSimScene:GetWorldPosByGridPos(posX, posY)
	local cos30 = 0.866
	local gridSize = XEnumConst.RogueSim.MapGridSize
	local x = posX * 1.5 * gridSize
    local y = (2 * posY - posX % 2) * cos30 * gridSize
    return CS.UnityEngine.Vector3(x, 0, y)
end

-- 世界坐标转格子坐标
function XRogueSimScene:GetGridPosByWorldPos(worldPos)
	local cos30 = 0.866
	local gridSize = XEnumConst.RogueSim.MapGridSize
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
            angle = 180 - angle -- 120°=60°
        end
        local centerToSideAngle = math.abs(angle - 30) -- 20°=10°, 51°=21° 
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
            angle = 180 - angle -- 120°=60°
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
        local areaIds = self._MainControl.MapSubControl:GetAreaIds()
        XLog.Error(string.format("出现相同PosX = %s, PosY = %s ，请检查区域表RogueSimAreaGrid.tab，当前地图由以下区域组成%s", posX, posY, XLog.Dump(areaIds)))
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
        return remainder == 0 and XEnumConst.RogueSim.AroundGridsOffset0 or XEnumConst.RogueSim.AroundGridsOffset1
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
    local centerPos = {x = 0, y = 0}
    local finishGridDic = {}
    finishGridDic[GetPosKey(centerPos)] = true

    local tempGrids = {centerPos}
    while(distance > 0) do
        local newGrids = {}
        for _, grid in ipairs(tempGrids) do
            local gridRemainder = (grid.x + gridPosX) % 2
            local offsets = gridRemainder == 0 and XEnumConst.RogueSim.AroundGridsOffset0 or XEnumConst.RogueSim.AroundGridsOffset1
            for _, offset in ipairs(offsets) do
                local pos = {x = grid.x + offset.x, y = grid.y + offset.y}
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
    local gridIds = {gridId}
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
        effectGo.position = self:GetWorldPosByGridId(id)
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
        if vGrid:GetIsBlock() then
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