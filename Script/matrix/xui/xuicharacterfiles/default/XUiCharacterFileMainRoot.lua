---试玩活动主界面默认版本，基于2.17的试玩活动界面逻辑
---若有定制化需求建议派生定制版本，否则可复用本控制代码
---@class XUiCharacterFileMainRoot: XLuaUi
local XUiCharacterFileMainRoot = XLuaUiManager.Register(XLuaUi, 'UiCharacterFileMainRoot')
local XUiPanelNewCharTask=require('XUi/XUiNewChar/XUiPanelNewCharTask')
local XUiPanelCharacterFileMain = require('XUi/XUiCharacterFiles/Default/XUiPanelCharacterFileMain')
local XUiPanelFubenPracticeStageList = require('XUi/XUiFubenPractice/UiFubenPracticeStageList/XUiPanelFubenPracticeStageList')
local XUiPanelFubenChallengeStageList = require('XUi/XUiCharacterFiles/Default/XUiPanelFubenChallengeStageList')
local XUiPanelCharacterFileFullBg = require('XUi/XUiCharacterFiles/Default/XUiPanelCharacterFileFullBg')

--region 生命周期
function XUiCharacterFileMainRoot:OnAwake()
    self:InitButtons()
end

function XUiCharacterFileMainRoot:OnStart(actId)
    self.Id = actId
    self.CurPanelStage = XDataCenter.FubenNewCharActivityManager.GetKoroLastOpenPanel() or XFubenNewCharConfig.KoroPanelType.Normal
    ---@type XTableTeachingActivity
    self.ActivityCfg = XFubenNewCharConfig.GetDataById(self.Id)

    self:InitPanel()
end

function XUiCharacterFileMainRoot:OnEnable()
    -- 界面缓存上一次播放的BGM
    self._LastBGMCueIdCache = XLuaAudioManager.GetCurrentMusicId()
    
    XDataCenter.FubenNewCharActivityManager.PlayMainUiBGMById(self.Id)
    self:SwitchPanelStage(self.CurPanelStage)
end

function XUiCharacterFileMainRoot:OnDisable()

end
--endregion

--region 初始化
function XUiCharacterFileMainRoot:InitPanel()
    -- 初始化主界面
    self.MainFullBgGo = self.PanelBgRoot:LoadPrefab(self.ActivityCfg.MainFullBgPrefab)
    self.MainFullBgGo.gameObject:SetActiveEx(true)

    if XTool.IsNumberValid(self.ActivityCfg.CustomUiControlType) then
        local script = XFubenNewCharConfig.UiCustomScripts[self.ActivityCfg.CustomUiControlType].FullBgUi

        if not string.IsNilOrEmpty(script) then
            self.PanelFullBg = require(script).New(self.MainFullBgGo, self, self.ActivityCfg)
        else
            XLog.Error('找不到目标类型的UI控件，CustomUiControlType：'..tostring(self.ActivityCfg.CustomUiControlType))
            return
        end
    else
        self.PanelFullBg = XUiPanelCharacterFileFullBg.New(self.MainFullBgGo, self, self.ActivityCfg)
    end
    self.PanelFullBg:Open()
    
    self.MainPanelGo = self.PanelMainRoot:LoadPrefab(self.ActivityCfg.MainPanelPrefab)
    self.MainPanelGo.gameObject:SetActiveEx(false)
    XUiHelper.SetCanvasesSortingOrder(self.MainPanelGo.transform)
    
    if XTool.IsNumberValid(self.ActivityCfg.CustomUiControlType) then
        local script = XFubenNewCharConfig.UiCustomScripts[self.ActivityCfg.CustomUiControlType].MainUi

        if not string.IsNilOrEmpty(script) then
            self.PanelMain = require(script).New(self.MainPanelGo, self, self.ActivityCfg)
        else
            XLog.Error('找不到目标类型的UI控件，CustomUiControlType：'..tostring(self.ActivityCfg.CustomUiControlType))
            return
        end
    else
        self.PanelMain = XUiPanelCharacterFileMain.New(self.MainPanelGo, self, self.ActivityCfg)
    end
    self.PanelMain:Open()
    
    -- 初始化教学关子界面
    self.FubenTeachingGo = self.PanelStageRoot:LoadPrefab(self.ActivityCfg.FubenPrefab)
    self.FubenTeachingGo.gameObject:SetActiveEx(false)
    XUiHelper.SetCanvasesSortingOrder(self.FubenTeachingGo.transform)
    self.PanelTeachingStage = XUiPanelFubenPracticeStageList.New( self.FubenTeachingGo, self,self.ActivityCfg)
    self.PanelTeachingStage:SetSubDetailPanelKey("UiCharacterFileFubenTeachingDetail")
    
    -- 初始化挑战关子界面
    self.FubenChallengeGo = self.PanelChallengeStageRoot:LoadPrefab(self.ActivityCfg.FubenChallengePrefab)
    self.FubenChallengeGo.gameObject:SetActiveEx(false)
    XUiHelper.SetCanvasesSortingOrder(self.FubenChallengeGo.transform)
    self.PanelChallengeStage = XUiPanelFubenChallengeStageList.New(self.FubenChallengeGo, self, self.ActivityCfg)
    self.PanelChallengeStage:SetSubDetailPanelKey("UiCharacterFileFubenChallengeDetail")
    
    -- 初始化任务奖励子界面
    self.TaskPanel = XUiPanelNewCharTask.New(self.PanelTreasure,self,self.ActivityCfg)
    self.TaskPanel:Close()
