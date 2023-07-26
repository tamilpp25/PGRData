local XUiFightRollingNum = XLuaUiManager.Register(XLuaUi, "UiFightRollingNum")
local XUiFightRollingNumGrid = require("XUi/XUiFightRollingNum/XUiFightRollingNumGrid")
local tableInsert = table.insert
local math = math
local ipairs = ipairs

function XUiFightRollingNum:OnStart(itemId)
    --设置道具图标和数量
    local item = XDataCenter.ItemManager.GetItem(itemId)
    local count = XDataCenter.ItemManager.GetCount(itemId)
    self.TotalCount = count
    self.RImgItem:SetRawImage(item.Template.Icon)
    
    --初始化文本
    self.UiRollingNumGrids = {}
    local height = self.NumTxts.transform.rect.height
    local texts = self.NumTxts:GetComponentsInChildren(typeof(CS.UnityEngine.UI.Text))
    self.MaxShowCount = math.pow(10, texts.Length - 1) - 1
    self.MinShowCount = -self.MaxShowCount
    local totalShowCount = self:GetTotalShowCount()
    for i = 0, texts.Length - 1 do
        local grid = XUiFightRollingNumGrid.New(texts[i], height, i, totalShowCount)
        tableInsert(self.UiRollingNumGrids, grid)
    end
end

function XUiFightRollingNum:OnDestroy()
    for _, grid in ipairs(self.UiRollingNumGrids) do
        grid:OnDestroy()
    end
end

function XUiFightRollingNum:GetTotalShowCount()
    if self.TotalCount > self.MaxShowCount then
        return self.MaxShowCount
    end

    if self.TotalCount < self.MinShowCount then
        return self.MinShowCount
    end
    
    return self.TotalCount
end

function XUiFightRollingNum:AddTotalCount(count)
    if count == 0 then
        return
    end
    
    local oldTotalShowCount = self:GetTotalShowCount()
    self.TotalCount = self.TotalCount + count
    local newTotalShowCount = self:GetTotalShowCount()
    if oldTotalShowCount == newTotalShowCount then
        return
    end
    
    local sign = 0
    if newTotalShowCount > 0 then
        sign = 1
    elseif newTotalShowCount < 0 then
        sign = -1
    end
    
    local isOpposite = oldTotalShowCount * newTotalShowCount < 0
    newTotalShowCount = math.abs(newTotalShowCount) -- 保证TotalShowCount为非负数 统一处理不同情况
    
    if isOpposite then
        for _, grid in ipairs(self.UiRollingNumGrids) do
            grid:SetTotalShowCount(0, 0)
        end
    end

    for _, grid in ipairs(self.UiRollingNumGrids) do
        grid:SetTotalShowCount(newTotalShowCount, sign)
    end
end