XSignInConfigs = XSignInConfigs or {}

XSignInConfigs.SignType = {
    Daily = 1,              -- 日常签到
    Activity = 2,           -- 活动签到
    PurchasePackage = 3,    -- 礼包签到
}

XSignInConfigs.SignOpen = {
    Default = 1, -- 默认打开
    Level = 2, -- 等级
    PreFunction = 3, -- 前置功能
}

local TABLE_SIGN_IN        = "Share/SignIn/SignIn.tab"
local TABLE_SIGN_IN_REWARD    = "Share/SignIn/SignInReward.tab"
local TABLE_SIGN_IN_SUBROUND = "Client/SignIn/SubRound.tab"
local TABLE_SIGN_CARD        = "Client/SignIn/SignCard.tab"
local TABLE_SIGN_RECHARGE    = "Client/SignIn/SignFirstRecharge.tab"
local TABLE_SIGN_WELFARE    = "Client/SignIn/Welfare.tab"
--元旦抽签表
local TABLE_SIGN_NEWYEAR_SIGN_IN = "Share/DailyLottery/DailyLottery.tab"
local TABLE_SIGN_DAILYLOTTERY_REWARD = "Share/DailyLottery/DailyLotteryReward.tab"
local TABLE_SIGN_DRAW_NEWYEAR = "Client/SignIn/SignDrawNewYear.tab"
--烟花活动表
local TABLE_SIGN_FIREWORKS = "Client/SignIn/SignFireworks.tab"

local SignInConfig = {}           -- 签到配置表
local SignInRewardConfig = {}     -- 签到奖励配置表[key = signId, value = (key = round, value = {conifig1, config2 ...})]
local SignInSubRound = {}         -- 客户端显示子轮次配置表
local SignCard = {}               -- 客户端月卡签到表
local SignRecharge = {}           -- 首充签到表
local SignWelfareList = {}        -- 福利配置表List
local SignWelfareDir = {}         -- 福利配置表dir
local SignInNewYearConfig = {}    -- 元旦活动签到表
local SignDrawNewYearConfig = {}  -- 元旦抽奖数据表
local SignInDailyLotteryRewardConfig = {}
local SignFireworksConfig = {}    -- 烟花活动配置表

function XSignInConfigs.Init()
    SignInConfig = XTableManager.ReadByIntKey(TABLE_SIGN_IN, XTable.XTableSignIn, "Id")
    SignInSubRound = XTableManager.ReadByIntKey(TABLE_SIGN_IN_SUBROUND, XTable.XTableSignInSubround, "Id")
    SignCard = XTableManager.ReadByIntKey(TABLE_SIGN_CARD, XTable.XTableSignCard, "Id")
    SignRecharge = XTableManager.ReadByIntKey(TABLE_SIGN_RECHARGE, XTable.XTableSignFirstRecharge, "Id")
    SignWelfareDir = XTableManager.ReadByIntKey(TABLE_SIGN_WELFARE, XTable.XTableWelfare, "Id")
    local signInReward = XTableManager.ReadByIntKey(TABLE_SIGN_IN_REWARD, XTable.XTableSignInReward, "Id")
    SignInNewYearConfig = XTableManager.ReadByIntKey(TABLE_SIGN_NEWYEAR_SIGN_IN, XTable.XTableDailyLottery, "Id")
    SignInDailyLotteryRewardConfig = XTableManager.ReadByIntKey(TABLE_SIGN_DAILYLOTTERY_REWARD, XTable.XTableDailyLotteryReward, "Id")
    SignDrawNewYearConfig = XTableManager.ReadByIntKey(TABLE_SIGN_DRAW_NEWYEAR, XTable.XTableSignDrawNewYear, "Id")
    SignFireworksConfig = XTableManager.ReadByIntKey(TABLE_SIGN_FIREWORKS, XTable.XTableSignFireworks, "Id");
    local signInRewardSort = {}
    -- 按SignId 建表
    for _, v in pairs(signInReward) do
        if not signInRewardSort[v.SignId] then
            signInRewardSort[v.SignId] = {}
        end

        table.insert(signInRewardSort[v.SignId], v)
    end

    -- 按Pre排序
    for _, v in pairs(signInRewardSort) do
        table.sort(v, function(a, b)
            return a.Pre < b.Pre
        end)
    end

    for _, v in pairs(signInRewardSort) do
        for _, v2 in ipairs(v) do
            if not SignInRewardConfig[v2.SignId] then
                SignInRewardConfig[v2.SignId] = {}
            end

            if not SignInRewardConfig[v2.SignId][v2.Round] then
                SignInRewardConfig[v2.SignId][v2.Round] = {}
            end

            table.insert(SignInRewardConfig[v2.SignId][v2.Round], v2)
        end
    end

    -- 福利表
    for _, v in pairs(SignWelfareDir) do
        table.insert(SignWelfareList, v)
    end

    table.sort(SignWelfareList, function(a, b)
        return a.Sort < b.Sort
    end)
