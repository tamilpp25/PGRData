local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
--当前界面的Action播放类型表
local PlayTypeList = {
    XGuildWarConfig.GWActionUiType.NodeDestroyed,
    XGuildWarConfig.GWActionUiType.Panda,
}
local WeaknessShowType = {
    WeaknessLeft = 1,
    WeaknessRight = 2,
    WeaknessLeft2Right = 3,
    WeaknessRight2Left = 4,
}

---@class XUiGuildWarPandaStageDetail:XLuaUi
local XUiGuildWarPandaStageDetail = XLuaUiManager.Register(XLuaUi, "UiGuildWarPandaStageDetail")

function XUiGuildWarPandaStageDetail:Ctor()
    self.GridPandaWhite = false
    self.GridPandaBlack = false

    self.PandaType = XGuildWarConfig.ChildNodeIndex.None
    self.NodeId = false
    self.Timer = false

    self._SelectedNodeId = false
end

function XUiGuildWarPandaStageDetail:OnStart(node, IsMonsterStatus, selectedNodeId)
    self.BattleManager = XDataCenter.GuildWarManager.GetBattleManager()
    self.NodeId = node:GetId()
    self:Init()
    self._SelectedNodeId = selectedNodeId
end
function XUiGuildWarPandaStageDetail:Init()
    -- 
    local XUiGuildWarPandaStageDetailGrid = require("XUi/XUiGuildWar/Node/Panda/XUiGuildWarPandaStageDetailGrid")
    self.GridPandaWhite = XUiGuildWarPandaStageDetailGrid.New(self.LeftBoss, XGuildWarConfig.ChildNodeIndex.Left, self.NodeId)
    self.GridPandaBlack = XUiGuildWarPandaStageDetailGrid.New(self.RightBoss, XGuildWarConfig.ChildNodeIndex.Right, self.NodeId)
    
    -- btn click
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    self:BindHelpBtn(self.BtnHelp, "GuildWarHelpPanda")
    XUiHelper.RegisterClickEvent(self, self.BtnCloseDetail, self.CloseDetail)
    XUiHelper.RegisterClickEvent(self, self.BtnAutoFight, self.OnBtnAutoFightClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnFight, self.OnBtnFightClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnPlayer, self.OnBtnPlayerClicked)
    XUiHelper.RegisterClickEvent(self, self.PressLeft, self.OnBtnLeftClicked)
    XUiHelper.RegisterClickEvent(self, self.PressRight, self.OnBtnRightClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnHelpDetail, self.OnBtnHelpClick)

    local node = self:GetNode()
    local panelModelLeft = self.UiModelGo.transform:FindTransform("PanelModelLeft")
    self.UiPanelRoleModelLeft = XUiPanelRoleModel.New(panelModelLeft, self.Name, nil, true)
    self.UiPanelRoleModelLeft:UpdateRoleModel(node:GetModelId(XGuildWarConfig.ChildNodeIndex.Left))

    local panelModelRight = self.UiModelGo.transform:FindTransform("PanelModelRight")
    self.UiPanelRoleModelRight = XUiPanelRoleModel.New(panelModelRight, self.Name, nil, true)
    self.UiPanelRoleModelRight:UpdateRoleModel(node:GetModelId(XGuildWarConfig.ChildNodeIndex.Right))

    local uiPanelAsset = XUiPanelAsset.New(self, self.PanelAsset, XGuildWarConfig.ActivityPointItemId)
    uiPanelAsset:HideBtnBuy()

    self.PanelDetail.gameObject:SetActiveEx(false)

    self.UiCamNearBossLeft = self:FindVirtualCamera("UiCamNearBossLeft")
    self.UiCamNearBossRight = self:FindVirtualCamera("UiCamNearBossRight")
    self.UiCamFarBossLeft = self:FindVirtualCamera("UiCamFarBossLeft")
    self.UiCamFarBossRight = self:FindVirtualCamera("UiCamFarBossRight")

    self.RImgCostFight1:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XGuildWarConfig.ActivityPointItemId))
    self.RImgCostFight2:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XGuildWarConfig.ActivityPointItemId))
end

---@return XPandaGWNode
function XUiGuildWarPandaStageDetail:GetNode()
    return XDataCenter.GuildWarManager:GetBattleManager():GetNode(self.NodeId)
end

