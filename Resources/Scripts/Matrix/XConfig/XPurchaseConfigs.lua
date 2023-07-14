XPurchaseConfigs = XPurchaseConfigs or {}
-- local TABLE_PURCHASE_GIFT = "Share/Purchase/PurchasePackage.tab"
-- local TABLE_PURCHASE_ITEM = "Share/Purchase/PurchaseItem.tab"
-- local TABLE_PAY = "Share/Pay/Pay.tab"
local TABLE_PURCHASE_ICON_ASSETPATH = "Client/Purchase/PurchaseIconAssetPath.tab"
local TABLE_PURCHASE_TAB_CONTROL = "Client/Purchase/PurchaseTabControl.tab"
local TABLE_PURCHASE_UITYPE = "Client/Purchase/PurchaseUiType.tab"
local TABLE_PURCHASE_TAGTYPE = "Client/Purchase/PurchaseTagType.tab"
local TABLE_ACCUMULATED_PAY = "Share/Pay/AccumulatedPay.tab"
local TABLE_ACCUMULATED_PAY_REWARD = "Share/Pay/AccumulatedPayReward.tab"
local TABLE_LB_BY_PASS = "Client/Purchase/PurchaseLBByPass.tab"
local TABLE_PURCHASE_YK_ICON = "Client/Purchase/PurchaseYKIcon.tab"

-- local PayConfig = {}
local PurchaseIconAssetPathConfig = {}
local PurchaseTabControlConfig = {}
local PurchaseUiTypeConfig = {}
local PurchaseTagTypeConfig = {}
local PurchaseYkIconConfig = {}

local AccumulatedPayConfig = {}
local AccumulatedPayRewardConfig = {}
local PurchaseLBByPassConfig = {}

local PurchaseUiTypeGroupConfig = nil

local PurchaseTabGroupConfig = nil
local PurchaseTabByUiTypeConfig = nil
local PurchasePayUiTypeConfig = nil
local PurchaseLBUiTypeListConfig = nil
local PurchaseLBUiTypeDic = nil
local PurchaseYKUiTypeConfig = nil
local PurchaseHKUiTypeConfig = nil
local PurchaseLBByPassIDDic = nil
local PurchaseYKUiTypeDic = nil

local PurchaseLBUiTypeDic = nil
local PurchaseYKUiTypeDic = nil

XPurchaseConfigs.PurchaseDataConfig = {
    Pay = 1, --充值
    LB = 2, --礼包
    YK = 3, --月卡
    HKDH = 4, --黑卡兑换
    HKShop = 5, --黑卡商店
}

XPurchaseConfigs.TabsConfig = {
    Pay = 1, --充值
    LB = 2, --礼包
    YK = 3, --月卡
    HK = 4--黑卡
}

XPurchaseConfigs.ConsumeTypeConfig = {
    RMB = 1, --人名币
    ITEM = 2, --道具
    FREE = 3, --免费
}

XPurchaseConfigs.RestTypeConfig = {
    Day = 0, --每日
    Week = 1, --每周
    Month = 2, --每月
    Interval = 3, --间隔
    RemainDay = 4,
}

XPurchaseConfigs.LBGetTypeConfig = {
    Direct = 1, --直接
    Day = 2, --每日
}

XPurchaseConfigs.PanelNameConfig = {
    PanelRecharge = "PanelRecharge",
    PanelLb = "PanelLb",
    --PanelYk = "PanelYk",
    PanelHksd = "PanelHksd",
    PanelDh = "PanelDh"
}

XPurchaseConfigs.PanelExNameConfig = {
    PanelRecharge = "PanelRechargeEx",
    PanelLb = "PanelLbEx",
    PanelYk = "PanelYkEx",
    PanelHksd = "PanelHksdEx",
    PanelDh = "PanelDhEx",
    PanelCoatingLb = "PanelCoatingLbEx"
}

XPurchaseConfigs.TabExConfig = {
    Sample = 1, --没有页签
    EXTable = 2, --左边有页签
}

