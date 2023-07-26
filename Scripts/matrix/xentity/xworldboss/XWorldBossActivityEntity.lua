local XWorldBossActivityEntity = XClass(nil, "XWorldBossActivityEntity")
local XSpecialSaleEntity = require("XEntity/XWorldBoss/XSpecialSaleEntity")
local XBossAreaEntity = require("XEntity/XWorldBoss/XBossAreaEntity")
local XAttributeAreaEntity = require("XEntity/XWorldBoss/XAttributeAreaEntity")
local CSTextManagerGetText = CS.XTextManager.GetText
function XWorldBossActivityEntity:Ctor(id)
    self.Id = id
    self.GlobalData = {}
    self.PrivateData = {}

    self.AttributeAreaEntityDic = {}
    for _, areaId in pairs(self:GetAttributeAreaIds() or {}) do
        self.AttributeAreaEntityDic[areaId] = XAttributeAreaEntity.New(areaId)
    end

    self.BossAreaEntityDic = {}
    for _, areaId in pairs(self:GetBossAreaIds() or {}) do
        self.BossAreaEntityDic[areaId] = XBossAreaEntity.New(areaId)
    end

    self.SpecialSaleEntityDic = {}
    for _, shopId in pairs(self:GetSpecialSaleIds() or {}) do
        self.SpecialSaleEntityDic[shopId] = XSpecialSaleEntity.New(shopId)
    end

    self.BossBuffList = {}
    self.GetedBossBuffList = {}
    self.GetedRobotIdList = {}
    self.FinishStageCount = 0
end

function XWorldBossActivityEntity:UpdateData(playerData)
    for key, value in pairs(playerData) do
        self[key] = value
    end
end

function XWorldBossActivityEntity:UpdateEntityDic()--此处顺序不能改变
    self:UpdateAttributeAreaEntityDic()
    self:UpdateBossAreaEntityDic()
    self:UpdateSpecialSaleEntityDic()
end

function XWorldBossActivityEntity:UpdateAttributeAreaEntityDic()--更新属性区域实体字典
    self.BossBuffList = {}
    self.GetedBossBuffList = {}
    self.GetedRobotIdList = {}
    self.FinishStageCount = 0

    for _, attributeArea in pairs(self:GetPrivateAttributeAreaDatas()) do
        local tmpData = {}
        tmpData.ChallengeCount = attributeArea.ChallengeCount
        tmpData.AreaRewardFlag = attributeArea.RewardFlag
        tmpData.Score = attributeArea.Score
        tmpData.CharacterDatas = attributeArea.CharacterDatas
        tmpData.PrivateData = attributeArea.AttributeStageDatas
        self.AttributeAreaEntityDic[attributeArea.Id]:UpdateData(tmpData)
    end

    for _, attributeArea in pairs(self:GetGlobalAttributeAreaDatas()) do
        self.AttributeAreaEntityDic[attributeArea.Id]:UpdateData({ GlobalData = attributeArea.AttributeStageDatas })
    end

    for _, attributeAreaEntity in pairs(self.AttributeAreaEntityDic) do
        attributeAreaEntity:UpdateStageEntityDic()
        self.FinishStageCount = self.FinishStageCount + attributeAreaEntity:GetFinishStageCount()

        for _, bossBuffId in pairs(attributeAreaEntity:GetBossBuffList()) do
            table.insert(self.BossBuffList, bossBuffId)
        end

        for _, bossBuffId in pairs(attributeAreaEntity:GetGetedBossBuffList()) do
            table.insert(self.GetedBossBuffList, bossBuffId)
        end

        for _, robotId in pairs(attributeAreaEntity:GetGetedRobotList()) do
            table.insert(self.GetedRobotIdList, robotId)
        end
    end

    XDataCenter.WorldBossManager.UpdateGetedBossBuff(self.GetedBossBuffList)
    XDataCenter.WorldBossManager.UpdateGetedBossBuff(self.GetedRobotIdList)
end

function XWorldBossActivityEntity:UpdateBossAreaEntityDic()--更新boss区域实体字典
    for _, BossArea in pairs(self:GetPrivateBossAreaDatas()) do
        local tmpData = {}
        tmpData.ChallengeCount = BossArea.ChallengeCount
        tmpData.HpRecord = BossArea.HpRecord
        tmpData.GetedPhasesRewardIds = BossArea.PhasesRewardIds
        tmpData.CharacterDatas = BossArea.CharacterDatas
        self.BossAreaEntityDic[BossArea.Id]:UpdateData(tmpData)
    end

    for _, BossArea in pairs(self:GetGlobalBossAreaDatas()) do
        local tmpData = {}
        tmpData.LoseHp = BossArea.LoseHp
        tmpData.MaxHp = BossArea.MaxHp
        self.BossAreaEntityDic[BossArea.Id]:UpdateData(tmpData)
    end

    for _, bossAreaEntity in pairs(self.BossAreaEntityDic) do
        local IsUnLock = self.FinishStageCount >= bossAreaEntity:GetOpenCount()
        bossAreaEntity:UpdateData({ IsLock = not IsUnLock })
        bossAreaEntity:UpdatePhasesReward()
    end
end

