---@class XTheatre4MapSubControl : XControl
---@field private _Model XTheatre4Model
---@field _MainControl XTheatre4Control
local XTheatre4MapSubControl = XClass(XControl, "XTheatre4MapSubControl")
function XTheatre4MapSubControl:OnInit()
    --初始化内部变量
end

function XTheatre4MapSubControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XTheatre4MapSubControl:RemoveAgencyEvent()

end

function XTheatre4MapSubControl:OnRelease()
    --XLog.Error("这里执行Control的释放")
end

--region 地图配置相关

-- 获取相机参数
function XTheatre4MapSubControl:GetCameraParams()
    local isPc = CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsEditor
        or CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsPlayer
    local cameraDistance = self._Model:GetClientConfigParams("CameraDistanceRange")
    local cameraMoveSpeed = self._Model:GetClientConfigParams("CameraMoveSpeedRange")
    local cameraZoomSpeed = self._Model:GetClientConfigParams("CameraZoomSpeed")
    local cameraDragMaxRange = self._Model:GetClientConfigParams("CameraDragMaxRange")
    local CameraDragMinRange = self._Model:GetClientConfigParams("CameraDragMinRange")
    local data = {
        CameraDistanceMin = tonumber(cameraDistance[1]),
        CameraDistanceMax = tonumber(cameraDistance[2]),
        CameraMoveSpeedMin = tonumber(cameraMoveSpeed[isPc and 3 or 1]),
        CameraMoveSpeedMax = tonumber(cameraMoveSpeed[isPc and 4 or 2]),
        CameraZoomSpeed = tonumber(cameraZoomSpeed[isPc and 2 or 1]) / 1000,
        DragMaxWidth = tonumber(cameraDragMaxRange[1]),
        DragMaxHeight = tonumber(cameraDragMaxRange[2]),
        DragMinWidth = tonumber(CameraDragMinRange[1]),
        DragMinHeight = tonumber(CameraDragMinRange[2]),
    }
    return data
end

-- 获取当前地图层的范围
function XTheatre4MapSubControl:GetCurMapFloorRange()
    local oneFloorRange = self._Model:GetClientConfigParams("MapFirstFloorRange")
    local twoFloorRange = self._Model:GetClientConfigParams("MapSecondFloorRange")
    local data = {
        [1] = {
            Min = tonumber(oneFloorRange[1]),
            Max = tonumber(oneFloorRange[2])
        },
        [2] = {
            Min = tonumber(twoFloorRange[1]),
            Max = tonumber(twoFloorRange[2])
        },
    }
    return data
end

-- 获取地图Index名称
function XTheatre4MapSubControl:GetMapIndexName(index)
    return self._Model:GetMapIndexNameById(index)
end

-- 根据地图组和地图Id获取index
function XTheatre4MapSubControl:GetIndexByMapGroupAndMaoId(mapGroup, mapId)
    -- MapGroup 表里的配置优先
    local index = self._Model:GetMapIndexByMapGroupAndMapId(mapGroup, mapId)
    if index > 0 then
        return index
    end
    -- 没有配置则使用MapBlueprint表里的配置
    local blueprintId = self._MainControl:GetMapBlueprintId()
    if not XTool.IsNumberValid(blueprintId) then
        return -1
    end
    local blueprintConfig = self._Model:GetMapBlueprintConfigById(blueprintId)
    if not blueprintConfig then
        return -1
    end
    local mapGroups = blueprintConfig.MapGroup or {}
    local indexList = blueprintConfig.Index or {}
    for i, group in pairs(mapGroups) do
        if group == mapGroup then
            return indexList[i] or -1
        end
    end
    return -1
end

-- 获取地图X轴大小
function XTheatre4MapSubControl:GetMapSizeX(mapId)
    return self._Model:GetMapSizeXById(mapId)
end

-- 获取地图Y轴大小
function XTheatre4MapSubControl:GetMapSizeY(mapId)
    return self._Model:GetMapSizeYById(mapId)
end

-- 获取地图基础镜头位置和距离
---@param mapId number 地图Id
---@return number, number, number 基础镜头X, 基础镜头Y, 基础镜头距离
function XTheatre4MapSubControl:GetMapCameraPosAndDistance(mapId)
    local config = self._Model:GetMapClientConfigById(mapId)
    local lensX = config.LensX or 0
    local lensY = config.LensY or 0
    local lensDistance = config.LensDistance or 0
    return lensX, lensY, lensDistance
end

-- 获取地图大镜头位置和距离
---@param mapId number 地图Id
---@return number, number, number 大镜头X, 大镜头Y, 大镜头距离
function XTheatre4MapSubControl:GetMapBigCameraPosAndDistance(mapId)
    local config = self._Model:GetMapClientConfigById(mapId)
    local bigLensX = config.BigMapLensX or 0
    local bigLensY = config.BigMapLensY or 0
    local bigLensDistance = config.BigMapDistance or 0
    return bigLensX, bigLensY, bigLensDistance
end

-- 获取地图偏移值
---@param mapId number 地图Id
---@return number, number 偏移X, 偏移Y
function XTheatre4MapSubControl:GetMapOffset(mapId)
    local config = self._Model:GetMapClientConfigById(mapId)
    local offsetX = config.MapOffsetX or 0
    local offsetY = config.MapOffsetY or 0
    return offsetX, offsetY
end

-- 获取地图音频标签
---@param mapId number 地图Id
function XTheatre4MapSubControl:GetMapCueTag(mapId)
    local config = self._Model:GetMapClientConfigById(mapId)
    return config and config.CueTag or "A"
