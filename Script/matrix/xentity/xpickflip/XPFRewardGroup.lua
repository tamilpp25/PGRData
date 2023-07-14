local XRuleTextViewModel = require("XEntity/XCommon/XRule/XRuleTextViewModel")
local XRuleDropItemViewModel = require("XEntity/XCommon/XRule/XRuleDropItemViewModel")
local XPFRewardLayer = require("XEntity/XPickFlip/XPFRewardLayer")
local XPFRewardGroup = XClass(nil, "XPFRewardGroup")

function XPFRewardGroup:Ctor(id)
    self.Config = XPickFlipConfigs.GetRewardGroupConfig(id)
    self.CurrentLayerId = nil
    -- XPFRewardLayer
    self.RewardLayerDic = {}
end

-- data : PickFlipActivityDataResponse
function XPFRewardGroup:InitOrUpdateWithServerData(data)
    -- 当前奖励活动所在的层的id
    self.CurrentLayerId = data.RewardGroupId
    local rewardLayer = nil
    for _, layerData in ipairs(data.GroupDatas) do
        rewardLayer = self:GetRewardLayerById(layerData.Id)    
        rewardLayer:InitOrUpadateWithServerData(layerData)
    end
end

function XPFRewardGroup:UpdateLayerRewardDatas(layerDatas)
    local rewardLayer = nil
    for _, layerData in ipairs(layerDatas) do
        rewardLayer = self:GetRewardLayerById(layerData.Id)
        rewardLayer:InitOrUpadateWithServerData(layerData)
    end
end

function XPFRewardGroup:GetId()
    return self.Config.Id
end

function XPFRewardGroup:GetName()
    return self.Config.Name
end

function XPFRewardGroup:GetBg()
    return self.Config.Bg
end

function XPFRewardGroup:GetEndTime()
    return XFunctionManager.GetEndTimeByTimeId(self.Config.TimeId)
end

function XPFRewardGroup:GetIsInTime()
    return XFunctionManager.CheckInTimeByTimeId(self.Config.TimeId)
end

function XPFRewardGroup:GetLeaveTimeStr()
    return XUiHelper.GetTime(self:GetEndTime() - XTime.GetServerNowTimestamp()
        , XUiHelper.TimeFormatType.ACTIVITY)
end

function XPFRewardGroup:GetAssetItemIds()
    return self.Config.AssetItemIds
end

-- 获取奖励层
function XPFRewardGroup:GetRewardLayer(id, index)
    if self.RewardLayerDic[index] == nil then
        self.RewardLayerDic[index] = XPFRewardLayer.New(id)
    end
    return self.RewardLayerDic[index]
end

function XPFRewardGroup:GetRewardLayerById(id)
    local layerConfig = XPickFlipConfigs.GetRewardLayerConfig(id)
    return self:GetRewardLayer(id, layerConfig.Order)
end

function XPFRewardGroup:GetCurrentLayer()
    return self:GetRewardLayerById(self.CurrentLayerId)
end

function XPFRewardGroup:GetIsOpen(showTip)
    -- 未满足开放时间
    if not self:GetIsInTime() then
        if showTip then
            XUiManager.TipError(CS.XTextManager.GetText("FunctionNotDuringOpening"))
        end
        return false
    end
    return true
end

function XPFRewardGroup:OpenShopUi(callback)
    if not self:GetIsOpen(true) then
        return
    end
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon) then
        return
    end
    XLuaUiManager.Open("UiShop", XShopManager.ShopType.PickFlip)
end

function XPFRewardGroup:OpenRuleUi()
    XLuaUiManager.Open("UiLivWarmRaceLog", {
        self:GetRuleTextViewModel(),
        self:GetRuleDropItemViewModel()
    })
end

function XPFRewardGroup:GetRuleTextViewModel()
    if self._RuleTextViewModel == nil then
        local config = XPickFlipConfigs.GetTextRuleConfig(self.Config.Id)
        self._RuleTextViewModel = XRuleTextViewModel.New()
        self._RuleTextViewModel:SetTitle(config.Title)
        for i = 1, #config.RuleTitles do
            self._RuleTextViewModel:AddRuleData(config.RuleTitles[i]
            , config.RuleDescs[i])
        end
    end
    return self._RuleTextViewModel
end

function XPFRewardGroup:GetRuleDropItemViewModel()
    if self._RuleDropItemViewModel == nil then
        self._RuleDropItemViewModel = XRuleDropItemViewModel.New()
        self._RuleDropItemViewModel:SetTitle(XUiHelper.GetText("PickFlipRuleDropItemTitle"))
        self._RuleDropItemViewModel:SetGoodSwitchBtnName(XUiHelper.GetText("PickFlipRuleGoodSwitchBtnName"))
        self._RuleDropItemViewModel:SetProbabilityBtnName(XUiHelper.GetText("PickFlipRuleProbabilitySwitchBtnName"))
        local layerIds = XPickFlipConfigs.GetRewardGroupAllLayerIds(self.Config.Id)
        table.sort(layerIds, function(idA, idB)
            return idA < idB
        end)
        local layer
        -- 创建层级商品视图
        for index, layerId in ipairs(layerIds) do
            self._RuleDropItemViewModel:CreateGoodGroup(index
                , XUiHelper.GetText("PickFlipRuleRewardLayerTitle", index))
            self._RuleDropItemViewModel:CreateProbailityGroup(index
                , XUiHelper.GetText("PickFlipRuleDropItemLayerTitle", index))
            local config
            local totalValue = 0
            local itemTypeWeightDic = {}
            for _, rewardId in ipairs(XPickFlipConfigs.GetLayerRewardIds(layerId)) do
                config = XPickFlipConfigs.GetRewardConfig(rewardId)
                self._RuleDropItemViewModel:AddGoodData(index, config.TemplateId, config.Count)
                -- 计算概率比重
                if config.Type == XPickFlipConfigs.RewardType.Random then
                    totalValue = totalValue + config.Weight
                    itemTypeWeightDic[config.ItemType] = itemTypeWeightDic[config.ItemType] or 0
                    itemTypeWeightDic[config.ItemType] = itemTypeWeightDic[config.ItemType] + config.Weight
                end
            end
            -- 创建概率视图数据
            local itemTypeWeights = table.dicToArray(itemTypeWeightDic)
            table.sort(itemTypeWeights, function(dataA, dataB)
                return dataA.key < dataB.key
            end)
            for i, v in ipairs(itemTypeWeights) do
                self._RuleDropItemViewModel:AddProbabilityData(index, 
                    XPickFlipConfigs.GetItemTypeName(v.key),
                    getRoundingValue((v.value / totalValue) * 100, 2),
                    XPickFlipConfigs.GetItemTypeIsSpecial(v.key))
            end
        end
    end
    return self._RuleDropItemViewModel
end

return XPFRewardGroup