local Quaternion = CS.UnityEngine.Quaternion
local Gizmos = CS.UnityEngine.Gizmos
local Debug = CS.UnityEngine.Debug

XPlanetDebugTool = XPlanetDebugTool or {}
local XPlanetDebugTool = XPlanetDebugTool

XPlanetDebugTool.DebugDrawTimer = nil

XPlanetDebugTool.CurDebugDrawMode = 1
XPlanetDebugTool.DebugDrawMode = {
    AffectedBuilding = 1,
    AffectedSlaveBuilding = 2,
    AffectedPlayer = 3,
    AffectedRoad = 4,
}

XPlanetDebugTool.CurDebugTextShowMode = 1
XPlanetDebugTool.DebugTextShowMode = {
    Building = 1,
    Tile = 2,
}

--region Buff依赖
function XPlanetDebugTool.StartDrawArrow(planetScene, res)
    XPlanetDebugTool.StopDrawArrow()
    XPlanetDebugTool.DebugDrawTimer = XScheduleManager.ScheduleForever(function()
        XPlanetDebugTool.RefreshBuffArrow(planetScene, res)
    end, 0, 0)
end

function XPlanetDebugTool.RefreshBuffArrow(planetScene, dataList)
    if not planetScene:Exist() then
        XPlanetDebugTool.StopDrawArrow()
        return
    end
    if XPlanetDebugTool.CurDebugDrawMode == XPlanetDebugTool.DebugDrawMode.AffectedBuilding then
        for _, data in pairs(dataList.AffectedBuilding) do
            local form = planetScene:GetBuildObjPosition(data.MasterGuid)
            local to = planetScene:GetBuildObjPosition(data.SlaveGuidId)
            XPlanetDebugTool.DrawArrow(form, to, CS.UnityEngine.Color.blue)
        end
    elseif XPlanetDebugTool.CurDebugDrawMode == XPlanetDebugTool.DebugDrawMode.AffectedSlaveBuilding then
        for _, data in pairs(dataList.AffectedSlaveBuilding) do
            local to, from
            from = planetScene:GetBuildObjPosition(data.SlaveGuid)
            for _, guid in pairs(data.MasterGuid) do
                to = planetScene:GetBuildObjPosition(guid)
                XPlanetDebugTool.DrawArrow(from, to, CS.UnityEngine.Color.green)
            end
        end
    elseif XPlanetDebugTool.CurDebugDrawMode == XPlanetDebugTool.DebugDrawMode.AffectedPlayer then
        for _, data in pairs(dataList.AffectedPlayer) do
            -- CS.UnityEngine.Color.red
        end
    elseif XPlanetDebugTool.CurDebugDrawMode == XPlanetDebugTool.DebugDrawMode.AffectedRoad then
        for _, data in pairs(dataList.AffectedRoad) do
            -- CS.UnityEngine.Color.cyan
        end
    end
end

function XPlanetDebugTool.StopDrawArrow()
    if XPlanetDebugTool.DebugDrawTimer then
        XScheduleManager.UnSchedule(XPlanetDebugTool.DebugDrawTimer)
        XPlanetDebugTool.DebugDrawTimer = nil
    end
end

function XPlanetDebugTool.ChangeDrawMode()
    if not XPlanetDebugTool.DebugDrawTimer then return end

    local txt = "行星测试Debug_Buff依赖关系绘制:"
    if XPlanetDebugTool.CurDebugDrawMode == XPlanetDebugTool.DebugDrawMode.AffectedBuilding then
        XLog.Warning(txt .. "AffectedBuilding MasterGuid指向SlaveGuid,箭头指向被影响的从建筑")
    elseif XPlanetDebugTool.CurDebugDrawMode == XPlanetDebugTool.DebugDrawMode.AffectedSlaveBuilding then
        XLog.Warning(txt .. "AffectedSlaveBuilding SlaveGuid指向MasterGuid,箭头指向被影响其他的主建筑")
    elseif XPlanetDebugTool.CurDebugDrawMode == XPlanetDebugTool.DebugDrawMode.AffectedPlayer then
        XLog.Warning(txt .. "AffectedPlayer_箭头指向被影响角色")
    elseif XPlanetDebugTool.CurDebugDrawMode == XPlanetDebugTool.DebugDrawMode.AffectedRoad then
        XLog.Warning(txt .. "AffectedRoad_箭头指向被影响道路")
    end
        
    XPlanetDebugTool.CurDebugDrawMode = XPlanetDebugTool.CurDebugDrawMode + 1
    if XPlanetDebugTool.CurDebugDrawMode > XPlanetDebugTool.DebugDrawMode.AffectedRoad then
        XPlanetDebugTool.ResetDrawMode()
    end