-- region 复制自 XUiGuildWarStageDetail
function XUiGuildWarPandaStageDetail:OnBtnAutoFightClicked()
    local node = self:GetNode()
    local pandaNode = XDataCenter.GuildWarManager.GetChildNode(node:GetId(), self.PandaType)
    local cost = pandaNode:GetSweepCostEnergy()
    if not XEntityHelper.CheckItemCountIsEnough(XGuildWarConfig.ActivityPointItemId, cost) then
        return
    end
    local damage = getRoundingValue((pandaNode:GetMaxDamage() / pandaNode:GetMaxHP()) * 100, 2)
    local power, textKey
    if pandaNode:HasWeakness() then
        textKey = "GuildWarSweepTip"
        power = XDataCenter.GuildWarManager.GetBattleManager():GetSweepHpFactor()
    else
        textKey = "GuildWarSweepTipNotWeakness"
        power = XDataCenter.GuildWarManager.GetBattleManager():GetBossSweepHpFactorWithoutWeakness()
    end
    power = power * 100
    XLuaUiManager.Open("UiDialog", nil
    , XUiHelper.GetText(textKey, cost, damage, power)
    , XUiManager.DialogType.Normal, nil
    , function()
        local sweepType = XGuildWarConfig.NodeFightType.FightNode
        local uid = pandaNode:GetUID()
        local stageId = pandaNode:GetStageId()
        XDataCenter.GuildWarManager.StageSweep(uid, sweepType, stageId, function()
            XUiManager.TipMsg(XUiHelper.GetText("GuildWarSweepFinished"))
            self:Update()
        end)
    end)
end

function XUiGuildWarPandaStageDetail:OnBtnFightClicked()
    local node = self:GetNode()
    local pandaNode = XDataCenter.GuildWarManager.GetChildNode(node:GetId(), self.PandaType)

    -- 检查体力是否充足
    if not XEntityHelper.CheckItemCountIsEnough(XGuildWarConfig.ActivityPointItemId,
            pandaNode:GetFightCostEnergy()) then
        return
    end
    XDataCenter.GuildWarManager.GetBattleManager():UpdateCurrentClientBattleInfo(pandaNode:GetUID(), pandaNode:GetStutesType())

    if pandaNode:GetHP() <= 0 then
        XUiManager.TipErrorWithKey("GuildWarNodeIsDead")
        return
    end

    if pandaNode:HasWeakness() then
        self:OpenBattleRoomUi(pandaNode:GetStageId())
    else
        XLuaUiManager.Open("UiDialog", nil
        , XUiHelper.GetText("GuildWarNotWeakness")
        , XUiManager.DialogType.Normal, nil
        , function()
                self:OpenBattleRoomUi(pandaNode:GetStageId())
            end)
    end
end

function XUiGuildWarPandaStageDetail:OpenBattleRoomUi(stageId)
    XDataCenter.GuildWarManager.GetBattleManager():OpenBattleRoomUi(stageId)
end

-- endregion

function XUiGuildWarPandaStageDetail:CloseDetail()
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_PANDA_UNFOLD_DETAIL, false, XGuildWarConfig.ChildNodeIndex.None)
end

function XUiGuildWarPandaStageDetail:OnEnable()
    XUiGuildWarPandaStageDetail.Super.OnEnable(self)
    self:StartTimer()
    self:UpdatePanda()
    self:AddEventListener()
    local selectedNodeId = self._SelectedNodeId
    if selectedNodeId then
        local pandaType = XGuildWarConfig.GetChildIndexByNodeId(selectedNodeId)
        self:OnEventUnfoldDetail(true, pandaType)
    else
        self:Update()
    end
    self:InitWeakness()
    self:ShowAction()
end

function XUiGuildWarPandaStageDetail:OnDisable()
    XUiGuildWarPandaStageDetail.Super.OnDisable(self)
    self:RemoveEventListener()
    self:StopTimer()
    if XLuaUiManager.IsMaskShow(XGuildWarConfig.MASK_KEY) then
        XLuaUiManager.SetMask(false, XGuildWarConfig.MASK_KEY)
    end
end

--添加监听
function XUiGuildWarPandaStageDetail:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_NODEDATA_CHANGE, self.UpdatePanda, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_PANDA_UNFOLD_DETAIL, self.OnEventUnfoldDetail, self)

    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTIONLIST_OVER, self.DoActionOver, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_NODEDESTROY, self.ShowNodeDestroyed, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_TRANSFER_WEAKNESS, self.ShowTransferWeakness, self)
