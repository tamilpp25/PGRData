local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridRegressionPassportItem = XClass(nil, "XUiGridRegressionPassportItem")

function XUiGridRegressionPassportItem:Ctor(ui, rootUi)
    XTool.InitUiObjectByUi(self, ui)
    self.GridCommon = XUiGridCommon.New(rootUi, self.Grid256)
    local viewModel = XDataCenter.Regression3rdManager.GetViewModel()
    self.PassportViewModel = viewModel:GetProperty("_PassportViewModel")
end

function XUiGridRegressionPassportItem:Refresh(data)
    if not data then
        self.GameObject:SetActiveEx(false)
        return
    end
    local viewModel = self.PassportViewModel
    local rewardInfo = viewModel:GetPassportRewardInfo(data.TypeInfoId, data.Level)
    local unlock = viewModel:CheckUnlock(data.Level, data.TypeInfoId)
    local received = viewModel:CheckReceive(rewardInfo.Id, data.TypeInfoId)
    
    local isBuy = viewModel:IsPassportBuy(data.TypeInfoId)
    --未解锁且未购买
    self.ImgLock.gameObject:SetActiveEx(not unlock and not isBuy)
    --未购买
    self.ImgUnlocked.gameObject:SetActiveEx(not isBuy)
    self.PanelReceived.gameObject:SetActiveEx(received)
    self.RImglight.gameObject:SetActiveEx(rewardInfo.IsPrimeReward)
    if unlock and not received then
        self.Effect.gameObject:SetActiveEx(true)
        self.GridCommon:SetClickCallback(handler(self, self.OnGridClick))
    else
        self.Effect.gameObject:SetActiveEx(false)
        self.GridCommon:AutoAddListener()
    end
    --self.Count.text = data.RewardData.Count
    self.GridCommon:Refresh(data.RewardData)
    self.Data = data
    self.PassportRewardId = rewardInfo.Id
end

function XUiGridRegressionPassportItem:OnGridClick()
    XDataCenter.Regression3rdManager.RequestSinglePassportReward(self.PassportRewardId)
end


local XUiGridRegressionPassport = XClass(nil, "XUiGridRegressionPassport")

local ColorEnum = {
    Blue    = XUiHelper.Hexcolor2Color("0e6fbb"),
    Orange  = XUiHelper.Hexcolor2Color("fa5826"),
}

function XUiGridRegressionPassport:Ctor(ui, rootUi, passportViewModel)
    XTool.InitUiObjectByUi(self, ui)
    self.RootUi = rootUi
    self.PassportViewModel = passportViewModel
end

function XUiGridRegressionPassport:Refresh(levelInfo)
    local viewModel = self.PassportViewModel
    local typeInfo = viewModel:GetPassportTypeInfos()
    self.TxtCount.text = tostring(levelInfo.TotalExp)
    self.TxtCount.color = viewModel:GetProperty("_Accumulated") >= levelInfo.TotalExp and ColorEnum.Blue or ColorEnum.Orange
    self.RImgIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XRegression3rdConfigs.Regression3rdCoinId))
    for idx, info in ipairs(typeInfo) do
        local rewardInfo = viewModel:GetPassportRewardInfo(info.Id, levelInfo.Level)
        local rewardId = rewardInfo.RewardId
        local ui = self["GridReward"..idx]
        if rewardId == nil then
            XLog.Error("refresh passport error!, rewardId is null! PassportId = " .. info.Id .. "Level = " .. levelInfo.Level)
            ui.gameObject:SetActiveEx(false)
            return
        end
        local rewardList = XRewardManager.GetRewardList(rewardId)
        local grid = self["GridItem"..idx]
        if not grid then
            grid = XUiGridRegressionPassportItem.New(ui, self.RootUi)
            self["GridItem"..idx] = grid
        end
        grid.GameObject:SetActiveEx(true)
        grid:Refresh({
            TypeInfoId = info.Id,
            Level = levelInfo.Level,
            RewardData = rewardList[1],
        })
    end
end

return XUiGridRegressionPassport