end

-- 获取地图描述
---@param mapId number 地图Id
function XTheatre4MapSubControl:GetMapDesc(mapId)
    local config = self._Model:GetMapClientConfigById(mapId)
    local desc = config and config.Desc or ""
    return XUiHelper.ConvertLineBreakSymbol(desc)
end

--endregion

--region 地图相关

-- 获取所有的章节数据
---@return XTheatre4ChapterData[]
function XTheatre4MapSubControl:GetAllChapterData()
    return self._Model:GetAllChapterData()
end

-- 获取章节数据
---@return XTheatre4ChapterData
function XTheatre4MapSubControl:GetChapterData(mapId)
    return self._Model:GetChapterData(mapId)
end

-- 获取最后一个章节数据
---@return XTheatre4ChapterData
function XTheatre4MapSubControl:GetLastChapterData()
    return self._Model:GetLastChapterData()
end

-- 获取倒数第二个章节数据
---@return XTheatre4ChapterData
function XTheatre4MapSubControl:GetPreLastChapterData()
    return self._Model:GetPreLastChapterData()
end

-- 获取当前地图Id
function XTheatre4MapSubControl:GetCurrentMapId()
    local lastChapterData = self:GetLastChapterData()
    if not lastChapterData then
        return 0
    end
    return lastChapterData:GetMapId()
end

-- 获取上一个地图Id
function XTheatre4MapSubControl:GetPreMapId()
    local preLastChapterData = self:GetPreLastChapterData()
    if not preLastChapterData then
        return 0
    end
    return preLastChapterData:GetMapId()
end

-- 获取当前章节名称
function XTheatre4MapSubControl:GetCurrentChapterName()
    local lastChapterData = self:GetLastChapterData()
    if not lastChapterData then
        return ""
    end
    local index = self:GetIndexByMapGroupAndMaoId(lastChapterData:GetMapGroup(), lastChapterData:GetMapId())
    return self:GetMapIndexName(index)
end

-- 检查历史章节是否可以点击 默认是可以点击的
function XTheatre4MapSubControl:CheckHistoryChapterCanClick(mapId)
    local chapterData = self:GetChapterData(mapId)
    if not chapterData then
        return false
    end
    local passChapterOperable = self._MainControl:GetConfig("PassChapterOperable")
    if passChapterOperable == 1 then
        return true
    end
    local curMapId = self:GetCurrentMapId()
    if curMapId == mapId then
        return true
    end
    -- 弹出提示
    self._MainControl:ShowRightTipPopup(XUiHelper.GetText("Theatre4HistoryMapInoperable"))
    return false
end

--endregion

--region 地图格子相关

-- 获取地图格子Id列表
function XTheatre4MapSubControl:GetMapGridIdsByMapId(mapId)
    local chapterData = self._Model:GetChapterData(mapId)
    if not chapterData then
        return nil
    end
    return chapterData:GetGridIds()
end

-- 获取所以格子Id列表 [y][x] = gridId
---@param mapId number 地图Id
function XTheatre4MapSubControl:GetGridPosIds(mapId)
    local chapterData = self._Model:GetChapterData(mapId)
    if not chapterData then
        return nil
    end
    return chapterData:GetGridPosIds()
end

-- 获取格子数据
---@return XTheatre4Grid
function XTheatre4MapSubControl:GetMapGridData(mapId, gridId)
    return self._Model:GetGridData(mapId, gridId)
end

-- 获取Boss格子生效天数和内容Id
---@return number, number 生效天数, 内容Id
function XTheatre4MapSubControl:GetBossTriggerDayAndContentId()
    local curDay = self._MainControl:GetDays()
    local bossGridData = self:GetCurrentBossGridData()
    if bossGridData then
        local countdown = bossGridData:GetGridPunishCountdown()
        if countdown < 0 then
            return -1, 0
        end
        return curDay + (countdown == 0 and 1 or countdown), bossGridData:GetGridContentId()
    end
    return -1, 0
end

-- 获取强制播放事件的地图Id和格子Id
---@return number, number 地图Id, 格子Id
function XTheatre4MapSubControl:GetForcePlayEventMapIdAndGridId()
    local lastChapterData = self:GetLastChapterData()
    if not lastChapterData then
        return 0, 0
    end
    for _, gridData in pairs(lastChapterData:GetAllGridData()) do
        if gridData:IsGridStateExplored() then
            local eventId = gridData:GetGridEventId()
            if eventId > 0 and self._MainControl:CheckEventForcePlay(eventId) then
                return lastChapterData:GetMapId(), gridData:GetGridId()
            end
        end
    end
    return 0, 0
end

-- 获取当前地图隐藏格子位置信息
---@return table<number, table<number, boolean>> [x][y] = 是否隐藏
function XTheatre4MapSubControl:GetHiddenGridPosInfo(mapId)
    local hiddenIds = self._Model:GetMapHiddenIdById(mapId)
    if not XTool.IsNumberValid(hiddenIds) then
        return {}
    end
    local hiddenPosInfo = {}
    for _, id in pairs(hiddenIds) do
        local conditionId = self._Model:GetMapHiddenGridConditionIdById(id)
        if not XTool.IsNumberValid(conditionId) then
            goto continue
        end
        local isOpen = XConditionManager.CheckCondition(conditionId)
        if isOpen then
            goto continue
        end
        local gridPosStr = self._Model:GetMapHiddenGridGridPosById(id)
        if string.IsNilOrEmpty(gridPosStr) then
            goto continue
        end
        local gridPosList = string.Split(gridPosStr, "|")
        for _, posStr in pairs(gridPosList) do
            local pos = string.Split(posStr, ",")
            if #pos == 2 then
                local x = tonumber(pos[1])
                local y = tonumber(pos[2])
                hiddenPosInfo[x] = hiddenPosInfo[x] or {}
                hiddenPosInfo[x][y] = true
            end
        end
        :: continue ::
    end
    return hiddenPosInfo
