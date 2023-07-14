local Json = require("XCommon/Json")
XAppEventManager = XAppEventManager or {}

XAppEventManager.CommonEventNameConfig = {
    ["Game_Privacy"] = "Game_Privacy",
    ["Change_account"] = "Change_account",
    ["SDK_Initialize"] = "SDK_Initialize",
    ["SDK_Login"] = "SDK_Login",
    ["Completed_Registration"] = "Completed_Registration",
    ["Anime_Start"] = "Anime_Start",
    ["First_Battle_Finish"] = "First_Battle_Finish",
    ["Second_Battle_End"] = "Second_Battle_End",
    ["Third_Battle_End"] = "Third_Battle_End",
    ["Newbee_Mission_End"] = "Newbee_Mission_End",
    ["Purchased"] = "Purchased",
    ["First_buy"] = "First_buy",
    ["draws_role_10"]="10draws_role",
    ["draws_weapon_10"] = "10draws_weapon",
    ["draws_limit_10"] = "10draws_limit",
    ["Daily_Task"] = "Daily_Task",
    ["Monthly_Card"] = "Monthly_Card"
}

local AccumulateEventConfig = {
    [1] = "Total_Purchase_1",
    [2] = "Total_Purchase_2",
    [3] = "Total_Purchase_3",
    [4] = "Total_Purchase_4",
    [5] = "Total_Purchase_5",
    [6] = "Total_Purchase_6",
    [7] = "Total_Purchase_7",
    [8] = "Total_Purchase_8",
    [9] = "Total_Purchase_9",
    [10] = "Total_Purchase_10",
}

local PurchaseConfig = {
    [1001] = "Redeemed_0.99",
    [1002] = "Redeemed_4.99",
    [1003] = "Redeemed_5.99",
    [1004] = "Redeemed_9.99",
    [1005] = "Redeemed_11.99",
    [1006] = "Redeemed_19.99",
    [1007] = "Redeemed_49.99",
    [1008] = "Redeemed_99.99",
}

local HKPurchaseConfig = {
    [83028] = "Monthly_Card1",
    [83029] = "Monthly_Card2",
}

local TaskStoryHKEventConfig = {
    [100] = "Newbee_Mission_End",
    [320] = "Complete_C1",
    [321] = "Complete_C2",
    [322] = "Complete_C3",
    [323] = "Complete_C4",
    [324] = "Complete_C5",
    [325] = "Complete_C6",
    [326] = "Complete_C7",
    [327] = "Complete_C8",
    [3130] = "SS_1",
    [3131] = "SS_3",
    [3134] = "SS_9",
    [3140] = "SSS_1",
    [3141] = "SSS_3",
    [3144] = "SSS_9",
    [3150] = "TotalSkin_2",
    [3151] = "TotalSkin_5",
    [3152] = "TotalSkin_10"

}

local LevelEventConfig = {
    [10] = "Level_10",
    [15] = "Level_15",
    [20] = "Level_20",
    [25] = "Level_25",
    [30] = "Level_30",
    [35] = "Level_35",
    [40] = "Level_40",
    [45] = "Level_45",
    [50] = "Level_50",
    [60] = "Level_60",
    [70] = "Level_70",
    [80] = "Level_80",
}

local WeeklyRewardConfig = {
    [30003] = "PainGage_3",
    [30006] = "PainGage_6",
    [30015] = "War_3",
    [30018] = "War_6"
}

local MedalConfig = {
    [1] = "Badge_Ace",
    [2] = "Badge_Pioneer",
    [3] = "Badge_Million",
    [4] = "Badge_Beacon",
    [5] = "Badge_Leader"
}

--通用打点
function XAppEventManager.AppLogEvent(eventName)
    CS.XAppEventManager.LogAppEvent(eventName)
end

function XAppEventManager.AppLogEventWithParameter(eventName, eventValue)
    CS.XAppEventManager.LogAppEventWithParameter(eventName, eventValue)
end

-- 领取累计充值打点
function XAppEventManager.AccumulatePayAppLogEvent(id)
    if not id or not AccumulateEventConfig[id] then
        return
    end
    XAppEventManager.AppLogEvent(AccumulateEventConfig[id])
end

-- 购买黑卡打点
function XAppEventManager.PurchasePayAppLogEvent(id)
    if not id or not PurchaseConfig[id] then
        return
    end
    XAppEventManager.AppLogEvent(PurchaseConfig[id])
end

-- 虹卡购买打点
function XAppEventManager.HKPurchasePayAppLogEvent(id)
    if not id or not HKPurchaseConfig[id] then
        return
    end
    XAppEventManager.AppLogEvent(HKPurchaseConfig[id])
end

-- 充值
function XAppEventManager.PayAppLogEvent(amount)
    local orderStr = Json.encode({["af_revenue"] = amount, ["af_currency"] = "USD"})
    XAppEventManager.AppLogEventWithParameter(XAppEventManager.CommonEventNameConfig.Purchased, orderStr)
end

--任务
function XAppEventManager.TaskAppLogEvent(taskId, status)
    if TaskStoryHKEventConfig[taskId] and (status == XDataCenter.TaskManager.TaskState.Achieved) then
        XAppEventManager.AppLogEvent(TaskStoryHKEventConfig[taskId])
    end
end

--等级
function XAppEventManager.LevelAppLogEvent(level)
    if LevelEventConfig[level] then
        XAppEventManager.AppLogEvent(LevelEventConfig[level])
    end
end

--周任务领奖
function XAppEventManager.WeeklyRewardAppLogEvent(taskId)
    if WeeklyRewardConfig[taskId] ~= nil then
        XAppEventManager.AppLogEvent(WeeklyRewardConfig[taskId])
    end
end

--勋章
function XAppEventManager.MedalAppLogEvent(medalId)
    if MedalConfig[medalId] ~= nil then
        XAppEventManager.AppLogEvent(MedalConfig[medalId])
    end
end