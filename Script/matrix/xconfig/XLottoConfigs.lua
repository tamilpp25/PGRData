XLottoConfigs = XConfigCenter.CreateTableConfig(XLottoConfigs, "XLottoConfigs", "Lotto")
--=============
--配置表枚举
--TableName : 表名，对应需要读取的表的文件名字，不写即为枚举的Key字符串
--TableDefindName : 表定于名，默认同表名
--ReadFuncName : 读取表格的方法，默认为ReadByIntKey
--ReadKeyName : 读取表格的主键名，默认为Id
--DirType : 读取的文件夹类型XConfigCenter.DirectoryType，默认是Share
--LogKey : GetCfgByIdKey方法idKey找不到时所输出的日志信息，默认是唯一Id
--=============
XLottoConfigs.TableKey = enum({
    LottoPrimary = {},
    LottoFashionSelfChoiceResources = { DirType = XConfigCenter.DirectoryType.Client, ReadKeyName = "LottoId" },
    LottoSceneVideo = { DirType = XConfigCenter.DirectoryType.Client, ReadKeyName = "LottoId" },
})

local TABLE_LOTTO = "Share/Lotto/Lotto.tab"
local TABLE_LOTTO_REWARD = "Share/Lotto/LottoReward.tab"
local TABLE_LOTTO_BUY_TICKET_RULE = "Share/Lotto/LottoBuyTicketRule.tab"
local TABLE_LOTTO_CLIENT_CONFIG = "Client/Lotto/LottoClientConfig.tab"
local TABLE_LOTTO_PROBSHOW = "Client/Lotto/LottoProbShow.tab"
local TABLE_LOTTO_GROUP_RULE = "Client/Lotto/LottoGroupRule.tab"
local TABLE_LOTTO_SHOW_REWARD_CONFIG = "Client/Lotto/LottoShowRewardConfig.tab"

local Lottos = {}
local LottoRewards = {}
local LottoProbShow = {}
local LottoRewardDic = {}
local LottoGroupRule = {}
local LottoBuyTicketRules = {}
local LottoShowRewardConfig = {}
local LottoClientConfig = {}

XLottoConfigs.RareLevel = {
    One = 1,
    Two = 2,
    Three = 3,
    Four = 4,
}

--- 稀有等级映射动画展示的品质。其中品质关联特效名称后缀索引（ClientConfig表的DrawRingQualityEffectX 和DrawQualityEffectX，X表示索引值）
XLottoConfigs.RareLevelToShowQuality = {
    [1] = 6,
    [2] = 5,
    [3] = 4,
    [4] = 3,
    [5] = 0,
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
    LottoShowRewardConfig = XTableManager.ReadByIntKey(TABLE_LOTTO_SHOW_REWARD_CONFIG,XTable.XTableLottoShowRewardConfig,"Id")
    LottoClientConfig = XTableManager.ReadByStringKey(TABLE_LOTTO_CLIENT_CONFIG,XTable.XTableLottoClientConfig,"Key")
    XLottoConfigs.SetLottoRewardDic()
end

function XLottoConfigs.GetLottoReward()
    return LottoRewards
end

function XLottoConfigs.GetLottos()
    return Lottos
end

--region Cfg - Lotto
---@return XTableLotto
function XLottoConfigs.GetLottoCfgById(id)
    if not Lottos[id] then
        XLog.Error("id is not exist in "..TABLE_LOTTO.." id = " .. id)
        return
    end
    return Lottos[id]
end

---@return XTableLottoPrimary
function XLottoConfigs.GetLottoPrimaryCfgById(id)
    return XLottoConfigs.GetAllConfigs(XLottoConfigs.TableKey.LottoPrimary)[id]
end

function XLottoConfigs.GetLottoStageActivity(id)
    local cfg = XLottoConfigs.GetLottoCfgById(id)
    return cfg and cfg.LottoStageActivity or 0
end

function XLottoConfigs.GetLottoOpenUiName(id)
    local cfg = XLottoConfigs.GetLottoCfgById(id)
    return cfg and cfg.OpenUiName or "UiLotto"
end
--endregion 

---@return XTableLottoProbShow[]
function XLottoConfigs.GetLottoProbShows()
    return LottoProbShow
end

---@return XTableLottoProbShow
function XLottoConfigs.GetLottoProbShowCfgById(id)
    if not LottoProbShow[id] then
        XLog.Error("id is not exist in "..TABLE_LOTTO_PROBSHOW.." id = " .. id)
        return
    end
    return LottoProbShow[id]
end

---@return XTableLottoReward
function XLottoConfigs.GetLottoRewardCfgById(id)
    if not LottoRewards[id] then
        XLog.Error("id is not exist in "..TABLE_LOTTO_REWARD.." id = " .. id)
        return
    end
    return LottoRewards[id]
end

---@return XTableLottoGroupRule
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


function XLottoConfigs.GetLottoRewardEffectPath(templateId)
    return LottoShowRewardConfig[templateId] and LottoShowRewardConfig[templateId].DrawEffectPath or nil
end

function XLottoConfigs.GetLottoRewardEffectPosition(templateId)
    return LottoShowRewardConfig[templateId] and LottoShowRewardConfig[templateId].EffectPosition or nil
end

function XLottoConfigs.GetLottoRewardEffectRotation(templateId)
    return LottoShowRewardConfig[templateId] and LottoShowRewardConfig[templateId].EffectRotation or nil
end

function XLottoConfigs.GetLottoRewardEffectScale(templateId)
    return LottoShowRewardConfig[templateId] and LottoShowRewardConfig[templateId].EffectScale or nil
end
function XLottoConfigs.GetLottoRewardAnimationName(templateId)
    return LottoShowRewardConfig[templateId] and LottoShowRewardConfig[templateId].AnimationName or nil
end

---@return string
function XLottoConfigs.GetLottoClientConfig(key, index)
    index = index or 1
    return LottoClientConfig[key] and LottoClientConfig[key].Value[index]
end

---@return number
function XLottoConfigs.GetLottoClientConfigNumber(key, index)
    index = index or 1
    return LottoClientConfig[key] and tonumber(LottoClientConfig[key].Value[index])
end