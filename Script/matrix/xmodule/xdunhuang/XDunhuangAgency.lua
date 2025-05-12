local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XDunhuangAgency : XFubenActivityAgency
---@field private _Model XDunhuangModel
local XDunhuangAgency = XClass(XFubenActivityAgency, "XDunhuangAgency")

function XDunhuangAgency:OnInit()
    --初始化一些变量
    self:RegisterActivityAgency()
end

function XDunhuangAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    XRpc.NotifyMuralShareData = handler(self, self.NotifyMuralShareData)
end

function XDunhuangAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

--function XDunhuangAgency:ExCheckInTime()
--    --return self._Model:CheckInTime()
--    --if self._Model:IsDebug() then
--    --    return true
--    --end
--    return self._Model:CheckInTime()
--end

function XDunhuangAgency:NotifyMuralShareData(serverData)
    self._Model:SetServerData(serverData)
end

function XDunhuangAgency:OpenMainUi()
    XLuaUiManager.Open("UiDunhuangMain")
end

---@param painting XDunhuangPainting
function XDunhuangAgency:RequestUnlockPainting(painting)
    if not painting then
        XLog.Error("[XDunhuangAgency] 解锁图片不存在")
        return
    end
    if self._Model:IsHasPainting(painting) then
        XLog.Error("[XDunhuangAgency] 已拥有:" .. painting:GetId())
        return
    end

    XNetwork.Call("MuralShareUnlockPaintingRequest", { PaintingId = painting:GetId() }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:SetPaintingOwned(painting)
    end)
end

---@param paintings XDunhuangPainting[]
function XDunhuangAgency:RequestSave(paintings)
    local saveData = {}
    for i = 1, #paintings do
        local painting = paintings[i]
        local dataToSave = painting:GetDataToSave()
        dataToSave.Scale = math.floor(dataToSave.Scale * 1000)
        saveData[#saveData + 1] = dataToSave
    end
    XNetwork.Call("MuralShareSaveRequest", { PaintingCombination = saveData }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        XUiManager.PopupLeftTip(XUiHelper.GetText("TipTitle"), XUiHelper.GetText("DunhuangSaveSuccess"))
        self._Model:SetPaintingCombination(saveData)
    end)
end

function XDunhuangAgency:RequestReceiveReward(rewardId)
    XNetwork.Call("MuralShareCollectRewardRequest", { RewarId = rewardId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        XUiManager.OpenUiObtain(res.RewardGoods)
        self._Model:SetRewardReceived(rewardId)
    end)
end

function XDunhuangAgency:RequestShareReward()
    XNetwork.Call("MuralShareRewardRequest", {  }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if res.RewardGoods then
            XUiManager.OpenUiObtain(res.RewardGoods)
        end
        self._Model:SetNotFirstShare()
    end)
end

function XDunhuangAgency:ExCheckIsShowRedPoint()
    if self:ExGetIsLocked() then
        return false
    end
    
    if self._Model:IsTaskCanAchieved() then
        return true
    end

    local configRewards = self._Model:GetConfigReward()
    local unlockAmount = self._Model:GetUnlockPaintingAmount()
    for i = 1, #configRewards do
        local reward = configRewards[i]
        local isOn = unlockAmount >= reward.PaintingNum
        local IsReceived = self._Model:IsRewardReceived(reward.Id)
        if isOn and not IsReceived then
            return true
        end
    end

    if self._Model:GetIsFirstTimeEnter() then
        return true
    end

    if self._Model:IsPaintingAfford() then
        return true
    end

    return false
end

return XDunhuangAgency
