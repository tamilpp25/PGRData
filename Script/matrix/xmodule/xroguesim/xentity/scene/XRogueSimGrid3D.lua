-- 肉鸽模拟经营场景3D节点
---@class XRogueSimGrid3D
---@field _Control XRogueSimControl
---@field Scene XRogueSimScene
---@field Grid XRogueSimGrid
local XRogueSimGrid3D = XClass(nil, "XRogueSimGrid3D")

function XRogueSimGrid3D:Ctor(scene, grid)
    self.Scene = scene
    self.Grid = grid
    self._Control = self.Scene._MainControl
    self.IsLoaded = false -- 是否已加载
end

-- 加载
function XRogueSimGrid3D:Load()
    local gridGo = CS.UnityEngine.Object.Instantiate(self.Scene.SceneGrid, self.Scene.SceneGridList)
    self.Transform = gridGo.transform
    self.GameObject = gridGo.gameObject
    self.GameObject:SetActiveEx(true)
    self.Transform.name = tostring(self.Grid.Id)
    self.Transform.position = self.Scene:GetWorldPosByGridId(self.Grid.Id)
    self.IsLoaded = true
    self:OnLoaded()
end

function XRogueSimGrid3D:OnLoaded()
    self.UnderWaterLink = XUiHelper.TryGetComponent(self.Transform, "UnderWaterLink")
    self.TerrainLink = XUiHelper.TryGetComponent(self.Transform, "TerrainLink")
    self.LandformLink = XUiHelper.TryGetComponent(self.Transform, "LandformLink")
    self.CloudLink = XUiHelper.TryGetComponent(self.Transform, "CloudLink")
    self.ExploredEffectLink = XUiHelper.TryGetComponent(self.Transform, "ExploredEffectLink")
    self.CanExploreEffectLink = XUiHelper.TryGetComponent(self.Transform, "CanExploreEffectLink")

    local underWaterPosY = self.Grid.UnderWaterPosYWan and (self.Grid.UnderWaterPosYWan / 10000) or 0
    local underWaterHeight = self.Grid.UnderWaterHeightWan and (self.Grid.UnderWaterHeightWan / 10000) or 1
    self.UnderWaterLink.transform.localPosition = XLuaVector3.New(0, underWaterPosY, 0)
    self.UnderWaterLink.transform.localScale = XLuaVector3.New(1, underWaterHeight, 1)
    
    local height = self.Grid.TerrainHeightWan and (self.Grid.TerrainHeightWan / 10000) or 1
    self.TerrainLink.transform.localScale = XLuaVector3.New(1, height, 1)
    local pos = self.LandformLink.transform.localPosition
    local landformPos = XLuaVector3.New(pos.x, self.Scene.TERRAIN_HEIGHT * height, pos.z)
    self.LandformLink.transform.localPosition = landformPos
    self.ExploredEffectLink.transform.localPosition = landformPos
    self.CanExploreEffectLink.transform.localPosition = landformPos
    
    self:RefreshUnderWater()
    self:RefreshTerrain()
    self:RefreshLandform()

    if not self.Grid:GetCanBeSeen() then
        self:LoadCloud()
        self:Darken()
    end
end

function XRogueSimGrid3D:Release()
    self:ClearAnimSequence()

    self.Scene = nil
    self.Grid = nil
    self._Control = nil
    self.Transform = nil
    self.GameObject = nil
    self.TerrainLink = nil
    self.LandformLink = nil
    self.CloudLink = nil
    self.ExploredEffectLink = nil
    self.TerrainMeshRenderer = nil
    self.LandformMeshRenderer = nil
    self.CloudMeshRenderer = nil
end

function XRogueSimGrid3D:Show(isShow)
    if not self.IsLoaded then
        return
    end

    self.GameObject:SetActiveEx(isShow)
    if not isShow then
        self.ExploredEffectLink.gameObject:SetActiveEx(false)
    end
end

-- 刷新水下地形
function XRogueSimGrid3D:RefreshUnderWater()
    if not self.IsLoaded then
        return
    end

    if not self.Grid.UnderWaterId or self.Grid.UnderWaterId == 0 then
        self.UnderWaterLink.gameObject:SetActiveEx(false)
        return
    end

    local terrainCfg = self._Control.MapSubControl:GetRogueSimTerrainConfig(self.Grid.UnderWaterId)
    if terrainCfg.Model == nil then
        self.UnderWaterLink.gameObject:SetActiveEx(false)
        return
    end

    self.UnderWaterLink.gameObject:SetActiveEx(true)
    local go = self.UnderWaterLink.gameObject:LoadPrefab(terrainCfg.Model)

    -- 设置layer
    local layerUiFar = 23
    local allTrans = go.transform:GetComponentsInChildren(typeof(CS.UnityEngine.Transform), true)
    for i = 0, allTrans.Length - 1 do
        allTrans[i].gameObject.layer = layerUiFar
    end