end

-- 获取当前boss格子数据
---@return XTheatre4Grid
---@param mapId number 地图Id
---@param isRemoveHidden boolean 是否移除隐藏的格子
function XTheatre4MapSubControl:GetCurrentBossGridData(mapId, isRemoveHidden)
    local chapterData = XTool.IsNumberValid(mapId) and self:GetChapterData(mapId) or self:GetLastChapterData()
    if not chapterData then
        return nil
    end
    local bossGrids = chapterData:GetAllBossGridData()
    if XTool.IsTableEmpty(bossGrids) then
        return nil
    end
    -- 移除隐藏的boss
    if isRemoveHidden then
        local hiddenInfo = self:GetHiddenGridPosInfo(chapterData:GetMapId())
        for i = #bossGrids, 1, -1 do
            local grid = bossGrids[i]
            local x, y = grid:GetGridPos()
            if hiddenInfo[x] and hiddenInfo[x][y] then
                table.remove(bossGrids, i)
            end
        end
        if XTool.IsTableEmpty(bossGrids) then
            return nil
        end
    end
    if #bossGrids == 1 then
        return bossGrids[1]
    end
    -- 返回真boss
    for _, grid in pairs(bossGrids) do
        local contentId = grid:GetGridContentId()
        local punishEffectGroup = self._Model:GetFightPunishEffectGroupById(contentId)
        if XTool.IsNumberValid(punishEffectGroup) then
            return grid
        end
    end
    return nil
end

--endregion

--region 地图建造相关

-- 检查天赋是否是主动技能
---@param talentId number 天赋Id
function XTheatre4MapSubControl:CheckTalentIsSkill(talentId)
    local isSkill = self._Model:GetColorTalentIsSkillById(talentId)
    return isSkill == 1
end

-- 获取建筑天赋Ids (主动技能)
function XTheatre4MapSubControl:GetBuildingTalentIds()
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return nil
    end
    local openBuilding = self._MainControl.EffectSubControl:GetEffect414ControlBuildSwitch()
    local allTalentIds = adventureData:GetAllActiveTalentIds()
    local talentIds = {}
    for _, id in pairs(allTalentIds) do

        -- 只显示主动技能
        if self:CheckTalentIsSkill(id) then
            if openBuilding then
                local effectGroupId = self._Model:GetColorTalentEffectGroupIdById(id)
                local effectIds = self._Model:GetEffectGroupEffectsById(effectGroupId)
                for i = 1, #effectIds do
                    local effectId = effectIds[i]
                    local buildingId = self._MainControl.EffectSubControl:GetBuildIdByEffectId(effectId)
                    if buildingId and buildingId > 0 then
                        if openBuilding[buildingId] == true or openBuilding[buildingId] == nil then
                            table.insert(talentIds, id)
                            break
                        end
                    else
                        table.insert(talentIds, id)
                        break
                    end
                end
            else
                table.insert(talentIds, id)
            end
        end
    end
    
    return talentIds
end

-- 获取关联的天赋Ids通过天赋Id
---@param talentId number 天赋Id
function XTheatre4MapSubControl:GetRelatedTalentIdsByTalentId(talentId)
    local relatedTalentIds = self._MainControl:GetRelatedTalentIdsById(talentId)
    if XTool.IsTableEmpty(relatedTalentIds) then
        return nil
    end
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return nil
    end
    local allTalentIds = adventureData:GetAllActiveTalentIds()
    local talentIds = {}
    for _, id in pairs(relatedTalentIds) do
        if table.contains(allTalentIds, id) then
            table.insert(talentIds, id)
        end
    end
    return talentIds
end

-- 获取地图建造信息
function XTheatre4MapSubControl:GetMapBuildData()
    if not self._Model.MapBuildData then
        self._Model.MapBuildData = require("XModule/XTheatre4/XEntity/MapBuild/XTheatre4MapBuildData").New()
    end
    return self._Model.MapBuildData
end

-- 清理建造数据
function XTheatre4MapSubControl:ClearMapBuildData()
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_BUILD_END, self:GetMapBuildMapId())
    self._Model.MapBuildData = nil
end

-- 设置建造信息
function XTheatre4MapSubControl:SetMapBuildData(effectId)
    if not XTool.IsNumberValid(effectId) then
        self:ClearMapBuildData()
        return
    end
    local mapBuildData = self:GetMapBuildData()
    mapBuildData:SetIsBuilding(true)
    mapBuildData:SetEffectId(effectId)
    mapBuildData:SetEffectType(self._MainControl.EffectSubControl:GetEffectTypeById(effectId))
    local mapId, optionalGridIds = self:GetEffectOptionalGridIds()
    if optionalGridIds then
        mapBuildData:SetMapId(mapId)
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_BUILD_START, mapId, optionalGridIds)
    end
end

-- 是否正在建造中
function XTheatre4MapSubControl:CheckIsBuilding()
    return self:GetMapBuildData():GetIsBuilding()
end

-- 获取建造效果类型
function XTheatre4MapSubControl:GetBuildEffectType()
    return self:GetMapBuildData():GetEffectType()
end

