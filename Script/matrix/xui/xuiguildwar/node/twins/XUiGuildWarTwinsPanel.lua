local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiGuildWarTwinsClickBoard = require("XUi/XUiGuildWar/Node/Twins/XUiGuildWarTwinsClickBoard")
local XUiGuildWarTwinsStageDetail = require("XUi/XUiGuildWar/Node/Twins/XUiGuildWarTwinsStageDetail")
--当前界面的Action播放类型表
local PlayTypeList = {
    XGuildWarConfig.GWActionUiType.NodeDestroyed,
    XGuildWarConfig.GWActionUiType.Twins,
}

---@class XUiGuildWarTwinsPanel:XLuaUi
local XUiGuildWarTwinsPanel = XLuaUiManager.Register(XLuaUi, "UiGuildWarTwinsPanel")
---@return XTwinsRootGWNode
function XUiGuildWarTwinsPanel:GetNode()
    return XDataCenter.GuildWarManager:GetBattleManager():GetNode(self.NodeId)
end
function XUiGuildWarTwinsPanel:OnAwake()
    --根节点ID
    self.NodeId = false
    --根节点
    self.Node = false
    --定时器
    self.Timer = false
    --是否选定了节点
    self._SelectedNodeId = false
    -- 注册点击事件
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    self:BindHelpBtn(self.BtnHelp, "GuildWarHelpTwins")
    XUiHelper.RegisterClickEvent(self, self.PressLeft, self.OnBtnLeftClicked)
    XUiHelper.RegisterClickEvent(self, self.LeftBtnChallenge, self.OnBtnLeftClicked)
    XUiHelper.RegisterClickEvent(self, self.PressRight, self.OnBtnRightClicked)
    XUiHelper.RegisterClickEvent(self, self.RightBtnChallenge, self.OnBtnRightClicked)
    XUiHelper.RegisterClickEvent(self, self.PressMix, self.OnBtnMixClicked)
    XUiHelper.RegisterClickEvent(self, self.MixBtnChallenge, self.OnBtnMixClicked)
end
function XUiGuildWarTwinsPanel:OnStart(node, IsMonsterStatus, selectedNodeId)
    self.BattleManager = XDataCenter.GuildWarManager.GetBattleManager()
    self.Node = node
    self.NodeId = node:GetId()
    self:Init()
    self:InitCamera()
    self._SelectedNodeId = selectedNodeId
end
function XUiGuildWarTwinsPanel:Init()
    local node = self:GetNode()
    -- BOSS点击面板
    self.GridMixBossDetail = XUiGuildWarTwinsClickBoard.New(self.MixBoss, node, self)
    self.GridLeftBossDetail = XUiGuildWarTwinsClickBoard.New(self.LeftBoss, node:GetChildByIndex(1), self)
    self.GridRightBossBlack = XUiGuildWarTwinsClickBoard.New(self.RightBoss, node:GetChildByIndex(2), self)
    
    --副本详细面板
    self.StageDetail = XUiGuildWarTwinsStageDetail.New(self.PanelDetail,self)
    self.StageDetail:Hide()
    
    -- 资源面板
    local uiPanelAsset = XUiPanelAsset.New(self, self.PanelAsset, XGuildWarConfig.ActivityPointItemId)
    uiPanelAsset:HideBtnBuy()
