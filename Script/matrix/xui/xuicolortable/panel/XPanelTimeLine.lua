local MaxTimePointCount = 6
local FirstTimePointPostionY = -330
local PositionOffectY = 45
local TimePointOffectY = 8

-- Grid - 时间轴点
--===============================================================================
local XTimelinePoint  = XClass(nil, "XTimelinePoint")

function XTimelinePoint:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XTimelinePoint:Refresh(timelineData, index)
    local icon = XColorTableConfigs.GetTimeLinePointIcon(timelineData.Type)
    if icon then
        self.ImgMod:SetSprite(icon)
    else
        self.ImgMod.gameObject:SetActiveEx(false)
    end
    local height = self.Transform.rect.height
    self.Transform.localPosition = Vector3(self.Transform.localPosition.x, FirstTimePointPostionY + (height - TimePointOffectY) * (index - 1), self.Transform.localPosition.z)
    self:SetActive(true)
end

function XTimelinePoint:SetPosition(YValue)
    self.Transform.localPosition = Vector3(self.Transform.localPosition.x, YValue, self.Transform.localPosition.z)
end

function XTimelinePoint:SetActive(active)
    self.GameObject:SetActiveEx(active)
end

--===============================================================================



-- 时间轴
local XPanelTimeLine = XClass(nil, "XPanelTimeLine")

function XPanelTimeLine:Ctor(root, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Root = root

    self:_InitUiObject()
end


-- public
---------------------------------------------------------------------

function XPanelTimeLine:TimeLineMove()
    local temp = self.TimeLineObjs[1]
    for i = 1, MaxTimePointCount - 1, 1 do
        self.TimeLineObjs[i] = self.TimeLineObjs[i + 1]
    end
    self.TimeLineObjs[MaxTimePointCount] = temp
end

function XPanelTimeLine:PlayTimePointDropAnim(callback)
    if self.CurTimelineId == self.GameData:GetTimelineId() then
        self:RefreshTimelineData(callback)
        return
    end
    XLuaUiManager.SetMask(true)
    self:_ShowEffect()
    -- 记录偏移前坐标
    local tagetValues = {}
    for index, obj in ipairs(self.TimeLineObjs) do
        tagetValues[index] = obj.Transform.localPosition.y
    end
    -- 播放动画
    XUiHelper.Tween(0.5, function(f)
        if XTool.UObjIsNil(self.Transform) then return end
        for index, obj in ipairs(self.TimeLineObjs) do
            obj:SetPosition(tagetValues[index] - self.Ruler.rect.height * f)
        end
    end, function()
        XLuaUiManager.SetMask(false)
        self:RefreshTimelineData(callback)
    end)
end

function XPanelTimeLine:RefreshTimelineData(callback)
    self:UpdataShowTimePointDir()
    for index, obj in ipairs(self.TimeLineObjs) do
        obj:Refresh(self.TimePointDatas[self.ShowTimeDataDir[index]], index)
    end
    if callback then
        callback()
    end
end

function XPanelTimeLine:UpdataShowTimePointDir()
    self.CurTimelineId = self.GameData:GetTimelineId()
    self.CurTimeBlock = self.GameData:GetTimeBlock()
    local timelineId = self.CurTimelineId + 1
    local dataCount = #self.TimePointDatas
    for i = 1, dataCount, 1 do
        local realTimeBlock = self.CurTimeBlock
        local index = timelineId + i - 1
        if timelineId < dataCount then
            realTimeBlock = realTimeBlock + 1
            realTimeBlock = realTimeBlock > self.EdgeId and self.EdgeId or realTimeBlock
        end
        while index > dataCount do
            local offset = index - dataCount
            index = realTimeBlock + offset - 1
            realTimeBlock = realTimeBlock + 1
            realTimeBlock = realTimeBlock > self.EdgeId and self.EdgeId or realTimeBlock
        end
        self.ShowTimeDataDir[i] = index
    end
end

function XPanelTimeLine:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_TIMEBLOCKCHANGE, self.PlayTimePointDropAnim, self)
    XEventManager.AddEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_TIMEBLOCKRESET, self.PlayTimePointDropAnim, self)
end

function XPanelTimeLine:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_TIMEBLOCKCHANGE, self.PlayTimePointDropAnim, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_TIMEBLOCKRESET, self.PlayTimePointDropAnim, self)
end

---------------------------------------------------------------------



-- private
---------------------------------------------------------------------

function XPanelTimeLine:_InitUiObject()
    XTool.InitUiObject(self)
    self.PanelEffect = self.Transform:Find("PanelEffect")
    self.TextScore.gameObject:SetActiveEx(false)
    -- 重定位坐标使时间轴下落消失点与特效对其
    self.TargetImage = XUiHelper.TryGetComponent(self.PanelContent.transform, "Image")
    self.TargetImage.transform:SetParent(self.Transform)
    self.PanelViewport = self.PanelContent.transform.parent
    self.PanelViewport.localPosition = self.PanelViewport.localPosition + Vector3(0, PositionOffectY, 0)

    self.GameData = XDataCenter.ColorTableManager.GetGameManager():GetGameData()
    self.CurTimelineId = self.GameData:GetTimelineId()
    self.CurTimeBlock = self.GameData:GetTimeBlock()
    self.EdgeId = nil
    self.ShowTimeDataDir = {}       -- 当前需显示时间点数据下标索引字典
    self.TimeLineObjs = {}          -- 时间点对象字典
    self.TimePointDatas = XColorTableConfigs.GetColorTableTimeline()
    for _, timeLineConfig in ipairs(self.TimePointDatas) do
        if XTool.IsNumberValid(timeLineConfig.IsEdge) then
            self.EdgeId = timeLineConfig.Id
        end
    end

    self:UpdataShowTimePointDir()
    self.Ruler.gameObject:SetActiveEx(false)
    for i = 1, MaxTimePointCount, 1 do
        table.insert(self.TimeLineObjs, XTimelinePoint.New(XUiHelper.Instantiate(self.Ruler, self.PanelContent)))
        self.TimeLineObjs[i]:Refresh(self.TimePointDatas[self.ShowTimeDataDir[i]], i)
    end
end

function XPanelTimeLine:_ShowEffect()
    if self.PanelEffect then
        self.PanelEffect.gameObject:SetActiveEx(false)
        self.PanelEffect.gameObject:SetActiveEx(true)
    end
end

---------------------------------------------------------------------

return XPanelTimeLine