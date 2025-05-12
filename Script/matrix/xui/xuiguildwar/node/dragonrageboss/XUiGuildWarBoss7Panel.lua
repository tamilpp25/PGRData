local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiGuildWarTerm4PanelDetail = require("XUi/XUiGuildWar/Node/Term4/XUiGuildWarTerm4PanelDetail")
local XUiGuildWarTerm4PanelGrid = require("XUi/XUiGuildWar/Node/Term4/XUiGuildWarTerm4PanelGrid")
local XUiPanelDragonRage = require('XUi/XUiGuildWar/Map/XUiPanelDragonRage')

--当前界面的Action播放类型表
local PlayTypeList = {
    XGuildWarConfig.GWActionUiType.NodeDestroyed,
}

---@class XUiGuildWarBoss7Panel:XLuaUi@ ui = UiGuildWarBossStageDetail
---@field private _Control XGuildWarControl
local XUiGuildWarBoss7Panel = XLuaUiManager.Register(XLuaUi, "UiGuildWarBoss7Panel")

--region ---------- 生命周期 --------->>>

function XUiGuildWarBoss7Panel:OnAwake()
    self.NodeId = false
    self.Timer = false
    ---@type XUiGuildWarTerm4PanelGrid
    self._UiModeLeft = false
    ---@type XUiGuildWarTerm4PanelGrid
    self._UiModeRight = false
    self._CameraGroup = false
    
    ---@type XUiGuildWarTerm4PanelDetail
    self._UiDetail = XUiGuildWarTerm4PanelDetail.New(self.PanelDetail)
    self._UiDetail:SetIsIngoreBossReward(true)
    self._UiDetail.GameObject:SetActiveEx(false)
    self._UiModeLeft = XUiGuildWarTerm4PanelGrid.New(self.Left2)
    self._UiModeRight = XUiGuildWarTerm4PanelGrid.New(self.Right2)
    self._UiDetail.GameObject:SetActiveEx(false)
    self._CameraGroup = {
        Main = {
            self:FindVirtualCamera("CamNearMain"),
            self:FindVirtualCamera("CamFarMain")
        },
        Open = {
            self:FindVirtualCamera("UiCamNearBossOpen"),
            self:FindVirtualCamera("UiCamFarBossOpen")
        },
        NormalState = {
            self:FindVirtualCamera("UiCamNearBossLeft"),
            self:FindVirtualCamera("UiCamFarBossLeft")
        },
        DragonRageState = {
            self:FindVirtualCamera("UiCamNearBossRight"),
            self:FindVirtualCamera("UiCamFarBossRight")
        },
    }
    self._TimelineGroup = {
        NormalState = {
            self:FindScene3DTimeline('Timeline_Phase_01'),
            self:FindScene3DTimeline('Effect_Phase_01')
        },
        DragonRageState = {
            self:FindScene3DTimeline('Timeline_Phase_02'),
            self:FindScene3DTimeline('Effect_Phase_02')
        }
    }
    self:SetCamera(self._CameraGroup.Open)

    self.PaneBoss = self.PaneBoss or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PaneBoss", "RectTransform")

    if self.PanelDragonFury then
        self.PanelDragonRage = XUiPanelDragonRage.New(self.PanelDragonFury, self)

        if self._Control.DragonRageControl:GetIsOpenDragonRage() then
            self.PanelDragonRage:Open()
            self.PanelDragonRage:Refresh()
        else
            self.PanelDragonRage:Close()
        end
    end
end

---@param node XBoss7GWNode @外面直接根据龙怒状态传入节点，内部不用特意切换
function XUiGuildWarBoss7Panel:OnStart(node)
    self.BattleManager = XDataCenter.GuildWarManager.GetBattleManager()
    self.NodeId = node:GetId()
    self.IsDragonRage = self._Control.DragonRageControl:GetIsDragonRageValueDown()
    self:Init()
    self:InitCamera()

    self:UpdateCurrentChildIndex()
end

