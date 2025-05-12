local XUiPanelCharacterFileMain = require('XUi/XUiCharacterFiles/Default/XUiPanelCharacterFileMain')
--- 试玩角色主界面 鬼泣联动派生类
---@class XUiPanelCharacterFileDMCMain: XUiPanelCharacterFileMain
---@field Parent XUiCharacterFileMainRoot
local XUiPanelCharacterFileDMCMain = XClass(XUiPanelCharacterFileMain, 'XUiPanelCharacterFileDMCMain')

-- 但丁-维吉尔活动互相跳转的映射
local ActivityIdSkipMap = nil

---@overload
function XUiPanelCharacterFileDMCMain:OnStart(cfg)
    XUiPanelCharacterFileMain.OnStart(self, cfg)

    if ActivityIdSkipMap == nil or XMain.IsEditorDebug then
        ActivityIdSkipMap = {}
        local activityId1 = XFubenNewCharConfig.GetClientConfigNumByKey('DMCActivityIds', 1)
        local activityId2 = XFubenNewCharConfig.GetClientConfigNumByKey('DMCActivityIds', 2)

        ActivityIdSkipMap[activityId1] = activityId2
        ActivityIdSkipMap[activityId2] = activityId1
    end

    if self.BtnSwitch then
        self.ReddotId = self:AddRedPointEvent(self.BtnSwitch, self.OnBtnSwitchReddot, self, {XRedPointConditions.Types.CONDITION_KOROMCHARACTIVITYMAINRED}, ActivityIdSkipMap[self.ActivityCfg.Id])
    end
end

---@overload
function XUiPanelCharacterFileDMCMain:CheckRedPoint()
    XUiPanelCharacterFileMain.CheckRedPoint(self)
    
    if XTool.IsNumberValid(self.ReddotId) then
        XRedPointManager.Check(self.ReddotId)
    end
end

---@overload
function XUiPanelCharacterFileDMCMain:InitButtons()
    XUiPanelCharacterFileMain.InitButtons(self)

    if self.BtnSwitch then
        local switchBtnShowTimeId = XFubenNewCharConfig.GetClientConfigNumByKey('DMCSwitchBtnShowTimeId', 1)

        local isBtnShow = XFunctionManager.CheckInTimeByTimeId(switchBtnShowTimeId, false)

        self.BtnSwitch.gameObject:SetActiveEx(isBtnShow)
        
        if isBtnShow then
            self.BtnSwitch.CallBack = handler(self, self.OnBtnSwitchClick)
        end
    end
end

function XUiPanelCharacterFileDMCMain:OnBtnSwitchClick()
    local aimActivityId = ActivityIdSkipMap[self.ActivityCfg.Id]

    if XTool.IsNumberValid(aimActivityId) then
        -- 直接移除界面不播切换动画，防止看到底下的其他界面
        XLuaUiManager.Remove('UiCharacterFileMainRoot')
        -- 根据新指定的活动Id重新打开界面
        XDataCenter.FubenNewCharActivityManager.SkipToActivityMain(aimActivityId)
    end
end

function XUiPanelCharacterFileDMCMain:OnBtnSwitchReddot(count)
    self.BtnSwitch:ShowReddot(count >= 0)
end

return XUiPanelCharacterFileDMCMain