end
--移除监听
function XUiGuildWarPandaStageDetail:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_NODEDATA_CHANGE, self.UpdatePanda, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_PANDA_UNFOLD_DETAIL, self.OnEventUnfoldDetail, self)

    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTIONLIST_OVER, self.DoActionOver, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_NODEDESTROY, self.ShowNodeDestroyed, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_TRANSFER_WEAKNESS, self.ShowTransferWeakness, self)
end

function XUiGuildWarPandaStageDetail:StartTimer()
    self:UpdateTime()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:UpdateTime()
    end, 1, 0)
    self.ActionTimer = XScheduleManager.ScheduleForever(function()
        self:ShowAction()
    end, XScheduleManager.SECOND, 0)
end

function XUiGuildWarPandaStageDetail:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = false
    end
    if self.ActionTimer then
        XScheduleManager.UnSchedule(self.ActionTimer)
        self.ActionTimer = false
    end
end

function XUiGuildWarPandaStageDetail:OnEventUnfoldDetail(isUnfold, pandaType)
    if isUnfold then
        self.BtnCloseDetail.gameObject:SetActiveEx(true)
        self.PanelDetail.gameObject:SetActiveEx(true)
        self:Update(pandaType)
    else
        self.UiCamNearBossLeft.gameObject:SetActiveEx(false)
        self.UiCamNearBossRight.gameObject:SetActiveEx(false)
        self.UiCamFarBossLeft.gameObject:SetActiveEx(false)
        self.UiCamFarBossRight.gameObject:SetActiveEx(false)
        self.LeftBoss.gameObject:SetActiveEx(true)
        self.RightBoss.gameObject:SetActiveEx(true)
        self.BtnCloseDetail.gameObject:SetActiveEx(false)
        self.PandaType = XGuildWarConfig.ChildNodeIndex.None
        self.PanelDetail.gameObject:SetActiveEx(false)
    end
end

function XUiGuildWarPandaStageDetail:Update(pandaType)
    if self.PandaType == pandaType then
        return
    end
    if pandaType then
        self.PandaType = pandaType
    end

    if self.PandaType == XGuildWarConfig.ChildNodeIndex.None then
        self.UiCamNearBossLeft.gameObject:SetActiveEx(false)
        self.UiCamNearBossRight.gameObject:SetActiveEx(false)
        self.UiCamFarBossLeft.gameObject:SetActiveEx(false)
        self.UiCamFarBossRight.gameObject:SetActiveEx(false)
        self.LeftBoss.gameObject:SetActiveEx(true)
        self.RightBoss.gameObject:SetActiveEx(true)
        return
    end

    self.LeftBoss.gameObject:SetActiveEx(false)
    self.RightBoss.gameObject:SetActiveEx(false)
    if self.PandaType == XGuildWarConfig.ChildNodeIndex.Left then
        self.UiCamNearBossLeft.gameObject:SetActiveEx(true)
        self.UiCamNearBossRight.gameObject:SetActiveEx(false)
        self.UiCamFarBossLeft.gameObject:SetActiveEx(true)
        self.UiCamFarBossRight.gameObject:SetActiveEx(false)

    elseif self.PandaType == XGuildWarConfig.ChildNodeIndex.Right then
        self.UiCamNearBossLeft.gameObject:SetActiveEx(false)
        self.UiCamNearBossRight.gameObject:SetActiveEx(true)
        self.UiCamFarBossLeft.gameObject:SetActiveEx(false)
        self.UiCamFarBossRight.gameObject:SetActiveEx(true)
    end

    local pandaNode = XDataCenter.GuildWarManager.GetChildNode(self.NodeId, self.PandaType)

    -- buff
    self:UpdateBuff(pandaNode)

    -- 击破奖励
    self:RefreshRewardList(pandaNode)
    
    -- 已击破
    if pandaNode:GetIsDead() then
        self.BtnFight.gameObject:SetActiveEx(false)
        self.BtnAutoFight.gameObject:SetActiveEx(false)
        if self.TxtFightTips then
            self.TxtFightTips.gameObject:SetActiveEx(true)
        end
    else
        -- 作战准备
        local sweepCostEnergy = XDataCenter.GuildWarManager.GetNodeSweepCostEnergy(pandaNode:GetId())
        self.BtnFight:SetName(sweepCostEnergy)
        self.BtnFight.gameObject:SetActiveEx(true)

        -- 区域扫荡
        local fightCostEnergy = XDataCenter.GuildWarManager.GetNodeFightCostEnergy(pandaNode:GetId())
        self.BtnAutoFight:SetName(fightCostEnergy)
        self.BtnAutoFight.gameObject:SetActiveEx(pandaNode:CheckCanSweep())
        if self.TxtFightTips then
            self.TxtFightTips.gameObject:SetActiveEx(false)
        end
    end

    -- hp
    local hp, maxHp = pandaNode:GetHP(), pandaNode:GetMaxHP()
    self.TxtHP.text = string.format("%.1f",hp / 100) .. "%"
    self.Progress.fillAmount = hp / maxHp

    -- name and icon
    self.TxtName.text = pandaNode:GetName(false)
    self.RImgIcon:SetRawImage(pandaNode:GetIcon())

    -- damage
    self.TxtMyDamage.text = XUiHelper.GetText("GuildWarMaxDamageTip"
    , getRoundingValue((pandaNode:GetMaxDamage() / pandaNode:GetMaxHP()) * 100, 2))

    self:UpdateTime()
    self:UpdateWeaknessOnUiDetail()
