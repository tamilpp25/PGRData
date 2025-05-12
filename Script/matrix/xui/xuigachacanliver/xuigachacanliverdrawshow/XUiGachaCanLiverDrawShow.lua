--- 可肝卡池抽卡动画基类
---@class XUiGachaCanLiverDrawShow: XLuaUi
---@field _Control XGachaCanLiverControl
---@field GachaId
---@field RewardList
---@field GachaCfg XTableGacha
local XUiGachaCanLiverDrawShow = XClass(XLuaUi, 'XUiGachaCanLiverDrawShow')

function XUiGachaCanLiverDrawShow:OnStart(gachaId, rewardList)
    self.GachaId = gachaId
    self.RewardList = rewardList
    self.GachaCfg = XGachaConfigs.GetGachaCfgById(self.GachaId)
end

function XUiGachaCanLiverDrawShow:GetQualityByRewardInfo(rewardInfo)
    --获取奖励品质
    local id = rewardInfo.Id and rewardInfo.Id > 0 and rewardInfo.Id or rewardInfo.TemplateId
    local Type = XTypeManager.GetTypeById(id)
    if rewardInfo.ConvertFrom > 0 then
        Type = XTypeManager.GetTypeById(rewardInfo.ConvertFrom)
        id = rewardInfo.ConvertFrom
    end
    local quality
    local templateIdData = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(id)
    if Type == XArrangeConfigs.Types.Wafer then
        quality = templateIdData.Star
    elseif Type == XArrangeConfigs.Types.Weapon then
        quality = templateIdData.Star
    elseif Type == XArrangeConfigs.Types.Character then
        quality = XMVCA.XCharacter:GetCharMinQuality(id)
    elseif Type == XArrangeConfigs.Types.Partner then
        quality = templateIdData.Quality
    else
        quality = XTypeManager.GetQualityById(id)
    end
    if XDataCenter.ItemManager.IsWeaponFashion(id) then
        quality = XTypeManager.GetQualityById(id)
    end
    -- 强制检测特效
    local foreceQuality = XGachaConfigs.GetGachaShowRewardConfigById(id)
    if foreceQuality then
        quality = foreceQuality.EffectQualityType
    end

    if XTool.IsNumberValid(rewardInfo.ShowQuality) then
        quality = rewardInfo.ShowQuality
    end
    
    return quality
end


return XUiGachaCanLiverDrawShow