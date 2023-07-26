local XBasePoint = require("XEntity/XColorTable/Map/XBasePoint")
local XMapPoint = XClass(XBasePoint, "XMapPoint")

function XMapPoint:Ctor()
    self._PointId = 0
end

-- overrride
-------------------------------------------------------------------

function XMapPoint:SetPointId(pointId)
    self._PointId = pointId
    self:_Init()
end

function XMapPoint:IsMapPoint()
    return true
end

function XMapPoint:Excute()
    local pointType = self:GetType()
    if pointType == XColorTableConfigs.PointType.Lab then
        local gamedata = XDataCenter.ColorTableManager.GetGameManager():GetGameData()
        if not gamedata:CheckIsStudyLevelMax(self:GetColorType()) then
            XDataCenter.ColorTableManager.GetGameManager():RequestExecute(0)
        end
    elseif pointType == XColorTableConfigs.PointType.Hospital then
        XDataCenter.ColorTableManager.GetGameManager():RequestExecute(0)
    elseif pointType == XColorTableConfigs.PointType.Supply then
        XDataCenter.ColorTableManager.GetGameManager():RequestRoll(self:GetColorType())
    end
end

function XMapPoint:SetTipPanelActive(active)
    if active then
        XEventManager.DispatchEvent(XEventId.EVENT_COLOR_TABLE_OPEN_MAPPOINT_TIP, self, self.Transform.position)
    else
        XEventManager.DispatchEvent(XEventId.EVENT_COLOR_TABLE_CLOSE_MAPPOINT_TIP)
    end
end

-------------------------------------------------------------------



-- public
-------------------------------------------------------------------

function XMapPoint:Refresh()
    local gameManager = XDataCenter.ColorTableManager.GetGameManager()
    local isDisable = gameManager:GetPointIsDiable(self:GetType(), self:GetColorType())
    if self.PanelDisable then
        self.PanelDisable.gameObject:SetActiveEx(isDisable)
    end
end

function XMapPoint:RefreshStudyLevel(studyLevels, cb)
    if self:GetType() ~= XColorTableConfigs.PointType.Lab then
        return
    end
    self.TxtName1.text = XUiHelper.GetText("ColorTableLvTxt", studyLevels[self:GetColorType()])

    local changeValue = studyLevels[self:GetColorType()] - self._LibLv
    local gamedata = XDataCenter.ColorTableManager.GetGameManager():GetGameData()
    if changeValue == 0 then
        if cb then cb() end
        return
    end
    self._LibLv = studyLevels[self:GetColorType()]
    self.TxtName2.transform.localPosition = self.LvUpDownInitPosition
    self.TxtName2.text = changeValue > 0 and "+" .. changeValue or changeValue
    self:_PlayLvUpDownAnim()
    if gamedata:CheckIsStudyLevelMax(self:GetColorType()) then
        XLuaUiManager.Open("UiColorTableMainTips", self:GetColorType(), function ()
            self:ShowStudyLevelChangeEffect(self:GetColorType(), cb)
        end)
    else
        self:ShowStudyLevelChangeEffect(self:GetColorType(), cb)
    end
end

function XMapPoint:ShowStudyLevelChangeEffect(color, cb)
    if self.PanelEffectRedStudy then
        self.EffectDir[color].gameObject:SetActiveEx(false)
        self.EffectDir[color].gameObject:SetActiveEx(true)
    end
    if cb then cb() end
end

-- 阶段二不需要显示名称
function XMapPoint:RefreshWin()
    if self.TxtName then self.TxtName.gameObject:SetActiveEx(false) end
    if self.TxtName1 then self.TxtName1.gameObject:SetActiveEx(false) end
    if self.TxtName2 then self.TxtName2.gameObject:SetActiveEx(false) end
    if self.TxtName3 then self.TxtName3.gameObject:SetActiveEx(false) end
    if self.TxtLvBg then self.TxtLvBg.gameObject:SetActiveEx(false) end
end

function XMapPoint:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_REFRESHEVENT, self.Refresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_STUDYLEVELCHANGE, self.RefreshStudyLevel, self)
end

function XMapPoint:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_REFRESHEVENT, self.Refresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_STUDYLEVELCHANGE, self.RefreshStudyLevel, self)
end

-------------------------------------------------------------------


-- private
-------------------------------------------------------------------

function XMapPoint:_Init()
    local gamedata = XDataCenter.ColorTableManager.GetGameManager():GetGameData()
    if self.Icon then
        self.Icon:SetRawImage(self:GetIcon())
    end
    self.TxtName.text = self:GetName()
    if self:GetType() == XColorTableConfigs.PointType.Lab then
        self.TxtName2.gameObject:SetActiveEx(false)
        if not self.TxtLvBg then
            self.TxtLvBg = self.Transform:Find("TxtLvBg")
        end
        if self.PanelEffectRedStudy then
            self.PanelEffectRedStudy.gameObject:SetActiveEx(false)
            self.PanelEffectGreenStudy.gameObject:SetActiveEx(false)
            self.PanelEffectBlueStudy.gameObject:SetActiveEx(false)
            self.EffectDir = {
                [XColorTableConfigs.ColorType.Red] = self.PanelEffectRedStudy,
                [XColorTableConfigs.ColorType.Green] = self.PanelEffectGreenStudy,
                [XColorTableConfigs.ColorType.Blue] = self.PanelEffectBlueStudy,
            }
        end
        self.LvUpDownInitPosition = self.TxtName2.transform.localPosition
        self._LibLv = gamedata:GetStudyLevels(self:GetColorType())
        self:RefreshStudyLevel(gamedata:GetStudyLevels())
        XDataCenter.ColorTableManager.GetGameManager():AddLabCount()
    elseif self:GetType() == XColorTableConfigs.PointType.Tower then
        self.TxtName.gameObject:SetActiveEx(true)
        self.TxtName3.gameObject:SetActiveEx(true)
    end
    local selectIcon = XColorTableConfigs.GetPointSelectIcon(self:GetType(), self:GetColorType())
    local disableIcon = XColorTableConfigs.GetPointDisableIcon(self:GetType(), self:GetColorType())
    if self.SelectIcon and selectIcon then
        self.SelectIcon:SetRawImage(selectIcon)
    end
    if self.DisableIcon and disableIcon then
        self.DisableIcon:SetRawImage(disableIcon)
    end
end

function XMapPoint:_PlayLvUpDownAnim()
    self.TxtName2.gameObject:SetActiveEx(true)
    XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self.TxtName2.gameObject:SetActive(false)
    end, 2000)
end

-------------------------------------------------------------------

return XMapPoint