end

-- 获取福利配置表
function XSignInConfigs.GetWelfareConfigs()
    local setConfig = function(id, name, path, functionType, welfareId)
        local config = {}
        config.Id = id
        config.Name = name
        config.PrefabPath = path
        config.FunctionType = functionType
        config.WelfareId = welfareId
        return config
    end

    local welfareConfigs = {}
    for _, v in pairs(SignWelfareList) do
        if v.FunctionType == XAutoWindowConfigs.AutoFunctionType.Sign then
            if XDataCenter.SignInManager.IsShowSignIn(v.SubConfigId, true) and
            not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.SignIn) then
                local cfg = XSignInConfigs.GetSignInConfig(v.SubConfigId)
                table.insert(welfareConfigs, setConfig(cfg.Id, cfg.Name, cfg.PrefabPath, v.FunctionType, v.Id))
            end
        elseif v.FunctionType == XAutoWindowConfigs.AutoFunctionType.FirstRecharge then
            if not XDataCenter.PayManager.GetFirstRechargeReward() then
                local cfg = XSignInConfigs.GetFirstRechargeConfig(v.SubConfigId)
                table.insert(welfareConfigs, setConfig(cfg.Id, cfg.Name, cfg.PrefabPath, v.FunctionType, v.Id))
            end
        elseif v.FunctionType == XAutoWindowConfigs.AutoFunctionType.Card then
            -- local cfg = XSignInConfigs.GetSignCardConfig(v.SubConfigId)
            -- table.insert(welfareConfigs, setConfig(cfg.Id, cfg.Name, cfg.PrefabPath, v.FunctionType, v.Id))
            local t = XSignInConfigs.GetSignCardConfig(v.SubConfigId);
            local param = t.Param;
            --如果已购买当前月卡或者没有购买当前月卡和互斥的月卡就显示当前的月卡
            if XDataCenter.PurchaseManager.IsYkBuyed(param[1], param[2]) or (not XDataCenter.PurchaseManager.IsYkBuyed(param[1], param[2])
                and not XDataCenter.PurchaseManager.CheckMutexPurchaseYKBuy(param[1], param[2])) then
                table.insert(welfareConfigs, setConfig(t.Id, t.Name, t.PrefabPath, v.FunctionType, v.Id))
            end
        elseif v.FunctionType == XAutoWindowConfigs.AutoFunctionType.NewYearZhanBu then
            if XSignInConfigs.IsShowDivining(v.SubConfigId) then
                local t = XSignInConfigs.GetNewYearSignInConfig(v.SubConfigId)
                if XPlayer.Level and XPlayer.Level >= t.OpenLevel then
                    table.insert(welfareConfigs, setConfig(t.Id, t.Name, t.PrefabPath, v.FunctionType, v.Id))
                end
            end
        elseif v.FunctionType == XAutoWindowConfigs.AutoFunctionType.NewYearDrawActivity then
            if XSignInConfigs.IsShowDrawNewYear(v.SubConfigId) then
                local t = XSignInConfigs.GetSignDrawNewYearConfig(v.SubConfigId)
                if XPlayer.Level and XPlayer.Level >= t.OpenLevel then
                    table.insert(welfareConfigs, setConfig(t.Id, t.Name, t.PrefabPath, v.FunctionType, v.Id))
                end
            end
        elseif v.FunctionType == XAutoWindowConfigs.AutoFunctionType.Fireworks then
            if XDataCenter.FireworksManager.IsActivityOpen() then
                local t = SignFireworksConfig[1];
                if t ~= nil then
                    table.insert(welfareConfigs, setConfig(t.Id, t.Name, t.PrefabPath, v.FunctionType, v.Id));
                end
            end
        end
    end

    return welfareConfigs
end

-- 获取福利配置表
function XSignInConfigs.GetWelfareConfig(id)
    local cfg = SignWelfareDir[id]
    if not cfg then
        XLog.ErrorTableDataNotFound("XSignInConfigs.GetWelfareConfig", "Welfare", TABLE_SIGN_WELFARE, "Id", tostring(id))
        return nil
    end

    return cfg