end

-- 更新地形
function XRogueSimGrid3D:RefreshTerrain()
    if not self.IsLoaded then
        return
    end

    if self.Grid.TerrainId == 0 then
        self.TerrainLink.gameObject:SetActiveEx(false)
        return
    end

    local terrainCfg = self._Control.MapSubControl:GetRogueSimTerrainConfig(self.Grid.TerrainId)
    if terrainCfg.Model == nil then
        self.TerrainLink.gameObject:SetActiveEx(false)
        return
    end
    
    -- 相同模型不刷新
    if self.TerrainModelPath == terrainCfg.Model then return end

    self.TerrainLink.gameObject:SetActiveEx(true)
    self.TerrainModelPath = terrainCfg.Model
    local go = self.TerrainLink.gameObject:LoadPrefab(terrainCfg.Model)
    self.TerrainMeshRenderer = go:GetComponentInChildren(typeof(CS.UnityEngine.MeshRenderer))
    
    -- 点击和拖拽事件
    self.TerrainMeshRenderer.gameObject:AddComponent(typeof(CS.UnityEngine.MeshCollider))
    self.GoInputHandler = self.TerrainMeshRenderer.gameObject:AddComponent(typeof(CS.XGoInputHandler))
    self.GoInputHandler:AddPointerClickListener(function(eventData)
        if self.Grid:IsCanClick() then
            XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, self.Scene.CLICK_CUE_ID)
        end
        self.Grid:OnGridClick() 
    end)
    self.GoInputHandler:AddDragListener(function(eventData) self.Grid.Scene:OnSceneDrag(eventData) end)
    -- 监听pc滚轮
    self.GoInputHandler.IsMidButtonEventEnable = true
    self.GoInputHandler:AddMidButtonScrollUpListener(function(val)
        XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_MID_BUTTON_SCROLL_UP, val)
    end)
    self.GoInputHandler:AddMidButtonScrollDownListener(function(val)
        XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_MID_BUTTON_SCROLL_DOWN, val)
    end)

    -- 设置layer TODO 预设改完可删除
    local layerUiFar = 23
    local allTrans = go.transform:GetComponentsInChildren(typeof(CS.UnityEngine.Transform), true)
    for i = 0, allTrans.Length - 1 do
        allTrans[i].gameObject.layer = layerUiFar
    end
end

-- 更新地貌
function XRogueSimGrid3D:RefreshLandform()
    -- 刷新可探索特效
    self:RefreshCanExploreEffect()
    
    if not self.IsLoaded then
        return
    end

    if self.Grid.LandformId == 0 then
        self.LandformLink.gameObject:SetActiveEx(false)
        return
    end

    local landformCfg = self._Control.MapSubControl:GetRogueSimLandformConfig(self.Grid.LandformId)
    if landformCfg.Model == nil then
        self.LandformLink.gameObject:SetActiveEx(false)
        return
    end

    self.LandformLink.gameObject:SetActiveEx(true)
    local scale = landformCfg.ScaleWan / 10000
    local rotationY = landformCfg.RotationYWan / 10000
    self.LandformLink.transform.localScale = XLuaVector3.New(scale, scale, scale)
    self.LandformLink.transform.eulerAngles = XLuaVector3.New(0, rotationY, 0)
    local go = self.LandformLink:LoadPrefab(landformCfg.Model)
    self.LandformMeshRenderer = go:GetComponentInChildren(typeof(CS.UnityEngine.MeshRenderer))
    local worldPos = self.Scene:GetGridChildsCenterWorldPos(self.Grid.Id)
    local landPosY = self.LandformLink.transform.position.y
    self.LandformLink.transform.position = CS.UnityEngine.Vector3(worldPos.x, landPosY, worldPos.z)

    -- 设置layer
    local layerDefault = 0
    local allTrans = go.transform:GetComponentsInChildren(typeof(CS.UnityEngine.Transform), true)
    for i = 0, allTrans.Length - 1 do
        allTrans[i].gameObject.layer = layerDefault
    end

    self:RefreshLandformShow()
