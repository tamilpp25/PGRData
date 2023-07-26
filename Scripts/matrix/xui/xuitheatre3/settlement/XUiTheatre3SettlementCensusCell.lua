---@class XUiTheatre3SettlementCensusCell : XUiNode
local XUiTheatre3SettlementCensusCell = XClass(XUiNode, "XUiTheatre3SettlementCensusCell")

function XUiTheatre3SettlementCensusCell:OnStart()
    self.Icon:SetRawImage(XDataCenter.ItemManager.GetItemBigIcon(XEnumConst.THEATRE3.Theatre3OutCoin))
end

function XUiTheatre3SettlementCensusCell:SetData(title, point, score)
    self.TxtDataTitle.text = title
    self.TxtDataNum.text = point
    self.TxtRewardNum.text = score
end

return XUiTheatre3SettlementCensusCell