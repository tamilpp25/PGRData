--- 背包玩法自己的枚举定义
local XBagOrganizeActivityEnumConst = {
    --- 货物格子类型(占位范围 0-99）
    GoodsBlockType = {
        Empty = 0, -- 空格子
        Normal = 1, -- 普通的占用格
    },
    --- 结算协议类型
    SettleType = {
        Normal = 1, -- 正常通关结算
        Reset = 2, -- 重置请求
        GiveUp = 3, -- 放弃请求
        NormalForce = 4, -- 提前通关结算（该字段仅用于埋点区分）
    },
    --- 实体类型，用于判断当前编辑的物体（占位范围 100-199）
    EntityType = {
        Placeable = 100,
        Goods = 101,
    },
    BuffType = {
        SameColorCombo = 1001, -- 同色加成
        RandomEvent = 1002, -- 随机事件加成
        TotalScorePart = 1003, -- 总分的一部分
    },
    GoodsRuleType = {
        Constant = 1, -- 固定生成
        Random = 2, -- 随机生成
    },
    EventResultType = {
        Compose = 0, -- 事件结果组合
        GoodsBuffWithId = 1, -- 指定Id道具加成
        GoodsBuffWithColor = 2, -- 指定颜色道具加成
        BagFreeWithId = 3, -- 指定Id背包无费用
        GoodsCreateByConstant = 4, -- 后续道具刷新固定组
    }
}


return XBagOrganizeActivityEnumConst