function XUiGuildWarBoss7Panel:OnEnable()
    self:CheckBossLevelChanged()
    self:StartTimer()
    self:Update()
    self:AddEventListener()
    self:DragonRageCheck(true, true)
    self:ShowAction()
end

function XUiGuildWarBoss7Panel:OnDisable()
    self:RemoveEventListener()
    self:StopTimer()
    if XLuaUiManager.IsMaskShow(XGuildWarConfig.MASK_KEY) then
        XLuaUiManager.SetMask(false, XGuildWarConfig.MASK_KEY)
    end
end


--endregion <<<---------------------------------

--region ---------- 初始化 ---------->>>
function XUiGuildWarBoss7Panel:Init()
    self:BindExitBtns()
    self:BindHelpBtn(self.BtnHelp, "GuildWarHelpPanda")
    XUiHelper.RegisterClickEvent(self, self.BtnAutoFight, self.OnBtnAutoFightClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnFight, self.OnBtnFightClicked)

    local uiPanelAsset = XUiPanelAsset.New(self, self.PanelAsset, XGuildWarConfig.ActivityPointItemId)
    uiPanelAsset:HideBtnBuy()

    self.PanelDetail.gameObject:SetActiveEx(false)
end

--添加监听
function XUiGuildWarBoss7Panel:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_NODEDATA_CHANGE, self.UpdateAndCheckBossLevel, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_PANDA_UNFOLD_DETAIL, self.OnEventUnfoldDetail, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTIONLIST_OVER, self.DoActionOver, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_NODEDESTROY, self.ShowNodeDestroyed, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_DRAGONRAGE_CHANGE, self.DragonRageCheck, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTIONLIST_CHANGE, self.CheckClose, self)
end

--移除监听
function XUiGuildWarBoss7Panel:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_NODEDATA_CHANGE, self.UpdateAndCheckBossLevel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_PANDA_UNFOLD_DETAIL, self.OnEventUnfoldDetail, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTIONLIST_OVER, self.DoActionOver, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_NODEDESTROY, self.ShowNodeDestroyed, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_DRAGONRAGE_CHANGE, self.DragonRageCheck, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTIONLIST_CHANGE, self.CheckClose, self)
end
--endregion <<<-----------------------

--region ---------- 界面刷新 ---------->>>
function XUiGuildWarBoss7Panel:UpdateCurrentChildIndex()
    self._UiDetail.BtnMode.gameObject:SetActiveEx(false)
    self._UiDetail.BtnCloseDetail.gameObject:SetActiveEx(false)
    
    self.IsDragonRage = self._Control.DragonRageControl:GetIsDragonRageValueDown()
    
    if self.IsDragonRage then
        -- 龙怒状态显示龙怒节点（子节点）
        local node = self:GetNode()
        local childNode = XDataCenter.GuildWarManager.GetChildNode(node:GetId(), 1)

        if childNode then
            self.NodeId = childNode:GetId()
        end
    else
        -- 非龙怒显示普通结点（原节点）
        local node = self:GetNode()
        local rootNodeId = node:GetRootId()

        if XTool.IsNumberValid(rootNodeId) then
            self.NodeId = rootNodeId
        end
    end
end

function XUiGuildWarBoss7Panel:UpdateAndCheckBossLevel()
    self:CheckBossLevelChanged()
    self:Update()
end

function XUiGuildWarBoss7Panel:Update()
    local node = self:GetNode()
    self._UiDetail:Show(node)
end
--endregion

--region ---------- 事件回调 ---------->>>