end

-- 刷新地貌的显示
function XRogueSimGrid3D:RefreshLandformShow()
    if self.LandformLink then
        local canBeSeen = self.Grid:GetCanBeSeen()
        self.LandformLink.gameObject:SetActiveEx(canBeSeen)
    end
end

-- 加载云雾
function XRogueSimGrid3D:LoadCloud()
    if not self.IsLoaded or self.CloudMeshRenderer then
        return
    end

    local CSInstantiate = CS.UnityEngine.Object.Instantiate
    local cloudGo = CSInstantiate(self.Scene.Cloud, self.CloudLink)
    cloudGo.gameObject:SetActiveEx(true)
    self.CloudMeshRenderer = cloudGo:GetComponent(typeof(CS.UnityEngine.MeshRenderer))
end

-- 云雾解锁
function XRogueSimGrid3D:UnlockCloud(isGetRender)
    if not self.IsLoaded or not self.CloudMeshRenderer or self.IsDissolve then
        return
    end

    if isGetRender then
        return self.CloudMeshRenderer
    end

    -- 设置为区域解锁云朵材质
    self.Scene.RogueSimHelper:RevertAlteredCloud(self.CloudMeshRenderer, self.Grid.Scene.MAP_CLOUND_ANIM_TIME)
end

-- 移除云雾
function XRogueSimGrid3D:RemoveCloud(isGetRender)
    if not self.IsLoaded or not self.CloudMeshRenderer or self.IsDissolve then
        return
    end

    self.IsDissolve = true
    self:RefreshLandformShow()
    if isGetRender then
        return self.CloudMeshRenderer
    end

    self.Scene.RogueSimHelper:DissolveCloudRenderer(self.CloudMeshRenderer, self.Grid.Scene.MAP_CLOUND_ANIM_TIME, false)
end

-- 设置压黑
function XRogueSimGrid3D:Darken()
    if not self.IsLoaded or self.IsDark then
        return
    end

    self.IsDark = true
    if self.TerrainMeshRenderer then
        self.Scene.RogueSimHelper:DarkenRenderer(self.TerrainMeshRenderer, true)
    end
    if self.LandformMeshRenderer then
        self.Scene.RogueSimHelper:DarkenRenderer(self.LandformMeshRenderer, true)
    end
end

-- 移除压黑
function XRogueSimGrid3D:RemoveDarken(isGetRender)
    if not self.IsLoaded or not self.IsDark then
        return
    end

    self.IsDark = false
    if isGetRender then
        return self.TerrainMeshRenderer, self.LandformMeshRenderer
    end

    if self.TerrainMeshRenderer then
        self.Scene.RogueSimHelper:TurnDarkenRendererIntoLight(self.TerrainMeshRenderer, true, self.Grid.Scene.MAP_DARK_TO_LIGHT_TIME)
    end
    if self.LandformMeshRenderer then
        self.Scene.RogueSimHelper:TurnDarkenRendererIntoLight(self.LandformMeshRenderer, true, self.Grid.Scene.MAP_DARK_TO_LIGHT_TIME)
    end
end

-- 加载已探索特效
function XRogueSimGrid3D:LoadExploredEffect()
    if not self.IsLoaded then
        return
    end

    local landType = self.Grid:GetLandType()
    local effectPath
    if landType == XEnumConst.RogueSim.LandformType.City then
        effectPath = self._Control:GetClientConfig("CityExploredEffect")
    end

    if effectPath then
        self.ExploredEffectLink.gameObject:SetActiveEx(true)
        self.ExploredEffectLink:LoadPrefab(effectPath, false)
    end
end

-- 加载升级成功特效
function XRogueSimGrid3D:LoadLevelUpEffect()
    if not self.IsLoaded then
        return
    end

    local landType = self.Grid:GetLandType()
    local effectPath
    if landType == XEnumConst.RogueSim.LandformType.Main then
        effectPath = self._Control:GetClientConfig("MainLevelUpEffect")
    elseif landType == XEnumConst.RogueSim.LandformType.City then
        effectPath = self._Control:GetClientConfig("CityExploredEffect")
    end

    if effectPath then
        self.ExploredEffectLink:LoadPrefab(effectPath, false)
        self.ExploredEffectLink.gameObject:SetActive(false)
        self.ExploredEffectLink.gameObject:SetActive(true)
    end
end

