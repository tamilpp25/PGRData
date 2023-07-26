local XMapPoint = require("XEntity/XColorTable/Map/XMapPoint")
local XBossPoint = require("XEntity/XColorTable/Map/XBossPoint")
local XMoviePoint = require("XEntity/XColorTable/Map/XMoviePoint")

local AnimDuration = 0.2

-- 关卡地图
local XPanelMap = XClass(nil, "XPanelMap")

function XPanelMap:Ctor(root, ui, mapId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Root = root

    self.MapId = mapId
    self.CurPositionId = XColorTableConfigs.GetMapBornPosition(self.MapId)
    self._GameManager = XDataCenter.ColorTableManager.GetGameManager()
    self._GameData = self._GameManager:GetGameData()

    self:_InitUiObject()
    self:_LoadPointPrefab()
end

function XPanelMap:Refresh()
    if self.PanelLine then
        self.PanelLine.gameObject:SetActiveEx(true)
        if self.Line7 and self._GameData:CheckIsFirstGuideStage() then
            for i = 0, self.PanelLine.childCount - 1, 1 do
                self.PanelLine:GetChild(i).gameObject:SetActiveEx(false)
            end
            self.Line7.gameObject:SetActiveEx(true)
            self.Line8.gameObject:SetActiveEx(true)
        end
    end
    self:RefreshPlayer()
    self:RefreshBossPoint()
    self:RefreshMoviePoint()
end

-- 地图点位相关
--===========================================================

function XPanelMap:RefreshPlayer()
    if self.CurPositionId ~= self._GameData:GetCurPosition() then
        self.CurPositionId = self._GameData:GetCurPosition()
    end
    self.Player.position = self.MapPointObjs[self.CurPositionId].position
end

function XPanelMap:RefreshBossPoint()
    for color, point in pairs(self.BossPoints) do
        point:SetData(self._GameData:GetBossLevels(color))
    end
    if self.HideBossPoint then
        self.HideBossPoint:SetData()
        self.HideBossPoint:SetActive(false)
    end
end

function XPanelMap:RefreshMoviePoint()
    local triggerDramaData = self._GameData:GetTriggerDramaData()
    for i = #triggerDramaData, 1, -1 do
        local data = triggerDramaData[i]
        local key = data.ColorType .. data.Index
        if not data.IsRead then
            if self.MoviePoints[key] then
                self.MoviePoints[key].GameObject:SetActiveEx(true)
                self.MoviePoints[key]:SetDramaId(data.DramaId)
            else
                local obj = self.MoviePointObjs[data.ColorType][data.Index].gameObject:LoadPrefab(XColorTableConfigs.GetMovePointPrefab())
                self.MoviePoints[key] = XMoviePoint.New(self, obj)
                self.MoviePoints[key]:SetDramaId(data.DramaId)
            end
        end
    end
end

function XPanelMap:RefreshMapWin(isSpecailWin)
    self.Player.gameObject:SetActiveEx(false)
    if self.HideBossPoint then
        self.HideBossPoint:SetActive(isSpecailWin)
    end
    for _, point in pairs(self.BossPoints) do
        point:SetActive(not isSpecailWin)
    end

    for _, point in pairs(self.MapPoints) do
        point:RefreshWin()
    end
end

function XPanelMap:AddMoviePoint(dramaId, callback)
    local dramaType = XColorTableConfigs.GetDramaType(dramaId)
    if dramaType == XColorTableConfigs.DramaType.Dialogue then
        local colorType = XColorTableConfigs.GetDramaParams(dramaId)[2]
        local data = self._GameData:GetDramaData(dramaId)
        if not XTool.IsNumberValid(colorType) then
            colorType = math.random(1, 3)
        end
        if XTool.IsTableEmpty(data) then
            local index = math.random(1, 2)
            local isExitDrama = not XTool.IsTableEmpty(self.MoviePoints[colorType .. index])
            if index == 1 then
                index = isExitDrama and 2 or 1
            elseif index == 2 then
                index = isExitDrama and 1 or 2
            end
            self._GameData:AddTriggerDramaData(dramaId, colorType, index)
        end

        self:RefreshMoviePoint()
        if callback then
            callback()
        end
    else
        XLuaUiManager.Open("UiColorTableCaptainDrama", dramaId, callback)
    end
end

function XPanelMap:SelectPoint(pointObj)
    if self.SelectingPoint and self.SelectingPoint == pointObj then
        return
    end
    self:UnSelectPoint()
    local ifEsayMode = self._GameManager:GetEsayActionMode()

    if ifEsayMode and pointObj:IsMapPoint() and self._GameData:GetCurStage() == XColorTableConfigs.CurStageType.PlayGame then
        -- 便捷模式下不在该点位则移动到该点位
        if not self:IsPlayerOnPoint(pointObj) then
            self._GameManager:RequestMove(pointObj:GetPositionId())
            return
        -- 便捷模式下除了治疗点都直接执行点位行动
        elseif pointObj:GetType() ~= XColorTableConfigs.PointType.Hospital then
            pointObj:Excute()
            return
        end
    end

    pointObj:SetTipPanelActive(true)
    if not pointObj:IsMoviePoint() then
        pointObj:RefreshSelectState(true)
        self.SelectingPoint = pointObj
    end
end

function XPanelMap:UnSelectPoint()
    if self.SelectingPoint then
        self.SelectingPoint:RefreshSelectState(false)
        self.SelectingPoint:SetTipPanelActive(false)
        self.SelectingPoint = nil
    end
end

--===========================================================



-- 角色移动相关
--===========================================================

function XPanelMap:PlayerMove(callback)
    -- 移动动画
    local paths = self._GameManager:GetCurMovePaths()
    if XTool.IsTableEmpty(paths) then
        return
    end
    XLuaUiManager.SetMask(true)
    self.Player.position = self.MapPointObjs[paths[1]].position
    local duration = AnimDuration * (#paths - 1)
    local i = 1
    XUiHelper.Tween(duration, function(f)
        if XTool.UObjIsNil(self.Transform) then  -- 防止动画还没结束就关闭界面导致计时器报错
            return
        end
        if (f * duration) - (i * AnimDuration) > 0 then
            self.Player.position = self.MapPointObjs[paths[i + 1]].position
            i = i + 1
        end
    end, function()
        XLuaUiManager.SetMask(false)
        if XTool.UObjIsNil(self.Transform) then
            return
        end
        self:RefreshPlayer()
        if callback then
            callback()
        end
    end)
end

function XPanelMap:IsPlayerOnPoint(pointObj)
    return self.CurPositionId == pointObj:GetPositionId()
end

--===========================================================


function XPanelMap:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_COLOR_TABLE_PALYER_MOVE_ANIM, self.PlayerMove, self)
    XEventManager.AddEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_TRIGGERDRAMA, self.AddMoviePoint, self)

    for _, point in pairs(self.BossPoints) do
        if point.AddEventListener then
            point:AddEventListener()
        end
    end

    for _, point in pairs(self.MapPoints) do
        if point.AddEventListener then
            point:AddEventListener()
        end
    end

    for _, point in pairs(self.MoviePoints) do
        if point.AddEventListener then
            point:AddEventListener()
        end
    end
