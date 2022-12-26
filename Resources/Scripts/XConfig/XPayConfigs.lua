XPayConfigs = XPayConfigs or {}

local TABLE_PAY_PATH = "Share/Pay/Pay.tab"
local TABLE_FIRST_PAY_PATH = "Share/Pay/FirstPayReward.tab"
local TABLE_PAYKEY_PLATFORMPREFIX = "Share/Pay/PayKeyPlatformPrefix.tab"
local Application = CS.UnityEngine.Application
local Platform = Application.platform
local RuntimePlatform = CS.UnityEngine.RuntimePlatform

local PayTemplates = {}
local FirstPayTemplates = {}
local PayPlatformTemplates = {}
local PayListDataConfig = nil

function XPayConfigs.Init()
    PayTemplates = XTableManager.ReadByStringKey(TABLE_PAY_PATH, XTable.XTablePay, "Key")
    FirstPayTemplates = XTableManager.ReadByIntKey(TABLE_FIRST_PAY_PATH, XTable.XTableFirstPayReward, "NeedPayMoney")
    PayPlatformTemplates = XTableManager.ReadByIntKey(TABLE_PAYKEY_PLATFORMPREFIX, XTable.XTablePayKeyPlatformPrefix, "Platform")
end

function XPayConfigs.GetPayTemplate(key)
    local template = PayTemplates[key]
    if not template then
        XLog.ErrorTableDataNotFound("XPayConfigs.GetPayTemplate", "template", TABLE_PAY_PATH, "key", tostring(key))
        return
    end

    return template
end

function XPayConfigs.GetPayConfig()
    if not PayListDataConfig then
        PayListDataConfig = {}
        for _,v in pairs(PayTemplates)do
            if v.ShowUIType == 1 then
                if v.Platform == 1 and Platform == RuntimePlatform.Android then
                    table.insert(PayListDataConfig,v)
                elseif v.Platform == 2 and  Platform == RuntimePlatform.IPhonePlayer then
                    table.insert(PayListDataConfig,v)
                else
                    if v.Platform == 1 and Platform ~= RuntimePlatform.Android and Platform ~= RuntimePlatform.IPhonePlayer then
                        table.insert(PayListDataConfig,v)
                    end
                end
            end
        end
    end
    return PayListDataConfig
end


function XPayConfigs.CheckFirstPay(totalPayMoney)
    for _, v in pairs(FirstPayTemplates) do
        return totalPayMoney >= v.NeedPayMoney
    end
end

function XPayConfigs.GetSmallRewards()
    for _, v in pairs(FirstPayTemplates) do
        return v.SmallRewardId
    end
end

function XPayConfigs.GetBigRewards()
    for _, v in pairs(FirstPayTemplates) do
        return v.BigRewardId
    end
end

--获取对应平台的字符串，用来请求的时候拼接
function XPayConfigs.GetPlatformConfig(id)
    return PayPlatformTemplates[id].KeyPrefix
end