end
function XUiGuildWarTwinsPanel:InitCamera()
    local node = self:GetNode()

    self.UiPanelRoleModelMix = self.UiModelGo.transform:FindTransform("PanelModelGeminiMix")
    local gameObjectModelMixLeft = self.UiPanelRoleModelMix:FindTransform("PanelModelGeminiLeft")
    local panelModelMixLeft = XUiPanelRoleModel.New(gameObjectModelMixLeft, self.Name, nil, true)
    panelModelMixLeft:UpdateRoleModel(node:GetChildModelId(1))
    local gameObjectModelMixRight = self.UiPanelRoleModelMix:FindTransform("PanelModelGeminiRight")
    local panelModelMixRight = XUiPanelRoleModel.New(gameObjectModelMixRight, self.Name, nil, true)
    panelModelMixRight:UpdateRoleModel(node:GetChildModelId(2))
    
    local panelModelLeft = self.UiModelGo.transform:FindTransform("PanelModelGeminiLeft")
    self.UiPanelRoleModelLeft = XUiPanelRoleModel.New(panelModelLeft, self.Name, nil, true)
    self.UiPanelRoleModelLeft:UpdateRoleModel(node:GetChildModelId(1))

    local panelModelRight = self.UiModelGo.transform:FindTransform("PanelModelGeminiRight")
    self.UiPanelRoleModelRight = XUiPanelRoleModel.New(panelModelRight, self.Name, nil, true)
    self.UiPanelRoleModelRight:UpdateRoleModel(node:GetChildModelId(2))


    self.CamNearMain = self:FindVirtualCamera("CamNearMain")
    self.UiCamNearBossMix1 = self:FindVirtualCamera("UiCamNearBossMix1")
    self.UiCamNearBossMix2 = self:FindVirtualCamera("UiCamNearBossMix2")
    self.UiCamNearBossLeft = self:FindVirtualCamera("UiCamNearBossLeft")
    self.UiCamNearBossRight = self:FindVirtualCamera("UiCamNearBossRight")
    
    self.CamFarMain = self:FindVirtualCamera("CamFarMain")
    self.UiCamFarBossMix2 = self:FindVirtualCamera("UiCamFarBossMix2")
    self.UiCamFarBossMix1 = self:FindVirtualCamera("UiCamFarBossMix1")
    self.UiCamFarBossLeft = self:FindVirtualCamera("UiCamFarBossLeft")
    self.UiCamFarBossRight = self:FindVirtualCamera("UiCamFarBossRight")
end
function XUiGuildWarTwinsPanel:OnEnable()
    XUiGuildWarTwinsPanel.Super.OnEnable(self)
    self:StartTimer()
    self:AddEventListener()
    local selectedNodeId = self._SelectedNodeId
    if selectedNodeId then
        self:SetNodeDetail(true, selectedNodeId)
    else
        self:SetNodeDetail(false, selectedNodeId)
    end
    self:UpdateView()
    local node = self:GetNode()
    if node:GetIsDead() then
        self:Close()
        --XLuaUiManager.Open("UiGuildWarStageDetail", node, false)
        return
    end
    self:UpdateNodeClickBoard()
    self:ShowAction()
end
function XUiGuildWarTwinsPanel:OnDisable()
    XUiGuildWarTwinsPanel.Super.OnDisable(self)
    self:RemoveEventListener()
    self:StopTimer()
    if XLuaUiManager.IsMaskShow(XGuildWarConfig.MASK_KEY) then
        XLuaUiManager.SetMask(false, XGuildWarConfig.MASK_KEY)
    end
end
--添加监听
function XUiGuildWarTwinsPanel:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_NODEDATA_CHANGE, self.UpdateNodeClickBoard, self)
    
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTIONLIST_OVER, self.DoActionOver, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_NODEDESTROY, self.ShowNodeDestroyed, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_BOSS_MERGE, self.ShowBossMerge, self)
end
--移除监听
function XUiGuildWarTwinsPanel:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_NODEDATA_CHANGE, self.UpdateNodeClickBoard, self)

    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTIONLIST_OVER, self.DoActionOver, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_NODEDESTROY, self.ShowNodeDestroyed, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_BOSS_MERGE, self.ShowBossMerge, self)
end
--开启界面倒计时更新和动画更新 计时器
function XUiGuildWarTwinsPanel:StartTimer()
    self:UpdateTime()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:UpdateTime()
    end, 1, 0)
    self.ActionTimer = XScheduleManager.ScheduleForever(function()
        self:ShowAction()
    end, XScheduleManager.SECOND, 0)
end
--关闭界面倒计时更新和动画更新 计时器
function XUiGuildWarTwinsPanel:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = false
    end
    if self.ActionTimer then
        XScheduleManager.UnSchedule(self.ActionTimer)
        self.ActionTimer = false
    end
end
--更新界面
function XUiGuildWarTwinsPanel:UpdateView()
    if self:GetNode():GetIsMerge() then
        self.TxtBuff1.text = CS.XTextManager.GetText("GuildWarTwinsRootDetail")
        self.UiPanelRoleModelMix.gameObject:SetActiveEx(true)
        self.UiPanelRoleModelLeft.GameObject:SetActiveEx(false)
        self.UiPanelRoleModelRight.GameObject:SetActiveEx(false)
    else
        self.TxtBuff1.text = CS.XTextManager.GetText("GuildWarTwinsChildDetail")
        self.UiPanelRoleModelMix.gameObject:SetActiveEx(false)
        self.UiPanelRoleModelLeft.GameObject:SetActiveEx(true)
        self.UiPanelRoleModelRight.GameObject:SetActiveEx(true)
    end
