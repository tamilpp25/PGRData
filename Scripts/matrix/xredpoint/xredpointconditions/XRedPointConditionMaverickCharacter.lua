local XRedPointConditionMaverickCharacter = {}

function XRedPointConditionMaverickCharacter.Check(memberId)
    local talentIds = XDataCenter.MaverickManager.GetMemberTalentIds(memberId)
    for _, talentId in ipairs(talentIds) do
        if XDataCenter.MaverickManager.CheckTalentCanActive(memberId, talentId) then
            return true
        end
    end

    local member = XDataCenter.MaverickManager.GetMember(memberId)
    local maxLevel = XDataCenter.MaverickManager.GetMaxMemberLevel(memberId)
    if member.Level < maxLevel then
        local itemInfo = XDataCenter.MaverickManager.GetMemberLvUpConsumeInfo(member)
        local itemId = XDataCenter.MaverickManager.LvUpConsumeItemId
        local item = XDataCenter.ItemManager.GetItem(itemId)
        return item.Count >= itemInfo.ConsumeItemCount
    end
    
    return false
end

return XRedPointConditionMaverickCharacter