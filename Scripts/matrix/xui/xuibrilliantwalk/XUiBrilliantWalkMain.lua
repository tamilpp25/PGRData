--光辉同行玩法主界面
local XUiBrilliantWalkMain = XLuaUiManager.Register(XLuaUi, "UiBrilliantWalkMain")
local XUIBrilliantWalkMiniTaskPanel = require("XUi/XUiBrilliantWalk/ModuleSubPanel/XUIBrilliantWalkMiniTaskPanel")--任务miniUI
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local WeaponModule = CS.XGame.ClientConfig:GetInt("BrilliantWalkWeaponModule")

function XUiBrilliantWalkMain:OnAwake()
    self.MainPanel = self.Transform:Find("SafeAreaContentPane")
    self:InitSceneRoot()
    --界面右边普通模块界面
    self.UiTaskPanel = XUIBrilliantWalkMiniTaskPanel.New(self.BtnTask,self)
    self.BtnZhuxian.CallBack =  function()
        self:OnMainClick()
    end
    self.BtnZhengzhuang.CallBack = function()
        self:OnZhengzhuangClick()
    end
    self.BtnMainUi.CallBack =  function()
        self:OnBtnMainUiClick()
    end
    self.BtnHelp.CallBack = function()
        self:OnBtnHelpClick()
    end
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnTask.CallBack = function()
        self:OnBtnTaskClick()
    end
    --活动结束自动关闭玩法
    self:SetAutoCloseInfo(XDataCenter.BrilliantWalkManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
    --子界面堆栈
    self.SubUIStack = XStack.New() --子UI堆栈(保存使用堆栈方式打开的UI)
    self.SubUIStackParament = XStack.New() --子UI堆栈数据堆栈(保存使用堆栈方式打开的UI的打开数据)
    --定时器
    self._Timer = nil

end
function XUiBrilliantWalkMain:InitSceneRoot()
    local root = self.UiModelGo.transform
    self.PanelRoleModel = root:FindTransform("PanelModel")
    self.CameraFar = {
        [XBrilliantWalkCameraType.Main] = root:FindTransform("UiCamFarMain"),
        [XBrilliantWalkCameraType.Chapter] = root:FindTransform("UiCamFarPanelExchange"),
        [XBrilliantWalkCameraType.Equipment] = root:FindTransform("UiCamFarEquipment"),
        [XBrilliantWalkCameraType.Trench1] = root:FindTransform("UiCamFarEquipment1"),
        [XBrilliantWalkCameraType.Trench2] = root:FindTransform("UiCamFarEquipment2"),
        [XBrilliantWalkCameraType.Trench3] = root:FindTransform("UiCamFarEquipment3"),
        [XBrilliantWalkCameraType.Trench4] = root:FindTransform("UiCamFarEquipment4"),
    }
    self.CameraNear = {
        [XBrilliantWalkCameraType.Main] = root:FindTransform("UiCamNearMain"),
        [XBrilliantWalkCameraType.Chapter] = root:FindTransform("UiCamNearPanelExchange"),
        [XBrilliantWalkCameraType.Equipment] = root:FindTransform("UiCamNearEquipment"),
        [XBrilliantWalkCameraType.Trench1] = root:FindTransform("UiCamNearEquipment1"),
        [XBrilliantWalkCameraType.Trench2] = root:FindTransform("UiCamNearEquipment2"),
        [XBrilliantWalkCameraType.Trench3] = root:FindTransform("UiCamNearEquipment3"),
        [XBrilliantWalkCameraType.Trench4] = root:FindTransform("UiCamNearEquipment4"),
    }
    self.UiEffect = {
        ["ChangePlugin"] = root:FindTransform("ImgEffectHuanren").gameObject,
    }
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true)
    self.RoleModelPanel:UpdateRoleModelWithAutoConfig("Mb1StarknightMd010002BW", XModelManager.MODEL_UINAME.UiBrilliantWalkMain,function()
        --更新机器人模型
        self:UpdateRobotModel()
    end)
    --UIModel动画
    self.UiModelAnime = {
        ["AnimEnable"] = root:FindTransform("AnimEnable").gameObject,
    }