end

function XPanelMap:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_COLOR_TABLE_PALYER_MOVE_ANIM, self.PlayerMove, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_TRIGGERDRAMA, self.AddMoviePoint, self)

    for _, point in pairs(self.BossPoints) do
        if point.RemoveEventListener then
            point:RemoveEventListener()
        end
    end

    for _, point in pairs(self.MapPoints) do
        if point.RemoveEventListener then
            point:RemoveEventListener()
        end
    end

    for _, point in pairs(self.MoviePoints) do
        if point.RemoveEventListener then
            point:RemoveEventListener()
        end
    end
end



-- private
---------------------------------------------------------------

function XPanelMap:_InitUiObject()
    XTool.InitUiObject(self)

    self.SelectingPoint = nil   -- 已选中的地图点
    self.BossPoints = {}        -- Boss点
    self.HideBossPoint = nil    -- 隐藏Boss点
    self.MapPoints = {}         -- 移动点
    self.MoviePoints = {}       -- 剧情点

    self.BossObjs = {
        self.RedBoss,
        self.GreenBoss,
        self.BlueBoss,
    }

    self.MapPointObjs = {
        self.GreenEnergy,
        self.GreenMedical,
        self.GreenStudy,
        self.BlueStudy,
        self.BlueMedical,
        self.BlueEnergy,
        self.RedMedical,
        self.RedEnergy,
        self.RedStudy,
    }
    if self.Downtown then
        table.insert(self.MapPointObjs, self.Downtown)
    end

    self.MoviePointObjs = {
        {self.RandomMovieRed1, self.RandomMovieRed2},
        {self.RandomMovieGreen1, self.RandomMovieGreen2},
        {self.RandomMovieBlue1, self.RandomMovieBlue2},
    }
end

function XPanelMap:_LoadPointPrefab()
    local pointGroupId = XColorTableConfigs.GetMapPointGroupId(self.MapId)
    local pointIds = XColorTableConfigs.GetPointsByGroupId(pointGroupId)
    for _, pointId in ipairs(pointIds) do
        local pointType = XColorTableConfigs.GetPointType(pointId)
        local pointColor = XColorTableConfigs.GetPointColor(pointId)
        local positionId = XColorTableConfigs.GetPointPositionId(pointId)
        if pointType == XColorTableConfigs.PointType.Boss then
            self.BossPoints[pointColor] = XBossPoint.New(self, self.BossObjs[pointColor].gameObject:LoadPrefab(XColorTableConfigs.GetBossPointPrefab()))
            self.BossPoints[pointColor]:SetPointId(pointId)
        elseif pointType == XColorTableConfigs.PointType.HideBoss and self._GameData:CheckIsHideBoss() then
            self.HideBossPoint = XBossPoint.New(self, self.HideBoss.gameObject:LoadPrefab(XColorTableConfigs.GetBossPointPrefab()))
            self.HideBossPoint:SetPointId(pointId)
        elseif pointType == XColorTableConfigs.PointType.Tower then
            self.MapPoints[positionId] = XMapPoint.New(self, self.Downtown)
            self.MapPoints[positionId]:SetPointId(pointId)
            self.MapPoints[positionId]:Refresh()
            self.DowntownName.gameObject:SetActiveEx(true)
        elseif XTool.IsNumberValid(positionId) then
            local obj = self.MapPointObjs[positionId].gameObject:LoadPrefab(XColorTableConfigs.GetMapPointPrefab(pointType))
            self.MapPoints[positionId] = XMapPoint.New(self, obj)
            self.MapPoints[positionId]:SetPointId(pointId)
            self.MapPoints[positionId]:Refresh()
        end
    end
end

---------------------------------------------------------------

return XPanelMap