-- 设置建造数据 点击格子时设置
function XTheatre4MapSubControl:SetMapBuildGridData(mapId, gridId, posX, posY)
    if XEnumConst.Theatre4.IsDebug then
        XLog.Warning("<color=#F1D116>Theatre4:</color> SetBuildData mapId: " .. mapId .. " gridId: " .. gridId .. " posX: " .. posX .. " posY: " .. posY)
    end
    local mapBuildData = self:GetMapBuildData()
    mapBuildData:SetMapId(mapId)
    mapBuildData:SetGridData(gridId, posX, posY)
    local gridIds = self:GetEffectTargetGridIds(mapId, gridId, posX, posY)
    if gridIds then
        -- 添加选中的格子Id
        if not table.contains(gridIds, gridId) then
            table.insert(gridIds, gridId)
        end
        if XEnumConst.Theatre4.IsDebug then
            XLog.Warning("<color=#F1D116>Theatre4:</color> EffectTarget gridIds: ", gridIds)
        end
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_BUILD_SELECT_GRID, mapId, gridIds)
    end
end

-- 检查是否已选择格子
function XTheatre4MapSubControl:CheckIsSelectGrid()
    return self:GetMapBuildData():CheckIsSelectGrid()
end

-- 获取建造的MapId
function XTheatre4MapSubControl:GetMapBuildMapId()
    return self:GetMapBuildData():GetMapId()
end

-- 获取建造的格子Id
function XTheatre4MapSubControl:GetMapBuildGridId()
    return self:GetMapBuildData():GetGridId()
end

-- 获取请求建造的Params
function XTheatre4MapSubControl:GetMapBuildParams()
    local mapBuildData = self:GetMapBuildData()
    return {
        mapBuildData:GetMapId(),
        mapBuildData:GetPosY(),
        mapBuildData:GetPosX(),
    }
end

-- 获取效果可选的所有格子Ids
---@return table<number, number[]> 地图Id, 格子Ids
function XTheatre4MapSubControl:GetEffectOptionalGridIds()
    local effectType = self:GetMapBuildData():GetEffectType()
    if not XTool.IsNumberValid(effectType) then
        return nil
    end
    local lastChapterData = self:GetLastChapterData()
    if XTool.IsTableEmpty(lastChapterData) then
        return nil
    end
    local gridIds = {}
    for _, gridData in pairs(lastChapterData:GetAllGridData()) do
        if self:CheckActiveSkillCondition(effectType, gridData, false) then
            table.insert(gridIds, gridData:GetGridId())
        end
    end
    return lastChapterData:GetMapId(), gridIds
end

--region 检查主动技能的条件

-- 检查是否满足主动技能条件
---@param effectType number 效果类型
---@param gridData XTheatre4Grid 格子数据
---@param isShowTips boolean 是否显示提示
function XTheatre4MapSubControl:CheckActiveSkillCondition(effectType, gridData, isShowTips)
    if not XTool.IsNumberValid(effectType) then
        return false
    end
    if effectType == XEnumConst.Theatre4.EffectType.Type101 then
        return self:CheckCreateBuildingCondition(gridData, isShowTips)  -- 主动-创建建筑
    elseif effectType == XEnumConst.Theatre4.EffectType.Type115 then
        return self:CheckChangeGridColorCondition(gridData, isShowTips) -- 主动-改造格子颜色
    elseif effectType == XEnumConst.Theatre4.EffectType.Type117 then
        return self:CheckRemoveObstacleCondition(gridData, isShowTips)  -- 主动-移除障碍
    elseif effectType == XEnumConst.Theatre4.EffectType.Type201 then
        return self:CheckChangeShopCondition(gridData, isShowTips)      -- 主动-改造商店
    elseif effectType == XEnumConst.Theatre4.EffectType.Type414 then
            return self:CheckCreateBuildingCondition(gridData, isShowTips)  -- 主动-创建建筑
    else
        XLog.Error("CheckActiveSkillCondition error, effectType:" .. effectType)
    end
    return false
end

-- 检查是否满足创建建筑条件
---@param gridData XTheatre4Grid
function XTheatre4MapSubControl:CheckCreateBuildingCondition(gridData, isShowTips)
    if not gridData:IsGridStateProcessed() then
        if isShowTips then
            self._MainControl:ShowRightTipPopup(XUiHelper.GetText("Theatre4GridNotProcessed"))
        end
        return false
    end
    if not gridData:IsGridTypeEmpty() then
        if isShowTips then
            self._MainControl:ShowRightTipPopup(XUiHelper.GetText("Theatre4BuildingGridIsNotEmpty"))
        end
        return false
    end
    return true
end

-- 检查是否满足改变格子颜色条件
---@param gridData XTheatre4Grid
function XTheatre4MapSubControl:CheckChangeGridColorCondition(gridData, isShowTips)
    -- 不支持的格子类型
    if gridData:IsGridTypeBoss() or gridData:IsGridTypeStart() or gridData:IsGridTypeNothing() or gridData:IsGridTypeBlank() or gridData:IsGridTypeBuilding() then
        if isShowTips then
            self._MainControl:ShowRightTipPopup(XUiHelper.GetText("Theatre4GridNotSupportChangeColor"))
        end
        return false
    end
    -- 已探索
    if gridData:IsGridStateExplored() then
        if isShowTips then
            self._MainControl:ShowRightTipPopup(XUiHelper.GetText("Theatre4GridHasExplored"))
        end
        return false
    end
    -- 已处理
    if gridData:IsGridStateProcessed() then
        if isShowTips then
            self._MainControl:ShowRightTipPopup(XUiHelper.GetText("Theatre4GridHasProcessed"))
        end
        return false
    end
    -- 颜色相同
    local effectColorId = self._MainControl.EffectSubControl:GetColorIdByEffectId(self:GetMapBuildData():GetEffectId())
    if gridData:GetGridColor() == effectColorId then
        if isShowTips then
            self._MainControl:ShowRightTipPopup(XUiHelper.GetText("Theatre4GridColorIsSame"))
        end
        return false
    end
    return true
