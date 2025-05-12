
XEquipGuideConfigs = XEquipGuideConfigs or {}

--==============================
---@desc 初始化入口
--==============================
function XEquipGuideConfigs.Init()
    XEquipGuideConfigs.TargetConfig = XConfig.New("Share/Equip/EquipGuide/EquipTarget.tab", XTable.XTableEquipTarget)
    XEquipGuideConfigs.JudgeConfig  = XConfig.New("Share/Equip/EquipGuide/EquipJudge.tab", XTable.XTableEquipJudge) 
end 

--物品类型
XEquipGuideConfigs.EquipType = {
    Suit  = 1, --套装，非真实装备
    Weapon = 2, --真实装备
}

--意识套装类型
XEquipGuideConfigs.ChipSuitType = {
    SixSuits                = 1, --6件套
    FourPlusTwoSuits        = 2, --4+2件套
    TwoPlusTwoPlusTwoSuits  = 3, --2+2+2件套
}

--计分常数
XEquipGuideConfigs.ScoreConstant = {
    NoResonance = 1, --未共鸣分数
    NotCurCharacterResonance = 10, --共鸣但非当前角色
    CurCharacterResonance = 100, --共鸣且当前角色
}

--积分读取Id
XEquipGuideConfigs.JudgeConfigKey = 1

--region   ------------------运营埋点 start-------------------

---@desc 装备状态（运营记录用）
---@field None      获取状态
---@field WaitWear  待穿戴状态
---@field Culture   培养状态
---@field Complete  达成状态
XEquipGuideConfigs.EquipState = {
    None = 1,
    WaitWear = 2,
    Culture = 3,
    Complete = 4
}

---@desc 埋点事件
---@field SetTargetEvent  设定事件
---@field SkipEvent       跳转事件
---@field ProgressEvent   进度事件
XEquipGuideConfigs.BuryingPointEvent = {
    SetTargetEvent = 1,
    SkipEvent = 2,
    ProgressEvent = 3
}

---@desc 埋点--界面跳转类型
---@field Acquire 获取装备跳转
---@field Culture 培养装备跳转
XEquipGuideConfigs.SkipType = {
    Acquire = 1,
    Culture = 2,
}

---@desc 埋点--跳转界面
---@field ChipCultureScene 意识培养界面
---@field WeaponCultureScene 武器培养界面
---@field ChipAcquireScene 意识获取界面
---@field WeaponAcquireScene 武器获取界面
XEquipGuideConfigs.SkipScene = {
    ChipCultureScene = 1,
    WeaponCultureScene = 2,
    ChipAcquireScene = 3,
    WeaponAcquireScene = 4
}

---@desc 埋点--进度条变化原因
---@field Wear 装备
---@field Culture 培养
---@field TakeOff 卸下
XEquipGuideConfigs.ProgressChangeReason = {
    Wear = 1,
    Culture = 2,
    TakeOff = 3,
}

--endregion------------------运营埋点 finish------------------

local SkipCheckFunc = {
    --跳转到协同作战，只支持5星及以下的装备
    [4003] = function(skipId, templateId)
        if not XTool.IsNumberValid(templateId) then
            return false
        end
        local cfg = XMVCA.XEquip:GetConfigEquip(templateId)
        return cfg.Star < XEnumConst.EQUIP.MAX_STAR_COUNT
    end
}

function XEquipGuideConfigs.GeneratorEquipSkipData(templateId, func)
    local data = {}
    local ids = XMVCA.XEquip:GetEquipSkipIds(templateId)
    for _, id in ipairs(ids) do
        local hook = SkipCheckFunc[id]
        if not hook or (hook and hook(id, templateId)) then
            table.insert(data, { id, false, func, templateId })
        end
    end
    return data
end 

--==============================
 ---@desc 计算装备的基础计分 score = 突破次数 * 1000 + level * 10
 ---@equipId 装备Id 
 ---@return number
--==============================
function XEquipGuideConfigs.CalEquipBaseScore(equipId)
    if not XTool.IsNumberValid(equipId) then
        return 0
    end
    local config = XEquipGuideConfigs.JudgeConfig:GetConfig(XEquipGuideConfigs.JudgeConfigKey)
    local breakthroughScore, levelScore
    local equipType = XMVCA.XEquip:GetEquipClassifyByEquipId(equipId)
    if equipType == XEnumConst.EQUIP.CLASSIFY.WEAPON then
        breakthroughScore, levelScore = config.WeaponBreakThroughScore, config.WeaponUpLevelScore
    else
        breakthroughScore, levelScore = config.ChipBreakThroughScore, config.ChipUpLevelScore
    end
    local equip = XMVCA.XEquip:GetEquip(equipId)
    return equip.Breakthrough * breakthroughScore 
            + equip.Level * levelScore
end 

--==============================
 ---@desc 计算装备共鸣的分数 指定角色（3次 > 2次 > 1次） > 非当前角色 > 为共鸣
 ---@equipId 装备Id
 ---@characterId 目标角色Id
 ---@return number
--==============================
function XEquipGuideConfigs.CalEquipResonanceScore(equipId, characterId)
    if not XTool.IsNumberValid(equipId) then
        return 0
    end
    local equip = XMVCA.XEquip:GetEquip(equipId)
    local isResonance = equip and not XTool.IsTableEmpty(equip.ResonanceInfo) or
            not XTool.IsTableEmpty(equip.UnconfirmedResonanceInfo)
    if not isResonance then
        return XEquipGuideConfigs.ScoreConstant.NoResonance
    end
    local getResonanceScore = function(resonanceInfo)
        local sum = 0
        for _, info in pairs(resonanceInfo or {}) do
            if info.CharacterId == characterId then
                sum = sum + XEquipGuideConfigs.ScoreConstant.CurCharacterResonance
            else
                sum = sum + XEquipGuideConfigs.ScoreConstant.NotCurCharacterResonance
            end
        end
        return sum
    end
    local score = getResonanceScore(equip.ResonanceInfo) + getResonanceScore(equip.UnconfirmedResonanceInfo)
    return score
end 