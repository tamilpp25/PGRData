-- 肉鸽模拟经营场景地图节点
---@class XRogueSimGrid
---@field _Control XRogueSimControl
---@field Grid2D XRogueSimGrid2D
---@field Grid3D XRogueSimGrid3D
---@field Scene XRogueSimScene
local XRogueSimGrid = XClass(nil, "XRogueSimGrid")

---@param scene XRogueSimScene
function XRogueSimGrid:Ctor(scene, gridCfg, areaIsUnlock, sreaCanUnlock)
    self.Scene = scene
    self._Control = scene._MainControl
    self.Id = gridCfg.Id
    self.AreaId = gridCfg.AreaId
    self.PosX = gridCfg.PosX
    self.PosY = gridCfg.PosY
    self.UnderWaterId = gridCfg.UnderWaterId
    self.TerrainId = gridCfg.TerrainId
    self.LandformId = gridCfg.LandformId
    self.ParentId = gridCfg.ParentId
    self.UnderWaterPosYWan = gridCfg.UnderWaterPosYWan
    self.UnderWaterHeightWan = gridCfg.UnderWaterHeightWan
    self.TerrainHeightWan = gridCfg.TerrainHeightWan

    self.AreaIsUnlock = areaIsUnlock   -- 区域是否已解锁
    self.AreaCanUnlock = sreaCanUnlock -- 区域是否可解锁
    self.IsExplored = false            -- 是否已探索
    self.IsPreview = false             -- 是否可预览，服务器下发的visibleId + 地貌表配置IsPreview为1

    self:InitLandformId()
    local XRogueSimGrid3D = require("XModule/XRogueSim/XEntity/Scene/XRogueSimGrid3D")
    self.Grid3D = XRogueSimGrid3D.New(self.Scene, self)
    local XRogueSimGrid2D = require("XModule/XRogueSim/XEntity/Scene/XRogueSimGrid2D")
    self.Grid2D = XRogueSimGrid2D.New(self.Scene, self)
end

-- 加载
function XRogueSimGrid:Load()
    self.Grid3D:Load()
    self.Grid2D:Refresh()
end

-- 释放
function XRogueSimGrid:Release()
    self.Grid3D:Release()
    self.Grid3D = nil
    self.Grid2D:Release()
    self.Grid2D = nil
    self.Scene = nil
    self._Control = nil
end

-- 设置区域已解锁
function XRogueSimGrid:SetAreaUnlock()
    self.AreaIsUnlock = true
    self.AreaCanUnlock = true
    self.Grid3D:RefreshLandformShow()
    self.Grid3D:RefreshCanExploreEffect()
    self.Grid2D:Refresh()
end

-- 设置区域可解锁
function XRogueSimGrid:SetAreaCanUnlock()
    self.AreaCanUnlock = true
    self.Grid3D:RefreshLandformShow()
    self.Grid2D:Refresh()
end

-- 设置已探索
function XRogueSimGrid:SetIsExplored()
    if not self.IsExplored then
        self.IsExplored = true
        self:CheckChangeLandform()
        self.Grid3D:RefreshLandform()
        self.Grid3D:LoadExploredEffect()
        self.Grid2D:Refresh()
    end
end

-- 获取是否已探索
function XRogueSimGrid:GetIsExplored()
    return self.IsExplored
end

-- 获取是否可探索
function XRogueSimGrid:GetCanExplore()
    return self.AreaIsUnlock and not self:GetIsExplored()
end

-- 获取是否可见
function XRogueSimGrid:GetCanBeSeen()
    if self.AreaIsUnlock then return true end
    return self.AreaCanUnlock and (self.IsPreview or self.IsExplored)
end

-- 设置可预览
function XRogueSimGrid:SetIsPreview()
    self.IsPreview = true
end

-- 设置显示/隐藏
function XRogueSimGrid:SetShow(isShow)
    self.Grid3D:Show(isShow)
    self.Grid2D:Show(isShow)
end

-- 解锁云雾
function XRogueSimGrid:UnlockCloud(isGetRender)
    return self.Grid3D:UnlockCloud(isGetRender)
end

-- 移除云雾
function XRogueSimGrid:RemoveCloud(isGetRender)
    return self.Grid3D:RemoveCloud(isGetRender)
end

-- 移除压黑
function XRogueSimGrid:RemoveDarken(isGetRender)
    return self.Grid3D:RemoveDarken(isGetRender)