end

-- 检查是否满足移除障碍条件
---@param gridData XTheatre4Grid
function XTheatre4MapSubControl:CheckRemoveObstacleCondition(gridData, isShowTips)
    if gridData:IsGridStateUnknown() or gridData:IsGridStateVisible() then
        if isShowTips then
            self._MainControl:ShowRightTipPopup(XUiHelper.GetText("Theatre4GridNotInView"))
        end
        return false
    end
    if gridData:IsGridStateProcessed() then
        if isShowTips then
            self._MainControl:ShowRightTipPopup(XUiHelper.GetText("Theatre4GridHasProcessed"))
        end
        return false
    end
    local isTalentEffectActive = self._MainControl.EffectSubControl:CheckTalentEffectContainEffect(XEnumConst.Theatre4.EffectType.Type120)
    local isTypeSupported = gridData:IsGridTypeHurdle() or (isTalentEffectActive and gridData:IsGridTypeMonster())
    if not isTypeSupported then
        if isShowTips then
            self._MainControl:ShowRightTipPopup(XUiHelper.GetText("Theatre4ChangeGridTypeTypeNotSupport"))
        end
        return false
    end
    return true
end

-- 检查是否满足改变商店条件
---@param gridData XTheatre4Grid
function XTheatre4MapSubControl:CheckChangeShopCondition(gridData, isShowTips)
    if not gridData:IsGridStateProcessed() then
        if isShowTips then
            self._MainControl:ShowRightTipPopup(XUiHelper.GetText("Theatre4GridNotProcessed"))
        end
        return false
    end
    if not gridData:IsGridTypeEmpty() then
        if isShowTips then
            self._MainControl:ShowRightTipPopup(XUiHelper.GetText("Theatre4BuildingGridIsNotEmpty"))
        end
        return false
    end
    return true
end

--endregion

--region 效果影响的格子相关

-- 获取效果影响的格子Ids
---@param mapId number 地图Id
---@param gridId number 格子Id
---@param posX number 格子X坐标
---@param posY number 格子Y坐标
function XTheatre4MapSubControl:GetEffectTargetGridIds(mapId, gridId, posX, posY)
    local mapBuildData = self:GetMapBuildData()
    local effectType = mapBuildData:GetEffectType()
    if not XTool.IsNumberValid(effectType) then
        return nil
    end
    local gridData = self:GetMapGridData(mapId, gridId)
    if not gridData then
        return nil
    end
    local length = self:GetMapSizeY(mapId)
    local width = self:GetMapSizeX(mapId)
    if length <= 0 or width <= 0 then
        return nil
    end
    local gridPosIds = self:GetGridPosIds(mapId)
    if not gridPosIds then
        return nil
    end
    if gridPosIds[posY][posX] ~= gridId then
        XLog.Error("GetEffectTargetGridIds error, gridId:" .. gridId)
        return nil
    end
    if effectType == XEnumConst.Theatre4.EffectType.Type101 then
        return self:GetCreateBuildingTargetGridIds(gridPosIds, posX, posY, length, width)
    elseif effectType == XEnumConst.Theatre4.EffectType.Type115 then
        return self:GetChangeGridColorTargetGridIds(gridPosIds, posX, posY, length, width)
    elseif effectType == XEnumConst.Theatre4.EffectType.Type117 then
        return self:GetRemoveObstacleTargetGridIds(gridPosIds, posX, posY, length, width)
    elseif effectType == XEnumConst.Theatre4.EffectType.Type201 then
        return self:GetChangeShopTargetGridIds(gridPosIds, posX, posY, length, width)
    elseif effectType == XEnumConst.Theatre4.EffectType.Type414 then
        return self:GetCreateBuildingTargetGridIds(gridPosIds, posX, posY, length, width)
    else
        XLog.Error("GetEffectTargetGrid error, effectType:" .. effectType)
    end
    return nil
end

-- 获取创建建筑效果影响的格子Ids
---@param gridPosIds table<number, table<number, number>> [y][x] = gridId 下标从0开始的
---@param posX number 格子X坐标
---@param posY number 格子Y坐标
---@param length number 地图长度
---@param width number 地图宽度
function XTheatre4MapSubControl:GetCreateBuildingTargetGridIds(gridPosIds, posX, posY, length, width)
    -- 获取建筑Id
    local buildId = self._MainControl.EffectSubControl:GetBuildIdByEffectId(self:GetMapBuildData():GetEffectId())
    if not XTool.IsNumberValid(buildId) then
        XLog.Warning("[XTheatre4MapSubControl] 获取建筑id失败, buildId:" .. tostring(buildId))
        return nil
    end
    local buildType = self._Model:GetBuildingTypeById(buildId)
    if not XTool.IsNumberValid(buildType) then
        return nil
    end
    if buildType == XEnumConst.Theatre4.BuildingType.Bonfire then
        return self:GetDiamondRangeGridIds(gridPosIds, posX, posY, length, width)  -- 篝火
    elseif buildType == XEnumConst.Theatre4.BuildingType.ArrowTower then
        return self:GetCrossRangeGridIds(gridPosIds, posX, posY, length, width, 1) -- 箭塔
    elseif buildType == XEnumConst.Theatre4.BuildingType.MoneyCan then
        return self:GetCubeRangeGridIds(gridPosIds, posX, posY, length, width)     -- 存钱罐
    elseif buildType == XEnumConst.Theatre4.BuildingType.Wonder then
        return {}                                                                  -- 奇观
    elseif buildType == XEnumConst.Theatre4.BuildingType.TempBase then
        return self:GetCrossRangeGridIds(gridPosIds, posX, posY, length, width, 1) -- (三合一建筑)临时基地
    else
        XLog.Error("GetCreateBuildingTargetGridIds error, buildType:" .. buildType)
    end
    return nil