function XUiGuildWarBoss7Panel:OnBtnAutoFightClicked()
    local node = self:GetNode()
    local cost = node:GetSweepCostEnergy()
    if not XEntityHelper.CheckItemCountIsEnough(XGuildWarConfig.ActivityPointItemId, cost) then
        return
    end
    local damage = getRoundingValue((node:GetMaxDamage() / node:GetMaxHP()) * 100, 2)
    local power, textKey
    textKey = "GuildWarSweepTip"
    power = XDataCenter.GuildWarManager.GetBattleManager():GetSweepHpFactor()
    power = power * 100
    XLuaUiManager.Open("UiDialog", nil
    , XUiHelper.GetText(textKey, cost, damage, power)
    , XUiManager.DialogType.Normal, nil
    , function()
                local sweepType = XGuildWarConfig.NodeFightType.FightNode
                local uid = node:GetUID()
                local stageId = node:GetStageId()
                XDataCenter.GuildWarManager.StageSweep(uid, sweepType, stageId, function()
                    XUiManager.TipMsg(XUiHelper.GetText("GuildWarSweepFinished"))
                    self:Update()
                end)
            end)
end

function XUiGuildWarBoss7Panel:OnBtnFightClicked()
    local node = self:GetNode()

    -- 检查体力是否充足
    if not XEntityHelper.CheckItemCountIsEnough(XGuildWarConfig.ActivityPointItemId,
            node:GetFightCostEnergy()) then
        return
    end
    XDataCenter.GuildWarManager.GetBattleManager():UpdateCurrentClientBattleInfo(node:GetUID(), node:GetStutesType())

    if node:GetHP() <= 0 then
        XUiManager.TipErrorWithKey("GuildWarNodeIsDead")
        return
    end

    self:OpenBattleRoomUi(node:GetStageId())
end

function XUiGuildWarBoss7Panel:OnBtnLeftClicked()
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_PANDA_UNFOLD_DETAIL, true, XGuildWarConfig.ChildNodeIndex.Left)
end

function XUiGuildWarBoss7Panel:OnBtnRightClicked()
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_PANDA_UNFOLD_DETAIL, true, XGuildWarConfig.ChildNodeIndex.Right)
end

function XUiGuildWarBoss7Panel:OpenBattleRoomUi(stageId)
    XDataCenter.GuildWarManager.GetBattleManager():OpenBattleRoomUi(stageId)
end

function XUiGuildWarBoss7Panel:OnEventUnfoldDetail(isUnfold, playAnimation)
    self._UiDetail.GameObject:SetActiveEx(true)
    self:Update()

    if self._Control.DragonRageControl:GetIsDragonRageValueDown() then
        self:SetCamera(self._CameraGroup.DragonRageState)
        self:SetScene3DTimeline(self._TimelineGroup.DragonRageState)
    else
        self:SetCamera(self._CameraGroup.NormalState)
        self:SetScene3DTimeline(self._TimelineGroup.NormalState)
    end

    if self.PaneBoss then
        self.PaneBoss.gameObject:SetActiveEx(true)
    end
    self._UiModeLeft.GameObject:SetActiveEx(false)
    self._UiModeRight.GameObject:SetActiveEx(false)

    if playAnimation then
        self:PlayAnimation("QieHuan")
    end
end

--endregion <<<-------------------------


---@return XTerm4BossGWNode
function XUiGuildWarBoss7Panel:GetNode()
    return XDataCenter.GuildWarManager:GetBattleManager():GetNode(self.NodeId)
end


function XUiGuildWarBoss7Panel:CheckBossLevelChanged()
    if self.IsDragonRage ~= self._Control.DragonRageControl:GetIsDragonRageValueDown() then
        self:UpdateCurrentChildIndex()
        return true
    end
    return false
end

function XUiGuildWarBoss7Panel:StartTimer()
    self.ActionTimer = XScheduleManager.ScheduleForever(function()
        self:ShowAction()
    end, XScheduleManager.SECOND, 0)
end

function XUiGuildWarBoss7Panel:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = false
    end
    if self.ActionTimer then
        XScheduleManager.UnSchedule(self.ActionTimer)
        self.ActionTimer = false
    end
end

--region 动作动画相关

