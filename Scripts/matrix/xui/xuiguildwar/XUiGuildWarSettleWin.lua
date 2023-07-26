--######################## XGuildWarSettleConceal ########################
--region BossPanel
local XUiGuildWarSettleBoss = XClass(nil, "XUiGuildWarSettleBoss")

function XUiGuildWarSettleBoss:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
end

function XUiGuildWarSettleBoss:SetData(guildWarFightResult, config)
    -- 显示图标
    local icon
    if guildWarFightResult.Type == XGuildWarConfig.NodeFightType.FightNode then
        icon = config.ShowMonsterIcon
    elseif guildWarFightResult.Type == XGuildWarConfig.NodeFightType.FightMonster then
        icon = config.Icon
    end
    -- 当前血量
    local hp = math.max(guildWarFightResult.CurHp - guildWarFightResult.Damage, 0)
    -- 上一次血量
    local lastHP = guildWarFightResult.CurHp
    self.RImgIcon:SetRawImage(icon)
    self.TxtHP.text = string.format( "%s%%", getRoundingValue((hp / config.HpMax) * 100, 2) )
    self.TxtDamage.text = string.format( "-%s%%", getRoundingValue((guildWarFightResult.Damage / config.HpMax) * 100, 2) )
    self.TxtHighDamage.text = string.format( "-%s%%", getRoundingValue((guildWarFightResult.MaxDamage / config.HpMax) * 100, 2) )
    self.TxtMaxScoreTip.gameObject:SetActiveEx(guildWarFightResult.IsNewRecord == 1)
    -- 血量
    self.ProgressHp.fillAmount = lastHP / config.HpMax
    self.ProgressDamage.fillAmount = lastHP / config.HpMax
    self.ProgressHp:DOFillAmount(hp / config.HpMax, 1)
end
--endregion
--######################## XUiGuildWarSettleRebuild ########################
--region rebuildPanel
local XUiGuildWarSettleRebuild = XClass(nil, "XUiGuildWarSettleRebuild")

function XUiGuildWarSettleRebuild:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
end

function XUiGuildWarSettleRebuild:SetData(guildWarFightResult, node)
    self.RImgIcon:SetRawImage(node:GetShowMonsterIcon())
    local addTime = node:GetRebuildTimeByDamage(guildWarFightResult.Damage)
    local maxAddTime = math.max(node:GetHistoryMaxRebuildTime(), addTime)
    self.TxtHighAddTime.text = XUiHelper.GetTime(maxAddTime, XUiHelper.TimeFormatType.GUILDCD)
    self.TxtAddTime.text = XUiHelper.GetTime(addTime, XUiHelper.TimeFormatType.GUILDCD)
    self.TxtRebuildTime.text = node:GetRebuildTimeStr(addTime)
    --XTime.TimestampToGameDateTimeString(node:GetRebuildTime(addTime), "HH:mm:ss")
    self.ProgressAddTime:DOFillAmount(node:GetRebuildProgress())
    self.ProgressTime.fillAmount = node:GetRebuildProgress()
    self.ProgressTime:DOFillAmount(node:GetRebuildProgress(addTime))
end
--endregion
--######################## XGuildWarSettleConceal ########################
--region concealPanel
local XUiGuildWarSettleConceal = XClass(nil, "XUiGuildWarSettleConceal")

function XUiGuildWarSettleConceal:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
end

function XUiGuildWarSettleConceal:SetData(guildWarFightResult)
    --隐藏节点结算数据
    self.TxtDamage.text = guildWarFightResult.Damage
end
--endregion
--######################## XUiChildPanel ########################
--region childPanelController
local XUiPanelExpBar = require("XUi/XUiSettleWinMainLine/XUiPanelExpBar")
local XUiChildPanel = XClass(nil, "XUiChildPanel")

function XUiChildPanel:Ctor(ui, rootUi)
    XUiHelper.InitUiClass(self, ui)
    self.RootUi = rootUi
    self.StageConfig = nil
    self.GuildWarManager = XDataCenter.GuildWarManager
    self.BattleManager = self.GuildWarManager.GetBattleManager()
    self.XUiGuildWarSettleBoss = XUiGuildWarSettleBoss.New(self.GuildWarSettleBoss)
    self.XUiGuildWarSettleRebuild = XUiGuildWarSettleRebuild.New(self.GuildWarSettleRebuild)
    self.XUiGuildWarSettleConceal = XUiGuildWarSettleConceal.New(self.GuildWarSettleConceal)
    self:RegisterUiEvents()
end

function XUiChildPanel:SetData(stageConfig, winData)
    self.GuildWarSettleRebuild.gameObject:SetActiveEx(false)
    self.GuildWarSettleConceal.gameObject:SetActiveEx(false)
    self.GuildWarSettleBoss.gameObject:SetActiveEx(false)
    self.PanelNewRecord.gameObject:SetActiveEx(false)
    
    self.PanelBtn1.gameObject:SetActiveEx(false) --精英怪和一般节点使用按钮
    self.PanelBtn2.gameObject:SetActiveEx(false) --隐藏节点使用按钮
    
    self.StageConfig = stageConfig
    local settleData = winData.SettleData
    -- 公会战结算数据
    local guildWarFightResult = settleData.GuildWarFightResult
    -- 获取节点or怪物配置
    if guildWarFightResult.Type == XGuildWarConfig.NodeFightType.FightNode then
        local nodeId = guildWarFightResult.NodeId
        if XGuildWarConfig.GetNodeType(nodeId) == XGuildWarConfig.NodeType.Term3SecretChild then
            self:UpdateSecretNode(stageConfig,guildWarFightResult)
        else
            self:UpdateCommonNode(stageConfig,guildWarFightResult)
        end
    elseif guildWarFightResult.Type == XGuildWarConfig.NodeFightType.FightMonster then
        self:UpdateMonster(stageConfig,guildWarFightResult)
    end