end

-- 获取更改网格颜色目标格子Ids
---@param gridPosIds table<number, table<number, number>> [y][x] = gridId 下标从0开始的
---@param posX number x坐标
---@param posY number y坐标
---@param length number 长度
---@param width number 宽度
function XTheatre4MapSubControl:GetChangeGridColorTargetGridIds(gridPosIds, posX, posY, length, width)
    local gridIds = {}
    local extraCount = self._MainControl.EffectSubControl:GetEffectAlterGridColorExtraGridCount()
    if extraCount > 0 then
        local extraGridIds = self:GetCrossRangeGridIds(gridPosIds, posX, posY, length, width, extraCount)
        XTool.MergeArray(gridIds, extraGridIds)
    end
    return gridIds
end

-- 获取移除障碍物目标格子Ids
---@param gridPosIds table<number, table<number, number>> [y][x] = gridId 下标从0开始的
---@param posX number x坐标
---@param posY number y坐标
---@param length number 长度
---@param width number 宽度
function XTheatre4MapSubControl:GetRemoveObstacleTargetGridIds(gridPosIds, posX, posY, length, width)
    local gridIds = {}
    local extraCount = self._MainControl.EffectSubControl:GetEffectRemoveHurdleExtraGridCount()
    if extraCount > 0 then
        local extraGridIds = self:GetCrossRangeGridIds(gridPosIds, posX, posY, length, width, 1)
        XTool.MergeArray(gridIds, extraGridIds)
    end
    return gridIds
end

-- 获取变更商店目标格子Id
---@param gridPosIds table<number, table<number, number>> [y][x] = gridId 下标从0开始的
---@param posX number x坐标
---@param posY number y坐标
---@param length number 长度
---@param width number 宽度
function XTheatre4MapSubControl:GetChangeShopTargetGridIds(gridPosIds, posX, posY, length, width)
    return {}
end

function XTheatre4MapSubControl:DiamondPosPreset()
    return {
        -- 距离1
        { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 },   --上下左右
        { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 }, --四个角
        -- 距离2
        { 2, 0 }, { 0, 2 }, { -2, 0 }, { 0, -2 },   --上下左右
    }
end

-- 获取菱形范围, 遍历有顺序需求, 用预设的坐标
---@param gridPosIds table<number, table<number, number>> [y][x] = gridId 下标从0开始的
---@param posX number x坐标
---@param posY number y坐标
---@param length number 长度
---@param width number 宽度
function XTheatre4MapSubControl:GetDiamondRangeGridIds(gridPosIds, posX, posY, length, width)
    local gridIds = {}
    for _, offset in ipairs(self:DiamondPosPreset()) do
        local y = posY + offset[1]
        local x = posX + offset[2]
        if y >= 0 and x >= 0 and y < length and x < width and gridPosIds[y] and gridPosIds[y][x] then
            table.insert(gridIds, gridPosIds[y][x])
        end
    end
    return gridIds
end

-- 顺序为:右,上,左,下 （部分计算规则依赖，顺序不能改动）
function XTheatre4MapSubControl:Directions()
    return {
        { 0, 1 }, { 1, 0 }, { 0, -1 }, { -1, 0 }
    }
end

-- 获取十字型范围
---@param gridPosIds table<number, table<number, number>> [y][x] = gridId 下标从0开始的
---@param posX number x坐标
---@param posY number y坐标
---@param length number 长度
---@param width number 宽度
---@param size number 大小
function XTheatre4MapSubControl:GetCrossRangeGridIds(gridPosIds, posX, posY, length, width, size)
    if not XTool.IsNumberValid(size) then
        size = 1
    end
    local gridIds = {}
    for _, offset in ipairs(self:Directions()) do
        for j = 1, size do
            local y = posY + offset[1] * j
            local x = posX + offset[2] * j
            if y >= 0 and x >= 0 and y < length and x < width and gridPosIds[y] and gridPosIds[y][x] then
                table.insert(gridIds, gridPosIds[y][x])
            end
        end
    end
    return gridIds
end

-- 获取方形范围格子
---@param gridPosIds table<number, table<number, number>> [y][x] = gridId 下标从0开始的
---@param posX number x坐标
---@param posY number y坐标
---@param length number 长度
---@param width number 宽度
---@param size number 大小
function XTheatre4MapSubControl:GetCubeRangeGridIds(gridPosIds, posX, posY, length, width, size)
    if not XTool.IsNumberValid(size) then
        size = 1
    end
    local gridIds = {}
    for i = 1, size do
        local startY = posY - i
        local startX = posX - i
        local range = 2 * i + 1
        for _, offset in ipairs(self:Directions()) do
            for j = 0, range - 2 do
                local y = startY + offset[1] * j
                local x = startX + offset[2] * j
                if y >= 0 and x >= 0 and y < length and x < width and gridPosIds[y] and gridPosIds[y][x] then
                    table.insert(gridIds, gridPosIds[y][x])
                end
            end
            startY = startY + (range - 1) * offset[1]
            startX = startX + (range - 1) * offset[2]
        end
    end
    return gridIds
