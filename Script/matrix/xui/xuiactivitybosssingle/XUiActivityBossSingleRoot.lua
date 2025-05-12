--- 超难关主界面根界面
---@class XUiActivityBossSingleRoot: XLuaUi
local XUiActivityBossSingleRoot = XLuaUiManager.Register(XLuaUi, 'UiActivityBossSingleRoot')

function XUiActivityBossSingleRoot:OnStart(sectionId)
    local activityId = XDataCenter.FubenActivityBossSingleManager.GetCurActivityId()

    if XTool.IsNumberValid(activityId) then
        local activityCfg = XFubenActivityBossSingleConfigs.GetActivityConfig(activityId)

        if activityCfg then
            if not string.IsNilOrEmpty(activityCfg.PrefabAddress) then
                self.PanelActivityObj = self.FullScreenBackground:LoadPrefab(activityCfg.PrefabAddress)
                
                if self.PanelActivityObj then
                    XUiHelper.SetCanvasesSortingOrder(self.PanelActivityObj)
                    local module = require(activityCfg.CustomUiScripts or 'XUi/XUiActivityBossSingle/PanelBossSingleMain/XUiPanelBossSingleMainNormal')
                    self.ActivityPanel = module.New(self.PanelActivityObj, self, sectionId, self._IsResumeRun)
                    self.ActivityPanel:Open()
                end
            else
                XLog.Error('活动'..tostring(activityId)..'未配置预制体路径')
            end
        else
            XLog.Error('没有活动Id为:'..tostring(activityId)..'的配置')
        end
    else
        XLog.Error('当前没有正在进行的活动')
    end

    self._IsResumeRun = nil
end

function XUiActivityBossSingleRoot:OnResume()
    self._IsResumeRun = true
end

return XUiActivityBossSingleRoot