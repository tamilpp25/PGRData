XLottoConfigs = XLottoConfigs or {}

local TABLE_LOTTO = "Share/Lotto/Lotto.tab"
local TABLE_LOTTO_REWARD = "Share/Lotto/LottoReward.tab"
local TABLE_LOTTO_BUY_TICKET_RULE = "Share/Lotto/LottoBuyTicketRule.tab"
local TABLE_LOTTO_PROBSHOW = "Client/Lotto/LottoProbShow.tab"
local TABLE_LOTTO_GROUP_RULE = "Client/Lotto/LottoGroupRule.tab"

local Lottos = {}
local LottoRewards = {}
local LottoProbShow = {}
local LottoRewardDic = {}
local LottoGroupRule = {}
local LottoBuyTicketRules = {}

XLottoConfigs.RareLevel = {
    One = 1,
    Two = 2,
    Three = 3,
    Four = 4,
}

XLottoConfigs.ExtraRewardState = {
    CanNotGet = 0,
    CanGet = 1,
    Geted = 2,
}

function XLottoConfigs.Init()
    Lottos = XTableManager.ReadByIntKey(TABLE_LOTTO, XTable.XTableLotto, "Id")
    LottoRewards = XTableManager.ReadByIntKey(TABLE_LOTTO_REWARD, XTable.XTableLottoReward, "Id")
    LottoProbShow = XTableManager.ReadByIntKey(TABLE_LOTTO_PROBSHOW, XTable.XTableLottoProbShow, "Id")
    LottoGroupRule = XTableManager.ReadByIntKey(TABLE_LOTTO_GROUP_RULE, XTable.XTableLottoGroupRule, "Id")
    LottoBuyTicketRules = XTableManager.ReadByIntKey(TABLE_LOTTO_BUY_TICKET_RULE, XTable.XTableLottoBuyTicketRule, "Id")
    
    XLottoConfigs.SetLottoRewardDic()
end

function XLottoConfigs.GetLottoReward()
    return LottoRewards
end

function XLottoConfigs.GetLottos()
    return Lottos
end

function XLottoConfigs.GetLottoCfgById(id)
    if not Lottos[id] then
        XLog.Error("id is not exist in "..TABLE_LOTTO.." id = " .. id)
        return
    end
    return Lottos[id]
end

function XLottoConfigs.GetLottoProbShows()
    return LottoProbShow
end

function XLottoConfigs.GetLottoProbShowCfgById(id)
    if not LottoProbShow[id] then
        XLog.Error("id is not exist in "..TABLE_LOTTO_PROBSHOW.." id = " .. id)
        return
    end
    return LottoProbShow[id]
end

function XLottoConfigs.GetLottoRewardCfgById(id)
    if not LottoRewards[id] then
        XLog.Error("id is not exist in "..TABLE_LOTTO_REWARD.." id = " .. id)
        return
    end
    return LottoRewards[id]
end

function XLottoConfigs.GetLottoGroupRuleCfgById(id)
    if not LottoGroupRule[id] then
        XLog.Error("id is not exist in "..LottoGroupRule.." id = " .. id)
        return
    end
    return LottoGroupRule[id]
end

function XLottoConfigs.GetLottoRewardListById(lottoId)
    if not LottoRewardDic[lottoId] then
        XLog.Error("id is not exist in "..TABLE_LOTTO_REWARD.." id = " .. lottoId)
        return
    end
    return LottoRewardDic[lottoId]
end

function XLottoConfigs.GetLottoBuyTicketRuleById(id)
    if not LottoBuyTicketRules[id] then
        XLog.Error("id is not exist in "..TABLE_LOTTO_BUY_TICKET_RULE.." id = " .. id)
        return
    end
    return LottoBuyTicketRules[id]
end

function XLottoConfigs.SetLottoRewardDic()
    for _,reward in pairs(LottoRewards) do
        LottoRewardDic[reward.LottoId] = LottoRewardDic[reward.LottoId] or {}
        table.insert(LottoRewardDic[reward.LottoId],reward)
    end
end