end
--更新BOSS点击面板数据
function XUiGuildWarTwinsPanel:UpdateNodeClickBoard()
    if self:GetNode():GetIsMerge() then
        self.GridMixBossDetail:Update()
    else
        self.GridLeftBossDetail:Update()
        self.GridRightBossBlack:Update()
    end
end
--定时器更新
function XUiGuildWarTwinsPanel:UpdateTime()
    if not XDataCenter.GuildWarManager.CheckRoundIsInTime() then
        self:Close()
        XLuaUiManager.Open("UiGuildWarStageDetail", self:GetNode(), false)
    end
    self.StageDetail:OnTimerUpdate()
end
--开启关闭关卡详情
function XUiGuildWarTwinsPanel:SetNodeDetail(isShowDetail, nodeId)
    local rootId = self.NodeId
    local leftId = self.Node:GetChildIdByIndex(1)
    local rightId = self.Node:GetChildIdByIndex(2)
    if isShowDetail then
        self._SelectedNodeId = nodeId
        self.MixBoss.gameObject:SetActiveEx(false)
        self.LeftBoss.gameObject:SetActiveEx(false)
        self.RightBoss.gameObject:SetActiveEx(false)
        if nodeId == rootId then
            self.UiCamNearBossMix2.gameObject:SetActiveEx(false)
            self.UiCamFarBossMix2.gameObject:SetActiveEx(false)
            self.UiCamNearBossMix2.gameObject:SetActiveEx(true)
            self.UiCamFarBossMix2.gameObject:SetActiveEx(true)
        elseif nodeId == leftId then
            self.UiCamNearBossLeft.gameObject:SetActiveEx(false)
            self.UiCamFarBossLeft.gameObject:SetActiveEx(false)
            self.UiCamNearBossLeft.gameObject:SetActiveEx(true)
            self.UiCamFarBossLeft.gameObject:SetActiveEx(true)
        elseif nodeId == rightId then
            self.UiCamNearBossRight.gameObject:SetActiveEx(false)
            self.UiCamFarBossRight.gameObject:SetActiveEx(false)
            self.UiCamNearBossRight.gameObject:SetActiveEx(true)
            self.UiCamFarBossRight.gameObject:SetActiveEx(true)
        end
        self.StageDetail:Show(nodeId)
    else
        self._SelectedNodeId = false
        if self:GetNode():GetIsMerge() then
            self.MixBoss.gameObject:SetActiveEx(true)
            self.PressMix.gameObject:SetActiveEx(true)
            self.LeftBoss.gameObject:SetActiveEx(false)
            self.PressLeft.gameObject:SetActiveEx(false)
            self.RightBoss.gameObject:SetActiveEx(false)
            self.PressRight.gameObject:SetActiveEx(false)
            
            self.UiCamNearBossMix1.gameObject:SetActiveEx(false)
            self.UiCamFarBossMix1.gameObject:SetActiveEx(false)
            self.UiCamNearBossMix1.gameObject:SetActiveEx(true)
            self.UiCamFarBossMix1.gameObject:SetActiveEx(true)
        else
            self.MixBoss.gameObject:SetActiveEx(false)
            self.PressMix.gameObject:SetActiveEx(false)
            self.LeftBoss.gameObject:SetActiveEx(true)
            self.PressLeft.gameObject:SetActiveEx(true)
            self.RightBoss.gameObject:SetActiveEx(true)
            self.PressRight.gameObject:SetActiveEx(true)
            
            self.CamFarMain.gameObject:SetActiveEx(false)
            self.CamNearMain.gameObject:SetActiveEx(false)
            self.CamFarMain.gameObject:SetActiveEx(true)
            self.CamNearMain.gameObject:SetActiveEx(true)
        end
        self.StageDetail:Hide()
    end
end
--打开队伍界面
function XUiGuildWarTwinsPanel:OpenBattleRoomUi(stageId)
    XDataCenter.GuildWarManager.GetBattleManager():OpenBattleRoomUi(stageId)
