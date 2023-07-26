
local XUiPanelReset = XClass(nil, "XUiPanelReset")
local CsColor = CS.UnityEngine.Color

function XUiPanelReset:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    
    self:InitUi()
    self:InitCb()
end

function XUiPanelReset:InitUi()
    --描述文本
    self.TxtEnoughDesc, self.TxtNotEnoughDesc = XUiHelper.GetText("DormResetEnoughDesc"), XUiHelper.GetText("DormResetNoEnoughDesc")
    --添加类型
    self.TxtAddType = XUiHelper.GetText("FurnitureAddItem")
    --重置家具最小消耗-最大消耗
    self.MinConsume, self.MaxConsume = XFurnitureConfigs.GetFurnitureCreateMinAndMax()
    
    self.GridInvestments = {}
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
    --家具币图标
    self.ImgDrawingIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XDataCenter.ItemManager.ItemId.FurnitureCoin))
    --选中家具
    self.FurnitureIds = {}
    
    self.OnSelectFurnitureCb = handler(self, self.OnSelectFurniture)
    self.OnRemakeRequestCb = handler(self, self.OnRemakeRequest)
    
end

function XUiPanelReset:InitCb()
    self.BtnConfirm.CallBack = function() 
        self:OnBtnConfirmClick()
    end
    
    self.BtnSelect.CallBack = function() 
        self:OnBtnSelectClick()
    end
end

function XUiPanelReset:OnBtnConfirmClick()
    if not self:HasSelectType() then
        XUiManager.TipText("DormFurnitureRecycelNull")
        return
    end
    
    if self:GetCoinCount() < self:GetResetCost() then
        XUiManager.TipText("FurnitureZeroCoin")
        return
    end

    --local selectIds, rejectIds = self:GetFilterFurnitureIds()
    
    local request = function()
        --local selectCount = #selectIds
        --if selectCount > XFurnitureConfigs.MaxRemakeCount then
        --    XUiManager.TipText("DormBuildMaxCount", nil, nil, XFurnitureConfigs.MaxRemakeCount)
        --    return
        --end

        for _, furnitureId in ipairs(self.FurnitureIds) do
            if XDataCenter.FurnitureManager.GetFurnitureIsLocked(furnitureId) then
                XUiManager.TipText("DormCannotRecycleLockFurniture")
                return
            end
        end

        local costA, costB, costC = self:GetABCPoint()
        XDataCenter.FurnitureManager.FurnitureRemake(self.FurnitureIds, costA, costB, costC, self.RoomId, self.OnRemakeRequestCb)

        --local realRequest = function()
        --    local costA, costB, costC = self:GetABCPoint()
        --    XDataCenter.FurnitureManager.FurnitureRemake(self.FurnitureIds, costA, costB, costC, self.RoomId, self.OnRemakeRequestCb)
        --end
        --if XTool.IsTableEmpty(rejectIds) then
        --    realRequest()
        --else
        --    XLuaUiManager.Open("UiFurnitureReCreateDetail", XUiHelper.GetText("FurnitureDontRemakeTip"), rejectIds, realRequest)
        --end
    end

    if self:CheckHasTargetLevel(self.FurnitureIds, XGoodsCommonManager.QualityType.Gold) then
        XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), XUiHelper.GetText("DormObtainLevelSReset"), nil, nil, request)
    else
        request()
    end
end

function XUiPanelReset:OnBtnSelectClick()
    
    XLuaUiManager.Open("UiDormBagChoice", self.FurnitureIds, 0, nil, self.OnSelectFurnitureCb)
end

function XUiPanelReset:Init(furnitureId, roomId)
    self.IsFromRoom = XTool.IsNumberValid(roomId)
    self.FurnitureIds = { furnitureId }
    self.RoomId = roomId
    
    self.BtnSelect:SetDisable(self.IsFromRoom, not self.IsFromRoom)
end

function XUiPanelReset:SetPanelActive(value)
    self.GameObject:SetActiveEx(value)
    if not value then
        return
    end
    self:ResetData()
    self:RefreshView()
end

function XUiPanelReset:ResetData()
    self.RewardKey = 0
    self.LastRewardKey = -1
    self.FilterKey = 0
    self.LastFilterKey = -1
    
    self.RejectFurnitureIds = {} --剔除家具列表
    self.SelectFurnitureIds = {} --选中家具列表
    self.RecycleCount = 0
end

function XUiPanelReset:RefreshView()
    local select = self:HasSelectType()
    self.HeadIcon.gameObject:SetActiveEx(select)
    self:RefreshGridState(select, select)
    local txtSelect = self.TxtAddType
    if select then
        local furnitureCount = #self.FurnitureIds
        local icon, name
        if furnitureCount == 1 then
            local furnitureId = self.FurnitureIds[1]
            local furniture = XDataCenter.FurnitureManager.GetFurnitureById(furnitureId)
            local template = XFurnitureConfigs.GetFurnitureTemplateById(furniture:GetConfigId())
            icon, name = template.Icon, template.Name
        else
            icon, name = XFurnitureConfigs.DefaultIcon, XFurnitureConfigs.DefaultResetName
        end
        self.ImgItemIcon:SetRawImage(icon)
        self.TxtTypeName.text = name
        txtSelect = ""
    end
    self.BtnSelect:SetNameByGroup(0, txtSelect)
    self:UpdateTotalNum()
end

--- 刷新分配属性控件状态
---@param state boolean
--------------------------
function XUiPanelReset:RefreshGridState(state, isSelect)
    for _, v in pairs(self.GridInvestments) do
        v:SetBtnState(state)
        if not isSelect then
            v:ResetSum()
        end
    end
end