XPurchaseConfigs.PurchaseRewardAddState = {
    CanGet = 1, --能领，没有领。
    Geted = 2, --已经领
    CanotGet = 3, --不能领，钱不够。
}

XPurchaseConfigs.PurchaseTagType = {
    Normal = 0, -- 默认
    Discount = 1 -- 打折
}

XPurchaseConfigs.PayAddType = {
    Activity = 1, -- 活动累充类型
    Forever = 2, -- 永久累充类型
}

-- 累积充值显示状态
XPurchaseConfigs.LjczLookState = {
    Hide = 1,
    Show = 2,
}

XPurchaseConfigs.YKType =
{
    Day = 14,   --日卡
    Week = 13,  --周卡
    Month = 2,  --月卡
}

XPurchaseConfigs.LjczLookStateKey = "LJCZ_LOOK_STATE_KEY"
XPurchaseConfigs.PurchaseLJCZDefaultLookStateKey = "PurchaseLJCZDefaultLookState"

function XPurchaseConfigs.Init()
    XPurchaseConfigs.PurChaseGiftTips = CS.XGame.ClientConfig:GetInt("PurChaseGiftTips") or 1
    XPurchaseConfigs.PurChaseCardUiType = CS.XGame.ClientConfig:GetInt("PurchaseCardUiType") or 0
    XPurchaseConfigs.PurChaseCardId = CS.XGame.ClientConfig:GetInt("PurchaseCardId")
    XPurchaseConfigs.PurChaseCardId1 = CS.XGame.ClientConfig:GetInt("PurchaseCardId1") or 0
    XPurchaseConfigs.PurYKContinueBuyDays = CS.XGame.ClientConfig:GetInt("PurYKContinueBuyDays") or 0

    
    if XPurchaseConfigs.PurChaseCardUiType == 0 then
        XLog.Error("配置错误请检查ClinetConfig表PurchaseCardUiType是否存在")
    end

    if XPurchaseConfigs.PurChaseCardId == 0 then
        XLog.Error("配置错误请检查ClinetConfig表PurchaseCardId是否存在")
    end

    if XPurchaseConfigs.PurChaseCardId1 == 0 then
        XLog.Error("配置错误请检查ClinetConfig表PurchaseCardId1是否存在")
    end

    -- PayConfig = XTableManager.ReadByStringKey(TABLE_PAY, XTable.XTablePay, "Key")
    PurchaseIconAssetPathConfig = XTableManager.ReadByStringKey(TABLE_PURCHASE_ICON_ASSETPATH, XTable.XTablePurchaseIconAssetPath, "Icon")
    PurchaseTabControlConfig = XTableManager.ReadByStringKey(TABLE_PURCHASE_TAB_CONTROL, XTable.XTablePurchaseTabControl, "Id")
    PurchaseUiTypeConfig = XTableManager.ReadByIntKey(TABLE_PURCHASE_UITYPE, XTable.XTablePurchaseUiType, "UiType")
    PurchaseTagTypeConfig = XTableManager.ReadByIntKey(TABLE_PURCHASE_TAGTYPE, XTable.XTablePurchaseTagType, "Tag")
    AccumulatedPayConfig = XTableManager.ReadByIntKey(TABLE_ACCUMULATED_PAY, XTable.XTableAccumulatedPay, "Id")
    AccumulatedPayRewardConfig = XTableManager.ReadByIntKey(TABLE_ACCUMULATED_PAY_REWARD, XTable.XTableAccumulatedPayReward, "Id")
    -- PurchaseLBByPassConfig = XTableManager.ReadByIntKey(TABLE_LB_BY_PASS, XTable.XTablePurchaseLBByPass, "Id")
    PurchaseYkIconConfig = XTableManager.ReadByIntKey(TABLE_PURCHASE_YK_ICON, XTable.XTablePurchaseYKIcon, "Id")
end

function XPurchaseConfigs.GetIconPathByIconName(iconName)
    return PurchaseIconAssetPathConfig[iconName]
