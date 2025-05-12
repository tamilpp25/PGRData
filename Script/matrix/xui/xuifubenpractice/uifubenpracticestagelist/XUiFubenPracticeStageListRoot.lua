---试玩角色的教学关部分，与试玩角色共用配置和基础逻辑，但是从赛利卡界面跳转的单独的界面
---@class XUiFubenPracticeStageList: XLuaUi
local XUiFubenPracticeStageListRoot = XLuaUiManager.Register(XLuaUi, 'UiFubenPracticeStageListRoot')
local XUiPanelFubenPracticeStageList = require('XUi/XUiFubenPractice/UiFubenPracticeStageList/XUiPanelFubenPracticeStageList')

function XUiFubenPracticeStageListRoot:OnAwake()
    self.BtnBack.CallBack = handler(self, self.Close)
    self.BtnMainUi.CallBack = XLuaUiManager.RunMain
    
    -- 界面暂不需要显示图文和资源的
    if self.BtnHelp then
        self.BtnHelp.gameObject:SetActiveEx(false)
    end

    if self.PanelAsset then
        self.PanelAsset.gameObject:SetActiveEx(false)
    end
end

---@param activityId @TeachingActivity.tab的Id
function XUiFubenPracticeStageListRoot:OnStart(activityId)
    self.ActivityId = activityId
    self.ActivityCfg = XFubenNewCharConfig.GetDataById(self.ActivityId)

    self.StageGo = self.PanelStageRoot:LoadPrefab(self.ActivityCfg.FubenPrefab)
    self.StageGo.gameObject:SetActiveEx(false)
    self.PanelStageList = XUiPanelFubenPracticeStageList.New(self.StageGo, self, self.ActivityCfg)
    self.PanelStageList:Open()
    self.PanelStageList:SetSubDetailPanelKey("UiFubenPracticeStageDetail")
end


return XUiFubenPracticeStageListRoot