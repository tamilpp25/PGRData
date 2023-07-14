local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiGuildWarTerm4PanelDetail = require("XUi/XUiGuildWar/Node/Term4/XUiGuildWarTerm4PanelDetail")
local XUiGuildWarTerm4PanelGrid = require("XUi/XUiGuildWar/Node/Term4/XUiGuildWarTerm4PanelGrid")

--当前界面的Action播放类型表
local PlayTypeList = {
    XGuildWarConfig.GWActionUiType.NodeDestroyed,
}

---@class XUiGuildWarTerm4Panel:XLuaUi@ ui = UiGuildWarBossStageDetail
local XUiGuildWarTerm4Panel = XLuaUiManager.Register(XLuaUi, "UiGuildWarTerm4Panel")

function XUiGuildWarTerm4Panel:Ctor()
    self._ChildIndex = XGuildWarConfig.ChildNodeIndex.None
    self.NodeId = false
    self.Timer = false

    ---@type XUiGuildWarTerm4PanelGrid
    self._UiModeLeft = false

    ---@type XUiGuildWarTerm4PanelGrid
    self._UiModeRight = false

    self._CameraGroup = false

    self._TimerDelayCameraOpen = false
    
    self._OldLevel = 0
end

function XUiGuildWarTerm4Panel:OnAwake()
    ---@type XUiGuildWarTerm4PanelDetail
    self._UiDetail = XUiGuildWarTerm4PanelDetail.New(self.PanelDetail)
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
        Left = {
            self:FindVirtualCamera("UiCamNearBossLeft"),
            self:FindVirtualCamera("UiCamFarBossLeft")
        },
        Right = {
            self:FindVirtualCamera("UiCamNearBossRight"),
            self:FindVirtualCamera("UiCamFarBossRight")
        },
    }
    self:SetCamera(self._CameraGroup.Open)
    
    self.PaneBoss = self.PaneBoss or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PaneBoss", "RectTransform")
end

---@param node XTerm4BossGWNode
---@param selectedNode XTerm4BossChildGWNode
function XUiGuildWarTerm4Panel:OnStart(node, selectedNode)
    self.BattleManager = XDataCenter.GuildWarManager.GetBattleManager()
    self.NodeId = node:GetId()
    self:Init()
    self:InitCamera()
    
    if selectedNode then
        self._ChildIndex = selectedNode:GetSelfChildIndex()
    else
        self:UpdateCurrentChildIndex()
    end
end

function XUiGuildWarTerm4Panel:UpdateCurrentChildIndex()
    local node = self:GetNode()
    -- 首次进入boss节点直接攻击第一个boss（等级1），不给选择，玩家通关第一个boss后，切换为第二个boss（等级2）。通关第二个boss后，再开启自选boss功能
    local bossLevel = node:GetBossLevel()
    if bossLevel == 1 then
        self._ChildIndex = XGuildWarConfig.ChildNodeIndex.Left
        self._UiDetail.BtnMode.gameObject:SetActiveEx(false)
        self._UiDetail.BtnCloseDetail.gameObject:SetActiveEx(false)

    elseif bossLevel == 2 then
        self._ChildIndex = XGuildWarConfig.ChildNodeIndex.Right
        self._UiDetail.BtnMode.gameObject:SetActiveEx(false)
        self._UiDetail.BtnCloseDetail.gameObject:SetActiveEx(false)

    else
        self._ChildIndex = XGuildWarConfig.ChildNodeIndex.None
        self._UiDetail.BtnMode.gameObject:SetActiveEx(true)
        self._UiDetail.BtnCloseDetail.gameObject:SetActiveEx(true)
    end
    self._OldLevel = bossLevel
end

function XUiGuildWarTerm4Panel:Init()
    self:BindExitBtns()
    self:BindHelpBtn(self.BtnHelp, "GuildWarHelpPanda")
    XUiHelper.RegisterClickEvent(self, self.BtnAutoFight, self.OnBtnAutoFightClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnFight, self.OnBtnFightClicked)

    local uiPanelAsset = XUiPanelAsset.New(self, self.PanelAsset, XGuildWarConfig.ActivityPointItemId)
    uiPanelAsset:HideBtnBuy()

    self.PanelDetail.gameObject:SetActiveEx(false)
end

---@return XTerm4BossGWNode
function XUiGuildWarTerm4Panel:GetNode()
    return XDataCenter.GuildWarManager:GetBattleManager():GetNode(self.NodeId)
end