end

function XPurchaseConfigs.GetPurchaseLBByPassIDDic()
    if PurchaseLBByPassIDDic then
        return PurchaseLBByPassIDDic
    end

    PurchaseLBByPassIDDic = {}
    PurchaseLBByPassConfig = XTableManager.ReadByIntKey(TABLE_LB_BY_PASS, XTable.XTablePurchaseLBByPass, "Id") or {}
    for _, v in pairs(PurchaseLBByPassConfig) do
        if v then
            PurchaseLBByPassIDDic[v.LBId] = v.LBId
        end
    end
    return PurchaseLBByPassIDDic
end

function XPurchaseConfigs.IsLBByPassID(id)
    if not id then
        return false
    end

    local config = XPurchaseConfigs.GetPurchaseLBByPassIDDic()
    if config then
        return config[id] ~= nil
    end

    return false
end

function XPurchaseConfigs.GetGroupConfigType()
    if not PurchaseTabGroupConfig then
        PurchaseTabGroupConfig = {}
        for _, v in pairs(PurchaseTabControlConfig) do
            if v.IsOpen == 1 then
                if not PurchaseTabGroupConfig[v.GroupId] then
                    local d = {}
                    d.GroupOrder = v.GroupOrder
                    d.GroupName = v.GroupName
                    d.GroupId = v.GroupId
                    d.GroupIcon = v.GroupIcon
                    d.Childs = {}
                    PurchaseTabGroupConfig[v.GroupId] = d
                else
                    local groupOrder = PurchaseTabGroupConfig[v.GroupId].GroupOrder
                    if groupOrder > v.GroupOrder then
                        PurchaseTabGroupConfig[v.GroupId].GroupOrder = v.GroupOrder
                    end
                end
                table.insert(PurchaseTabGroupConfig[v.GroupId].Childs, v)
            end
            table.sort(PurchaseTabGroupConfig[v.GroupId].Childs, function(a, b)
                return a.GroupOrder < b.GroupOrder
            end)
        end
        table.sort(PurchaseTabGroupConfig, function(a, b)
            return a.GroupOrder < b.GroupOrder
        end)
    end
    return PurchaseTabGroupConfig
end

function XPurchaseConfigs.GetUiTypeGroupConfig()
    if not PurchaseUiTypeGroupConfig then
        PurchaseUiTypeGroupConfig = {}
        XPurchaseConfigs.GetGroupConfigType()
        for _, v in pairs(PurchaseUiTypeConfig) do
            if not PurchaseUiTypeGroupConfig[v.GroupType] then
                PurchaseUiTypeGroupConfig[v.GroupType] = {}
            end

            table.insert(PurchaseUiTypeGroupConfig[v.GroupType], v)
        end
    end
end

-- 参数XPurchaseConfigs.TabsConfig,所有的uiType
function XPurchaseConfigs.GetUiTypesByTab(t)
    XPurchaseConfigs.GetUiTypeGroupConfig()
    return PurchaseUiTypeGroupConfig[t]
end

-- 充值的uiType
function XPurchaseConfigs.GetPayUiTypes()
    if not PurchasePayUiTypeConfig then
        PurchasePayUiTypeConfig = {}
        local cfg = XPurchaseConfigs.GetUiTypesByTab(XPurchaseConfigs.TabsConfig.Pay)
        for _, v in pairs(cfg) do
            PurchasePayUiTypeConfig[v.UiType] = v.UiType
        end
    end

    return PurchasePayUiTypeConfig
end

-- 礼包的uiType的list
function XPurchaseConfigs.GetLBUiTypesList()
    if not PurchaseLBUiTypeListConfig then
        PurchaseLBUiTypeListConfig = {}
        local cfg = XPurchaseConfigs.GetUiTypesByTab(XPurchaseConfigs.TabsConfig.LB)
        for _, v in pairs(cfg) do
            table.insert(PurchaseLBUiTypeListConfig, v.UiType)
        end
    end

    return PurchaseLBUiTypeListConfig
end

