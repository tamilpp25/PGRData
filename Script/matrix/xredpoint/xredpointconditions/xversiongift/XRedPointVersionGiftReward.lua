local XRedPointVersionGiftReward = {}

---@param ignoreOpenCheck @是否忽略系统开启检测，用于组合红点，上层已负责检测时，不必重复检测
function XRedPointVersionGiftReward:Check(ignoreOpenCheck)
    if not ignoreOpenCheck then
        if not XMVCA.XVersionGift:GetIsOpen() then
            return false
        end
    end

    return XMVCA.XVersionGift:CheckAnyRewardCanGet()
end



return XRedPointVersionGiftReward