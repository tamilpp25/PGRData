-- 建造家具，家具币选择
XUiGridInvestment = XClass(nil, "XUiGridInvestment")

local incresment = CS.XGame.ClientConfig:GetInt("FurnitureInvestmentIncreaseStep")

function XUiGridInvestment:Ctor(rootUi, ui)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.CurrentSum = 0
    XTool.InitUiObject(self)

    self:AddBtnsListeners()
end

function XUiGridInvestment:AddBtnsListeners()
    self.AutoCreateListeners = {}
    XUiHelper.RegisterClickEvent(self, self.BtnReduce, self.OnBtnReduceClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAdd, self.OnBtnAddClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMax, self.OnBtnMaxClick)
end

function XUiGridInvestment:OnBtnReduceClick()
    if not self.Parent then return end
    if not self.Parent:HasSelectType() then
        XUiManager.TipMsg(CS.XTextManager.GetText("FurnitureSelectAType"))
        return
    end

    if self.CurrentSum - incresment <= 0 then
        self.CurrentSum = 0
    else
        self.CurrentSum = self.CurrentSum - incresment
    end

    self:SetSumText(self.CurrentSum)
    self.Parent:UpdateTotalNum()
end

function XUiGridInvestment:OnBtnAddClick()
    if not self.Parent then return end
    if not self.Parent:HasSelectType() then
        XUiManager.TipMsg(CS.XTextManager.GetText("FurnitureSelectAType"))
        return
    end

    if self.Parent:CheckCanAddSum() then
        self.CurrentSum = self.CurrentSum + incresment
        self:SetSumText(self.CurrentSum)
        self.Parent:UpdateTotalNum()
    else
        local isEngouth = self.Parent:CheckInverstNum()
        if isEngouth then
            XUiManager.TipMsg(CS.XTextManager.GetText("FurnitureMaxCoin"))
        else
            XUiManager.TipMsg(CS.XTextManager.GetText("FurnitureZeroCoin"))
        end
    end
end

function XUiGridInvestment:OnBtnMaxClick()
    if not self.Parent then return end
    if not self.Parent:HasSelectType() then
        XUiManager.TipMsg(CS.XTextManager.GetText("FurnitureSelectAType"))
        return
    end

    if self.Parent:CheckCanAddSum() then
        local extraNum = self.Parent:GetPassableSum()
        self.CurrentSum = self.CurrentSum + extraNum
        self:SetSumText(self.CurrentSum)
        self.Parent:UpdateTotalNum()
    else
        local isEngouth = self.Parent:CheckInverstNum()
        if isEngouth then
            XUiManager.TipMsg(CS.XTextManager.GetText("FurnitureMaxCoin"))
        else
            XUiManager.TipMsg(CS.XTextManager.GetText("FurnitureZeroCoin"))
        end
    end
end

function XUiGridInvestment:RegisterListener(uiNode, eventName, func)
    if not uiNode then return end
    local key = eventName .. uiNode:GetHashCode()
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiBtnTab:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiGridInvestment:GetCurrentSum()
    return self.CurrentSum or 0
end

function XUiGridInvestment:Init(cfg, parent)
    self.Parent = parent
    self.Cfg = cfg

    self.CurrentSum = 0
    self:SetSumText(self.CurrentSum)
    self.RootUi:SetUiSprite(self.ImgAttributeIcon, self.Cfg.TypeIcon)
    self.TxtAttributeName.text = self.Cfg.TypeName

    self:UpdateInfos()

end

function XUiGridInvestment:UpdateInfos()
    if not self.Parent then return end

    self.BtnReduce.interactable = not (self.CurrentSum <= 0)
end

function XUiGridInvestment:SetBtnState(state)
    self.BtnAdd.interactable = state
    self.BtnMax.interactable = state
end

function XUiGridInvestment:GetCostDatas()
    return self.Cfg, self.CurrentSum
end

function XUiGridInvestment:SetSumText(num)

    if self.Parent:HasSelectType() and num > 0 then
        self.TxtSum.text = ""
        self.TxtSumOn.text = num
        self.TxtAttributeName.text = ""
        self.TxtAttributeNameOn.text = self.Cfg and self.Cfg.TypeName or ""
    else
        self.TxtSum.text = num
        self.TxtSumOn.text = ""
        self.TxtAttributeName.text = self.Cfg and self.Cfg.TypeName or ""
        self.TxtAttributeNameOn.text = ""
    end

end

return XUiGridInvestment