end
--点击左子节点BOSS
function XUiGuildWarTwinsPanel:OnBtnLeftClicked()
    self:SetNodeDetail(true,  self:GetNode():GetChildIdByIndex(1))
end
--点击右子节点BOSS
function XUiGuildWarTwinsPanel:OnBtnRightClicked()
    self:SetNodeDetail(true,  self:GetNode():GetChildIdByIndex(2))
end
--点击合体根节点BOSS
function XUiGuildWarTwinsPanel:OnBtnMixClicked()
    self:SetNodeDetail(true, self.NodeId)
end
--点击帮助界面
function XUiGuildWarTwinsPanel:OnBtnHelpClick()
    XLuaUiManager.Open("UiGuildWarStageTips", self:GetNode())
end

--镜头Timeline动画
function XUiGuildWarTwinsPanel:GetCameraAnim(name)
    local root = self.UiModelGo.transform
    return root:Find(string.format("Animation/%s", name)).gameObject
end
--播放镜头Timeline动画
function XUiGuildWarTwinsPanel:PlayCameraAnim(name, callBack)
    self:GetCameraAnim(name):PlayTimelineAnimation(callBack)
end

--特效
function XUiGuildWarTwinsPanel:GetEffectGo(name)
    local root = self.UiModelGo.transform
    return root:Find(string.format("UiNearRoot/%s", name)).gameObject
end
--特效
function XUiGuildWarTwinsPanel:SetActiveEffectGo(name, isActive)
    local gameObj = self:GetEffectGo(name)
    gameObj:SetActiveEx(isActive)
end

--region 动作动画相关

--开始播放行动动画
function XUiGuildWarTwinsPanel:ShowAction()
    local node = self:GetNode()
    if node:GetIsDead() then
        return
    end
    if not XLuaUiManager.GetTopUiName() == "UiGuildWarTwinsPanel" then
        return
    end
    if XLuaUiManager.IsMaskShow(XGuildWarConfig.MASK_KEY) then
        return
    end
    local IsHasCanPlayAction = self.BattleManager:GetIsHasCanPlayAction(PlayTypeList)
    if not IsHasCanPlayAction then
        return
    end
    --正在播放 return
    if self.BattleManager:CheckActionPlaying() then
        return
    end
    --检查有没有可以播放的行为动画 并播放
    self.BattleManager:CheckActionList(PlayTypeList)
end

--一个行动动画播放完毕时调用 
function XUiGuildWarTwinsPanel:DoActionOver()
    if XLuaUiManager.IsMaskShow(XGuildWarConfig.MASK_KEY) then
        XLuaUiManager.SetMask(false, XGuildWarConfig.MASK_KEY)
    end
end

--节点攻破动画
function XUiGuildWarTwinsPanel:ShowNodeDestroyed(actionGroup)
    XDataCenter.GuildWarManager.ShowNodeDestroyed(actionGroup,function()
        self.BattleManager:DoActionFinish(XGuildWarConfig.GWActionType.NodeDestroyed,PlayTypeList)
    end)
end

--Boss合体动画
function XUiGuildWarTwinsPanel:ShowBossMerge(actionGroup)
    if not self.ShowBossMergeTimer then
        self.ShowBossMergeTimer = XScheduleManager.ScheduleOnce(function()
            self.ShowBossMergeTimer = nil
            self:UpdateView()
            self:UpdateNodeClickBoard()
            self:SetNodeDetail(false)
            self.UiCamNearBossMix1.gameObject:SetActiveEx(false)
            self.UiCamFarBossMix1.gameObject:SetActiveEx(false)
            self.UiCamNearBossMix1.gameObject:SetActiveEx(true)
            self.UiCamFarBossMix1.gameObject:SetActiveEx(true)
            self.PanelButtonTop.gameObject:SetActiveEx(false)
            self:PlayCameraAnim("CameraMix",function()
                self.PanelButtonTop.gameObject:SetActiveEx(true)
                self.BattleManager:DoActionFinish(XGuildWarConfig.GWActionType.BossMerge,PlayTypeList)
            end)
        end, XScheduleManager.SECOND)
    end
end

--endregion


return XUiGuildWarTwinsPanel
