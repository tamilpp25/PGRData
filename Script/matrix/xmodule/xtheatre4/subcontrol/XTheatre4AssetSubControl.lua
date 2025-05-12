---@class XTheatre4AssetSubControl : XControl
---@field private _Model XTheatre4Model
---@field _MainControl XTheatre4Control
local XTheatre4AssetSubControl = XClass(XControl, "XTheatre4AssetSubControl")
function XTheatre4AssetSubControl:OnInit()
    --初始化内部变量
end

function XTheatre4AssetSubControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XTheatre4AssetSubControl:RemoveAgencyEvent()

end

function XTheatre4AssetSubControl:OnRelease()
    --XLog.Error("这里执行Control的释放")
end

function XTheatre4AssetSubControl:RemovePopupUiWhenApUnEnough()
    XLuaUiManager.Remove("UiTheatre4Outpost")
end

-- 检查行动点是否足够
---@param isNotTips boolean 是否不提示
function XTheatre4AssetSubControl:CheckApEnough(isNotTips)
    local cost = XEnumConst.Theatre4.MapExploredCost
    if not self:CheckAssetEnough(XEnumConst.Theatre4.AssetType.ActionPoint, nil, cost, true) then
        if not isNotTips then
            local title = XUiHelper.GetText("Theatre4PopupCommonTitle")
            local content = XUiHelper.GetText("Theatre4ActionPointZero")

            self._MainControl:ShowCommonPopup(title, content, function()
                self:RemovePopupUiWhenApUnEnough()

                local ui = XLuaUiManager.GetTopLuaUi("UiTheatre4Game")
                
                if ui and ui.OnBtnNextSureClick then
                    ui:OnBtnNextSureClick()
                end
            end)
        end

        return false
    end

    return true
end


-- 检查资产是否足够
---@param type number 资产类型
---@param assetId number 资产Id
---@param count number 需要的资产数量
---@param isNotTips boolean 是否不提示
function XTheatre4AssetSubControl:CheckAssetEnough(type, assetId, count, isNotTips)
    local assetCount = self:GetAssetCount(type, assetId)
    if assetCount < count then
        if not isNotTips then
            local assetName = self:GetAssetName(type, assetId)
            self._MainControl:ShowRightTipPopup(XUiHelper.GetText("Theatre4AssetNotEnough", assetName))
        end
        return false
    end
    return true
end

-- 获取资产数量
function XTheatre4AssetSubControl:GetAssetCount(type, assetId)
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return 0
    end
    if type == XEnumConst.Theatre4.AssetType.ItemBox then
        return adventureData:GetItemBoxCountById(assetId)
    elseif type == XEnumConst.Theatre4.AssetType.Item then
        return adventureData:GetItemCountById(assetId)
    elseif type == XEnumConst.Theatre4.AssetType.Recruit then
        return adventureData:GetRecruitTicketCountById(assetId)
    elseif type == XEnumConst.Theatre4.AssetType.Gold then
        return adventureData:GetGold()
    elseif type == XEnumConst.Theatre4.AssetType.Hp then
        return adventureData:GetHp()
    elseif type == XEnumConst.Theatre4.AssetType.Prosperity then
        return adventureData:GetProsperity()
    elseif type == XEnumConst.Theatre4.AssetType.ColorLevel then
        return adventureData:GetColorLevelById(assetId)
    elseif type == XEnumConst.Theatre4.AssetType.ColorResource then
        return adventureData:GetColorResourceById(assetId)
    elseif type == XEnumConst.Theatre4.AssetType.ColoPoint then
        return adventureData:GetColorPointById(assetId)
    elseif type == XEnumConst.Theatre4.AssetType.BuildPoint then
        return adventureData:GetBp()
    elseif type == XEnumConst.Theatre4.AssetType.ActionPoint then
        return adventureData:GetAp()
    elseif type == XEnumConst.Theatre4.AssetType.ColorDailyResource then
        return adventureData:GetDailyColorResourceById(assetId)
    elseif type == XEnumConst.Theatre4.AssetType.ItemLimit then
        return adventureData:GetItemLimit()
    elseif type == XEnumConst.Theatre4.AssetType.SettleBpExp then
        return adventureData:GetSettleBpExp()
    elseif type == XEnumConst.Theatre4.AssetType.ColorCostPoint then
        return adventureData:GetColorPointCanCostById(assetId)
    elseif type == XEnumConst.Theatre4.AssetType.AwakeningPoint then
        return adventureData:GetAwakeningPoint()
    elseif type == XEnumConst.Theatre4.AssetType.TimeBack then
        return adventureData:GetTracebackPoint()
    end
    return 0