end

function XPlanetDebugTool.ResetDrawMode()
    XPlanetDebugTool.CurDebugDrawMode = XPlanetDebugTool.DebugDrawMode.AffectedBuilding
end
--endregion


--region Id显示
---显示关卡id
function XPlanetDebugTool.DebugShowStageIdText(planetScene)
    if not planetScene:Exist() then
        return
    end

    if planetScene.ShowBuildGuid then
        planetScene:ShowBuildGuid(XPlanetDebugTool.CurDebugTextShowMode == XPlanetDebugTool.DebugTextShowMode.Building)
    end
    if planetScene.ShowTileid then
        planetScene:ShowTileid(XPlanetDebugTool.CurDebugTextShowMode == XPlanetDebugTool.DebugTextShowMode.Tile)
    end

    XPlanetDebugTool.ChangeShowTextMode()
end

function XPlanetDebugTool.ChangeShowTextMode()
    local txt = "行星测试Debug_Id显示:"
    if XPlanetDebugTool.CurDebugTextShowMode == XPlanetDebugTool.DebugTextShowMode.Building then
        XLog.Warning(txt .. "建筑Guid")
    elseif XPlanetDebugTool.CurDebugTextShowMode == XPlanetDebugTool.DebugTextShowMode.Tile then
        XLog.Warning(txt .. "地块Id")
    end

    XPlanetDebugTool.CurDebugTextShowMode = XPlanetDebugTool.CurDebugTextShowMode + 1
    if XPlanetDebugTool.CurDebugTextShowMode > XPlanetDebugTool.DebugTextShowMode.Tile then
        XPlanetDebugTool.ResetShowTextMode()
    end
end

function XPlanetDebugTool.ResetShowTextMode()
    XPlanetDebugTool.CurDebugTextShowMode = XPlanetDebugTool.DebugTextShowMode.Building
end
--endregion


--region Scene绘制接口
---绘制建筑buff依赖箭头
function XPlanetDebugTool.DrawArrow(fromPosition, toPosition, color)
    if not fromPosition or not toPosition then return end
    fromPosition = fromPosition * 1.05
    toPosition = toPosition * 1.05
    local direction = toPosition - fromPosition
    fromPosition = fromPosition + direction * 0.3
    direction = direction * 0.4
    Debug.DrawRay(fromPosition, direction, color)
    XPlanetDebugTool.DrawArrowEnd(false, fromPosition, direction, color)
end

function XPlanetDebugTool.DrawArrowEnd(drawGizmos, arrowEndPosition, direction, color, arrowHeadLength, arrowHeadAngle)
    if (direction == Vector3.zero) then return end
    arrowHeadLength = arrowHeadLength or 0.25
    arrowHeadAngle = arrowHeadAngle or 40
    local right = Quaternion.LookRotation(direction) * Quaternion.Euler(arrowHeadAngle, 0, 0) * Vector3.back
    local left = Quaternion.LookRotation(direction) * Quaternion.Euler(-arrowHeadAngle, 0, 0) * Vector3.back
    local up = Quaternion.LookRotation(direction) * Quaternion.Euler(0, arrowHeadAngle, 0) * Vector3.back
    local down = Quaternion.LookRotation(direction) * Quaternion.Euler(0, -arrowHeadAngle, 0) * Vector3.back
    if (drawGizmos) then
        Gizmos.color = color
        Gizmos.DrawRay(arrowEndPosition + direction, right * arrowHeadLength)
        Gizmos.DrawRay(arrowEndPosition + direction, left * arrowHeadLength)
        Gizmos.DrawRay(arrowEndPosition + direction, up * arrowHeadLength)
        Gizmos.DrawRay(arrowEndPosition + direction, down * arrowHeadLength)
    else
        Debug.DrawRay(arrowEndPosition + direction, right * arrowHeadLength, color)
        Debug.DrawRay(arrowEndPosition + direction, left * arrowHeadLength, color)
        Debug.DrawRay(arrowEndPosition + direction, up * arrowHeadLength, color)
        Debug.DrawRay(arrowEndPosition + direction, down * arrowHeadLength, color)
    end
end
--endregion


return XPlanetDebugTool