end

-- 通过福利表Id获取PrefabPath
function XSignInConfigs.GetPrefabPath(id)
    local config = XSignInConfigs.GetWelfareConfig(id)

    if config.FunctionType == XAutoWindowConfigs.AutoFunctionType.Sign then
        local cfg = XSignInConfigs.GetSignInConfig(config.SubConfigId)
        return cfg.PrefabPath
    elseif config.FunctionType == XAutoWindowConfigs.AutoFunctionType.FirstRecharge then
        local cfg = XSignInConfigs.GetFirstRechargeConfig(config.SubConfigId)
        return cfg.PrefabPath
    elseif config.FunctionType == XAutoWindowConfigs.AutoFunctionType.Card then
        local cfg = XSignInConfigs.GetSignCardConfig(config.SubConfigId)
        return cfg.PrefabPath
    elseif config.FunctionType == XAutoWindowConfigs.AutoFunctionType.NewYearZhanBu then
        local t = XSignInConfigs.GetNewYearSignInConfig(config.SubConfigId)
        return t.PrefabPath
    elseif config.FunctionType == XAutoWindowConfigs.AutoFunctionType.NewYearDrawActivity then
        local t = XSignInConfigs.GetSignDrawNewYearConfig(config.SubConfigId)
        return t.PrefabPath
    elseif config.FunctionType == XAutoWindowConfigs.AutoFuncitonType.Fireworks then
        local t = SignFireworksConfig[1];
        return t.PrefabPath;
    end

    return nil
end

-- 获取签到配置表
function XSignInConfigs.GetSignInConfig(signInId)
    local cfg = SignInConfig[signInId]
    if not cfg then
        XLog.ErrorTableDataNotFound("XSignInConfigs.GetSignInConfig", "SignIn", TABLE_SIGN_IN, "Id", tostring(signInId))
        return nil
    end

    return cfg
end

--获取元旦占卜配置表
function XSignInConfigs.GetNewYearSignInConfig(signInId)
    return SignInNewYearConfig[signInId]
end

--获取元旦抽奖配置表
function XSignInConfigs.GetSignDrawNewYearConfig(id)
    return SignDrawNewYearConfig[id]
end

function XSignInConfigs.GetDiviningSignRewardConfig(id)
    return SignInDailyLotteryRewardConfig[id]
end

-- 获取子轮次配置表
function XSignInConfigs.GetSubRoundConfig(subRoundId)
    local cfg = SignInSubRound[subRoundId]
    if not cfg then
        XLog.ErrorTableDataNotFound("XSignInConfigs.GetSubRoundConfig", "SubRound", TABLE_SIGN_IN_SUBROUND, "Id", tostring(subRoundId))
        return nil
    end

    return cfg
end

-- 获取月卡签到配置表
function XSignInConfigs.GetSignCardConfig(id)
    local cfg = SignCard[id]
    if not cfg then
        XLog.ErrorTableDataNotFound("XSignInConfigs.GetSignCardConfig", "SignCard", TABLE_SIGN_CARD, "Id", tostring(id))
        return nil
    end

    return cfg
end

-- 获取首充签到配置表
function XSignInConfigs.GetFirstRechargeConfig(id)
    local cfg = SignRecharge[id]
    if not cfg then
        XLog.ErrorTableDataNotFound("XSignInConfigs.GetFirstRechargeConfig", "SignFirstRecharge", TABLE_SIGN_RECHARGE, "Id", tostring(id))
        return nil
    end

    return cfg
end

-- 获取月卡签到配置表
function XSignInConfigs.GetSignCardConfigs(id)
    return SignCard;
end

-- 获取当签到结束是否继续显示签到
function XSignInConfigs.GetSignInShowWhenDayOver(signInId)
    local cfg = XSignInConfigs.GetSignInConfig(signInId)
    return cfg.IsShowWhenDayOver
end

