-- 资源
local XUiPanelRogueSimFluctuate = require("XUi/XUiRogueSim/Battle/Panel/XUiPanelRogueSimFluctuate")
---@class XUiGridRogueSimResource : XUiNode
---@field private _Control XRogueSimControl
local XUiGridRogueSimResource = XClass(XUiNode, "XUiGridRogueSimResource")

function XUiGridRogueSimResource:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnResource, self.OnBtnResourceClick)
    self.ImgAddition.gameObject:SetActiveEx(false)
    self.PanelFluctuations.gameObject:SetActiveEx(false)
    self.IsPrice = true
    self.Alignment = XEnumConst.RogueSim.Alignment.LC
    self.IsShowBubble = true
end

-- 设置显示状态
---@param isShowPrice boolean 是否显示价格
---@param isShowNum boolean 是否显示数量
---@param isShowFluctuations boolean 是否显示波动
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
        if not self.PanelFluctuationsUi then
            ---@type XUiPanelRogueSimFluctuate
            self.PanelFluctuationsUi = XUiPanelRogueSimFluctuate.New(self.PanelFluctuations, self)
        end
        self.PanelFluctuationsUi:Open()
        self.PanelFluctuationsUi:Refresh(id)
    end
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
