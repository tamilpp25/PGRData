local XUiArenaSceneZone = require("XUi/XUiArenaNew/XUiArenaSceneZone")

---@class XUiArenaScene
---@field UiStateControl XUiComponent.XUiStateControl
---@field StageGroup1 UnityEngine.RectTransform
---@field StageGroup2 UnityEngine.RectTransform
---@field StageGroup3 UnityEngine.RectTransform
---@field StageGroup4 UnityEngine.RectTransform
---@field StageGroup5 UnityEngine.RectTransform
---@field EarthPoint1 UnityEngine.Transform
---@field EarthPoint2 UnityEngine.Transform
---@field EarthPoint3 UnityEngine.Transform
---@field EarthPoint4 UnityEngine.Transform
---@field EarthPoint5 UnityEngine.Transform
---@field ArenaStage XUiComponent.XUiStateControl
---@field BtnZone XUiComponent.XUiButton
local XUiArenaScene = XClass(nil, "XUiArenaScene")

function XUiArenaScene:Ctor(sceneObject)
    ---@type XUiArenaSceneZone[]
    self._ZoneList = {}
    self._StartIndex = 0
    self._CurrentSelectIndex = 1
    XTool.InitUiObjectByUi(self, sceneObject)
end

function XUiArenaScene:PlayStartAnimation()
    if self.Transform then
        local animation = self.Transform:FindTransform("UiArenaNewEntryEnable")

        if animation then
            animation.gameObject:PlayTimelineAnimation()
        end
    end
end

function XUiArenaScene:PlayRankAnimation()
    if XTool.IsNumberValid(self._CurrentSelectIndex) then
        local zone = self._ZoneList[self._CurrentSelectIndex - self._StartIndex]
        
        if zone then
            zone:PlayRankAnimation()
        end
    end
end

function XUiArenaScene:PlayZoneStartAnimation()
    if not XTool.IsTableEmpty(self._ZoneList) then
        for _, zone in pairs(self._ZoneList) do
            zone:PlayeStartAnimation()
        end
    end
end

function XUiArenaScene:ChangeCamera(cameraName)
    self.UiStateControl:ChangeState(cameraName)
end

function XUiArenaScene:SetZoneByIndex(index, startIndex, info)
    local zone = self._ZoneList[index]

    self._StartIndex = startIndex
    if not zone then
        local zoneObject = XUiHelper.Instantiate(self.BtnZone, self["StageGroup" .. (index + startIndex)])
        local stageObject = XUiHelper.Instantiate(self.ArenaStage, self["EarthPoint" .. (index + startIndex)])

        zone = XUiArenaSceneZone.New(zoneObject, stageObject)
        self._ZoneList[index] = zone
    end

    zone:SetCurrentState(info.HasPoint and "Finish" or "Normal")
    zone:SetTextByIndex(0, info.StageName)
    zone:SetPlayerListActive(false)
    if info.HasPoint then
        zone:SetTextByIndex(1, info.Point)
        zone:SetTextActiveByIndex(1, true)
        zone:ShowTag(false)
    else
        zone:SetTextActiveByIndex(1, false)
        zone:ShowTag(true)
    end
end

function XUiArenaScene:ShowEnterEffect()
    if not XTool.IsTableEmpty(self._ZoneList) then
        for _, zone in pairs(self._ZoneList) do
            zone:SetEnterEffectActive(false)
            zone:SetEnterEffectActive(true)
        end
    end
end

function XUiArenaScene:ShowChangeEffect()
    if not XTool.IsTableEmpty(self._ZoneList) then
        for _, zone in pairs(self._ZoneList) do
            zone:SetChangeEffectActive(false)
            zone:SetChangeEffectActive(true)
        end
    end
end

function XUiArenaScene:HideChangeEffect()
    if not XTool.IsTableEmpty(self._ZoneList) then
        for _, zone in pairs(self._ZoneList) do
            zone:SetChangeEffectActive(false)
        end
    end
end

function XUiArenaScene:SetZoneClickEvent(index, clickEvent)
    local zone = self._ZoneList[index]

    if zone then
        zone:SetClickEvent(clickEvent)
    end
end

function XUiArenaScene:SetZonesSelectEvent(clickEvent)
    if not XTool.IsTableEmpty(self._ZoneList) then
        for index, zone in pairs(self._ZoneList) do
            zone:SetClickEvent(function()
                self:SelectZone(index)
                if clickEvent then
                    clickEvent(index)
                end
            end)
        end
    end
end

function XUiArenaScene:SetZoneActive(isActive)
    if not XTool.IsTableEmpty(self._ZoneList) then
        for _, zone in pairs(self._ZoneList) do
            zone:SetActive(isActive)
        end
    end
end

function XUiArenaScene:ChangeZoneState(index, stateName)
    local zone = self._ZoneList[index]

    if zone then
        zone:ChangeState(stateName)
    end
end

function XUiArenaScene:SelectZone(index)
    if not XTool.IsTableEmpty(self._ZoneList) then
        self._CurrentSelectIndex = index + self._StartIndex
        self:ChangeCamera("StageCamera" .. (index + self._StartIndex))
        for i, zone in pairs(self._ZoneList) do
            if index == i then
                zone:ChangeState("Select")
                zone:ShowPoint(true)
                zone:SetPlayerListActive(true)
            else
                zone:RecoveryState()
                zone:ShowPoint(false)
                zone:SetPlayerListActive(false)
            end
        end
    end
end

function XUiArenaScene:CancelSelectZone()
    if not XTool.IsTableEmpty(self._ZoneList) then
        for i, zone in pairs(self._ZoneList) do
            zone:ShowPoint(false)
            zone:RecoveryState()
        end
    end
end

---@param areaShowData XArenaAreaShowData
function XUiArenaScene:RefreshPlayerGrid(index, areaShowData)
    local zone = self._ZoneList[index]

    if zone then
        zone:RefreshPlayerGrid(areaShowData)
    end
end

function XUiArenaScene:GetCurrentSelectIndex()
    return self._CurrentSelectIndex
end

function XUiArenaScene:Destroy()
    self._ZoneList = {}
    self._StartIndex = 0
end

return XUiArenaScene
