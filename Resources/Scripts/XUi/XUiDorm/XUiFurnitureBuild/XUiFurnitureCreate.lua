-- 家具建造子界面
local XUiFurnitureCreate = XLuaUiManager.Register(XLuaUi, "UiFurnitureCreate")

function XUiFurnitureCreate:OnAwake()
    self.GridInvestmentPool = {}
    self.SelectTypeIds = nil
    self.FurnitrueCreateCount = 0
end

function XUiFurnitureCreate:OnBtnCancelClick()
    self:Close()
end

function XUiFurnitureCreate:OnBtnStartClick()
    if not self.SelectTypeIds or #self.SelectTypeIds <= 0 then
        XUiManager.TipMsg(CS.XTextManager.GetText("FurnitureChooseAType"))
        return
    end

    local textNum = tonumber(self.InputFunitueCount.text)
    if not textNum or textNum <= 0 then
        XUiManager.TipMsg(CS.XTextManager.GetText("DormBuildNotCount"))
        return
    end

    local _, isEnough = self:GetCostFurnitureCoin()
    if not isEnough then
        XUiManager.TipMsg(CS.XTextManager.GetText("FurnitureZeroCoin"))
        return
    end

    local isModifyTips = false --是否要提示地板天花板等数量多于1的提示
    for _, id in ipairs(self.SelectTypeIds) do
        local cfg = XFurnitureConfigs.GetFurnitureTypeById(id)
        if cfg.MajorType == XFurnitureConfigs.MajorType.Refit then
            isModifyTips = textNum > 1
            break
        end
    end
    if isModifyTips then
        CsXUiManager.Instance:Open("UiDialog", nil, CS.XTextManager.GetText("DormBuildNotChangeCount"), XUiManager.DialogType.Normal, nil, function() self:CreateFurniture() end)
    else
        self:CreateFurniture()
    end
end

function XUiFurnitureCreate:CreateFurniture()
    local costA = 0
    local costB = 0
    local costC = 0
    for i = 1, #self.InvestmentCfg do
        local investmentItem = self.GridInvestmentPool[i]
        local cfg, sum = investmentItem:GetCostDatas()
        if cfg.Id == XFurnitureConfigs.AttrType.AttrA then
            costA = sum
        elseif cfg.Id == XFurnitureConfigs.AttrType.AttrB then
            costB = sum
        elseif cfg.Id == XFurnitureConfigs.AttrType.AttrC then
            costC = sum
        end
    end
    -- update界面，关闭界面
    XDataCenter.FurnitureManager.CreateFurniture(self.SelectPos, self.SelectTypeIds, self.FurnitrueCreateCount, costA, costB, costC, function()
            XUiManager.TipText("FurnitureBuildStart")
            if self.CallBack then
                self.CallBack(self.SelectPos)
            end
            if XTool.UObjIsNil(self.GameObject) then return end
            self:Close()
        end)
end

function XUiFurnitureCreate:OnStart(typeId, createCount, pos, callBack)
    self.BtnTanchuangClose.CallBack = function() self:OnBtnCancelClick() end
    self.BtnStart.CallBack = function() self:OnBtnStartClick() end
    self.BtnSelect.CallBack = function() self:OnBtnSelectClick() end
    self.BtnReduce.CallBack = function() self:OnBtnReduceClick() end
    self.BtnAdd.CallBack = function() self:OnBtnAddClick() end
    self.BtnMax.CallBack = function() self:OnBtnMaxClick() end
    self.InputFunitueCount.onValueChanged:AddListener(function()
        self:OnInputValueChanged()
    end)
    self.CallBack = callBack
    self:ShowPanelCreationDetail()

    if typeId then
        self:SetSelectType({ typeId }, nil, createCount)
    end
end

