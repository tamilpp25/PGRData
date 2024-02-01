-- 资源
---@class XUiGridRogueSimResource : XUiNode
---@field private _Control XRogueSimControl
local XUiGridRogueSimResource = XClass(XUiNode, "XUiGridRogueSimResource")

function XUiGridRogueSimResource:OnStart()
    self.ImgAddition.gameObject:SetActiveEx(false)
    XUiHelper.RegisterClickEvent(self, self.BtnResource, self.OnBtnResourceClick)
    self.IsPrice = true
    self.Alignment = XEnumConst.RogueSim.Alignment.LC
    self.IsShowBubble = true
end

-- 设置显示状态
function XUiGridRogueSimResource:SetShowStatus(isShowPrice, isShowNum, isShowFluctuations)
    self.IsShowPrice = isShowPrice or false
    self.IsShowNum = isShowNum or false
    self.IsShowFluctuations = isShowFluctuations or false
    self.PanelPrice.gameObject:SetActiveEx(self.IsShowPrice)
    self.TxtNum.gameObject:SetActiveEx(self.IsShowNum)
    self.PanelFluctuations.gameObject:SetActiveEx(self.IsShowFluctuations)
end

-- 设置产量回合结算数据
function XUiGridRogueSimResource:SetProduceData(produceCount, produceIsCritical)
    self.IsTurnSettle = true
    -- 产出数量
    self.ProduceCount = produceCount or 0
    -- 产出暴击
    self.ProduceIsCritical = produceIsCritical or false
end

-- 设置产量弹框
function XUiGridRogueSimResource:SetProduceBubble()
    self.IsPrice = false
end

-- 设置弹框位置
function XUiGridRogueSimResource:SetRCBubble()
    self.Alignment = XEnumConst.RogueSim.Alignment.RC
end

-- 不显示弹框
function XUiGridRogueSimResource:HideBubble()
    self.IsShowBubble = false
end

---@param id number 货物Id
function XUiGridRogueSimResource:Refresh(id)
    self.Id = id
    -- 货物图标
    self.RawImage:SetRawImage(self._Control.ResourceSubControl:GetCommodityIcon(id))
    -- 价格
    if self.IsShowPrice then
        -- 金币图标
        local goldId = XEnumConst.RogueSim.ResourceId.Gold
        self.RImgCoin:SetRawImage(self._Control.ResourceSubControl:GetResourceIcon(goldId))
        self.TxtPrice.text = self._Control.ResourceSubControl:GetCommodityTotalPrice(id)
    end
    -- 产量
    if self.IsShowNum then
        local produceRate = 0
        if self.IsTurnSettle then
            produceRate = self.ProduceCount
            self.ImgAddition.gameObject:SetActiveEx(self.ProduceIsCritical)
            local color = self._Control:GetClientConfig("RoundStarProduceColor", 1)
            self.TxtNum.color = XUiHelper.Hexcolor2Color(color)
            -- 播放暴击动画
            if self.ProduceIsCritical then
                self:PlayAnimation("NewRecordEnable")
            end
        else
            produceRate = self._Control.ResourceSubControl:GetCommodityTotalProduceRate(id)
        end
        self.TxtNum.text = string.format("x%d", produceRate)
    end
    -- 波动
    if self.IsShowFluctuations then
        -- 货物价格波动值（万分比）
        local priceRate = self._Control.ResourceSubControl:GetCommodityPriceRate(id)
        -- 价格波动百分比
        local percentage = priceRate / 100
        -- 保留一位小数
        percentage = self._Control.ResourceSubControl:ConvertNumberToInteger(percentage, 1)
        self.TxtFluctuationsUp.gameObject:SetActiveEx(percentage >= 0)
        self.TxtFluctuationsDown.gameObject:SetActiveEx(percentage < 0)
        if percentage >= 0 then
            local prefix = percentage > 0 and "+" or ""
            self.TxtFluctuationsUp.text = self:AddPrefixAndSuffix(percentage, prefix)
        else
            self.TxtFluctuationsDown.text = self:AddPrefixAndSuffix(percentage)
        end
    end
end

-- 添加前后缀
function XUiGridRogueSimResource:AddPrefixAndSuffix(value, prefix, suffix)
    return string.format("%s%s%s", prefix or "", value, suffix or "%")
end

function XUiGridRogueSimResource:OnBtnResourceClick()
    if not self.IsShowBubble then
        return
    end
    XLuaUiManager.Open("UiRogueSimComponent", XEnumConst.RogueSim.BubbleType.Property, self.Transform, self.Id, {
        IsPrice = self.IsPrice,
        Alignment = self.Alignment,
    })
end

return XUiGridRogueSimResource