end

--精英怪显示的结算界面
function XUiChildPanel:UpdateMonster(stageConfig, guildWarFightResult)
    self.PanelBtn1.gameObject:SetActiveEx(true)
    local monsterConfig = XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.EliteMonster, guildWarFightResult.MonsterId)
    self.TxtPoint.text = guildWarFightResult.Point
    if guildWarFightResult.Point >= monsterConfig.MaxPoint then
        self.TxtPoint.text = self.TxtPoint.text .. "<size=40>MAX</size>"
    end

    -- 挑战花费
    local costCount = monsterConfig.FightCostEnergy
    self.TxtCostCount.text = costCount
    self.RImgSpendIcon:SetRawImage(XEntityHelper.GetItemIcon(XGuildWarConfig.ActivityPointItemId))

    self.GuildWarSettleBoss.gameObject:SetActiveEx(true)
    self.XUiGuildWarSettleBoss:SetData(guildWarFightResult, monsterConfig)
end

--一般节点显示的结算画面
function XUiChildPanel:UpdateCommonNode(stageConfig, guildWarFightResult)
    self.PanelBtn1.gameObject:SetActiveEx(true)
    self.GuildWarSettleBoss.gameObject:SetActiveEx(true)
    local nodeConfig = XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.Node, guildWarFightResult.NodeId)
    self.TxtPoint.text = guildWarFightResult.Point
    if guildWarFightResult.Point >= nodeConfig.MaxPoint then
        self.TxtPoint.text = self.TxtPoint.text .. "<size=40>MAX</size>"
    end
    
    -- 挑战花费
    local costCount = nodeConfig.FightCostEnergy
    self.TxtCostCount.text = costCount
    self.RImgSpendIcon:SetRawImage(XEntityHelper.GetItemIcon(XGuildWarConfig.ActivityPointItemId))
    
    self.XUiGuildWarSettleBoss:SetData(guildWarFightResult, nodeConfig)
    local node = self.BattleManager:GetNode(guildWarFightResult.NodeId)
    if node:GetNodeType() == XGuildWarConfig.NodeType.Sentinel and
            self.BattleManager:GetCurrentClientBattleNodeStatus() == XGuildWarConfig.NodeStatusType.Revive then
        self.GuildWarSettleRebuild.gameObject:SetActiveEx(true)
        self.GuildWarSettleBoss.gameObject:SetActiveEx(false)
        self.XUiGuildWarSettleRebuild:SetData(guildWarFightResult, node)
    end
end

--第三期隐藏节点显示的结算画面
function XUiChildPanel:UpdateSecretNode(stageConfig, guildWarFightResult)
    self.PanelBtn2.gameObject:SetActiveEx(true)
    self.GuildWarSettleConceal.gameObject:SetActiveEx(true)
    local nodeConfig = XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.Node, guildWarFightResult.NodeId)
    self.TxtPoint.text = guildWarFightResult.Point
    if guildWarFightResult.Point >= nodeConfig.MaxPoint then
        self.TxtPoint.text = self.TxtPoint.text .. "<size=40>MAX</size>"
    end
    self.TxtCostCount.text = guildWarFightResult.costCount
    self.RImgSpendIcon:SetRawImage(XEntityHelper.GetItemIcon(XGuildWarConfig.ActivityPointItemId))
    self.PanelNewRecord.gameObject:SetActiveEx(guildWarFightResult.IsNewRecord == 1)
    self.XUiGuildWarSettleConceal:SetData(guildWarFightResult)
end

function XUiChildPanel:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnOK, self.OnBtnOKClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnExit, self.OnBtnExitClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnConfirm, self.OnBtnExitClicked)
end
function XUiChildPanel:OnBtnOKClicked()
    self.GuildWarManager.ConfirmFight(self.StageConfig.StageId, function()
        self.GuildWarManager.GetActivityData(function()
            XUiManager.TipText("GuildWarSettleFinish")
            self:OnBtnExitClicked()
        end)
    end)
end
function XUiChildPanel:OnBtnExitClicked()
    self.RootUi:Close()
end
--endregion
--######################## XUiGuildWarSettleWin ########################
local XUiSettleWinCommonDefaultProxy = require("XUi/XUiSettleWin/XUiSettleWinCommonDefaultProxy")
local XUiGuildWarSettleWin = XClass(XUiSettleWinCommonDefaultProxy, "XUiGuildWarSettleWin")

-- 获取子面板数据，主要用来增加界面自身玩法信息，就不用污染通用的预制体
--[[
return : {
assetPath : 资源路径
proxy : 子面板代理
proxyArgs : 子面板SetData传入的参数列表
}
]]
function XUiGuildWarSettleWin:GetChildPanelData()
    return {
        assetPath = XUiConfigs.GetComponentUrl("PanelGuildWarSettle"),
        proxy = XUiChildPanel,
        proxyArgs = { "StageConfig", "WinData"}
    }
end

function XUiGuildWarSettleWin:AOPOnStartBefore(rootUi)
    rootUi.PanelRewardList.gameObject:SetActiveEx(false)
    rootUi.PanelPlayerExp.gameObject:SetActiveEx(false)
    rootUi.PanelBtns.gameObject:SetActiveEx(false)
end

return XUiGuildWarSettleWin