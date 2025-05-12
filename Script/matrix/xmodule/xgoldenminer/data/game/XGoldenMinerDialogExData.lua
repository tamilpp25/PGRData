---@class XGoldenMinerDialogExData
local XGoldenMinerDialogExData = XClass(nil, "XGoldenMinerDialogExData")

function XGoldenMinerDialogExData:Ctor()
    self.TxtSure = ""
    self.TxtClose = ""
    self.FuncSpecial = false
    self.FuncSpecialIsSure = false
    self.IsCanShowClose = true
    self.IsCanShowSure = true
    
    --结算相关
    self.IsSettleGame = false
end

return XGoldenMinerDialogExData