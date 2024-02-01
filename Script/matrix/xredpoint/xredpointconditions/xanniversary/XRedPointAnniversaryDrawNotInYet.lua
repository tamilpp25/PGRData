local XRedPointAnniversaryDrawNotInYet = {}


function XRedPointAnniversaryDrawNotInYet.Check()
    local isOpen=XMVCA.XAnniversary:JudgeCanOpen(XEnumConst.Anniversary.ActivityType.AnniversaryDraw)
    return not XSaveTool.GetData(XMVCA.XAnniversary:GetHadInDrawkey()) and isOpen
end

return XRedPointAnniversaryDrawNotInYet