---
--- 获取签到轮次数据List
--- 日常签到轮次：轮次数由SubRound.tab的数组决定，不同轮次属于同一个SubRound数据行，数组第N个信息就是第N个轮次
---
--- 其余签到轮次：轮次数由SignIn.tab的数组决定，数组第N个信息就是第N个轮次，
--- 不同轮次有不同的SubRound数据行，只取数组的第一个信息
function XSignInConfigs.GetSignInInfos(signInId)
    local cfg = XSignInConfigs.GetSignInConfig(signInId)
    local signInfos = {}

    if cfg.Type == XSignInConfigs.SignType.Activity
            or cfg.Type == XSignInConfigs.SignType.PurchasePackage then
        -- 读取SignIn.tab配置的 全部 SubRoundId在SubRound.tab中的数据
        for i = 1, #cfg.SubRoundId do
            local subRoundCfg = XSignInConfigs.GetSubRoundConfig(cfg.SubRoundId[i])
            local signInfo = {}

            -- 只读取SubRoundId配置的第一个信息
            signInfo.RoundName = subRoundCfg.SubRoundName[1] or ""
            signInfo.Round = i
            signInfo.Day = subRoundCfg.SubRoundDays[1] or 0
            signInfo.Icon = subRoundCfg.SubRoundIcon[1] or 0
            signInfo.Description = subRoundCfg.SubRoundDesc or ""
            table.insert(signInfos, signInfo)
        end
    else
        -- 只读取SignIn.tab配置的 第round个 SubRoundId在SubRound.tab中的数据（日常签到的round一直为1）
        local round = XDataCenter.SignInManager.GetSignRound(signInId)
        local subRoundCfg = XSignInConfigs.GetSubRoundConfig(cfg.SubRoundId[round])

        -- 读取SubRoundId配置的全部轮次奖池信息
        for i = 1, #subRoundCfg.SubRoundDays do
            local signInfo = {}
            signInfo.RoundName = subRoundCfg.SubRoundName[i] or ""
            signInfo.Round = i
            signInfo.Day = subRoundCfg.SubRoundDays[i] or 0
            signInfo.Icon = subRoundCfg.SubRoundIcon[i] or 0
            signInfo.Description = subRoundCfg.SubRoundDesc or ""
            table.insert(signInfos, signInfo)
        end
    end

    return signInfos
end

local GetDailyRewardConfigs = function(data, sunRoundId, subRound)
    local subRoundCfg = XSignInConfigs.GetSubRoundConfig(sunRoundId)
    local dailyData = {}
    local startIndex = 1
    local endIndex = 1

    for i = 1, #subRoundCfg.SubRoundDays do
        if subRound == i then
            endIndex = endIndex + subRoundCfg.SubRoundDays[i] - 1
            break
        else
            startIndex = startIndex + subRoundCfg.SubRoundDays[i]
            endIndex = startIndex
        end
    end

    for i = startIndex, endIndex do
        table.insert(dailyData, data[i])
    end

    return dailyData
end

-- 获得每轮奖励配置表List
function XSignInConfigs.GetSignInRewardConfigs(signInId, round)
    local signInInfo = SignInRewardConfig[signInId]
    local config = XSignInConfigs.GetSignInConfig(signInId)

    if not signInInfo then
        XLog.ErrorTableDataNotFound("XSignInConfigs.GetSignInRewardConfigs", "SignInReward", TABLE_SIGN_IN_REWARD, "SignId", tostring(signInId))
        return nil
    end

    if config.Type == XSignInConfigs.SignType.Daily then
        local curRound = XDataCenter.SignInManager.GetSignRound(signInId)
        local sunRoundId = config.SubRoundId[curRound]

        local cfg = signInInfo[curRound]
        local dailyData = GetDailyRewardConfigs(cfg, sunRoundId, round)
        return dailyData
    else
        local cfg = signInInfo[round]
        if not cfg then
            XLog.Error(string.format("%s出错:找不到%s数据。搜索路径: %s 索引SignId = %s, Round = %s", "XSignInConfigs.GetSignInRewardConfigs", "SignInReward", TABLE_SIGN_IN_REWARD, tostring(signInId), tostring(round)))
            return nil
        end
        return cfg
    end
end

-- 获取签到与当天差距天数
function XSignInConfigs.GetDayOffsize(signInId, curRound, curDay, targetRound, targetDay)
    local offsizeDay = 0
    local signInInfo = SignInRewardConfig[signInId]
    if not signInInfo then
        XLog.ErrorTableDataNotFound("XSignInConfigs.GetDayOffsize", "SignInReward", TABLE_SIGN_IN_REWARD, "SignId", tostring(signInId))
        return offsizeDay
    end
    local config = XSignInConfigs.GetSignInConfig(signInId)
    if config.Type == XSignInConfigs.SignType.Daily then
        offsizeDay = offsizeDay + targetDay - curDay + 1
    else
        for i = curRound, targetRound do
            local roundDays = #signInInfo[i]
            if i == curRound and i == targetRound then
                offsizeDay = offsizeDay + targetDay - curDay + 1
            elseif i == curRound then
                offsizeDay = offsizeDay + roundDays - curDay + 1
            elseif i == targetRound then
                offsizeDay = offsizeDay + targetDay
            else
                offsizeDay = offsizeDay + roundDays
            end
        end
    end

    return offsizeDay
