---@field _Control XRhythmGameControl
---@class XUiRhythmGamePopupChoose : XLuaUi
local XUiRhythmGamePopupChoose = XLuaUiManager.Register(XLuaUi, "UiRhythmGamePopupChoose")

function XUiRhythmGamePopupChoose:OnAwake()
    self:InitButton()
end

function XUiRhythmGamePopupChoose:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.Close)
end

--- func desc
---@param mapIdList number[]
function XUiRhythmGamePopupChoose:OnStart(rhythmGameControlId, ...)
    self.RhythmGameControlId = rhythmGameControlId
    self.GameArg = {...}
    local controlConfig = XMVCA.XRhythmGame:GetModeltRhythmGameControl()[rhythmGameControlId]
    self.ControlConfig = controlConfig
    self.MapIdList = controlConfig.MapIds
    self:RefreshUiShow()
end

function XUiRhythmGamePopupChoose:RefreshUiShow()
    for k, mapId in pairs(self.MapIdList) do
        local curBtn = XUiHelper.Instantiate(self.BtnMap.gameObject, self.BtnMap.transform.parent):GetComponent("XUiButton")
        local mapConfig = self._Control:GetModelRhythmGameTaikoMapConfig("Map"..mapId)
        curBtn:SetNameByGroup(0, mapConfig["Title"].Value)
        curBtn:SetRawImage(mapConfig["EntranceIcon"].Value)

        local mapCondition = self.ControlConfig.MapConditions[k]
        local isLock = false
        local res, tipString
        res = true
        if XTool.IsNumberValid(mapCondition) then
            res, tipString = XConditionManager.CheckCondition(mapCondition)
            if not res then
                isLock = true
                curBtn:SetNameByGroup(1, tipString)
            end
        end
        curBtn:SetDisable(isLock)

        XUiHelper.RegisterClickEvent(self, curBtn, function ()
            if not res then
                XUiManager.TipMsg(tipString)
                return
            end
            XMVCA.XRhythmGame:EnterGame(mapId, table.unpack(self.GameArg))
            XMVCA.XRhythmGame:RecordEnterMapCache(mapId)
        end)
    end
    self.BtnMap.gameObject:SetActiveEx(false)
end