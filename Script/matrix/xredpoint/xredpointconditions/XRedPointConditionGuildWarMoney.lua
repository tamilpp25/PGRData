local XRedPointConditionGuildWarMoney = {}


function XRedPointConditionGuildWarMoney.Check()
    local seconds=tonumber(XGuildWarConfig.GetServerConfigValue('MoneyHipLeftTime','Int')) or 0
    if XDataCenter.GuildWarManager.CheckActivityIsInTime() and XDataCenter.GuildWarManager.GetActivityLeftTime() < seconds then
        --判断货币数量及购买力
        local itemId=tonumber(XGuildWarConfig.GetServerConfigValue('RewardItemId'))
        local limitCount=tonumber(XGuildWarConfig.GetServerConfigValue('RewardItemHipLimitCount'))or 0
        if XTool.IsNumberValid(itemId) then
            local item=XDataCenter.ItemManager.GetItem(itemId)
            if not item and item:GetCount() >= limitCount then
                return true
            end
        end
    end
    return false
end

return XRedPointConditionGuildWarMoney