--开始播放行动动画
function XUiGuildWarBoss7Panel:ShowAction()
    local node = self:GetNode()
    if node:GetIsDead() then
        return
    end
    if not XLuaUiManager.GetTopUiName() == self.Name then
        return
    end
    if XLuaUiManager.IsMaskShow(XGuildWarConfig.MASK_KEY) then
        return
    end
    
    -- 正在播引导 return
    if XDataCenter.GuideManager.CheckIsInGuide() then
        return
    end

    if self:CheckNeedShowNewGameThrough() then
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
function XUiGuildWarBoss7Panel:DoActionOver()
    if XLuaUiManager.IsMaskShow(XGuildWarConfig.MASK_KEY) then
        XLuaUiManager.SetMask(false, XGuildWarConfig.MASK_KEY)
    end
end

--节点攻破动画
function XUiGuildWarBoss7Panel:ShowNodeDestroyed(actionGroup)
    XDataCenter.GuildWarManager.ShowNodeDestroyed(actionGroup, function()
        self.BattleManager:DoActionFinish(XGuildWarConfig.GWActionType.NodeDestroyed, PlayTypeList)
    end)
end

-- 龙怒状态切换
function XUiGuildWarBoss7Panel:DragonRageCheck(noAnimation, forceUpdate)
    if self:CheckBossLevelChanged() or forceUpdate then
        self:OnEventUnfoldDetail(nil, not noAnimation)
        self:UpdateRoleModel()
    end
end

--endregion

function XUiGuildWarBoss7Panel:CheckClose(actionList)
    local IsClose = false
    for _, action in pairs(actionList or {}) do
        -- 如果是龙怒动画，也需要关闭
        if action.ActionType == XGuildWarConfig.GWActionType.NewGameThrough or action.ActionType == XGuildWarConfig.GWActionType.DragonRageFull or action.ActionType == XGuildWarConfig.GWActionType.DragonRageEmpty then
            IsClose = true
            break
        end
    end
    if IsClose and not self._IsClosing then
        self._IsClosing = true
        self:Close()
    end
end

function XUiGuildWarBoss7Panel:CheckNeedShowNewGameThrough()
    -- 有新周目，需要踢出
    if XMVCA.XGuildWar.DragonRageCom:GetIsNewGameThroughActionWaitToPlay() and not self._IsClosing then
        self._IsClosing = true
        self:Close()
        XMVCA.XGuildWar.DragonRageCom:SetIsNewGameThroughActionWaitToPlay(nil)
        return true
    end
end

--region camera
function XUiGuildWarBoss7Panel:InitCamera()
    ---@type XBoss7GWNode
    local node = self:GetNode()

    local panelRoleModelMix = self.UiModelGo.transform:FindTransform("PanelModelGeminiMix")
    self._PanelModel = XUiPanelRoleModel.New(panelRoleModelMix, self.Name, nil, true)
    self._PanelModel:UpdateRoleModel(node:GetModelId())
end

function XUiGuildWarBoss7Panel:UpdateRoleModel()
    ---@type XBoss7GWNode
    local node = self:GetNode()
    self._PanelModel:UpdateRoleModel(node:GetModelId())
end

function XUiGuildWarBoss7Panel:SetCamera(cameraGroupEnable)
    for i, cameraGroup in pairs(self._CameraGroup) do
        local isEnable = cameraGroup == cameraGroupEnable
        
        for i = 1, #cameraGroup do
            local camera = cameraGroup[i]
            camera.gameObject:SetActiveEx(isEnable)
        end
    end
end

--endregion

--region 场景Timeline

function XUiGuildWarBoss7Panel:FindScene3DTimeline(gameObjectName)
    local timeline = nil
    timeline = self.UiSceneInfo.Transform:FindTransform(gameObjectName)
    return timeline
end

function XUiGuildWarBoss7Panel:SetScene3DTimeline(timelineGroupEnable)
    for i, timelineGroup in pairs(self._TimelineGroup) do
        local isEnable = timelineGroup == timelineGroupEnable

        for i = 1, #timelineGroup do
            local timeline = timelineGroup[i]
            timeline.gameObject:SetActiveEx(isEnable)
        end
    end
end

--endregion

return XUiGuildWarBoss7Panel