end

--endregion

--endregion

--region 打开建筑详情时显示生效范围

-- 显示建筑详情特效
---@param mapId number 地图Id
---@param gridId number 格子Id
---@param posX number 格子X坐标
---@param posY number 格子Y坐标
---@param buildingId number 建筑Id
function XTheatre4MapSubControl:ShowBuildingDetailEffect(mapId, gridId, posX, posY, buildingId)
    local gridIds = self:GetBuildingDetailEffectGridIds(mapId, gridId, posX, posY, buildingId)
    if gridIds then
        if XEnumConst.Theatre4.IsDebug then
            XLog.Warning("<color=#F1D116>Theatre4:</color> ShowBuildingDetailEffect gridIds: ", gridIds)
        end
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_OPEN_BUILDING_DETAIL, mapId, gridIds)
    end
end

-- 获取建筑详情生效范围的格子Ids
---@param mapId number 地图Id
---@param gridId number 格子Id
---@param posX number 格子X坐标
---@param posY number 格子Y坐标
---@param buildingId number 效果类型
---@return table<number> 格子Ids
function XTheatre4MapSubControl:GetBuildingDetailEffectGridIds(mapId, gridId, posX, posY, buildingId)
    local gridData = self:GetMapGridData(mapId, gridId)
    if not gridData then
        return nil
    end
    local length = self:GetMapSizeY(mapId)
    local width = self:GetMapSizeX(mapId)
    if length <= 0 or width <= 0 then
        return nil
    end
    local gridPosIds = self:GetGridPosIds(mapId)
    if not gridPosIds then
        return nil
    end
    if gridPosIds[posY][posX] ~= gridId then
        XLog.Error("GetBuildingEffectShowGridIds error, gridId:" .. gridId)
        return nil
    end
    local buildingType = self._Model:GetBuildingTypeById(buildingId)
    if not XTool.IsNumberValid(buildingType) then
        return nil
    end
    if buildingType == XEnumConst.Theatre4.BuildingType.Bonfire then
        return self:GetDiamondRangeGridIds(gridPosIds, posX, posY, length, width)  -- 篝火
    elseif buildingType == XEnumConst.Theatre4.BuildingType.ArrowTower then
        return self:GetCrossRangeGridIds(gridPosIds, posX, posY, length, width, 1) -- 箭塔
    elseif buildingType == XEnumConst.Theatre4.BuildingType.MoneyCan then
        return self:GetCubeRangeGridIds(gridPosIds, posX, posY, length, width)     -- 存钱罐
    elseif buildingType == XEnumConst.Theatre4.BuildingType.Wonder then
        return {}                                                                  -- 奇观
    elseif buildingType == XEnumConst.Theatre4.BuildingType.TempBase then
        return self:GetCrossRangeGridIds(gridPosIds, posX, posY, length, width, 1) -- (三合一建筑)临时基地
    else
        XLog.Error("GetBuildingEffectShowGridIds error, buildingId:" .. buildingId)
    end
    return nil
end

--endregion

--region 建筑相关

-- 获取拥有的建筑信息列表
---@return { BuildingId:number, Count:number }[]
function XTheatre4MapSubControl:GetOwnBuildingDataList()
    local chapterList = self:GetAllChapterData()
    if XTool.IsTableEmpty(chapterList) then
        return {}
    end
    local temp = {}
    for _, chapterData in pairs(chapterList) do
        for _, gridData in pairs(chapterData:GetAllGridData()) do
            if gridData:IsGridTypeBuilding() then
                local buildingId = gridData:GetGridBuildingId()
                if not temp[buildingId] then
                    temp[buildingId] = 0
                end
                temp[buildingId] = temp[buildingId] + 1
            end
        end
    end
    local ownBuildingData = {}
    for buildingId, count in pairs(temp) do
        table.insert(ownBuildingData, { BuildingId = buildingId, Count = count })
    end
    return ownBuildingData
end

-- 获取建筑数量 (默认为当前章节)
---@param mapId number 地图Id
---@param buildingId number 建筑Id
function XTheatre4MapSubControl:GetBuildingCount(mapId, buildingId)
    local chapterData = XTool.IsNumberValid(mapId) and self:GetChapterData(mapId) or self:GetLastChapterData()
    if not chapterData then
        return 0
    end
    local count = 0
    local isBuildingIdValid = XTool.IsNumberValid(buildingId)
    for _, gridData in pairs(chapterData:GetAllGridData()) do
        if gridData:IsGridTypeBuilding() and (not isBuildingIdValid or gridData:GetGridBuildingId() == buildingId) then
            count = count + 1
        end
    end
    return count
end

-- 获取篝火建造点恢复
---@return number 建造点
function XTheatre4MapSubControl:GetBonfireBuildPointRecover()
    local allChapterData = self:GetAllChapterData()
    if XTool.IsTableEmpty(allChapterData) then
        return 0
    end
    local bonfireBuildPointRecover = 0
    for _, chapterData in pairs(allChapterData) do
        for _, gridData in pairs(chapterData:GetAllGridData()) do
            if gridData:IsGridTypeBuilding() and gridData:GetGridBuildingType() == XEnumConst.Theatre4.BuildingType.Bonfire then
                local buildingId = gridData:GetGridBuildingId()
                if XTool.IsNumberValid(buildingId) then
                    local params = self._MainControl:GetBuildingParams(buildingId)
                    if params and params[1] and params[1] > 0 then
                        bonfireBuildPointRecover = bonfireBuildPointRecover + params[1]
                    end
                end
            end
        end
    end
    return bonfireBuildPointRecover
