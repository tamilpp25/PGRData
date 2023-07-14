local XUiGuildWarStageDetailEvent = require("XUi/XUiGuildWar/Node/XUiGuildWarStageDetailEvent")

---@class XUiGuildWarTerm4PanelDetail
local XUiGuildWarTerm4PanelDetail = XClass(nil, "XUiGuildWarTerm4PanelDetail")

function XUiGuildWarTerm4PanelDetail:Ctor(ui)
    ---@type XUiGuildWarStageDetailEvent[]
    self._UiEvent = {}
    XTool.InitUiObjectByUi(self, ui)
    self:Init()
end

function XUiGuildWarTerm4PanelDetail:Init()
    XUiHelper.RegisterClickEvent(self, self.BtnPlayer, self.OnBtnPlayerClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnCloseDetail, self.OnBtnCloseDetailClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnAutoFight, self.OnBtnAutoFightClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnFight, self.OnBtnFightClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnHelpDetail, self.OnBtnHelpClick)
    XUiHelper.RegisterClickEvent(self, self.ButtonReward, self.OnClickRewardPreview)
    XUiHelper.RegisterClickEvent(self, self.BtnMode, self.OnBtnModeSwitch)
    self.RImgCostFight1:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XGuildWarConfig.ActivityPointItemId))
    self.RImgCostFight2:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XGuildWarConfig.ActivityPointItemId))
    self.PanelShelling.gameObject:SetActiveEx(false)
end

function XUiGuildWarTerm4PanelDetail:Show(node)
    self.NodeId = node:GetId()
    ---@type XTerm4BossChildGWNode
    self.Node = node
    self.GameObject:SetActiveEx(true)
    self:Update()
end

function XUiGuildWarTerm4PanelDetail:Hide()
    self.GameObject:SetActiveEx(false)
end

--更新界面
function XUiGuildWarTerm4PanelDetail:Update()
    ---@type XTerm4BossChildGWNode
    local node = self.Node
    local rootNode = node:GetParentNode()
    -- 血量
    local hp, maxHp = rootNode:GetHP(), rootNode:GetMaxHP()
    self.TxtHP.text = string.format("%.1f", hp / 100) .. "%"
    self.Progress.fillAmount = hp / maxHp

    -- 名字和图标
    self.TxtName.text = node:GetShowMonsterName()
    self.RImgIcon:SetRawImage(node:GetShowMonsterIcon())

    -- 伤害
    self.TxtMyDamage.text = XUiHelper.GetText("GuildWarMaxDamageTip"
    , getRoundingValue((node:GetMaxDamage() / node:GetMaxHP()) * 100, 2))

    -- 显示节点已被击破内容
    if node:GetIsDead() then
        self.BtnFight.gameObject:SetActiveEx(false)
        self.BtnAutoFight.gameObject:SetActiveEx(false)
        if self.TxtFightTips then
            self.TxtFightTips.gameObject:SetActiveEx(true)
        end
    else
        -- 显示节点未被击破内容
        -- 作战准备
        local sweepCostEnergy = XDataCenter.GuildWarManager.GetNodeSweepCostEnergy(node:GetId())
        self.BtnFight:SetName(sweepCostEnergy)
        self.BtnFight.gameObject:SetActiveEx(true)

        -- 区域扫荡
        local fightCostEnergy = XDataCenter.GuildWarManager.GetNodeFightCostEnergy(node:GetId())
        self.BtnAutoFight:SetName(fightCostEnergy)
        self.BtnAutoFight.gameObject:SetActiveEx(node:CheckCanSweep())
        if self.TxtFightTips then
            self.TxtFightTips.gameObject:SetActiveEx(false)
        end
    end

    -- 区域成员(只显示根节点的)
    if node:IsChildNode() then
        self.BtnPlayer:SetNameByGroup(1, node:GetParentNode():GetMemberCount())
    else
        self.BtnPlayer:SetNameByGroup(1, node:GetMemberCount())
    end

    --更新Buff
    self:UpdateBuff()

    --更新弱点UI信息
    self:UpdateWeaknessOnUiDetail()

    --更新奖励情报
    self:RefreshRewardList()
end