end

-- 获取资产图标
function XTheatre4AssetSubControl:GetAssetIcon(type, assetId)
    if type == XEnumConst.Theatre4.AssetType.ItemBox then
        return self._Model:GetItemBoxIconById(assetId)
    elseif type == XEnumConst.Theatre4.AssetType.Item then
        return self._Model:GetItemIconById(assetId)
    elseif type == XEnumConst.Theatre4.AssetType.Recruit then
        return self._Model:GetRecruitTicketIconById(assetId)
    elseif type == XEnumConst.Theatre4.AssetType.Gold
        or type == XEnumConst.Theatre4.AssetType.Hp
        or type == XEnumConst.Theatre4.AssetType.Prosperity
        or type == XEnumConst.Theatre4.AssetType.BuildPoint
        or type == XEnumConst.Theatre4.AssetType.ActionPoint
        or type == XEnumConst.Theatre4.AssetType.ItemLimit 
            or type == XEnumConst.Theatre4.AssetType.TimeBack
    then
        return self._Model:GetAssetIcon(type)
    elseif type == XEnumConst.Theatre4.AssetType.ColorLevel
        or type == XEnumConst.Theatre4.AssetType.ColorResource
        or type == XEnumConst.Theatre4.AssetType.ColoPoint
        or type == XEnumConst.Theatre4.AssetType.ColorDailyResource then
        return self._Model:GetAssetIcon(type, assetId)
    elseif type == XEnumConst.Theatre4.AssetType.ColorCostPoint
            or type == XEnumConst.Theatre4.AssetType.AwakeningPoint
    then
        return self._Model:GetAssetIcon(type, assetId)
    end
    return nil
end

-- 获取资产名称
function XTheatre4AssetSubControl:GetAssetName(type, assetId)
    if type == XEnumConst.Theatre4.AssetType.ItemBox then
        return self._Model:GetItemBoxNameById(assetId)
    elseif type == XEnumConst.Theatre4.AssetType.Item then
        return self._Model:GetItemNameById(assetId)
    elseif type == XEnumConst.Theatre4.AssetType.Recruit then
        return self._Model:GetRecruitTicketNameById(assetId)
    elseif type == XEnumConst.Theatre4.AssetType.Gold
        or type == XEnumConst.Theatre4.AssetType.Hp
        or type == XEnumConst.Theatre4.AssetType.Prosperity
        or type == XEnumConst.Theatre4.AssetType.BuildPoint
        or type == XEnumConst.Theatre4.AssetType.ActionPoint
        or type == XEnumConst.Theatre4.AssetType.ItemLimit then
        return self._Model:GetAssetName(type)
    elseif type == XEnumConst.Theatre4.AssetType.ColorLevel
        or type == XEnumConst.Theatre4.AssetType.ColorResource
        or type == XEnumConst.Theatre4.AssetType.ColoPoint
        or type == XEnumConst.Theatre4.AssetType.ColorDailyResource
        or type == XEnumConst.Theatre4.AssetType.AwakeningPoint
    then
        return self._Model:GetAssetName(type, assetId)
    end
    return ""
end

-- 获取资产描述
function XTheatre4AssetSubControl:GetAssetDesc(type, assetId)
    if type == XEnumConst.Theatre4.AssetType.ItemBox then
        return self._Model:GetItemBoxDescById(assetId)
    elseif type == XEnumConst.Theatre4.AssetType.Item then
        return self._Model:GetItemDescById(assetId)
    elseif type == XEnumConst.Theatre4.AssetType.Recruit then
        return self._Model:GetRecruitTicketDescById(assetId)
    elseif type == XEnumConst.Theatre4.AssetType.Gold
        or type == XEnumConst.Theatre4.AssetType.Hp
        or type == XEnumConst.Theatre4.AssetType.Prosperity
        or type == XEnumConst.Theatre4.AssetType.BuildPoint
        or type == XEnumConst.Theatre4.AssetType.ActionPoint
        or type == XEnumConst.Theatre4.AssetType.ItemLimit then
        return self._Model:GetAssetDesc(type)
    elseif type == XEnumConst.Theatre4.AssetType.ColorLevel
        or type == XEnumConst.Theatre4.AssetType.ColorResource
        or type == XEnumConst.Theatre4.AssetType.ColoPoint
        or type == XEnumConst.Theatre4.AssetType.ColorDailyResource
        or type == XEnumConst.Theatre4.AssetType.AwakeningPoint
    then
        return self._Model:GetAssetDesc(type, assetId)
    end
    return ""
