local XRedPointDlcMouseHunterActivity = {}

function XRedPointDlcMouseHunterActivity.Check()
    -- if XMVCA.XDlcMultiMouseHunter:CheckShopRedPointWithSyncShopInfo() then
    --     return true
    -- end
    if XMVCA.XDlcMultiMouseHunter:CheckTitleRedPoint() then
        return true
    end
    if XMVCA.XDlcMultiMouseHunter:CheckDiscussionRedPoint() then
        return true
    end
    if XMVCA.XDlcMultiMouseHunter:CheckBpRedPoint() then
        return true
    end

    return false
end

return XRedPointDlcMouseHunterActivity