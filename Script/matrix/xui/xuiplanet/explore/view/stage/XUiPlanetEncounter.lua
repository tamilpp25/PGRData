---@class XUiPlanetEncounter:XLuaUi
local XUiPlanetEncounter = XLuaUiManager.Register(XLuaUi, "UiPlanetEncounter")

function XUiPlanetEncounter:Ctor()
    self._Timer = false
    self._Duration = 1
    self._Time = 0
    self._Callback = false
end

function XUiPlanetEncounter:OnAwake()
    self:InitUiObj()
end

function XUiPlanetEncounter:OnStart(callback, tipType)
    if not self._Timer then
        -- 应对同时打开多个窗口, 相互覆盖造成的bug
        self._Timer = XScheduleManager.ScheduleForever(function()
            if self._Time > self._Duration then
                XLuaUiManager.SafeClose(self.Name)
                return
            end
            self._Time = self._Time + CS.UnityEngine.Time.unscaledDeltaTime
        end, 0)
    end
    self._Callback = callback
    self._TipType = tipType or XPlanetConfigs.TipType.Boss
    self:SetAutoCloseInfo()
end

function XUiPlanetEncounter:OnEnable()
    self:RefreshTip()
end

function XUiPlanetEncounter:OnDisable()
end

function XUiPlanetEncounter:OnDestroy()
    if self._Callback then
        self._Callback()
        self._Callback = false
    end
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XUiPlanetEncounter:InitUiObj()
    self.TipObjList = {
        [XPlanetConfigs.TipType.Boss] = self.RImgBoss02,
        [XPlanetConfigs.TipType.Monster] = self.RImgBoss01,
        [XPlanetConfigs.TipType.BossBorn] = self.RImgTips07,
        [XPlanetConfigs.TipType.GameWin] = self.RImgTips05,
        [XPlanetConfigs.TipType.GameOver] = self.RImgTips06,

        [XPlanetConfigs.TipType.NewTalentBuildLimit] = self.RImgTips01,
        [XPlanetConfigs.TipType.NewBuild] = self.RImgTips02,
        [XPlanetConfigs.TipType.NewCharacter] = self.RImgTips04,
    }

    self.TipEffectList = {
        [XPlanetConfigs.TipType.Boss] = self.RImgBoss02Effect,
    }
end

function XUiPlanetEncounter:RefreshTip()
    for key, obj in pairs(self.TipObjList) do
        obj.gameObject:SetActiveEx(key == self._TipType)
        if self.TipEffectList[key] then
            self.TipEffectList[key].gameObject:SetActiveEx(key == self._TipType)
        end
    end
end

return XUiPlanetEncounter