end

-- 获取资产世界观描述
function XTheatre4AssetSubControl:GetAssetWorldDesc(type, assetId)
    if type == XEnumConst.Theatre4.AssetType.Gold
        or type == XEnumConst.Theatre4.AssetType.Hp
        or type == XEnumConst.Theatre4.AssetType.Prosperity
        or type == XEnumConst.Theatre4.AssetType.BuildPoint
        or type == XEnumConst.Theatre4.AssetType.ActionPoint
        or type == XEnumConst.Theatre4.AssetType.ItemLimit then
        return self._Model:GetAssetWorldDesc(type)
    elseif type == XEnumConst.Theatre4.AssetType.ColorLevel
        or type == XEnumConst.Theatre4.AssetType.ColorResource
        or type == XEnumConst.Theatre4.AssetType.ColoPoint
        or type == XEnumConst.Theatre4.AssetType.ColorDailyResource
        or type == XEnumConst.Theatre4.AssetType.AwakeningPoint
    then
        return self._Model:GetAssetWorldDesc(type, assetId)
    end
    return ""
end

-- 获取资产品质
function XTheatre4AssetSubControl:GetAssetQuality(type, assetId)
    if type == XEnumConst.Theatre4.AssetType.ItemBox then
        return self._Model:GetItemBoxQualityById(assetId)
    elseif type == XEnumConst.Theatre4.AssetType.Item then
        return self._Model:GetItemQualityById(assetId)
    elseif type == XEnumConst.Theatre4.AssetType.Recruit then
        return self._Model:GetRecruitTicketQualityById(assetId)
    end
    return 0
end

-- 获取资产品质图标
function XTheatre4AssetSubControl:GetAssetQualityIcon(type, assetId)
    local quality = self:GetAssetQuality(type, assetId)
    return XArrangeConfigs.GeQualityPath(quality)
end

-- 获取总的行动点 = 最大行动点 + 额外增加的行动点
function XTheatre4AssetSubControl:GetTotalAp()
    return self:GetMaxAp() + self:GetExtraMaxAp()
end

-- 获取最大行动点
function XTheatre4AssetSubControl:GetMaxAp()
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return 0
    end
    return adventureData:GetMaxAp()
end

-- 获取额外增加的行动点
function XTheatre4AssetSubControl:GetExtraMaxAp()
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return 0
    end
    return adventureData:GetExtraMaxAp()
end

-- 获取藏品上限
function XTheatre4AssetSubControl:GetItemLimit()
    -- 配置上限
    local maxLimit = self._MainControl:GetConfig("ItemCountLimit")
    -- 额外增加的上限
    local extraLimit = self:GetAssetCount(XEnumConst.Theatre4.AssetType.ItemLimit)
    return maxLimit + extraLimit
end

-- 获取每回合回复能量值 总值 = 配置里的基础值 + 篝火建造点恢复 + 效果111 + 效果113
function XTheatre4AssetSubControl:GetTotalRecoverEnergy()
    local difficultyId = self._MainControl:GetDifficulty()
    -- 配置里的基础值
    local baseValue = self._MainControl:GetDifficultyReEnergy(difficultyId)
    -- 篝火建造点恢复
    local bonfireBuildPoint = self._MainControl.MapSubControl:GetBonfireBuildPointRecover()
    -- 效果111 + 效果113
    local effectValue = self._MainControl.EffectSubControl:GetEffectBuildPointAdds()
    -- 临时基地
    local tempBasePoint = self._MainControl.MapSubControl:GetTempBaseBuildPointRecover()
    return baseValue + bonfireBuildPoint + effectValue + tempBasePoint
end

-- 获取每回合回复金币 效果218、113、209总和
function XTheatre4AssetSubControl:GetTotalRecoverGold()
    return self._MainControl.EffectSubControl:GetEffectGoldAdds()
end

function XTheatre4AssetSubControl:GetColorDatas()
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return {}
    end
    return adventureData.Colors
end

function XTheatre4AssetSubControl:GetAdventureData()
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return nil
    end
    return adventureData
end

return XTheatre4AssetSubControl