-- 加载建造成功特效
function XRogueSimGrid3D:LoadBuildSuccessEffect()

    if not self.IsLoaded then
        return
    end

    local landType = self.Grid:GetLandType()
    local effectPath
    if landType == XEnumConst.RogueSim.LandformType.Building then
        effectPath = self._Control:GetClientConfig("BuildingEffect")
    end

    if effectPath then
        self.ExploredEffectLink.gameObject:SetActiveEx(true)
        self.ExploredEffectLink:LoadPrefab(effectPath, false)
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, self.Scene.BUILD_SUCCESS_CUE_ID)
    end
end

-- 刷新可探索特效
function XRogueSimGrid3D:RefreshCanExploreEffect()
    if not self.IsLoaded then
        return
    end

    -- 看不到
    if not self.Grid:GetCanBeSeen() then
        self.CanExploreEffectLink.gameObject:SetActiveEx(false)
        return 
    end
    
    local landType = self.Grid:GetLandType()
    local isShowEffect = false
    if landType == XEnumConst.RogueSim.LandformType.Prop or landType == XEnumConst.RogueSim.LandformType.Resource then
        isShowEffect = self.Grid:GetCanExplore()
    elseif landType == XEnumConst.RogueSim.LandformType.Event then
        local eventData = self._Control.MapSubControl:GetEventDataByGridId(self.Grid:GetId())
        local eventGambleData = self._Control.MapSubControl:GetCanGetEventGambleDataByGridId(self.Grid:GetId())
        if not self.Grid:GetIsExplored() or eventData ~= nil or eventGambleData ~= nil then -- 有未处理事件或者有未处理的事件投机
            isShowEffect = true
        end
    elseif landType == XEnumConst.RogueSim.LandformType.BuildingField then
        isShowEffect = true
    end 
    if isShowEffect then
        local effectPath = self._Control:GetClientConfig("GridCanExploreEffect")
        self.CanExploreEffectLink:LoadPrefab(effectPath, false)
    end
    self.CanExploreEffectLink.gameObject:SetActiveEx(isShowEffect)
end

-- 播放格子变化动画
-- beforeLastAnimCb 在最后一个动画播放前执行回调
-- endCb 在动画结束时候执行回调
function XRogueSimGrid3D:PlayGridChangeAnim(beforeLastAnimCb, endCb)
    self:ClearAnimSequence()
    local originPos = self.TerrainLink.localPosition
    local CsTween = CS.DG.Tweening
    self.TweenSequence = CsTween.DOTween.Sequence()

    -- 根据间隔设置时间
    local landmarkGridId = self.Scene:GetAreaLandmarkGridId(self.Grid.AreaId)
    if landmarkGridId then
        local distance = self.Scene:GetGridDistance(landmarkGridId, self.Grid.Id)
        local timeInterval = self._Control:GetClientConfig("GridChangeTimeInterval")
        local intervalTime = (distance - 1) * tonumber(timeInterval)
        if intervalTime > 0 then
            self.TweenSequence:AppendInterval(intervalTime)
        end
    end

    local params = self._Control:GetClientConfigParams("GridChangeAnim")
    local animCnt = #params / 2
    for i = 1, animCnt do
        local index1 = i * 2 - 1
        local index2 = i * 2
        local posY = tonumber(params[index1])
        local time = tonumber(params[index2])
        local animPos = XLuaVector3.New(originPos.x, posY, originPos.z)
        if i == animCnt - 1 then
            -- 在最后一个动画开始播放前执行回调
            self.TweenSequence:Append(self.TerrainLink:DOLocalMove(animPos, time):SetEase(CsTween.Ease.OutQuad):OnComplete(function()
                XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, self.Scene.TERRAIN_CHANGE_CUE_ID)
                if beforeLastAnimCb then beforeLastAnimCb() end
            end))
        else
            if self.Grid.TerrainId == 0 then
                -- 格子变化前无地形，跳过动画表现，直接设置位置
                self.TerrainLink.transform.localPosition = animPos
            else
                self.TweenSequence:Append(self.TerrainLink:DOLocalMove(animPos, time):SetEase(CsTween.Ease.OutQuad))
            end
        end
    end
    self.TweenSequence.onComplete = function()
        self.TerrainLink.localPosition = originPos
        if endCb then endCb() end
        self:ClearAnimSequence()
    end
    self.TweenSequence:Play()
end

function XRogueSimGrid3D:ClearAnimSequence()
    if self.TweenSequence then
        self.TweenSequence:Kill()
        self.TweenSequence = nil
    end
end

return XRogueSimGrid3D