function XUiFurnitureCreate:OnInputValueChanged()
    if not self.SelectTypeIds then
        return
    end

    if not self.InputFunitueCount.text or self.InputFunitueCount.text == "" then
        self.InputFunitueCount.text = tostring(self.FurnitrueCreateCount)
        return
    end

    local textNum = tonumber(self.InputFunitueCount.text)
    if not self:CheckCanChangeNum() then
        XUiManager.TipMsg(CS.XTextManager.GetText("DormBuildNotChangeCount"))
        self.InputFunitueCount.text = tostring(self.FurnitrueCreateCount)
        return
    end

    if textNum < 1 then
        XUiManager.TipMsg(CS.XTextManager.GetText("DormBuildMinCount"))
        self.InputFunitueCount.text = tostring(self.FurnitrueCreateCount)
        return
    end

    local typeCount = (self.SelectTypeIds and #self.SelectTypeIds > 0) and #self.SelectTypeIds or 1
    if (textNum * typeCount) > XFurnitureConfigs.MaxCreateCount then
        self.InputFunitueCount.text = tostring(self.FurnitrueCreateCount)
        XUiManager.TipMsg(CS.XTextManager.GetText("DormBuildMaxCount", XFurnitureConfigs.MaxCreateCount))
        return
    end

    self.FurnitrueCreateCount = textNum
    self:UpdateTotalNum()
end

function XUiFurnitureCreate:OnBtnReduceClick()
    if self.BtnReduceDisable then
        return
    end

    if self.FurnitrueCreateCount <= 1 then
        XUiManager.TipMsg(CS.XTextManager.GetText("DormBuildMinCount"))
        return
    end

    self.FurnitrueCreateCount = self.FurnitrueCreateCount - 1
    self:UpdateTotalNum()
end

function XUiFurnitureCreate:OnBtnAddClick()
    if self.BtnAddDisable then
        return
    end

    if not self:CheckCanChangeNum() then
        XUiManager.TipMsg(CS.XTextManager.GetText("DormBuildNotChangeCount"))
        return
    end

    local textNum = tonumber(self.InputFunitueCount.text)
    self.FurnitrueCreateCount = textNum > 0 and self.FurnitrueCreateCount + 1 or 1
    local typeCount = (self.SelectTypeIds and #self.SelectTypeIds > 0) and #self.SelectTypeIds or 1

    if (self.FurnitrueCreateCount * typeCount) > XFurnitureConfigs.MaxCreateCount then
        self.FurnitrueCreateCount = math.floor(XFurnitureConfigs.MaxCreateCount / typeCount)
        XUiManager.TipMsg(CS.XTextManager.GetText("DormBuildMaxCount", XFurnitureConfigs.MaxCreateCount))
        return
    end

    self:UpdateTotalNum()
end

function XUiFurnitureCreate:OnBtnMaxClick()
    if self.BtnMaxDisable then
        return
    end

    if not self:CheckCanChangeNum() then
        XUiManager.TipMsg(CS.XTextManager.GetText("DormBuildNotChangeCount"))
        return
    end

    local max = self:GetMaxBuildCount()
    self.FurnitrueCreateCount = max > 0 and max or 1
    self:UpdateTotalNum(max <= 0)
end

function XUiFurnitureCreate:CheckCanChangeNum()
    --[[
    for _, id in ipairs(self.SelectTypeIds) do
        local cfg = XFurnitureConfigs.GetFurnitureTypeById(id)
        if cfg.MajorType == XFurnitureConfigs.MajorType.Refit then
            return false
        end
    end
    ]]
    return true
end

function XUiFurnitureCreate:SetPanelActive(value)
    self.GameObject:SetActive(value)
end

--显示制造家具详情UI
function XUiFurnitureCreate:ShowPanelCreationDetail(pos)
    self.SelectPos = pos or 0

    local maxCreateNum = CS.XGame.Config:GetInt("DormFurnitureCreateNum")
    for i = 0, maxCreateNum, 1 do
        local furnitureCreateData = XDataCenter.FurnitureManager.GetFurnitureCreateItemByPos(i)
        if not furnitureCreateData then
            self.SelectPos = i
            break
        end
    end

    --清除上一个状态
    self.SelectTypeIds = nil
    self.FurnitrueCreateCount = 0

    self.PanelCreationDetail.gameObject:SetActive(true)
    self.ImgAdd.gameObject:SetActive(true)
    self:UpdateCreationDetail()
    local icon = XDataCenter.ItemManager.GetItemIcon(XDataCenter.ItemManager.ItemId.FurnitureCoin)
    self.RImgFurnitureCoinIcon:SetRawImage(icon)

    self.BtnSelect:SetNameByGroup(0, CS.XTextManager.GetText("FurnitureAddType"))
end

-- 制造家具详情ui界面设置
function XUiFurnitureCreate:UpdateCreationDetail(isIgnoreUpdateInvesment, createCount)
    if not isIgnoreUpdateInvesment then
        self.InvestmentCfg = XFurnitureConfigs.GetFurnitureAttrType()
        local onCreate = function(grid, data)
            grid:Init(data, self)
        end
        XUiHelper.CreateTemplates(self, self.GridInvestmentPool, self.InvestmentCfg,
        XUiGridInvestment.New, self.GridInvestment, self.PanelInvestment, onCreate)
        self.GridInvestment.gameObject:SetActive(false)
    end

    self:UpdateCostCount()
    local typeName = ""
    local icon
    self.HeadIcon.gameObject:SetActive(self.SelectTypeIds ~= nil)
    self.ImgItemIcon.gameObject:SetActive(self.SelectTypeIds ~= nil)
    if self.SelectTypeIds then
        if #self.SelectTypeIds <= 1 then
            local furnitureTypeTemplate = XFurnitureConfigs.GetFurnitureTypeById(self.SelectTypeIds[1])
            typeName = furnitureTypeTemplate.CategoryName
            icon = furnitureTypeTemplate.TypeIcon
        else
            typeName = XFurnitureConfigs.DefaultName
            icon = XFurnitureConfigs.DefaultIcon
        end

        self.ImgItemIcon:SetRawImage(icon)
        self:SetInvestBtnsState(true)
    else
        self:SetInvestBtnsState(false)
    end
    self.TxtTypeName.text = typeName
    self:UpdateTotalNum(nil, createCount)
end

function XUiFurnitureCreate:UpdateCostCount(isMaxZero)
    local costCount, isEnough = self:GetCostFurnitureCoin(isMaxZero)
    local textManager = CS.XTextManager
    self.TxtFurnitureCoinCount.text = isEnough and textManager.GetText("DormBuildEnoughCount", costCount)
    or textManager.GetText("DormBuildNoEnoughCount", costCount)
end

function XUiFurnitureCreate:SetInvestBtnsState(state)
    for _, v in pairs(self.GridInvestmentPool) do
        if v then
            v:SetBtnState(state)
        end
    end
end

-- 获得所有家具币-建造加多少币有么有限制
function XUiFurnitureCreate:GetTotalFurnitureCoin()
    local _, maxConsume = XFurnitureConfigs.GetFurnitureCreateMinAndMax()
    local currentOwn = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.FurnitureCoin)

    return (currentOwn >= maxConsume) and maxConsume or currentOwn
end

-- 获得当前消耗家具币数量
function XUiFurnitureCreate:GetCostFurnitureCoin(isMaxZero)
    local currentSum = 0
    for _, v in pairs(self.GridInvestmentPool) do
        currentSum = currentSum + v:GetCurrentSum()
    end

    local typeCount = self.SelectTypeIds and #self.SelectTypeIds or 0
    local createCount = isMaxZero and 0 or self.FurnitrueCreateCount
    local costCount = currentSum * typeCount * createCount
    local currentOwn = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.FurnitureCoin)

    local isEnough = currentOwn >= costCount
    return costCount, isEnough
