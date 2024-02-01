
---@class XUiFurnitureCreateNew 制作家具
---@field InputFunitueCount UnityEngine.UI.InputField
local XUiFurnitureCreateNew = XClass(nil, "XUiFurnitureCreateNew")

local FurnitureCoinId = XDataCenter.ItemManager.ItemId.FurnitureCoin

function XUiFurnitureCreateNew:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self.GridInvestments = {}
    self:InitUi()
    self:InitCb()
end

function XUiFurnitureCreateNew:InitCb()
    self.BtnSelect.CallBack = function() 
        self:OnBtnSelectClick() 
    end
    
    self.BtnConfirm.CallBack = function() 
        self:OnBtnConfirmClick()
    end
    
    self.InputFunitueCount.onValueChanged:AddListener(function() 
        self:OnInputValueChanged()
    end)

    self.BtnReduce.CallBack = function()
        self:OnBtnReduceClick()
    end

    self.BtnMin.CallBack = function()
        self:OnBtnMinClick()
    end

    self.BtnMax.CallBack = function()
        self:OnBtnMaxClick()
    end

    self.BtnAdd.CallBack = function()
        self:OnBtnAddClick()
    end
end

function XUiFurnitureCreateNew:InitUi()
    self.OnSelectTypeIdsCb = handler(self, self.OnSelectTypeIds)
    self.CreateFurnitureCb = handler(self, self.CreateFurniture)
    self.CreateResponseCb = handler(self, self.OnCreateFurnitureResponse)
    
    --未选中时显示文本
    self.TxtSelectBtn = CS.XTextManager.GetText("FurnitureAddType")
    --家具最小消耗-最大消耗
    self.MinConsume, self.MaxConsume = XFurnitureConfigs.GetFurnitureCreateMinAndMax()
    --制作家具数量
    self.CreateCount = 0
    self.InputFunitueCount.text = tostring(self.CreateCount)
    --描述文本
    self.TxtEnoughDesc, self.TxtNotEnoughDesc = XUiHelper.GetText("DormBuildEnoughDesc"), XUiHelper.GetText("DormBuildNoEnoughDesc")
    
    self.RImgDrawingIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(FurnitureCoinId))
end

function XUiFurnitureCreateNew:Init()
    
end

function XUiFurnitureCreateNew:SetPanelActive(value)
    self.GameObject:SetActiveEx(value)
    if not value then
        return
    end
    self:RefreshView()
end

function XUiFurnitureCreateNew:HasSelectType()
    return not XTool.IsTableEmpty(self.SelectTypeIds)
end

function XUiFurnitureCreateNew:CheckCanAddSum()
    local totalCount = self:GetTotalPoint()
    local current = 0
    for _, v in pairs(self.GridInvestments) do
        current = current + v:GetCurrentSum()
    end
    
    return totalCount >= current + XFurnitureConfigs.Incresment
end

function XUiFurnitureCreateNew:CheckInvestNum()
    local current = 0
    for _, v in pairs(self.GridInvestments) do
        current = current + v:GetCurrentSum()
    end
    
    local ownCount = XDataCenter.ItemManager.GetCount(FurnitureCoinId)
    
    return ownCount >= current and current >= self.MaxConsume
end

--界面刷新总控
function XUiFurnitureCreateNew:RefreshView()
    self:RefreshInvestment()
    self:RefreshDetail()
end

--创建分配属性控件
function XUiFurnitureCreateNew:RefreshInvestment()
    local investmentList = XFurnitureConfigs.GetFurnitureAttrType()
    for i, config in ipairs(investmentList) do
        local grid = self.GridInvestments[i]
        if not grid then
            local ui = i == 1 and self.GridInvestment or XUiHelper.Instantiate(self.GridInvestment, self.PanelInvestment)
            grid = XUiGridInvestment.New(ui)
            grid:Init(config, self)
            self.GridInvestments[i] = grid
        end
    end
end