end

function XUiGuildWarPandaStageDetail:InitWeakness()
    local pandaType = XDataCenter.GuildWarManager.GetWeaknessChildIndex(self.NodeId)
    if pandaType == XGuildWarConfig.ChildNodeIndex.Right then
        self:TransferWeakness(WeaknessShowType.WeaknessRight)
        return
    end
    if pandaType == XGuildWarConfig.ChildNodeIndex.Left then
        self:TransferWeakness(WeaknessShowType.WeaknessLeft)
        return
    end
end

function XUiGuildWarPandaStageDetail:RefreshRewardList(node)
    local rewardId = XDataCenter.GuildWarManager.GetNodeRewardId(node:GetId())
    self.PanelReward.gameObject:SetActiveEx(rewardId > 0)
    if rewardId > 0 then
        local rewardDatas = XRewardManager.GetRewardList(rewardId) or {}
        self.PanelReward.gameObject:SetActiveEx(#rewardDatas > 0)
        XUiHelper.RefreshCustomizedList(self.RewardParent, self.GridCommon, #rewardDatas, function(index, child)
            local grid = XUiGridCommon.New(self, child)
            grid:Refresh(rewardDatas[index])
        end)
    end
end

function XUiGuildWarPandaStageDetail:OnBtnPlayerClicked()
    local rankType = XGuildWarConfig.RankingType.Node
    local node = self:GetNode()
    local uid = node:GetUID()
    XDataCenter.GuildWarManager.RequestRanking(rankType, uid, function(rankList, myRankInfo)
        XLuaUiManager.Open("UiGuildWarStageRank", rankList, myRankInfo, rankType, uid, node)
    end)
end

function XUiGuildWarPandaStageDetail:OnBtnLeftClicked()
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_PANDA_UNFOLD_DETAIL, true, XGuildWarConfig.ChildNodeIndex.Left)
end

function XUiGuildWarPandaStageDetail:OnBtnRightClicked()
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_PANDA_UNFOLD_DETAIL, true, XGuildWarConfig.ChildNodeIndex.Right)
end

function XUiGuildWarPandaStageDetail:UpdateBuff(node)
    local buffData = node:GetFightEventDetailConfig()
    self.GameObject:SetActiveEx(buffData ~= nil)
    if buffData == nil then
        return
    end
    self.RImgShellingIcon:SetRawImage(buffData.Icon)
    self.TxtShellingName.text = buffData.Name
    self.TxtShellingDetails.text = buffData.Description
    self.TxtAreaDetails.text = node:GetDesc()
    self:RefreshTimeData(node)
end

function XUiGuildWarPandaStageDetail:UpdateTime()
    if not self.PandaType then
        return
    end
    self:RefreshTimeData(self:GetNode())
end

function XUiGuildWarPandaStageDetail:RefreshTimeData(node)
    local timeRemaining = node:GetTimeToBossAttack()
    if timeRemaining > 0 then
        local textTime = XUiHelper.GetTime(timeRemaining, XUiHelper.TimeFormatType.HOUR_MINUTE_SECOND)
        self.TxtShellingTime.text = XUiHelper.GetText("GuildWarDamageTime",
                textTime)
        self.TxtShellingTime.gameObject:SetActiveEx(true)
    else
        self.TxtShellingTime.gameObject:SetActiveEx(false)
    end
end

function XUiGuildWarPandaStageDetail:OnBtnHelpClick()
    XLuaUiManager.Open("UiGuildWarStageTips", self:GetNode())
end

function XUiGuildWarPandaStageDetail:GetEffectGo(name)
    local root = self.UiModelGo.transform
    return root:Find(string.format("UiNearRoot/%s", name)).gameObject
