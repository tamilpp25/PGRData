local XUiDrawBuyAssert = XClass(nil, "XUiDrawBuyAssert")

local UiType = 15

local Application = CS.UnityEngine.Application
local Platform = Application.platform
local RuntimePlatform = CS.UnityEngine.RuntimePlatform

function XUiDrawBuyAssert:Ctor(rootUi, ui)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:InitAutoScript()
end

function XUiDrawBuyAssert:InitAutoScript()
    self.BtnConfirm.CallBack = function()
        self:OnBtnConfirmClick()
    end
    self.BtnTanchuangClose.CallBack = function()
        self:OnBtnCloseClick()
    end
    self.BtnCancel.CallBack = function()
        self:OnBtnCloseClick()
    end
end

function XUiDrawBuyAssert:Show()
    local data = XDataCenter.PurchaseManager.GetDatasByUiType(UiType)[1]
    self.CurData = data
    if not data then
        return
    end
    
    self.GameObject:SetActiveEx(true)
    --先显示目标物品
    local targetItemId
    local targeTotalCount = 0
    if data.RewardGoodsList and #data.RewardGoodsList > 0 then
        for _, v in pairs(data.RewardGoodsList) do
            targetItemId = v.TemplateId
            targeTotalCount = targeTotalCount + v.Count
        end
    end
    self.TxtTargetName.text = XDataCenter.ItemManager.GetItemName(targetItemId)
    self.ImgTarget:SetRawImage(XDataCenter.ItemManager.GetItemIcon(targetItemId))
    self.TxtTargetCount.text = targeTotalCount
    
    local consumeCount = 0
    --再显示兑换源
    if data.PayKeySuffix then
        local key
        if Platform == RuntimePlatform.Android then
            key = string.format("%s%s", XPayConfigs.GetPlatformConfig(1), data.PayKeySuffix)
        else
            key = string.format("%s%s", XPayConfigs.GetPlatformConfig(2), data.PayKeySuffix)
        end
        
        local payConfig = XPayConfigs.GetPayTemplate(key)
        consumeCount = payConfig.Amount
    end
    
    local path = CS.XGame.ClientConfig:GetString("PurchaseBuyRiYuanIconPath")
    self.ImgConsume:SetRawImage(path)
    self.TxtConsumeName.text = ""
    self.TxtConsumeCount.text = consumeCount
end

function XUiDrawBuyAssert:OnBtnConfirmClick()
    if self.CurData.PayKeySuffix then
        local key
        if Platform == RuntimePlatform.Android then
            key = string.format("%s%s", XPayConfigs.GetPlatformConfig(1), self.CurData.PayKeySuffix)
        else
            key = string.format("%s%s", XPayConfigs.GetPlatformConfig(2), self.CurData.PayKeySuffix)
        end
        self.GameObject:SetActiveEx(false)
        XDataCenter.PayManager.Pay(key, 1, { self.CurData.Id })
    end
end

function XUiDrawBuyAssert:OnBtnCloseClick()
    self.GameObject:SetActiveEx(false)
end

return XUiDrawBuyAssert