--region 复制自 XUiGuildWarStageDetail
function XUiGuildWarTerm4Panel:OnBtnAutoFightClicked()
    local node = self:GetNode()
    local childNode = XDataCenter.GuildWarManager.GetChildNode(node:GetId(), self._ChildIndex)
    local cost = childNode:GetSweepCostEnergy()
    if not XEntityHelper.CheckItemCountIsEnough(XGuildWarConfig.ActivityPointItemId, cost) then
        return
    end
    local damage = getRoundingValue((childNode:GetMaxDamage() / childNode:GetMaxHP()) * 100, 2)
    local power, textKey
    textKey = "GuildWarSweepTip"
    power = XDataCenter.GuildWarManager.GetBattleManager():GetSweepHpFactor()
    power = power * 100
    XLuaUiManager.Open("UiDialog", nil
    , XUiHelper.GetText(textKey, cost, damage, power)
    , XUiManager.DialogType.Normal, nil
    , function()
                local sweepType = XGuildWarConfig.NodeFightType.FightNode
                local uid = childNode:GetUID()
                local stageId = childNode:GetStageId()
                XDataCenter.GuildWarManager.StageSweep(uid, sweepType, stageId, function()
                    XUiManager.TipMsg(XUiHelper.GetText("GuildWarSweepFinished"))
                    self:Update()
                end)
            end)
end

function XUiGuildWarTerm4Panel:OnBtnFightClicked()
    local node = self:GetNode()
    local childNode = XDataCenter.GuildWarManager.GetChildNode(node:GetId(), self._ChildIndex)

    -- 检查体力是否充足
    if not XEntityHelper.CheckItemCountIsEnough(XGuildWarConfig.ActivityPointItemId,
            childNode:GetFightCostEnergy()) then
        return
    end
    XDataCenter.GuildWarManager.GetBattleManager():UpdateCurrentClientBattleInfo(childNode:GetUID(), childNode:GetStutesType())

    if childNode:GetHP() <= 0 then
        XUiManager.TipErrorWithKey("GuildWarNodeIsDead")
        return
    end

    self:OpenBattleRoomUi(childNode:GetStageId())
end

function XUiGuildWarTerm4Panel:OpenBattleRoomUi(stageId)
    XDataCenter.GuildWarManager.GetBattleManager():OpenBattleRoomUi(stageId)
end
-- endregion

function XUiGuildWarTerm4Panel:CheckBossLevelChanged()
    local node = self:GetNode()
    if self._OldLevel ~= node:GetBossLevel() then
        self:UpdateCurrentChildIndex()
    end
end

function XUiGuildWarTerm4Panel:OnEnable()
    XUiGuildWarTerm4Panel.Super.OnEnable(self)
    self:CheckBossLevelChanged()
    self:StartTimer()
    self:Update()
    self:AddEventListener()
    local childIndex = self._ChildIndex
    if childIndex ~= XGuildWarConfig.ChildNodeIndex.None then
        self:OnEventUnfoldDetail(true, childIndex)
    else
        -- 延迟，否则virtualCamera的过度不展示
        self._TimerDelayCameraOpen = XScheduleManager.ScheduleOnce(function()
            self._TimerDelayCameraOpen = false
            self:SetCamera(self._CameraGroup.Main)
        end, 500)
        self:Update()
    end
    self:ShowAction()
end

function XUiGuildWarTerm4Panel:OnDisable()
    if self._TimerDelayCameraOpen then
        XScheduleManager.UnSchedule(self._TimerDelayCameraOpen)
        self._TimerDelayCameraOpen = false
    end
    XUiGuildWarTerm4Panel.Super.OnDisable(self)
    self:RemoveEventListener()
    self:StopTimer()
    if XLuaUiManager.IsMaskShow(XGuildWarConfig.MASK_KEY) then
        XLuaUiManager.SetMask(false, XGuildWarConfig.MASK_KEY)
    end
end

--添加监听
function XUiGuildWarTerm4Panel:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_NODEDATA_CHANGE, self.UpdateAndCheckBossLevel, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_PANDA_UNFOLD_DETAIL, self.OnEventUnfoldDetail, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTIONLIST_OVER, self.DoActionOver, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_NODEDESTROY, self.ShowNodeDestroyed, self)
end
--移除监听
function XUiGuildWarTerm4Panel:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_NODEDATA_CHANGE, self.UpdateAndCheckBossLevel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_PANDA_UNFOLD_DETAIL, self.OnEventUnfoldDetail, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTIONLIST_OVER, self.DoActionOver, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_NODEDESTROY, self.ShowNodeDestroyed, self)
end