end

-- 刷新主城可升级按钮
function XRogueSimGrid:RefreshMainLevelUp()
    self.Grid2D:Refresh()
end

-- 刷新城邦可升级按钮
function XRogueSimGrid:RefreshCityLevelUp()
    self.Grid2D:Refresh()
end

-- 刷新城邦购买面板
function XRogueSimGrid:RefreshCityBuyPanel()
    self.Grid2D:Refresh()
end

-- 刷新城邦任务
function XRogueSimGrid:RefreshTask()
    self.Grid2D:Refresh()
end

-- 刷新事件
function XRogueSimGrid:RefreshEvent()
    self.Grid2D:Refresh()
end

-- 主城升级
function XRogueSimGrid:OnMainLevelUp()
    self:CheckChangeLandform()
    self.Grid3D:RefreshLandform()
    self.Grid2D:Refresh()
end

-- 城邦升级
function XRogueSimGrid:OnCityLevelUp()
    self:CheckChangeLandform()
    self.Grid3D:RefreshLandform()
    self.Grid2D:Refresh()
end

-- 添加建筑
function XRogueSimGrid:OnBuildingAdd()
    self:CheckChangeLandform()
    self.Grid3D:RefreshLandform()
    self.Grid2D:Refresh()
end

-- 格子变化
function XRogueSimGrid:OnGridChange(gridData)
    local oldTerrainId = self.TerrainId
    if gridData.TerrainId and gridData.TerrainId ~= -1 then
        self.TerrainId = gridData.TerrainId
    end
    if gridData.LandformId ~= -1 then
        self.LandformId = gridData.LandformId
    end
    self.ParentId = gridData.ParentId
    self:CheckChangeLandform()

    if oldTerrainId ~= self.TerrainId then
        self.Grid3D:PlayGridChangeAnim(function()
            self.Grid3D:RefreshTerrain()
        end, function()
            self.Grid3D:RefreshLandform()
            self.Grid2D:Refresh()
        end)
    else
        self.Grid3D:RefreshTerrain()
        self.Grid3D:RefreshLandform()
        self.Grid2D:Refresh()
    end
end

-- 增加事件
function XRogueSimGrid:OnEventAdd()
    self.Grid2D:Refresh()
end

-- 移除事件
function XRogueSimGrid:OnEventRemove()
    self:CheckChangeLandform()
    self.Grid3D:RefreshLandform()
    self.Grid2D:Refresh()
end

-- 增加点位奖励选择
function XRogueSimGrid:OnRewardAdd()
    self.Grid2D:Refresh()
end

-- 移除点位奖励选择
function XRogueSimGrid:OnRewardRemove()
    self:CheckChangeLandform()
    self.Grid3D:RefreshLandform()
    self.Grid2D:Refresh()
end

-- 初始化地貌Id
function XRogueSimGrid:InitLandformId()
    -- 服务器随机格子/区域升级改变格子
    local mapData = self._Control.MapSubControl:GetMapData()
    local gridData = mapData:GetGridData(self.Id)
    if gridData then
        if gridData.TerrainId and gridData.TerrainId ~= -1 then
            self.TerrainId = gridData.TerrainId
        end
        if gridData.LandformId ~= -1 then
            self.LandformId = gridData.LandformId
        end
        self.ParentId = gridData.ParentId
    end
    self:CheckChangeLandform()
end