function XWorldBossActivityEntity:UpdateSpecialSaleEntityDic()--更新特卖实体字典
    for _, specialSaleId in pairs(self:GetPurchasedSaleIds()) do
        self.SpecialSaleEntityDic[specialSaleId]:UpdateData({ IsPurchased = true })
    end

    for _, specialSaleEntity in pairs(self.SpecialSaleEntityDic) do
        local curDiscountText = ""
        local curConsumeCount = specialSaleEntity:GetConsumeCount()
        local maxConsumeCount = specialSaleEntity:GetConsumeCount()
        for _, discount in pairs(specialSaleEntity:GetDiscountDic()) do
            local bossArea = self.BossAreaEntityDic[discount.BossId]
            local IsDiscount = bossArea and bossArea:GetBossHp() <= (discount.HpPercent * 0.01 * bossArea:GetTotalHp())
            if IsDiscount and curConsumeCount > discount.Discount * maxConsumeCount then
                curConsumeCount = discount.Discount * maxConsumeCount
                curDiscountText = discount.DiscountText
            end
        end
        local tmpData = {}
        tmpData.MinDiscountText = curDiscountText
        tmpData.MinConsumeCount = curConsumeCount
        specialSaleEntity:UpdateData(tmpData)
    end
end

function XWorldBossActivityEntity:GetCfg()
    return XWorldBossConfigs.GetActivityTemplatesById(self.Id)
end

function XWorldBossActivityEntity:GetId()
    return self.Id
end

function XWorldBossActivityEntity:GetFinishStageCount()
    return self.FinishStageCount
end

function XWorldBossActivityEntity:GetGetedBossBuffList()
    return self.GetedBossBuffList
end

function XWorldBossActivityEntity:GetBossBuffList()
    return self.BossBuffList
end

function XWorldBossActivityEntity:GetGetedRobotIdList()
    return self.GetedRobotIdList
end

function XWorldBossActivityEntity:GetPrivateAttributeAreaDatas()--获取私有属性区域数据
    return self.PrivateData.AttributeAreaDatas or {}
end

function XWorldBossActivityEntity:GetGlobalAttributeAreaDatas()--获取公共属性区域数据
    return self.GlobalData.AttributeAreaDatas or {}
end

function XWorldBossActivityEntity:GetPrivateBossAreaDatas()--获取私有boss区域数据
    return self.PrivateData.BossAreaDatas or {}
end

function XWorldBossActivityEntity:GetGlobalBossAreaDatas()--获取公共boss区域数据
    return self.GlobalData.BossAreaDatas or {}
end

function XWorldBossActivityEntity:GetPurchasedSaleIds()--获取特卖已购买列表
    return self.PrivateData.ShopIds or {}
end

function XWorldBossActivityEntity:GetName()
    return self:GetCfg().Name
end

function XWorldBossActivityEntity:GetBeginTime()
    return XFunctionManager.GetStartTimeByTimeId(self:GetCfg().TimeId) or 0
end

function XWorldBossActivityEntity:GetEndTime()
    return XFunctionManager.GetEndTimeByTimeId(self:GetCfg().TimeId) or 0
end

function XWorldBossActivityEntity:GetAttributeAreaIds()
    return self:GetCfg().AttributeAreaId
end

function XWorldBossActivityEntity:GetBossAreaIds()
    return self:GetCfg().BossAreaId
end

function XWorldBossActivityEntity:GetSpecialSaleIds()
    return self:GetCfg().SpecialSaleId
end

function XWorldBossActivityEntity:GetActionPointId()
    return self:GetCfg().ActionPointId
end

function XWorldBossActivityEntity:GetMaxActionPoint()
    return self:GetCfg().MaxActionPoint
end

function XWorldBossActivityEntity:GetShopCurrencyId()
    return self:GetCfg().ShopCurrencyId
end

function XWorldBossActivityEntity:GetStartStoryId()
    return self:GetCfg().StartStoryId
end

function XWorldBossActivityEntity:GetBg()
    return self:GetCfg().Bg
end

function XWorldBossActivityEntity:GetAttributeAreaEntityDic()
    return self.AttributeAreaEntityDic
end

function XWorldBossActivityEntity:GetBossAreaEntityDic()
    return self.BossAreaEntityDic
end

function XWorldBossActivityEntity:GetSpecialSaleEntityDic()
    return self.SpecialSaleEntityDic
end

function XWorldBossActivityEntity:GetAttributeAreaEntityById(id)--获取某个属性区域实体
    if not self.AttributeAreaEntityDic[id] then
        XLog.Error("WorldBossActivity Id:" .. self.Id .. " Is Not Have AttributeArea id:" .. id)
    end
    return self.AttributeAreaEntityDic[id]
end

function XWorldBossActivityEntity:GetBossAreaEntityById(id)--获取某个boss区域实体
    if not self.BossAreaEntityDic[id] then
        XLog.Error("WorldBossActivity Id:" .. self.Id .. " Is Not Have BossArea id:" .. id)
    end
    return self.BossAreaEntityDic[id]
end

function XWorldBossActivityEntity:GetSpecialSaleEntityById(id)--获取某个特卖实体
    if not self.SpecialSaleEntityDic[id] then
        XLog.Error("WorldBossActivity Id:" .. self.Id .. " Is Not Have SpecialSale id:" .. id)
    end
    return self.SpecialSaleEntityDic[id]
end

return XWorldBossActivityEntity