function XUiGuildWarTerm4Panel:UpdateAndCheckBossLevel()
    self:CheckBossLevelChanged()
    self:Update()
end

function XUiGuildWarTerm4Panel:StartTimer()
    self.ActionTimer = XScheduleManager.ScheduleForever(function()
        self:ShowAction()
    end, XScheduleManager.SECOND, 0)
end

function XUiGuildWarTerm4Panel:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = false
    end
    if self.ActionTimer then
        XScheduleManager.UnSchedule(self.ActionTimer)
        self.ActionTimer = false
    end
end

function XUiGuildWarTerm4Panel:OnEventUnfoldDetail(isUnfold, childIndex)
    if isUnfold then
        self._UiDetail.GameObject:SetActiveEx(true)
        self:Update(childIndex)
        if childIndex == XGuildWarConfig.ChildNodeIndex.Left then
            self:SetCamera(self._CameraGroup.Left)
        elseif childIndex == XGuildWarConfig.ChildNodeIndex.Right then
            self:SetCamera(self._CameraGroup.Right)
        end
        if self.PaneBoss then
            self.PaneBoss.gameObject:SetActiveEx(false)
        end
        self._UiModeLeft.GameObject:SetActiveEx(false)
        self._UiModeRight.GameObject:SetActiveEx(false)
    else
        self:Update(XGuildWarConfig.ChildNodeIndex.None)
        self:SetCamera(self._CameraGroup.Main)
        self._UiDetail.GameObject:SetActiveEx(false)
        if self.PaneBoss then
            self.PaneBoss.gameObject:SetActiveEx(true)
        end
        self._UiModeLeft.GameObject:SetActiveEx(true)
        self._UiModeRight.GameObject:SetActiveEx(true)
    end
end

function XUiGuildWarTerm4Panel:Update(childIndex)
    if self._ChildIndex == childIndex then
        return
    end
    if childIndex then
        self._ChildIndex = childIndex
    end

    local node = self:GetNode()
    if self._ChildIndex == XGuildWarConfig.ChildNodeIndex.None then
        local node1 = node:GetChildByIndex(XGuildWarConfig.ChildNodeIndex.Left)
        self._UiModeLeft:Update(node1)
        local node2 = node:GetChildByIndex(XGuildWarConfig.ChildNodeIndex.Right)
        self._UiModeRight:Update(node2)
        return
    end
    self._UiDetail:Show(node:GetChildByIndex(self._ChildIndex))
end

function XUiGuildWarTerm4Panel:OnBtnLeftClicked()
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_PANDA_UNFOLD_DETAIL, true, XGuildWarConfig.ChildNodeIndex.Left)
end

function XUiGuildWarTerm4Panel:OnBtnRightClicked()
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_PANDA_UNFOLD_DETAIL, true, XGuildWarConfig.ChildNodeIndex.Right)
end

--region 动作动画相关

--开始播放行动动画
function XUiGuildWarTerm4Panel:ShowAction()
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
function XUiGuildWarTerm4Panel:DoActionOver()
    if XLuaUiManager.IsMaskShow(XGuildWarConfig.MASK_KEY) then
        XLuaUiManager.SetMask(false, XGuildWarConfig.MASK_KEY)
    end
end

--节点攻破动画
function XUiGuildWarTerm4Panel:ShowNodeDestroyed(actionGroup)
    XDataCenter.GuildWarManager.ShowNodeDestroyed(actionGroup, function()
        self.BattleManager:DoActionFinish(XGuildWarConfig.GWActionType.NodeDestroyed, PlayTypeList)
    end)
end
--endregion

--region camera
function XUiGuildWarTerm4Panel:InitCamera()
    ---@type XTerm4BossGWNode
    local node = self:GetNode()

    local panelRoleModelMix = self.UiModelGo.transform:FindTransform("PanelModelGeminiMix")
    self._PanelModel = XUiPanelRoleModel.New(panelRoleModelMix, self.Name, nil, true)
    self._PanelModel:UpdateRoleModel(node:GetModelId())
end

function XUiGuildWarTerm4Panel:SetCamera(cameraGroupEnable)
    for i, cameraGroup in pairs(self._CameraGroup) do
        if cameraGroup == cameraGroupEnable then
            for i = 1, #cameraGroup do
                local camera = cameraGroup[i]
                camera.gameObject:SetActiveEx(true)
            end
        else
            for i = 1, #cameraGroup do
                local camera = cameraGroup[i]
                camera.gameObject:SetActiveEx(false)
            end
        end
    end
end

--endregion camera

return XUiGuildWarTerm4Panel
