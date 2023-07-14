--######################## XUiGuildWarSettleRebuild ########################
local XUiGuildWarSettleRebuild = XClass(nil, "XUiGuildWarSettleRebuild")

function XUiGuildWarSettleRebuild:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
end

function XUiGuildWarSettleRebuild:SetData(winData, node)
    local settleData = winData.SettleData
    -- 公会战结算数据
    local guildWarFightResult = settleData.GuildWarFightResult
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

--######################## XUiChildPanel ########################
local XUiPanelExpBar = require("XUi/XUiSettleWinMainLine/XUiPanelExpBar")
local XUiChildPanel = XClass(nil, "XUiChildPanel")

function XUiChildPanel:Ctor(ui, rootUi)
    XUiHelper.InitUiClass(self, ui)
    self.RootUi = rootUi
    self.StageConfig = nil
    self.GuildWarManager = XDataCenter.GuildWarManager
    self.BattleManager = self.GuildWarManager.GetBattleManager()
    self.UiGuildWarSettleRebuild = XUiGuildWarSettleRebuild.New(self.GuildWarSettleRebuild)
    self:RegisterUiEvents()
end

function XUiChildPanel:SetData(stageConfig, winData)
    local settleData = winData.SettleData
    -- 公会战结算数据
    local guildWarFightResult = settleData.GuildWarFightResult
    self.StageConfig = stageConfig
    -- 获取节点or怪物配置
    local config
    -- 显示图标
    local icon
    if guildWarFightResult.Type == XGuildWarConfig.NodeFightType.FightNode then
        config = XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.Node, guildWarFightResult.NodeId)
        icon = config.ShowMonsterIcon
    elseif guildWarFightResult.Type == XGuildWarConfig.NodeFightType.FightMonster then
        config = XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.EliteMonster, guildWarFightResult.MonsterId)
        icon = config.Icon
    end
    -- 当前血量
    local hp = math.max(guildWarFightResult.CurHp - guildWarFightResult.Damage, 0)
    -- 上一次血量
    local lastHP = guildWarFightResult.CurHp
    -- 挑战花费
    local costCount = config.FightCostEnergy
    self.RImgIcon:SetRawImage(icon)
    self.TxtHP.text = string.format( "%s%%", getRoundingValue((hp / config.HpMax) * 100, 2) )
    self.TxtDamage.text = string.format( "-%s%%", getRoundingValue((guildWarFightResult.Damage / config.HpMax) * 100, 2) )
    self.TxtHighDamage.text = string.format( "-%s%%", getRoundingValue((guildWarFightResult.MaxDamage / config.HpMax) * 100, 2) )
    self.TxtMaxScoreTip.gameObject:SetActiveEx(guildWarFightResult.IsNewRecord == 1)
    self.TxtPoint.text = guildWarFightResult.Point
    if guildWarFightResult.Point >= config.MaxPoint then
        self.TxtPoint.text = self.TxtPoint.text .. "<size=40>MAX</size>"
    end
    self.TxtCostCount.text = costCount
    self.RImgSpendIcon:SetRawImage(XEntityHelper.GetItemIcon(XGuildWarConfig.ActivityPointItemId))
    -- 血量
    self.ProgressHp.fillAmount = lastHP / config.HpMax
    self.ProgressDamage.fillAmount = lastHP / config.HpMax
    self.ProgressHp:DOFillAmount(hp / config.HpMax, 1)
    -- 扩展
    self.GuildWarSettleRebuild.gameObject:SetActiveEx(false)
    self.GuildWarSettleBoss.gameObject:SetActiveEx(true)
    if guildWarFightResult.Type == XGuildWarConfig.NodeFightType.FightNode then
        local node = self.BattleManager:GetNode(guildWarFightResult.NodeId)
        if node:GetNodeType() == XGuildWarConfig.NodeType.Sentinel and
            self.BattleManager:GetCurrentClientBattleNodeStatus() == XGuildWarConfig.NodeStatusType.Revive then
            self.GuildWarSettleRebuild.gameObject:SetActiveEx(true)
            self.GuildWarSettleBoss.gameObject:SetActiveEx(false)
            self.UiGuildWarSettleRebuild:SetData(winData, node)
        end
    end
end

function XUiChildPanel:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnOK, self.OnBtnOKClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnExit, self.OnBtnExitClicked)
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