end
function XUiBrilliantWalkMain:OnStart()
    self:PlayEnterAnime()
    XEventManager.AddEventListener(XEventId.EVENT_BRILLIANT_WALK_PLUGIN_SKIP, self.OnPluginSkip, self)
    XEventManager.AddEventListener(XEventId.EVENT_BRILLIANT_WALK_UIEFFECT_CHANGEPLUGIN, self.PlayChangePluginEffect, self)
    XEventManager.AddEventListener(XEventId.EVENT_BRILLIANT_WALK_PLUGIN_CHANGE, self.UpdateRobotModel, self)
    self.SubUIStack:Clear()
    self.SubUIStackParament:Clear()
end
function XUiBrilliantWalkMain:OnEnable()
    self.Super.OnEnable(self)
    self:UpdateView()
    self:SwitchSceneCamera(XBrilliantWalkCameraType.Main)
    self.RedPointID = XRedPointManager.AddRedPointEvent(self.BtnZhengzhuang.ReddotObj, nil, self,{ XRedPointConditions.Types.CONDITION_BRILLIANTWALK_PLUGIN }, -1)
    self.UiTaskPanel:OnEnable()
    if XDataCenter.BrilliantWalkManager.GetUiMainClearCache() then
        self.LastData = nil
    end
    --处理预存数据(跳转至之前选择的关卡界面)
    if self.LastData and self.LastData.SubUIStack then
        self.SubUIStack = self.LastData.SubUIStack
        self.SubUIStackParament = self.LastData.SubUIStackParament
        while( not self.SubUIStack:IsEmpty()) do
            local UiName = self.SubUIStack:Peek()
            if UiName == "UiBrilliantWalkChapterBoss" or UiName == "UiBrilliantWalkChapterStage" then
                local args = nil
                if not (self.SubUIStackParament:Peek() == "nil") then args = self.SubUIStackParament:Peek() end
                self:OpenOneChildUi(UiName,args)
                self.MainPanel.gameObject:SetActiveEx(false)
                break
            else
                self.SubUIStack:Pop()
                self.SubUIStackParament:Pop();
            end
        end
    else
        self.UiModelAnime.AnimEnable:PlayTimelineAnimation(function()
            XLuaUiManager.SetMask(false)
        end,function()
            XLuaUiManager.SetMask(true)
        end)
    end
    --关闭特效节点
    for k,effectNode in pairs(self.UiEffect) do
        effectNode:SetActiveEx(false)
    end
end
function XUiBrilliantWalkMain:OnDisable()
    self.Super.OnDisable(self)
    XEventManager.RemoveEventListener(XEventId.EVENT_BRILLIANT_WALK_PLUGIN_SKIP, self.OnPluginSkip, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_BRILLIANT_WALK_UIEFFECT_CHANGEPLUGIN, self.PlayChangePluginEffect, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_BRILLIANT_WALK_PLUGIN_CHANGE, self.UpdateRobotModel, self)
    XRedPointManager.RemoveRedPointEvent(self.RedPointID)
    self:StopTimer()
    self.UiTaskPanel:OnDisable()
    self.LastData = nil
end
function XUiBrilliantWalkMain:OnReleaseInst()
    return { SubUIStack = self.SubUIStack, SubUIStackParament = self.SubUIStackParament}
end
function XUiBrilliantWalkMain:OnResume(data)
    self.LastData = data