end

-- 获取临时基地恢复
---@return number 建造点
function XTheatre4MapSubControl:GetTempBaseBuildPointRecover()
    local allChapterData = self:GetAllChapterData()
    if XTool.IsTableEmpty(allChapterData) then
        return 0
    end
    local bonfireBuildPointRecover = 0
    for _, chapterData in pairs(allChapterData) do
        for _, gridData in pairs(chapterData:GetAllGridData()) do
            if gridData:IsGridTypeBuilding() and gridData:GetGridBuildingType() == XEnumConst.Theatre4.BuildingType.TempBase then
                local buildingId = gridData:GetGridBuildingId()
                if XTool.IsNumberValid(buildingId) then
                    local params = self._MainControl:GetBuildingParams(buildingId)
                    if params and params[1] and params[1] > 0 then
                        bonfireBuildPointRecover = bonfireBuildPointRecover + params[2]
                    end
                end
            end
        end
    end
    return bonfireBuildPointRecover
end

-- 检查建筑数量是否达到上限
---@param mapId number 地图Id
---@param effectId number 效果Id
---@param isShowTips boolean 是否显示提示
function XTheatre4MapSubControl:CheckEffectBuildingCountLimit(mapId, effectId, isShowTips)
    local buildingId = self._MainControl.EffectSubControl:GetBuildIdByEffectId(effectId)
    if not XTool.IsNumberValid(buildingId) then
        return false
    end
    return self:CheckChapterBuildingCountLimit(mapId, buildingId, isShowTips)
end

-- 检查建筑数量是否已达上限
---@param mapId number 地图Id
---@param buildingId number 建筑Id
---@param isShowTips boolean 是否显示提示
function XTheatre4MapSubControl:CheckChapterBuildingCountLimit(mapId, buildingId, isShowTips)
    -- 获取建筑最大数量
    local maxCountInChapter = self._Model:GetBuildingMaxCountInChapterById(buildingId)
    if maxCountInChapter <= 0 then
        return false
    end
    -- 获取当前建筑数量
    local buildingCount = self:GetBuildingCount(mapId, buildingId)
    if buildingCount >= maxCountInChapter then
        if isShowTips then
            self._MainControl:ShowRightTipPopup(XUiHelper.GetText("Theatre4BuildingCountLimited"))
        end
        return true
    end
    return false
end

--endregion

--region 相机拖拽缩放相关

-- 获取格子Id通过地图Id和X、Y坐标
---@param mapId number 地图Id
---@param posX number X坐标
---@param posY number Y坐标
---@return number 格子Id
function XTheatre4MapSubControl:GetGridIdByPos(mapId, posX, posY)
    local chapterData = self:GetChapterData(mapId)
    if not chapterData then
        return 0
    end
    local gridPosIds = chapterData:GetGridPosIds()
    if not gridPosIds[posY] then
        return 0
    end
    return gridPosIds[posY][posX] or 0
end

-- 获取格子世界坐标
---@param mapId number 地图Id
---@param gridId number 格子Id
function XTheatre4MapSubControl:GetGridWorldPos(mapId, gridId)
    ---@type XUiTheatre4Game
    local luaUi = XLuaUiManager.GetTopLuaUi("UiTheatre4Game")
    if luaUi then
        return luaUi:GetGridWorldPos(mapId, gridId)
    end
end

-- 聚焦相机到指定位置
---@param posX number x世界坐标
---@param posY number y世界坐标
---@param duration number 持续时间
---@param ease DG.Tweening.Ease 缓动函数
---@param callback function 回调
function XTheatre4MapSubControl:FocusCameraToPosition(posX, posY, duration, ease, callback)
    ---@type XUiTheatre4Game
    local luaUi = XLuaUiManager.GetTopLuaUi("UiTheatre4Game")
    if luaUi then
        luaUi:FocusCameraToPosition(posX, posY, duration, ease, callback)
    end
end

-- 缩放相机的距离
---@param distance number 相机距离
---@param duration number 持续时间
---@param ease DG.Tweening.Ease 缓动函数
---@param callback function 回调
function XTheatre4MapSubControl:ZoomCameraToDistance(distance, duration, ease, callback)
    ---@type XUiTheatre4Game
    local luaUi = XLuaUiManager.GetTopLuaUi("UiTheatre4Game")
    if luaUi then
        luaUi:ZoomCameraToDistance(distance, duration, ease, callback)
    end
end

-- 同时聚焦和缩放相机到指定位置和距离
---@param posX number x世界坐标
---@param posY number y世界坐标
---@param distance number 相机距离
---@param duration number 持续时间
---@param ease DG.Tweening.Ease 缓动函数
---@param callback function 回调
function XTheatre4MapSubControl:FocusAndZoomCamera(posX, posY, distance, duration, ease, callback)
    ---@type XUiTheatre4Game
    local luaUi = XLuaUiManager.GetTopLuaUi("UiTheatre4Game")
    if luaUi then
        luaUi:FocusAndZoomCamera(posX, posY, distance, duration, ease, callback)
    end
end

--endregion

function XTheatre4MapSubControl:GetMapConfigById(mapId)
    return self._Model:GetMapConfigById(mapId)
end

return XTheatre4MapSubControl