--界面刷新
function XUiFurnitureCreateNew:RefreshDetail()
    local selectType = self:HasSelectType()
    self.ImgItemIcon.gameObject:SetActiveEx(selectType)
    self:RefreshGridState(selectType, selectType)
    local selectTxt = selectType and "" or self.TxtSelectBtn
    local typeIcon, typeName
    if selectType then
        if #self.SelectTypeIds > 1 then
            typeName = XFurnitureConfigs.DefaultCreateName
            typeIcon = XFurnitureConfigs.DefaultIcon
        else
            local template = XFurnitureConfigs.GetFurnitureTypeById(self.SelectTypeIds[1])
            typeIcon = template.TypeIcon
            typeName = template.CategoryName
        end
        self.ImgItemIcon:SetRawImage(typeIcon)
    end
    self.TxtTypeName.text = typeName
    self.BtnSelect:SetNameByGroup(0, selectTxt)
    
    self:UpdateTotalNum()
end

--- 刷新分配属性控件状态
---@param state boolean 
--------------------------
function XUiFurnitureCreateNew:RefreshGridState(state, isSelect)
    for _, v in pairs(self.GridInvestments) do
        v:SetBtnState(state)
        if not isSelect then
            v:ResetSum()
        end
    end
end

--- 玩家数量后更新界面
---@param isMaxZero boolean 最大为0
--------------------------
function XUiFurnitureCreateNew:UpdateTotalNum(isMaxZero)
    local current = 0
    for _, v in pairs(self.GridInvestments) do
        current = current + v:GetCurrentSum()
        v:UpdateInfos()
    end
    
    self:UpdateCost(isMaxZero)
    local typeCount = (self.SelectTypeIds and #self.SelectTypeIds > 0) and #self.SelectTypeIds or 1
    local createCount = self.CreateCount > 0 and self.CreateCount or 0
    
    local minConsume = typeCount * createCount * self.MinConsume
    local curConsume = typeCount * createCount * current
    
    local enough = curConsume >= minConsume
    self.TxtDesc.text = enough and self.TxtEnoughDesc or self.TxtNotEnoughDesc
    self.BtnConfirm:SetDisable(not enough, enough)
    self:RefreshEdit(enough, isMaxZero, createCount)
end

--- 更新消耗
---@param isMaxZero boolean 最大为0
--------------------------
function XUiFurnitureCreateNew:UpdateCost(isMaxZero)
    local costCount, isEnough = self:GetCostFurnitureCoin(isMaxZero)
    
    self.TxtConsumeCount.text = isEnough and XUiHelper.GetText("DormBuildEnoughCount", costCount) 
            or XUiHelper.GetText("DormBuildNoEnoughCount", costCount)
end

--- 刷新编辑Ui状态
---@param enough boolean 货币是否足够
---@param isMaxZero boolean 最大为0
---@param createCount number 制作数量
--------------------------
function XUiFurnitureCreateNew:RefreshEdit(enough, isMaxZero, createCount)
    local notEnough = not enough
    local selectType = self:HasSelectType()
    local disableAdd = notEnough or not selectType
    self.BtnAdd:SetDisable(disableAdd, not disableAdd)
    self.BtnMax:SetDisable(disableAdd, not disableAdd)
    self.BtnMin:SetDisable(self.CreateCount <= 0, self.CreateCount > 0)
    local disableReduce = notEnough or self.CreateCount <= 1
    self.BtnReduce:SetDisable(disableReduce, not disableReduce)
    self.InputFunitueCount.interactable = enough
    
    local count = 0
    if not enough then
        count = createCount and createCount or 0
    else
        count = isMaxZero and 0 or self.CreateCount
    end
    self.InputFunitueCount.text = tostring(count)
end

--选择家具类型
function XUiFurnitureCreateNew:OnBtnSelectClick()
    local selectTypeIds = self.SelectTypeIds or {}
    XLuaUiManager.Open("UiFurnitureTypeSelect", selectTypeIds, nil, true, self.OnSelectTypeIdsCb)
end

--确认制作
function XUiFurnitureCreateNew:OnBtnConfirmClick()
    if not self:HasSelectType() then
        XUiManager.TipText("FurnitureChooseAType")
        return
    end
    
    local createCount = tonumber(self.InputFunitueCount.text)
    if not createCount or createCount <= 0 then
        XUiManager.TipText("DormBuildNotCount")
        return
    end
    
    local maxCount = XFurnitureConfigs.MaxTotalFurnitureCount
    local allCount = XDataCenter.FurnitureManager.GetAllFurnitureCount()

    if allCount + createCount > maxCount then
        XUiManager.TipText("DormFurnitureCreateLimitTips", nil, nil, allCount, maxCount)
        return
    end
    
    local _, enough = self:GetCostFurnitureCoin()
    if not enough then
        XUiManager.TipText("FurnitureZeroCoin")
        return
    end
    
    local isModifyTips = false --是否要提示地板天花板等数量多于1的提示
    for _, id in pairs(self.SelectTypeIds) do
        local cfg = XFurnitureConfigs.GetFurnitureTypeById(id)
        if cfg.MajorType == XFurnitureConfigs.MajorType.Refit and createCount > 1 then
            isModifyTips = true
            break
        end
    end

    if isModifyTips then
        XUiManager.DialogTip("", XUiHelper.GetText("DormBuildNotChangeCount"), nil, nil, self.CreateFurnitureCb)
    else
        self:CreateFurniture()
    end
end

--输入回调
function XUiFurnitureCreateNew:OnInputValueChanged()
    if XTool.IsTableEmpty(self.SelectTypeIds) then
        XUiManager.TipText("FurnitureSelectAType")
        return
    end

    if string.IsNilOrEmpty(self.InputFunitueCount.text) then
        self.InputFunitueCount.text = tostring(self.CreateCount)
        return
    end
    
    local createCount = tonumber(self.InputFunitueCount.text)

    if createCount <= 0 then
        XUiManager.TipText("DormBuildMinCount")
        self.InputFunitueCount.text = tostring(self.CreateCount)
        return
    end
    
    local typeCount = #self.SelectTypeIds

    if (createCount * typeCount) > XFurnitureConfigs.MaxCreateCount then
        self.InputFunitueCount.text = tostring(self.CreateCount)
        XUiManager.TipMsg(XUiHelper.GetText("DormBuildMaxCount", XFurnitureConfigs.MaxCreateCount))
        return
    end

    self.CreateCount = createCount
    self:UpdateTotalNum()
end

--减少一个
function XUiFurnitureCreateNew:OnBtnReduceClick()
    if not self:HasSelectType() then
        XUiManager.TipText("FurnitureSelectAType")
        return
    end
    if self.CreateCount <= 1 then
        XUiManager.TipText("DormBuildMinCount")
        return
    end
    
    self.CreateCount = self.CreateCount - 1
    self:UpdateTotalNum()
end

--最小
function XUiFurnitureCreateNew:OnBtnMinClick()
    self.CreateCount = 1
    self.InputFunitueCount.text = tostring(self.CreateCount)
    self:UpdateTotalNum()
end

--最大
function XUiFurnitureCreateNew:OnBtnMaxClick()
    if not self:HasSelectType() then
        XUiManager.TipText("FurnitureSelectAType")
        return
    end
    local maxBuild = self:GetMaxBuildCount()
    self.CreateCount = maxBuild > 0 and maxBuild or 1
    self:UpdateTotalNum(maxBuild <= 0)
end

--增加一个
function XUiFurnitureCreateNew:OnBtnAddClick()
    if not self:HasSelectType() then
        XUiManager.TipText("FurnitureSelectAType")
        return
    end
    
    local createCount = tonumber(self.InputFunitueCount.text)
    
    self.CreateCount = createCount > 0 and self.CreateCount  + 1 or 1
    local typeCount = (self.SelectTypeIds and #self.SelectTypeIds > 0) and #self.SelectTypeIds or 1

    if (self.CreateCount * typeCount) > XFurnitureConfigs.MaxCreateCount then
        self.CreateCount = math.floor(XFurnitureConfigs.MaxCreateCount / typeCount)
        XUiManager.TipMsg(XUiHelper.GetText("DormBuildMaxCount", XFurnitureConfigs.MaxCreateCount))
        return
    end
    
    self:UpdateTotalNum()
end

--- 选中家具回调
---@param typeIds number[] 家具类型列表
---@param suitIds number[] 套装列表
--------------------------
function XUiFurnitureCreateNew:OnSelectTypeIds(typeIds, suitIds)
    self.SelectTypeIds = typeIds
    self.CreateCount = 1

    if self.CreateCount * self.MinConsume <= XDataCenter.ItemManager.GetCount(FurnitureCoinId) then
        for _, v in pairs(self.GridInvestments) do
            if not v then
                goto continue
            end

            local sum = v:GetCurrentSum()
            if not XTool.IsNumberValid(sum) then
                v:OnBtnAddClick()
            end

            ::continue::
        end
    end
    
    self:RefreshDetail()
end

--- 获取家具币有效值
---@return number
--------------------------
function XUiFurnitureCreateNew:GetTotalPoint()
    local ownCount = XDataCenter.ItemManager.GetCount(FurnitureCoinId)
    return math.min(ownCount, self.MaxConsume)
end

--- 当前设置下，剩余家具币
---@return number
--------------------------
function XUiFurnitureCreateNew:GetPassableSum()
    local totalCount = self:GetTotalPoint()
    local current = 0
    for _, v in pairs(self.GridInvestments) do
        current = current + v:GetCurrentSum()
    end
    
    return math.max(totalCount - current, 0)
end

--- 制作家具消耗数量
---@param isMaxZero boolean 最大为0
---@return number, boolean
--------------------------
function XUiFurnitureCreateNew:GetCostFurnitureCoin(isMaxZero)
    local current = 0
    for _, v in pairs(self.GridInvestments) do
        current = current + v:GetCurrentSum()
    end
    
    local typeCount = self.SelectTypeIds and #self.SelectTypeIds or 0
    local count = isMaxZero and 0 or self.CreateCount
    local costCount = current * typeCount * count
    
    local ownCount = XDataCenter.ItemManager.GetCount(FurnitureCoinId)
    
    return costCount, ownCount >= costCount
end

--- 最大制作数量
---@return number
--------------------------
function XUiFurnitureCreateNew:GetMaxBuildCount()
    if XTool.IsTableEmpty(self.SelectTypeIds) then
        return 0
    end
    
    local current = 0
    for _, v in pairs(self.GridInvestments) do
        current = current + v:GetCurrentSum()
    end
    
    local ownCount = XDataCenter.ItemManager.GetCount(FurnitureCoinId)
    local typeCount = self.SelectTypeIds and #self.SelectTypeIds or 1
    local count = math.floor(ownCount / (typeCount * current))
    local maxCount = math.floor(XFurnitureConfigs.MaxCreateCount / typeCount)
    
    return math.min(count, maxCount)
end

--- 制作家具
--------------------------
function XUiFurnitureCreateNew:CreateFurniture()
    local costA, costB, costC = 0, 0, 0
    for _, v in pairs(self.GridInvestments) do
        local cfg, sum = v:GetCostDatas()
        if cfg.Id == XFurnitureConfigs.AttrType.AttrA then
            costA = sum
        elseif cfg.Id == XFurnitureConfigs.AttrType.AttrB then
            costB = sum
        elseif cfg.Id == XFurnitureConfigs.AttrType.AttrC then
            costC = sum
        end
    end
    self.GainType = XFurnitureConfigs.GainType.Create
    XUiHelper.LimitContinuousClick(self.BtnConfirm)
    XDataCenter.FurnitureManager.CreateFurniture(self.SelectTypeIds, self.CreateCount, costA, costB, costC, self.CreateResponseCb)
end

function XUiFurnitureCreateNew:OnCreateFurnitureResponse(furnitureList, createCoinCount)
    self.SelectTypeIds = {}
    self.CreateCount = 0
    self:RefreshDetail()
end

return XUiFurnitureCreateNew