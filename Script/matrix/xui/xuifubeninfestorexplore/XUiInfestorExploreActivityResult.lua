local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiInfestorExploreActivityResult = XLuaUiManager.Register(XLuaUi, "UiInfestorExploreActivityResult")

function XUiInfestorExploreActivityResult:OnAwake()
    self:AutoAddListener()
end

function XUiInfestorExploreActivityResult:OnStart(lastDiff, curDiff)
    local icon = XDataCenter.FubenInfestorExploreManager.GetDiffIcon(curDiff)
    self.RImgArenaLevel:SetRawImage(icon)

    local diffName = XDataCenter.FubenInfestorExploreManager.GetDiffName(curDiff)
    if curDiff > lastDiff then
        self.TxtInfo.text = CSXTextManagerGetText("InfestorExploreUpDiff", diffName)
    elseif curDiff == lastDiff then
        self.TxtInfo.text = CSXTextManagerGetText("InfestorExploreUnchangeDiff", diffName)
    else
        self.TxtInfo.text = CSXTextManagerGetText("InfestorExploreDownDiff", diffName)
    end
    
    self.EffectUp.gameObject:SetActiveEx(curDiff > lastDiff)
    self.EffectDown.gameObject:SetActiveEx(curDiff < lastDiff)
    self.EffectStay.gameObject:SetActiveEx(curDiff == lastDiff)
end

function XUiInfestorExploreActivityResult:AutoAddListener()
    self.BtnBg.CallBack = function() self:Close() end
end