end

function XUiCharacterFileMainRoot:InitButtons()
    self.BtnBack.CallBack = handler(self, self.OnBtnBackClick)
    self.BtnMainUi.CallBack = handler(self, self.OnBtnMainUiClick)
end
--endregion

--region 界面刷新
function XUiCharacterFileMainRoot:RefreshMainTask()
    self.PanelMain:RefreshMainTask()
end

function XUiCharacterFileMainRoot:CheckRedPoint()
    self.PanelMain:CheckRedPoint()
end
--endregion

--region 事件
function XUiCharacterFileMainRoot:OnBtnBackClick()
    if self.CurPanelStage == XFubenNewCharConfig.KoroPanelType.Normal then
        XDataCenter.FubenNewCharActivityManager.SetKoroLastOpenPanel(self.CurPanelStage)
        self:Close()
        self:ResumeLastBGM()
        return
    end
    self:SwitchPanelStage(XFubenNewCharConfig.KoroPanelType.Normal)
end

function XUiCharacterFileMainRoot:OnBtnMainUiClick()
    XDataCenter.FubenNewCharActivityManager.SetKoroLastOpenPanel(XFubenNewCharConfig.KoroPanelType.Normal)
    XLuaUiManager.RunMain()
end
--endregion

--region 功能逻辑
--- 切换到挑战界面或者教学关界面
function XUiCharacterFileMainRoot:SwitchPanelStage(panelStage)
    local isChallenge = panelStage == XFubenNewCharConfig.KoroPanelType.Challenge
    if isChallenge and not XMVCA.XSubPackage:CheckSubpackage() then
        return
    end
    XDataCenter.FubenNewCharActivityManager.SetKoroLastOpenPanel(panelStage)
    if panelStage ~= XFubenNewCharConfig.KoroPanelType.Normal then
        self.PanelMain:Close()
        if panelStage == XFubenNewCharConfig.KoroPanelType.Teaching then
            self.PanelTeachingStage:Open()
        elseif isChallenge then
            self.PanelChallengeStage:Open()
        end
        self.CurPanelStage = panelStage
    else
        if self.PanelTeachingStage:CheckCanClose() and self.PanelChallengeStage:CheckCanClose() then
            self.PanelMain:Open()
            self.PanelTeachingStage:Close()
            self.PanelChallengeStage:Close()
            self.CurPanelStage = panelStage
        end
    end
end


--- 结束当前玩法的BGM，恢复上次的BGM
function XUiCharacterFileMainRoot:ResumeLastBGM()
    if XTool.IsNumberValid(self._LastBGMCueIdCache) then
        XLuaAudioManager.PlayMusicCD(self._LastBGMCueIdCache, 0, 0)
    end    
end

--endregion




return XUiCharacterFileMainRoot