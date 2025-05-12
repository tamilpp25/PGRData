
local XUiGrid3DBase = require("XUi/XUiRestaurant/XUiGrid/XUiGrid3DBase")

local ColorEnum = {
    Pause = XUiHelper.Hexcolor2Color("ff0000"),
    Working = XUiHelper.Hexcolor2Color("ffffff"),
}

---@class XUiGrid3DWorkBench : XUiGrid3DBase
---@field ImgQuality UnityEngine.UI.Image
---@field RImgIcon UnityEngine.UI.RawImage
---@field ImgFull UnityEngine.UI.Image
---@field TxtCount UnityEngine.UI.Text
---@field Add UnityEngine.UI.RawImage
---@field BtnClick XUiComponent.XUiButton
---@field ViewModel XBenchViewModel
local XUiGrid3DWorkBench = XClass(XUiGrid3DBase, "XUiGrid3DWorkBench")

function XUiGrid3DWorkBench:InitCb()
    self.BtnClick.CallBack = function() 
        self:OnBtnClick()
    end
end

--- 显示格子
---@param viewModel XBenchViewModel
---@return void
--------------------------
function XUiGrid3DWorkBench:Show(viewModel)
    self.ViewModel = viewModel
    self:BindViewModel(viewModel)
    XUiGrid3DBase.Show(self)
end

function XUiGrid3DWorkBench:OnDestroy()
    if self.ViewModel then
        self.ViewModel:ClearBind(self.GameObject:GetHashCode())
    end
end

--- 刷新工作台显示
--------------------------
function XUiGrid3DWorkBench:OnRefresh()
    if not self.ViewModel then
        return
    end
    local state = self.ViewModel:GetClientState()
    self.CurState = state
    if self.CurState ~= self.LastState then
        self:OnGlobalUpdate(self.ViewModel, state)
    else
        self:OnLocalUpdate(self.ViewModel, state)
    end
    self:RefreshRedPoint()
end

--- 全局更新
---@param viewModel XBenchViewModel
function XUiGrid3DWorkBench:OnGlobalUpdate(viewModel, state)
    if not viewModel then
        return
    end
    local isRunning = viewModel:IsRunning()
    self.RImgIcon.gameObject:SetActiveEx(isRunning)
    self.Add.gameObject:SetActiveEx(not isRunning)
    self.PanelCount.gameObject:SetActiveEx(isRunning)
    self.ImgFull.gameObject:SetActiveEx(viewModel:IsFull())
    self.ImgProgress.gameObject:SetActiveEx(viewModel:IsWorking())
    local qualityIcon
    if isRunning then
        local icon = viewModel:GetProductIcon()
        if not string.IsNilOrEmpty(icon) then
            self.RImgIcon:SetRawImage(icon)
        end
        local isPause = viewModel:IsPause()
        local txt = isPause and XUiHelper.GetText("GoldenMinerStopTipsTitle") or XUiHelper.GetTime(viewModel:GetCountDown(), XUiHelper.TimeFormatType.MINUTE_SECOND)
        self.TxtCount.text = txt
        local product = viewModel:GetProduct()
        if product then
            qualityIcon = product:GetQualityIcon(true)
        end
        self.ImgStop.gameObject:SetActiveEx(isPause)
    else
        self.ImgStop.gameObject:SetActiveEx(false)
        qualityIcon = self._Control:GetCommonQualityIcon(true)
    end
    if viewModel:IsWorking() then
        local progress = isRunning and viewModel:GetWorkProgress() or 0
        self.ImgProgress.fillAmount = progress
    end
    self.ImgQuality:SetSprite(qualityIcon)
    self.LastState = state
end

--- 局部更新
---@param viewModel XBenchViewModel
function XUiGrid3DWorkBench:OnLocalUpdate(viewModel, state)
    if not viewModel then
        return
    end
    local isRunning = viewModel:IsRunning()
    self.RImgIcon.gameObject:SetActiveEx(isRunning)
    self.Add.gameObject:SetActiveEx(not isRunning)
    self.PanelCount.gameObject:SetActiveEx(isRunning)
    self.ImgFull.gameObject:SetActiveEx(viewModel:IsFull())
    self.ImgProgress.gameObject:SetActiveEx(viewModel:IsWorking())
    if viewModel:IsWorking() then
        local progress = isRunning and viewModel:GetWorkProgress() or 0
        self.ImgProgress.fillAmount = progress
    end
    
    self.TxtCount.text = viewModel:IsPause() and XUiHelper.GetText("GoldenMinerStopTipsTitle") 
            or XUiHelper.GetTime(self.ViewModel:GetCountDown(), XUiHelper.TimeFormatType.MINUTE_SECOND)
end

function XUiGrid3DWorkBench:OnBtnClick()
    if not self.ViewModel then
        return
    end
    XLuaUiManager.Open("UiRestaurantWork", self.ViewModel:GetAreaType(), self.ViewModel:GetWorkbenchId())
end

--- 绑定数据层
---@param viewModel XBenchViewModel
--------------------------
function XUiGrid3DWorkBench:BindViewModel(viewModel)
    if not viewModel then
        return
    end
    local name = self.GameObject:GetHashCode()
    viewModel:BindViewModelPropertiesToObj(name, {
        viewModel.Property.ClientWorkState,
        viewModel.Property.CharacterId,
        viewModel.Property.ProductId,
        viewModel.Property.CountDown,
        viewModel.Property.Progress
    }, function()
        self:OnRefresh()
    end)
end

function XUiGrid3DWorkBench:RefreshRedPoint()
    if XTool.UObjIsNil(self.RedPoint) then
        return
    end
    if not self.ViewModel then
        return
    end
    local areaType, benchId = self.ViewModel:GetAreaType(), self.ViewModel:GetWorkbenchId()
    self.RedPoint.gameObject:SetActiveEx(self._Control:CheckWorkBenchRedPoint(areaType, benchId))
end

return XUiGrid3DWorkBench