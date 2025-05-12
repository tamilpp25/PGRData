local XUiButtonLongClick = require("XUi/XUiCommon/XUiButtonLongClick")
local handler = handler

local LongClickIntervel = 100
local AddCountPerPressTime = 1 / 150

local XUiGridStrongholdPluginSet = XClass(nil, "XUiGridStrongholdPluginSet")

function XUiGridStrongholdPluginSet:Ctor(ui, checkCountCb, countChangeCb, getMaxCountCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.CheckCountCb = checkCountCb
    self.CountChangeCb = countChangeCb
    self.GetMaxCountCb = getMaxCountCb
    self.Count = 0

    XTool.InitUiObject(self)

    if self.BtnAdd then self.BtnAdd.CallBack = handler(self, self.OnClickBtnAdd) end
    if self.BtnReduce then self.BtnReduce.CallBack = handler(self, self.OnClickBtnSub) end

    XUiButtonLongClick.New(self.BtnAdd, LongClickIntervel, self, nil, self.OnLongClickBtnAdd, nil, true)
    XUiButtonLongClick.New(self.BtnReduce, LongClickIntervel, self, nil, self.OnLongClickBtnReduce, nil, true)
end

function XUiGridStrongholdPluginSet:Refresh(plugin)
    self.Plugin = plugin
    self.Count = plugin:GetCount()

    local icon = plugin:GetIcon()
    self.RImgIconCore:SetRawImage(icon)

    local name = plugin:GetName()
    self.TxtName.text = name

    local desc = plugin:GetDesc()
    self.TxtDetails.text = desc

    self:UpdateCount()
end

function XUiGridStrongholdPluginSet:UpdateCount()
    self.TxtNumber.text = self.Count
end

function XUiGridStrongholdPluginSet:OnLongClickBtnAdd(pressingTime)
    local maxCount = self.GetMaxCountCb(self.Plugin:GetCostElectricSingle())
    local addCount = XMath.Clamp(math.floor(pressingTime * AddCountPerPressTime), 1, maxCount)
    local countLimitLeft = self.Plugin:GetCountLimit() - self.Count
    if countLimitLeft < 1 then
        countLimitLeft = 1
    end
    addCount = XMath.Clamp(addCount, 1, countLimitLeft)

    if addCount > 0 then
        self:AddCount(addCount)
    else
        XUiManager.TipText("StrongholdPluginAddFail")
    end
end

function XUiGridStrongholdPluginSet:OnLongClickBtnReduce(pressingTime)
    local subCount = XMath.Clamp(math.floor(pressingTime * AddCountPerPressTime), 0, self.Count)
    self:SubCount(subCount)
end

function XUiGridStrongholdPluginSet:OnClickBtnAdd()
    self:AddCount(1)
end

function XUiGridStrongholdPluginSet:OnClickBtnSub()
    self:SubCount(1)
end

function XUiGridStrongholdPluginSet:GetCount()
    return self.Count or 0
end

function XUiGridStrongholdPluginSet:AddCount(addCount)
    local costElectric = self.Plugin:GetCostElectricSingle() * addCount
    if not self.CheckCountCb(costElectric) then
        XUiManager.TipText("StrongholdPluginAddFail")
        return
    end

    local newCount = self.Count + addCount
    local countLimit = self.Plugin:GetCountLimit()
    if newCount > countLimit then
        XUiManager.TipText("StrongholdPluginAddOverLimit")
        return
    end

    self.Count = newCount
    self.CountChangeCb(costElectric)
    self:UpdateCount()
end

function XUiGridStrongholdPluginSet:SubCount(subCount)
    local newCount = self.Count - subCount
    if newCount < 0 then
        return
    end

    local costElectric = self.Plugin:GetCostElectricSingle() * subCount
    self.Count = newCount
    self.CountChangeCb(-costElectric)

    self:UpdateCount()
end

return XUiGridStrongholdPluginSet