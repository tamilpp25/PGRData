local XPurchaseRecommend = require("XEntity/XPurchase/XPurchaseRecommend")
local XPurchaseRecommendManager = XClass(nil, "XPurchaseRecommendManager")

function XPurchaseRecommendManager:Ctor() 
    self.RecommendConfigDic = {}
end

-- { XPurchaseRecommend, XPurchaseRecommend }
function XPurchaseRecommendManager:GetRecommends()
    local result = {}
    local configs = self:GetPurchaseRecommendConfigs()
    for _, config in ipairs(configs) do
        local purchaseRecommend = XPurchaseRecommend.New(config.Id)
        local package = purchaseRecommend:GetPurchasePackage()
        local skipSteps = purchaseRecommend:GetSkipSteps()
        -- 拿不到礼包数据同时跳转步骤为0，直接跳过
        if XTool.IsTableEmpty(package) and #skipSteps <= 0 then
            goto continue 
        end
        -- 时间已经过去，直接跳过
        if not purchaseRecommend:GetIsInTime() then
            goto continue
        end
        if config.IsLockShow or not purchaseRecommend:GetIsSellOut() then
            table.insert(result, purchaseRecommend)
        end
        :: continue ::
    end
    return result
end

function XPurchaseRecommendManager:CheckHasRecommend()
    return #self:GetRecommends() > 0
end

function XPurchaseRecommendManager:RequestServerData(cb)
    local uiTypes = XPurchaseConfigs.GetUiTypesByUiPurchaseTopType(XPurchaseConfigs.UiPurchaseTopType.Recommend)
    XDataCenter.PurchaseManager.GetPurchaseListRequest(uiTypes, cb)
end

function XPurchaseRecommendManager:GetIsShowRedPoint()
    local recommends = self:GetRecommends()
    for _, value in pairs(recommends) do
        if value:GetIsShowRedPoint() then
            return true
        end
    end
    return false
end

function XPurchaseRecommendManager:AddOrModifyRecommendConfigs(addOrModifyConfigs)
    if addOrModifyConfigs == nil then return end
    for _, config in pairs(addOrModifyConfigs) do
        self.RecommendConfigDic[config.Id] = config
    end
end

function XPurchaseRecommendManager:DeleteRecommendConfigs(removeIds)
    if removeIds == nil then return end
    for _, id in ipairs(removeIds) do
        self.RecommendConfigDic[id] = nil
    end
end

function XPurchaseRecommendManager:GetPurchaseRecommendConfig(id)
    return self.RecommendConfigDic[id]
end

function XPurchaseRecommendManager:GetPurchaseRecommendConfigs()
    local result = {}
    for _, config in pairs(self.RecommendConfigDic) do
        table.insert(result, config)
    end
    table.sort(result, function(aConfig, bConfig)
        return aConfig.Id < bConfig.Id
    end)
    return result
end

return XPurchaseRecommendManager