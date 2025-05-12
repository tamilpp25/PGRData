local XUiButtonLongClick = require("XUi/XUiCommon/XUiButtonLongClick")
local XUiCoinPackage = XClass(nil, "XUiCoinPackage")
local COINPACKAGE_OVER_NUM_TIP = CS.XTextManager.GetText("ChoiseNutPackageOver")
local REWARD_CONFIG_INDEX = 2
local MINUS_LONG_TRIGGER_TIME = 300

function XUiCoinPackage:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    -- 当前的item信息
    self.Item = nil
    self.Index = 0
    self.UseCoinPackageUi = nil
    self.EffectNum = 0
    XTool.InitUiObject(self)
    -- 重新注册下ui组件名字
    self.BtnSelf = self.BtnClick
    self.BtnMinus = self.BtnMinusSelect
    self.TxtSelectCount = self.TxtSelectHide
    self:RegisterUiEvents()
    -- 螺母包目前没有时间限制
    self.TimeTag.gameObject:SetActiveEx(false)
end

-- useCoinPackageUi:XUiUseCoinPackage
function XUiCoinPackage:DynamicSetData(item, index, useCoinPackageUi)
    self.Item = item
    self.Index = index
    self.UseCoinPackageUi = useCoinPackageUi
    local rewards = XRewardManager.GetRewardList(item.Data.Template.SubTypeParams[REWARD_CONFIG_INDEX])
    self.EffectNum = rewards[1].Count
    -- 设置图标
    local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(item.Data.Id)
    self.RImgIcon:SetRawImage(goodsShowParams.Icon)
    -- 物品数量
    self.TxtCount.text = CS.XTextManager.GetText("ShopGridCommonCount", item.Count)
    -- 品质
    if goodsShowParams.QualityIcon then
        useCoinPackageUi:SetUiSprite(self.ImgQuality, goodsShowParams.QualityIcon)
    else
        XUiHelper.SetQualityIcon(useCoinPackageUi, self.ImgQuality, goodsShowParams.Quality)
    end
    self:SetSelectedGosActive(false)
end

function XUiCoinPackage:OnSelfClicked()
    local currentSelectCount = self.UseCoinPackageUi:GetSelectItemCount(self.Index)
    if currentSelectCount >= self.Item.Count then
        XUiManager.TipMsg(COINPACKAGE_OVER_NUM_TIP)
        return 
    end
    self:SetSelectCount(currentSelectCount + 1)
end

--######################## 私有方法 ########################

function XUiCoinPackage:RegisterUiEvents()
    self.BtnSelf.CallBack = function() self:OnSelfClicked() end
    -- 添加长按事件
    local btnSelfClickPointer = self.BtnSelf.gameObject:GetComponent("XUiPointer")
    XUiButtonLongClick.New(btnSelfClickPointer, 90, self, nil, self.OnBtnSelfLongClick, nil, true)
    local btnMinusPointer = self.BtnMinus.gameObject:GetComponent("XUiPointer")
    XUiButtonLongClick.New(btnMinusPointer, 10, self, nil, self.OnBtnMinusLongClick, nil, true)
    self.BtnMinus.CallBack = function() self:OnBtnMinusClicked() end
end

function XUiCoinPackage:OnBtnSelfLongClick(time)
    local currentSelectCount = self.UseCoinPackageUi:GetSelectItemCount(self.Index)
    if currentSelectCount >= self.Item.Count then
        XUiManager.TipMsg(COINPACKAGE_OVER_NUM_TIP)
        return
    end
    self:SetSelectCount(currentSelectCount + 1)
end

function XUiCoinPackage:SetSelectCount(count)
    self.UseCoinPackageUi:CacheSelectItemCount(self.Index, count, self.EffectNum)
    self:SetSelectedGosActive(count > 0)
    self.BtnMinus:SetButtonState(CS.UiButtonState.Normal)
    self.TxtSelectCount.text = count
end

function XUiCoinPackage:SetSelectedGosActive(isActive)
    self.TxtSelectCount.gameObject:SetActiveEx(isActive)
    self.BtnMinus.gameObject:SetActiveEx(isActive)
    self.ImgSelect.gameObject:SetActiveEx(isActive)
end

function XUiCoinPackage:OnBtnMinusClicked()
    local currentSelectCount = self.UseCoinPackageUi:GetSelectItemCount(self.Index)
    if currentSelectCount <= 0 then
        return
    end
    self:SetSelectCount(currentSelectCount - 1)
end

function XUiCoinPackage:OnBtnMinusLongClick(time)
    if time <= MINUS_LONG_TRIGGER_TIME then
        return 
    end
    local currentSelectCount = self.UseCoinPackageUi:GetSelectItemCount(self.Index)
    if currentSelectCount <= 0 then
        return
    end
    self:SetSelectCount(0)
end

return XUiCoinPackage