-- 检查改变地貌
function XRogueSimGrid:CheckChangeLandform()
    if self.LandformId == 0 then
        return
    end
    local landformCfg = self._Control.MapSubControl:GetRogueSimLandformConfig(self.LandformId)

    -- 主城升级
    if landformCfg.LandType == XEnumConst.RogueSim.LandformType.Main then
        local curLevel = self._Control:GetCurMainLevel()
        local configId = self._Control:GetMainLevelConfigId(curLevel)
        self.LandformId = self._Control:GetMainLevelLandformId(configId)

        -- 地图只配置1级城邦点、2级城邦点、3级城邦点，需要根据随机到的城邦Id和当前等级确定地貌
    elseif landformCfg.LandType == XEnumConst.RogueSim.LandformType.City then
        local cityData = self._Control.MapSubControl:GetCityDataByGridId(self.Id)
        if cityData then
            local cityLevelConfigId = self._Control.MapSubControl:GetCityLevelConfigIdById(cityData:GetId(), cityData:GetLevel())
            self.LandformId = self._Control.MapSubControl:GetCityLevelLandformId(cityLevelConfigId)
        elseif XEnumConst.RogueSim.IsDebug then
            XLog.Error(tostring(self.Id).."格子没有下发cityData，请服务器老师检查一下！")
        end

        -- 地图预设建筑/自建建筑
    elseif landformCfg.LandType == XEnumConst.RogueSim.LandformType.Building or landformCfg.LandType == XEnumConst.RogueSim.LandformType.BuildingField then
        local buildingData = self._Control.MapSubControl:GetBuildingDataByGridId(self.Id)
        if buildingData then
            self.LandformId = self._Control.MapSubControl:GetBuildingLandformId(buildingData.ConfigId)
        end

        -- 事件处理完成
    elseif landformCfg.LandType == XEnumConst.RogueSim.LandformType.Event then
        local eventData = self._Control.MapSubControl:GetEventDataByGridId(self.Id)
        if self:GetIsExplored() and landformCfg.FinishLandformId ~= 0 and not eventData then
            self.LandformId = landformCfg.FinishLandformId
        end

        -- 道具已选择
    elseif landformCfg.LandType == XEnumConst.RogueSim.LandformType.Prop then
        local rewardData = self._Control:GetRewardDataByGridId(self.Id)
        if self:GetIsExplored() and landformCfg.FinishLandformId ~= 0 and (not rewardData or rewardData:GetPick()) then
            self.LandformId = landformCfg.FinishLandformId
        end
    elseif self:GetIsExplored() and landformCfg.FinishLandformId ~= 0 then
        self.LandformId = landformCfg.FinishLandformId
    end
end

function XRogueSimGrid:GetId()
    return self.Id
end

-- 获取父格子id
function XRogueSimGrid:GetParentId()
    return self.ParentId ~= 0 and self.ParentId or self.Id
end

-- 获取地貌
function XRogueSimGrid:GetLandformId()
    return self.LandformId
end

-- 获取名称
function XRogueSimGrid:GetName()
    if self:GetLandType() == XEnumConst.RogueSim.LandformType.City then
        local cityData = self._Control.MapSubControl:GetCityDataByGridId(self.Id)
        if cityData then
            local cityLevelConfigId = self._Control.MapSubControl:GetCityLevelConfigIdById(cityData:GetId(), cityData:GetLevel())
            return self._Control.MapSubControl:GetCityLevelName(cityLevelConfigId)
        end
    end
    if self.LandformId ~= 0 then
        return self._Control.MapSubControl:GetLandformName(self.LandformId)
    end
    return ""
end

-- 获取地貌类型
function XRogueSimGrid:GetLandType()
    if self.LandformId ~= 0 then
        return self._Control.MapSubControl:GetLandformLandType(self.LandformId)
    end

    return 0
end

-- 是否可点击
function XRogueSimGrid:IsCanClick()
    if self:GetCanBeSeen() and self.LandformId ~= 0 and self:GetLandType() ~= XEnumConst.RogueSim.LandformType.Block then
        return true
    end

    -- 区域不可解锁
    if not self.AreaCanUnlock then
        local mapData = self._Control.MapSubControl:GetMapData()
        local areaDatas = mapData:GetAreaDatas()
        local index = 0
        for i, areaData in ipairs(areaDatas) do
            if self.AreaId == areaData.Id then
                index = i
            end
        end

        local levelIds = self._Control:GetMainLevelList()
        for _, id in ipairs(levelIds) do
            local unlockIdxs = self._Control:GetMainLevelUnlockAreaIdxs(id)
            for _, unlockIdx in ipairs(unlockIdxs) do
                if unlockIdx == index then
                    local lv = self._Control:GetMainLevelConfigLevel(id)
                    return false, string.format(self._Control:GetClientConfig("AreaUnlockTips"), lv)
                end
            end
        end

        -- 区域未解锁
    elseif not self.AreaIsUnlock then
        return false, nil
    end
end

-- 获取区域是否已解锁
function XRogueSimGrid:GetAreaIsUnlock()
    return self.AreaIsUnlock
end

-- 获取区域是否可解锁
function XRogueSimGrid:GetAreaCanUnlock()
    return self.AreaCanUnlock
end

-- 点击格子
function XRogueSimGrid:OnGridClick()
    self.Scene:OnGridClick(self)
end

return XRogueSimGrid