end

function XUiGuildWarPandaStageDetail:SetActiveEffectGo(name, isActive)
    local gameObj = self:GetEffectGo(name)
    gameObj:SetActiveEx(isActive)
end

--region 动作动画相关

--开始播放行动动画
function XUiGuildWarPandaStageDetail:ShowAction()
    local node = self:GetNode()
    if node:GetIsDead() then
        return
    end
    if not XLuaUiManager.GetTopUiName() == "UiGuildWarPandaStageDetail" then
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
function XUiGuildWarPandaStageDetail:DoActionOver()
    if XLuaUiManager.IsMaskShow(XGuildWarConfig.MASK_KEY) then
        XLuaUiManager.SetMask(false, XGuildWarConfig.MASK_KEY)
    end
end

--节点攻破动画
function XUiGuildWarPandaStageDetail:ShowNodeDestroyed(actionGroup)
    XDataCenter.GuildWarManager.ShowNodeDestroyed(actionGroup,function()
        self.BattleManager:DoActionFinish(XGuildWarConfig.GWActionType.NodeDestroyed,PlayTypeList)
    end)
end

--弱点交换动画
function XUiGuildWarPandaStageDetail:ShowTransferWeakness(actionGroup)
    if #actionGroup > 0 then
        local lastAction = actionGroup[#actionGroup]
        local fromNode = XDataCenter.GuildWarManager.GetBattleManager():GetNodeByUid(lastAction.FromNodeUid)
        if fromNode then
            local pandaType = XGuildWarConfig.GetChildIndexByNodeId(fromNode:GetId())
            if pandaType == XGuildWarConfig.ChildNodeIndex.Left then
                self:TransferWeakness(WeaknessShowType.WeaknessLeft2Right)
                self.BattleManager:DoActionFinish(XGuildWarConfig.GWActionType.TransferWeakness,PlayTypeList)
                return
            end
            if pandaType == XGuildWarConfig.ChildNodeIndex.Left then
                self:TransferWeakness(WeaknessShowType.WeaknessRight2Left)
                self.BattleManager:DoActionFinish(XGuildWarConfig.GWActionType.TransferWeakness,PlayTypeList)
                return
            end
        end
    end
    
end

--设置交换弱点特效
function XUiGuildWarPandaStageDetail:TransferWeakness(weaknessType)
    local typeBool1 = weaknessType == WeaknessShowType.WeaknessLeft -- 弱点在左
    local typeBool2 = weaknessType == WeaknessShowType.WeaknessRight -- 弱点在右
    local typeBool3 = weaknessType == WeaknessShowType.WeaknessLeft2Right -- 弱点从左到右
    local typeBool4 = weaknessType == WeaknessShowType.WeaknessRight2Left -- 弱点从右到左
    self:SetActiveEffectGo("ImgEffectLeftRuodian", typeBool1 or typeBool4)
    self:SetActiveEffectGo("ImgEffectLeftRuodianStart", typeBool1 or typeBool4)
    self:SetActiveEffectGo("ImgEffectLeftRuodianMove", typeBool3)
    self:SetActiveEffectGo("ImgEffectRightRuodian", typeBool2 or typeBool3)
    self:SetActiveEffectGo("ImgEffectRightRuodianStart", typeBool2 or typeBool3)
    self:SetActiveEffectGo("ImgEffectRightRuodianMove", typeBool4)
    self.BattleManager:DoActionFinish(XGuildWarConfig.GWActionType.TransferWeakness,PlayTypeList)
end

--endregion


function XUiGuildWarPandaStageDetail:UpdatePanda()
    local node = self:GetNode()
    if node:GetIsDead() then
        self:Close()
        XLuaUiManager.Open("UiGuildWarStageDetail", node, false)
        return
    end
    
    self.GridPandaWhite:Update()
    self.GridPandaBlack:Update()

    -- 区域成员
    self.BtnPlayer:SetNameByGroup(1, node:GetMemberCount())
    self:UpdateWeaknessOnUiDetail()
end

function XUiGuildWarPandaStageDetail:UpdateWeaknessOnUiDetail()
    if self.PandaType ~= XGuildWarConfig.ChildNodeIndex.None then
        local isHasWeakness = XDataCenter.GuildWarManager.IsChildHasWeakness(self.NodeId, self.PandaType)
        self.TxtRuodian.gameObject:SetActiveEx(isHasWeakness)
    end
end

return XUiGuildWarPandaStageDetail