end
--刷新界面
function XUiBrilliantWalkMain:UpdateView()
    local viewData = XDataCenter.BrilliantWalkManager.GetUiDataMain()
    self.BtnBoss:SetNameByGroup(1, "/" .. viewData.MaxBossStageProcess)
    self.BtnBoss:SetNameByGroup(2, viewData.BossStageProcess)
    self.BtnBoss:SetNameByGroup(3, "/" .. viewData.MaxBossHardStageProcess)
    self.BtnBoss:SetNameByGroup(4, viewData.BossHardStageProcess)
    if viewData.IsBossChapterUnlock == true then
        self.BtnBoss:SetDisable(false)
        self.BtnBoss.CallBack = function()
            self:OnBossClick()
        end
    else
        self.BossChapter = viewData.BossChapterId
        self.BtnBoss:SetDisable(true)
        local lockMsg = ""
        if XDataCenter.BrilliantWalkManager.GetChapterIsOpen(self.BossChapter) then
            local preChapterConfig = XBrilliantWalkConfigs.GetChapterConfig(viewData.IsBossChapterUnlock)
            lockMsg = CsXTextManagerGetText("BrilliantWalkChapterUnlock",preChapterConfig.Name)
        else --还没开放 开定时器
            lockMsg = XDataCenter.BrilliantWalkManager.GetChapterOpenTimeMsg(self.BossChapter)
            self:StartTimer()
        end
        self.BtnBoss:SetNameByGroup(5, lockMsg)
        self.BtnBoss.CallBack = function()
            self:OnLockBossClick(lockMsg,self.BossChapter)
        end 
    end
    
    self.BtnZhuxian:SetNameByGroup(1, "/" .. viewData.MaxMainStageProcess)
    self.BtnZhuxian:SetNameByGroup(2, viewData.MainStageProcess)
    self.BtnZhuxian:SetNameByGroup(3, "/" .. viewData.MaxSubStageProcess)
    self.BtnZhuxian:SetNameByGroup(4, viewData.SubStageProcess)
    self.ActivityLeftTime.text = viewData.ActivityTime

    --任务miniUI视图
    self.UiTaskPanel:UpdateView(true)
end
--刷新机器人武器
function XUiBrilliantWalkMain:UpdateRobotModel()
    local ui = self.RoleModelPanel.Ui
    local equiped = XDataCenter.BrilliantWalkManager.CheckPluginEquiped(WeaponModule)
    local object1 = ui.transform:FindTransform("Mb1StarknightMd010001Weapon").gameObject
    object1:SetActiveEx(equiped)
    local object2 = ui.transform:FindTransform("Mb1StarknightMd010001Weapon01").gameObject
    object2:SetActiveEx(equiped)
    local object3 = ui.transform:FindTransform("Mb1StarknightMd010001Weapon02").gameObject
    object3:SetActiveEx(not equiped)
end

--region BOSS章开启倒计时
--开启章节开放倒计时
function XUiBrilliantWalkMain:StartTimer()
    if self._Timer then
        self:StopTimer()
    end
    self._Timer = XScheduleManager.ScheduleForever(
            function()
                self:ChapterOpenTick()
            end,
            XScheduleManager.SECOND
    )
end
--关闭章节开放倒计时
function XUiBrilliantWalkMain:StopTimer()
    if not self._Timer then
        return
    end
    XScheduleManager.UnSchedule(self._Timer)
    self._Timer = false
end
--章节开放倒计时TickFunction
function XUiBrilliantWalkMain:ChapterOpenTick()
    local chapterId = self.BossChapter
    if XDataCenter.BrilliantWalkManager.GetChapterIsOpen(chapterId) then
        self:UpdateView()
        self:StopTimer()
    else
        local lockMsg = XDataCenter.BrilliantWalkManager.GetChapterOpenTimeMsg(chapterId)
        self.BtnBoss:SetNameByGroup(5, lockMsg)
    end
end
--endregion

--region 子UI接口
--打开子UI（使用堆栈管理） 限制一个参数，想用多个参数请上表
function XUiBrilliantWalkMain:OpenStackSubUi(name, args)
    if args == nil then args = {} end
    args.OnStart = true
    self:OpenOneChildUi(name,args)
    self.SubUIStack:Push(name)
    self.SubUIStackParament:Push(args)
    self.MainPanel.gameObject:SetActiveEx(false)
