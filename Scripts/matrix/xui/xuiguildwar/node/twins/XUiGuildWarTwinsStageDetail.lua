---@class XUiGuildWarTwinsStageDetail
local XUiGuildWarTwinsStageDetail = XClass(nil, "XUiGuildWarTwinsStageDetail")

function XUiGuildWarTwinsStageDetail:Ctor(ui,rootUi)
    XTool.InitUiObjectByUi(self, ui)
    self.RootUi = rootUi
    self:Init()
end

function XUiGuildWarTwinsStageDetail:Init()
    XUiHelper.RegisterClickEvent(self, self.BtnPlayer, self.OnBtnPlayerClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnCloseDetail, self.OnBtnCloseDetailClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnAutoFight, self.OnBtnAutoFightClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnFight, self.OnBtnFightClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnHelpDetail, self.OnBtnHelpClick)
    self.RImgCostFight1:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XGuildWarConfig.ActivityPointItemId))
    self.RImgCostFight2:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XGuildWarConfig.ActivityPointItemId))
end

function XUiGuildWarTwinsStageDetail:Show(nodeId)
    self.NodeId = nodeId
    self.Node = XDataCenter.GuildWarManager.GetNode(nodeId)
    self.GameObject:SetActiveEx(true)
    self:Update()
end

function XUiGuildWarTwinsStageDetail:Hide()
    self.GameObject:SetActiveEx(false)
end

--更新界面
function XUiGuildWarTwinsStageDetail:Update()
    ---@type XGWNode
    local node = self.Node
    -- 血量
    local hp, maxHp = node:GetHP(), node:GetMaxHP()
    self.TxtHP.text = string.format("%.1f",hp / 100) .. "%"
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
    else -- 显示节点未被击破内容
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
function XUiGuildWarTwinsStageDetail:UpdateBuff()
    local node = self.Node
    local buffData = node:GetFightEventDetailConfig()
    self.GameObject:SetActiveEx(buffData ~= nil)
    if buffData == nil then
        return
    end
    self.RImgShellingIcon:SetRawImage(buffData.Icon)
    self.TxtShellingName.text = buffData.Name
    self.TxtShellingDetails.text = buffData.Description
    self.TxtAreaDetails.text = node:GetDesc()
    self:RefreshTimeData()
end

--更新弱点UI信息
function XUiGuildWarTwinsStageDetail:UpdateWeaknessOnUiDetail()
    if self.PandaType ~= XGuildWarConfig.ChildNodeIndex.None then
        local isHasWeakness = self.Node:HasWeakness()
        self.TxtRuodian.gameObject:SetActiveEx(isHasWeakness)
    end
end

--更新奖励列表
function XUiGuildWarTwinsStageDetail:RefreshRewardList()
    local node = self.Node
    local rewardId = XDataCenter.GuildWarManager.GetNodeRewardId(node:GetId())
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

--更新BOSS进攻时间
function XUiGuildWarTwinsStageDetail:RefreshTimeData()
    local node = self.Node
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

--定时器更新
function XUiGuildWarTwinsStageDetail:OnTimerUpdate()
    if not self.NodeId then return end
    self:RefreshTimeData()
end

--点击关闭详情
function XUiGuildWarTwinsStageDetail:OnBtnCloseDetailClicked()
    self.RootUi:SetNodeDetail(false)
end

--点击扫荡按钮
function XUiGuildWarTwinsStageDetail:OnBtnAutoFightClicked()
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
function XUiGuildWarTwinsStageDetail:OnBtnFightClicked()
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

    self.RootUi:OpenBattleRoomUi(node:GetStageId())
end

--点击玩家按钮
function XUiGuildWarTwinsStageDetail:OnBtnPlayerClicked()
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
function XUiGuildWarTwinsStageDetail:OnBtnHelpClick()
    XLuaUiManager.Open("UiGuildWarStageTips", self.Node)
end


function XUiGuildWarTwinsStageDetail:OnClick()
end

return XUiGuildWarTwinsStageDetail