-- 礼包的uiType的Dic
function XPurchaseConfigs.GetLBUiTypesDic()
    if not PurchaseLBUiTypeDic then
        PurchaseLBUiTypeDic = {}
        local cfg = XPurchaseConfigs.GetUiTypesByTab(XPurchaseConfigs.TabsConfig.LB)
        for _,v in pairs(cfg) do
            PurchaseLBUiTypeDic[v.UiType] = true
        end
    end

    return PurchaseLBUiTypeDic
end

function XPurchaseConfigs.GetYKUiTypesDic()
    if not PurchaseYKUiTypeDic then
        PurchaseYKUiTypeDic = {}
        local cfg = XPurchaseConfigs.GetUiTypesByTab(XPurchaseConfigs.TabsConfig.YK)
        for _,v in pairs(cfg)do
            PurchaseYKUiTypeDic[v.UiType] = true
        end
    end

    return PurchaseYKUiTypeDic
end

-- 月卡的uiType
function XPurchaseConfigs.GetYKUiTypes()
    if not PurchaseYKUiTypeConfig then
        PurchaseYKUiTypeConfig = {}
        local cfg = XPurchaseConfigs.GetUiTypesByTab(XPurchaseConfigs.TabsConfig.YK) or {}
        for _, v in pairs(cfg) do
            table.insert(PurchaseYKUiTypeConfig, v.UiType)
        end
    end

    return PurchaseYKUiTypeConfig
end

-- 黑卡的uiType
function XPurchaseConfigs.GetHKUiTypes()
    if not PurchaseHKUiTypeConfig then
        PurchaseHKUiTypeConfig = {}
        local cfg = XPurchaseConfigs.GetUiTypesByTab(XPurchaseConfigs.TabsConfig.HK)
        for _, v in pairs(cfg) do
            table.insert(PurchaseHKUiTypeConfig, v.UiType)
        end
    end

    return PurchaseHKUiTypeConfig
end

function XPurchaseConfigs.GetTabControlUiTypeConfig()
    if not PurchaseTabByUiTypeConfig then
        PurchaseTabByUiTypeConfig = {}
        for _, v in pairs(PurchaseTabControlConfig) do
            PurchaseTabByUiTypeConfig[v.UiType] = v
        end
    end

    return PurchaseTabByUiTypeConfig
end

function XPurchaseConfigs.GetUiTypeConfigByType(uiType)
    return PurchaseUiTypeConfig[uiType]
end

function XPurchaseConfigs.GetTagDes(tag)
    if not PurchaseTagTypeConfig[tag] then
        return ""
    end
    return PurchaseTagTypeConfig[tag].Des
end

function XPurchaseConfigs.GetTagBgPath(tag)
    if not PurchaseTagTypeConfig[tag] then
        return nil
    end
    return PurchaseTagTypeConfig[tag].Style
end

function XPurchaseConfigs.GetTagEffectPath(tag)
    if not PurchaseTagTypeConfig[tag] then
        return nil
    end
    return PurchaseTagTypeConfig[tag].Effect
end

function XPurchaseConfigs.GetTagType(tag)
    if not PurchaseTagTypeConfig[tag] then
        return nil
    end
    return PurchaseTagTypeConfig[tag].Type
end

function XPurchaseConfigs.GetAccumulatePayConfigById(id)
    if not id or not AccumulatedPayConfig[id] then
        return
    end

    return AccumulatedPayConfig[id]
end

function XPurchaseConfigs.GetAccumulateRewardConfigById(id)
    if not id or not AccumulatedPayRewardConfig[id] then
        return
    end

    return AccumulatedPayRewardConfig[id]
end

function XPurchaseConfigs.GetPurchaseNameByUiType(uitype)
    local name

    for _, v in pairs(PurchaseTabControlConfig) do
        if v.UiType == uitype then
            name = v.Name
        end
    end

    return name
end

function XPurchaseConfigs.GetPurchaseYKIconById(id)
    return PurchaseYkIconConfig[id]
end