local XRedPointVersionGiftTask = {}

---@param ignoreOpenCheck @是否忽略系统开启检测，用于组合红点，上层已负责检测时，不必重复检测
function XRedPointVersionGiftTask:Check(ignoreOpenCheck)
    if not ignoreOpenCheck then
        if not XMVCA.XVersionGift:GetIsOpen() then
            return false
        end
    end
    
    
    return XTool.IsNumberValid(XMVCA.XVersionGift:CheckAnyTaskGroupContainsFinishableTask()) and true or false
end 



return XRedPointVersionGiftTask