function XUiPanelReset:HasSelectType()
    return not XTool.IsTableEmpty(self.FurnitureIds)
end

function XUiPanelReset:UpdateTotalNum()
    local ownCount = self:GetCoinCount()
    local costCount = self:GetResetCost()
    local enough = ownCount >= costCount
    self.TxtDesc.text = enough and self.TxtEnoughDesc or self.TxtNotEnoughDesc
    self.TxtConsumeCount.text = costCount
    self.TxtConsumeCount.color = enough and CsColor.black or CsColor.red
    
    local point = self:GetAllocatePoints()
    local disable = not (enough and point >= self.MinConsume and self:HasSelectType())
    self.BtnConfirm:SetDisable(disable, not disable)
end

function XUiPanelReset:CheckInvestNum()
    local current = self:GetAllocatePoints()
    local ownCount = self:GetCoinCount()
    
    return ownCount >= current and current >= self.MaxConsume
end

function XUiPanelReset:GetPassableSum()
    return math.max(self:GetTotalPoint() - self:GetAllocatePoints(), 0)
end

function XUiPanelReset:CheckCanAddSum()
    local current = self:GetAllocatePoints()
    
    return self:GetTotalPoint() >= current + XFurnitureConfigs.Incresment
end

function XUiPanelReset:OnSelectFurniture(furnitureIds)
    self.FurnitureIds = furnitureIds
    self:UpdateCacheKey()
    
    self:RefreshView()
end

function XUiPanelReset:GetCoinCount()
    return XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.FurnitureCoin)
end

--获取分配点数
function XUiPanelReset:GetAllocatePoints()
    local current = 0
    for _, grid in pairs(self.GridInvestments) do
        local point = grid and grid:GetCurrentSum() or 0
        current = current + point
    end
    return current
end

--- 剔除部分家具
---@return number[],number[]
--------------------------
function XUiPanelReset:GetFilterFurnitureIds()
    if not self:HasSelectType() then
        return {}, {}
    end

    if self.FilterKey == self.LastFilterKey then
        return self.SelectFurnitureIds, self.RejectFurnitureIds
    end
    --local ids, filterIds = {}, {}
    --local current = self:GetAllocatePoints()
    --for _, furnitureId in pairs(self.FurnitureIds) do
    --    local furniture = XDataCenter.FurnitureManager.GetFurnitureById(furnitureId)
    --    if furniture then
    --        local costA, costB, costC = furniture:GetBaseAttr()
    --        local attr = costA + costB + costC
    --        if current >= attr then
    --            table.insert(ids, furnitureId)
    --        else
    --            table.insert(filterIds, furnitureId)
    --        end
    --    end
    --end

    self.SelectFurnitureIds, self.RejectFurnitureIds = XDataCenter.FurnitureManager.FilterBeforeRemake(self.FurnitureIds, self:GetAllocatePoints())
    self.LastFilterKey = self.FilterKey
    return self.SelectFurnitureIds, self.RejectFurnitureIds
end

--回收返回货币数
function XUiPanelReset:GetRecycleCoinCount()
    if self.RewardKey == self.LastRewardKey then
        return self.RecycleCount
    end

    self.LastRewardKey = self.RewardKey
    if not self:HasSelectType() then
        self.RecycleCount = 0
        return self.RecycleCount
    end
    local furnitureIds, _ = self:GetFilterFurnitureIds()
    local rewards = XDataCenter.FurnitureManager.GetRecycleRewards(furnitureIds)
    local count = 0
    for _, reward in pairs(rewards) do
        if reward.TemplateId == XDataCenter.ItemManager.ItemId.FurnitureCoin then
            count = count + reward.Count
        end
    end
    self.RecycleCount = count
    
    return count
end

--回收消耗货币
function XUiPanelReset:GetResetCost()
    local furnitureIds, _ = self:GetFilterFurnitureIds()
    return math.max(0, self:GetAllocatePoints() * #furnitureIds - self:GetRecycleCoinCount())
end

--能够分配的点数
function XUiPanelReset:GetTotalPoint()
    return math.min(self:GetCoinCount(), self.MaxConsume)
end

--获取ABC,分别分配的点数
---@return number,number,number
function XUiPanelReset:GetABCPoint()
    local cA, cB, cC = 0, 0, 0
    for _, grid in pairs(self.GridInvestments) do
        local cfg, sum = grid:GetCostDatas()
        if cfg.Id == XFurnitureConfigs.AttrType.AttrA then
            cA = sum
        elseif cfg.Id == XFurnitureConfigs.AttrType.AttrB then
            cB = sum
        elseif cfg.Id == XFurnitureConfigs.AttrType.AttrC then
            cC = sum
        end
    end
    return cA, cB, cC
end

--分配点数
function XUiPanelReset:OnInvestmentChanged()
    self:UpdateCacheKey()
end

--采用缓存，避免每次都算一遍
function XUiPanelReset:UpdateCacheKey()
    if self.RewardKey then
        self.RewardKey = self.RewardKey + 1
    end

    if self.FilterKey then
        self.FilterKey = self.FilterKey + 1
    end
end

function XUiPanelReset:CheckHasTargetLevel(furnitureIds, targetLevel)
    if XTool.IsTableEmpty(furnitureIds) then
        return false
    end
    for _, furnitureId in pairs(furnitureIds) do
        local furniture = XDataCenter.FurnitureManager.GetFurnitureById(furnitureId)
        if furniture then
            if furniture:GetFurnitureTotalAttrLevel() >= targetLevel then
                return true
            end
        end
    end
    return false
end

function XUiPanelReset:OnRemakeRequest(furnitureList, count)
    self.FurnitureIds = {}
    self:RefreshView()
end


return XUiPanelReset