--更新Buff
function XUiGuildWarTerm4PanelDetail:UpdateBuff()
    local node = self.Node
    local buffData = node:GetFightEventDetailConfig()
    self.GameObject:SetActiveEx(buffData ~= nil)
    if buffData == nil then
        return
    end
    --self.RImgShellingIcon:SetRawImage(buffData.Icon)
    --self.TxtShellingName.text = buffData.Name
    --self.TxtShellingDetails.text = buffData.Description
    self.TxtAreaDetails.text = node:GetDesc()

    local eventDetails = node:GetAllFightEventDetailConfig()
    for i = 1, #eventDetails do
        local uiEvent = self._UiEvent[i]
        if not uiEvent then
            local ui = XUiHelper.Instantiate(self.PanelShelling.gameObject, self.PanelShelling.transform.parent.transform)
            uiEvent = XUiGuildWarStageDetailEvent.New(ui)
            self._UiEvent[i] = uiEvent
        end
        local event = eventDetails[i]
        uiEvent:Update(event)
        uiEvent.GameObject:SetActiveEx(true)
    end
    for i = #eventDetails + 1, #self._UiEvent do
        local uiEvent = self._UiEvent[i]
        uiEvent.GameObject:SetActiveEx(false)
    end
end

--更新弱点UI信息
function XUiGuildWarTerm4PanelDetail:UpdateWeaknessOnUiDetail()
    self.TxtRuodian.gameObject:SetActiveEx(false)
end

--更新奖励列表
function XUiGuildWarTerm4PanelDetail:RefreshRewardList()
    local node = self.Node
    local rewardId = XGuildWarConfig.GetBossRewardId(node)
    self.PanelReward.gameObject:SetActiveEx(rewardId > 0)
    if rewardId > 0 then
        local rewardDatas = XRewardManager.GetRewardList(rewardId) or {}
        self.PanelReward.gameObject:SetActiveEx(#rewardDatas > 0)
        XUiHelper.RefreshCustomizedList(self.RewardParent, self.GridCommon, #rewardDatas, function(index, child)
            local grid = XUiGridCommon.New(nil, child)
            grid:Refresh(rewardDatas[index])
        end)
    end
end

--点击关闭详情
function XUiGuildWarTerm4PanelDetail:OnBtnCloseDetailClicked()
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_PANDA_UNFOLD_DETAIL, false)
end

--点击扫荡按钮
function XUiGuildWarTerm4PanelDetail:OnBtnAutoFightClicked()
    local node = self.Node
    local cost = node:GetSweepCostEnergy()
    if not XEntityHelper.CheckItemCountIsEnough(XGuildWarConfig.ActivityPointItemId, cost) then
        return
    end
    local damage = getRoundingValue((node:GetMaxDamage() / node:GetMaxHP()) * 100, 2)
    local textKey = "GuildWarSweepTip"
    local power = XDataCenter.GuildWarManager.GetBattleManager():GetSweepHpFactor() * 100
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

--点击作战按钮
function XUiGuildWarTerm4PanelDetail:OnBtnFightClicked()
    if not XDataCenter.GuildWarManager.CheckRoundIsInTime() then
        XUiManager.TipText("GuildWarNotFighting")
        return
    end

    local node = self.Node
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

    local stageId = node:GetStageId()
    XDataCenter.GuildWarManager.GetBattleManager():OpenBattleRoomUi(stageId)
end

--点击玩家按钮
function XUiGuildWarTerm4PanelDetail:OnBtnPlayerClicked()
    local rankType = XGuildWarConfig.RankingType.Node
    --只取根节点的排行
    local node = self.Node
    if self.Node:IsChildNode() then
        node = self.Node:GetParentNode()
    end
    local uid = node:GetUID()
    XDataCenter.GuildWarManager.RequestRanking(rankType, uid, function(rankList, myRankInfo)
        XLuaUiManager.Open("UiGuildWarStageRank", rankList, myRankInfo, rankType, uid, node)
    end)
end

--点击帮助按钮
function XUiGuildWarTerm4PanelDetail:OnBtnHelpClick()
    XLuaUiManager.Open("UiGuildWarStageTips", self.Node)
end

function XUiGuildWarTerm4PanelDetail:OnClick()
end

function XUiGuildWarTerm4PanelDetail:OnClickRewardPreview()
    XLuaUiManager.Open("UiGuildWarLzTask", self.Node:GetParentNode())
end

function XUiGuildWarTerm4PanelDetail:OnBtnModeSwitch()
    if self.Node:GetSelfChildIndex() == XGuildWarConfig.ChildNodeIndex.Right then
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_PANDA_UNFOLD_DETAIL, true, XGuildWarConfig.ChildNodeIndex.Left)
    elseif self.Node:GetSelfChildIndex() == XGuildWarConfig.ChildNodeIndex.Left then
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_PANDA_UNFOLD_DETAIL, true, XGuildWarConfig.ChildNodeIndex.Right)
    end
end

return XUiGuildWarTerm4PanelDetail