end

---
--- 判断签到是处于开放时间
function XSignInConfigs.IsShowSignIn(signInId)
    local cfg = XSignInConfigs.GetSignInConfig(signInId)

    if cfg.Type == XSignInConfigs.SignType.PurchasePackage then
        -- 礼包签到不受TimeId控制
        return true
    end

    local timeId = cfg.TimeId
    if not XTool.IsNumberValid(timeId) then
        return false
    end

    local startTime, closeTime = XFunctionManager.GetTimeByTimeId(timeId)
    if not startTime or not closeTime then
        return false
    end

    local now = XTime.GetServerNowTimestamp()
    if now <= startTime or now > closeTime then
        return false
    end

    return true
end

-- 判断占卜是否显示
function XSignInConfigs.IsShowDivining(signInId)
    local isShowSignIn = false
    local t = XSignInConfigs.GetNewYearSignInConfig(signInId)
    if not t then
        return false
    end
    local _, startTime = CS.XDateUtil.TryParseToTimestamp(t.StartTimeStr)
    local _, closeTime = CS.XDateUtil.TryParseToTimestamp(t.CloseTimeStr)
    local now = XTime.GetServerNowTimestamp()
    if now <= startTime or now > closeTime then
        return false
    end

    return true
end

--判断元旦抽奖是否显示
function XSignInConfigs.IsShowDrawNewYear(id)
    local isShowSignIn = false
    local t = XSignInConfigs.GetSignDrawNewYearConfig(id)
    local _, startTime = CS.XDateUtil.TryParseToTimestamp(t.StartTimeStr)
    local _, closeTime = CS.XDateUtil.TryParseToTimestamp(t.CloseTimeStr)
    local now = XTime.GetServerNowTimestamp()

    if now <= startTime or now > closeTime then
        return false
    end

    return true
end

-- 判断最后一轮最后一天获得后是否继续再福利界面显示
function XSignInConfigs.JudgeLastDayGet(signInId, signData)
    local config = XSignInConfigs.GetSignInConfig(signInId)
    if config.Type == XSignInConfigs.SignType.Daily then
        return true
    end

    -- 判断是不是最后一轮
    local cfg = XSignInConfigs.GetSignInConfig(signInId)
    if #cfg.RoundDays > signData.Round then
        return true
    end

    -- 判断是不是最后一天
    if cfg.RoundDays[#cfg.RoundDays] > signData.Day then
        return true
    end

    -- 最后一天是否签到
    if not signData.Got then
        return true
    end

    -- 配置表是否继续显示
    return config.IsShowWhenSignOver
end

-- 判断是否当前轮的最后一天
function XSignInConfigs.JudgeLastRoundDay(signInId, round, day)
    local cfg = XSignInConfigs.GetSignInConfig(signInId)
    if not cfg then
        return false
    end

    if cfg.Type == XSignInConfigs.SignType.Daily then
        local subRoundCfg = XSignInConfigs.GetSubRoundConfig(cfg.SubRoundId[round])
        local subDay = 0
        local isLastDay = false
        local subRound = 1
        for i = 1, #subRoundCfg.SubRoundDays do
            subDay = subDay + subRoundCfg.SubRoundDays[i]
            if day <= subDay then
                subRound = i

                if day == subDay then
                    isLastDay = true
                end

                break
            end
        end

        return isLastDay, subRound
    else
        local allDay = cfg.RoundDays[round]
        return day >= allDay, round
    end
end

---
--- 获取签到类型
function XSignInConfigs.GetSignInType(signInId)
    local cfg = XSignInConfigs.GetSignInConfig(signInId)
    return cfg.Type
end

---
--- 获取签到预制体路径
function XSignInConfigs.GetSignPrefabPath(signInId)
    local cfg = XSignInConfigs.GetSignInConfig(signInId)
    return cfg.PrefabPath
end

---
--- 获取签到的开放时间
function XSignInConfigs.GetSignTimeId(signInId)
    local cfg = XSignInConfigs.GetSignInConfig(signInId)
    return cfg.TimeId
end