end

-- 获取最大建造数量
function XUiFurnitureCreate:GetMaxBuildCount()
    if not self.SelectTypeIds or #self.SelectTypeIds <= 0 then
        return 0
    end

    local currentSum = 0
    for _, v in pairs(self.GridInvestmentPool) do
        currentSum = currentSum + v:GetCurrentSum()
    end

    local currentOwn = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.FurnitureCoin)
    local count = math.floor(currentOwn / (#self.SelectTypeIds * currentSum))
    local maxCount = math.floor(XFurnitureConfigs.MaxCreateCount / #self.SelectTypeIds)
    if count > maxCount then
        count = maxCount
    end

    return count
end

-- 检查是否可以投入
function XUiFurnitureCreate:CheckCanAddSum()
    local totalNum = self:GetTotalFurnitureCoin()
    local currentSum = 0
    for _, v in pairs(self.GridInvestmentPool) do
        currentSum = currentSum + v:GetCurrentSum()
    end
    currentSum = currentSum

    local incresment = XFurnitureConfigs.Incresment
    return totalNum >= currentSum + incresment
end

-- 可以投入的最大数量
function XUiFurnitureCreate:GetPassableSum()
    local totalNum = self:GetTotalFurnitureCoin()
    local currentSum = 0
    for _, v in pairs(self.GridInvestmentPool) do
        currentSum = currentSum + v:GetCurrentSum()
    end
    if totalNum > currentSum then
        return totalNum - currentSum
    end
    return 0
end

function XUiFurnitureCreate:CheckInverstNum()
    local currentSum = 0
    for _, v in pairs(self.GridInvestmentPool) do
        currentSum = currentSum + v:GetCurrentSum()
    end

    local currentOwn = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.FurnitureCoin)
    local _, maxConsume = XFurnitureConfigs.GetFurnitureCreateMinAndMax()
    return currentOwn - currentSum >= 0 and currentSum >= maxConsume
end

function XUiFurnitureCreate:UpdateTotalNum(isMaxZero)
    local currentSum = 0
    for _, v in pairs(self.GridInvestmentPool) do
        currentSum = currentSum + v:GetCurrentSum()
        v:UpdateInfos()
    end

    self:UpdateCostCount(isMaxZero)
    local minConsume, _ = XFurnitureConfigs.GetFurnitureCreateMinAndMax()
    local typeCount = (self.SelectTypeIds and #self.SelectTypeIds > 0) and #self.SelectTypeIds or 1
    local createCount = self.FurnitrueCreateCount > 0 and self.FurnitrueCreateCount or 1
    minConsume = typeCount * createCount * minConsume
    currentSum = currentSum * typeCount * createCount

    local notEnought = minConsume > currentSum
    local desc = notEnought and CS.XTextManager.GetText("DormBuildNoEnoughDesc") or CS.XTextManager.GetText("DormBuildEnoughDesc")
    self.TxtDesc.text = desc
    self.BtnStart:SetDisable(notEnought, not notEnought)
    self:UpdateCountEdit(notEnought, isMaxZero, createCount)
end

function XUiFurnitureCreate:UpdateCountEdit(notEnought, isMaxZero, createCount)
    if notEnought then
        self.BtnMaxDisable = notEnought
        self.BtnAddDisable = notEnought
        self.BtnReduceDisable = notEnought
        self.BtnReduce:SetDisable(notEnought)
        self.BtnAdd:SetDisable(notEnought)
        self.BtnMax:SetDisable(notEnought)
        self.InputFunitueCount.interactable = not notEnought
        local count = createCount and createCount or 0
        self.InputFunitueCount.text = count
        return
    end

    self.BtnReduce:SetDisable(self.FurnitrueCreateCount <= 1)
    self.BtnAdd:SetDisable(false)
    self.BtnMax:SetDisable(false)
    self.BtnMaxDisable = false
    self.BtnAddDisable = false
    self.BtnReduceDisable = self.FurnitrueCreateCount <= 1
    self.InputFunitueCount.interactable = true
    self.InputFunitueCount.text = isMaxZero and 0 or self.FurnitrueCreateCount
end

-- 选择TypeId
function XUiFurnitureCreate:OnBtnSelectClick()
    local selectTypeIds = self.SelectTypeIds or {}
    XLuaUiManager.Open("UiFurnitureTypeSelect", selectTypeIds, nil, true, handler(self, self.SetSelectType))
end

function XUiFurnitureCreate:SetSelectType(typeIds, suitId, createCount)
    self.SelectTypeIds = typeIds
    self.BtnSelect:SetNameByGroup(0, "")
    local count = 1
    if createCount and createCount > 1 then
        count = createCount
    end
    self.FurnitrueCreateCount = count
    self.ImgAdd.gameObject:SetActive(false)
    self:UpdateCreationDetail(true, createCount)
end

function XUiFurnitureCreate:HasSelectType()
    return self.SelectTypeIds ~= nil
end

return XUiFurnitureCreate