end
--关闭顶层UI
function XUiBrilliantWalkMain:CloseStackTopUi()
    if self.SubUIStack:IsEmpty() then return end
    self:CloseChildUi(self.SubUIStack:Pop());
    self.SubUIStackParament:Pop();
    if self.SubUIStack:IsEmpty() then
        self.MainPanel.gameObject:SetActiveEx(true)
        self:UpdateView()
        self:SwitchSceneCamera(XBrilliantWalkCameraType.Main)
        return 
    end
    local args = self.SubUIStackParament:Peek()
    args.OnStart = false
    self:OpenOneChildUi(self.SubUIStack:Peek(),args)
end
--打开附属子UI (在打开或关闭某个子UI时，会关闭所有附属的子UI)
function XUiBrilliantWalkMain:OpenMiniSubUI(name,...)
    if self.SubUI then self:CloseMiniSubUI(self.SubUI) end
    self:OpenChildUi(name,...)
    self.SubUI = name
end
--关闭附属子UI
function XUiBrilliantWalkMain:CloseMiniSubUI(name)
    self:CloseChildUi(name);
end
--清空子界面缓存
function XUiBrilliantWalkMain:ClearSubUICache()
    self.SubUIStack:Clear()
    self.SubUIStackParament:Clear()
end
--切换场景镜头 参数是XBrilliantWalkCameraType
function XUiBrilliantWalkMain:SwitchSceneCamera(cameraType)
    self.CameraFar[cameraType].gameObject:SetActiveEx(false)
    self.CameraFar[cameraType].gameObject:SetActiveEx(true)
    self.CameraNear[cameraType].gameObject:SetActiveEx(false)
    self.CameraNear[cameraType].gameObject:SetActiveEx(true)
end
--播放机器人动画
function XUiBrilliantWalkMain:PlayModelAnim(anime,cb)
    self.RoleModelPanel:PlayAnima(anime,true,cb)
end
--播放机器人入场动画
function XUiBrilliantWalkMain:PlayEnterAnime()
    self:PlayModelAnim("In"..XTool.Random(1,2))
end
--播放机器人出击动画
function XUiBrilliantWalkMain:PlaySallyAnime(cb)
    XLuaUiManager.SetMask(true)
    self:PlayModelAnim("Out1",function()
        XLuaUiManager.SetMask(false)
        cb()
    end)
end
--endregion

--播放特效
function XUiBrilliantWalkMain:PlayChangePluginEffect()
    self.UiEffect.ChangePlugin:SetActiveEx(false)
    self.UiEffect.ChangePlugin:SetActiveEx(true)
end
--插件界面跳转
function XUiBrilliantWalkMain:OnPluginSkip(subUIView, skipData)
    self:OpenStackSubUi(subUIView, skipData)
end
--点击主线关卡
function XUiBrilliantWalkMain:OnMainClick()
    self:OpenStackSubUi("UiBrilliantWalkChapter")
end
--点击BOSS关卡
function XUiBrilliantWalkMain:OnBossClick()
    self:OpenStackSubUi("UiBrilliantWalkChapterBoss")
end
--点击未解锁BOSS关卡
function XUiBrilliantWalkMain:OnLockBossClick(msg,chapterId)
    if not XDataCenter.BrilliantWalkManager.GetChapterIsOpen(chapterId) then
        XUiManager.TipMsg(CS.XTextManager.GetText("BrilliantWalkChapterTimeTip"))
        return
    end
    XUiManager.TipMsg(msg)
end
--点击任务按钮
function XUiBrilliantWalkMain:OnBtnTaskClick()
    self:OpenStackSubUi("UiBrilliantWalkTask")
end
--点击整装按钮
function XUiBrilliantWalkMain:OnZhengzhuangClick()
    self:OpenStackSubUi("UiBrilliantWalkEquipment")
end
--点击返回按钮
function XUiBrilliantWalkMain:OnBtnBackClick()
    self:Close()
end
--点击主界面按钮
function XUiBrilliantWalkMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end
--点击感叹号按钮
function XUiBrilliantWalkMain:OnBtnHelpClick()
    XUiManager.ShowHelpTip("BrilliantWalk")
end