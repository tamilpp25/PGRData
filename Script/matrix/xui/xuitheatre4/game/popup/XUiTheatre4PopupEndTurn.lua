local XUiGridTheatre4Prop = require("XUi/XUiTheatre4/Common/XUiGridTheatre4Prop")
local XUiTheatre4ColorResource = require("XUi/XUiTheatre4/System/Resources/XUiTheatre4ColorResource")
local XUiTheatre4RollingNumber = require("XUi/XUiTheatre4/Common/XUiTheatre4RollingNumber")
-- 回合结算
---@class XUiTheatre4PopupEndTurn : XLuaUi
---@field private _Control XTheatre4Control
local XUiTheatre4PopupEndTurn = XLuaUiManager.Register(XLuaUi, "UiTheatre4PopupEndTurn")

function XUiTheatre4PopupEndTurn:OnAwake()
    self:RegisterUiEvents()
    self.GridProp.gameObject:SetActiveEx(false)
    self.Effect.gameObject:SetActiveEx(false)
    if self.TxtItemNone then
        self.TxtItemNone.gameObject:SetActiveEx(false)
    end
end

function XUiTheatre4PopupEndTurn:OnStart(callback)
    self.Callback = callback
    self.IsSkipAnim = self._Control:CheckRoundSettleSkipAnim()
    ---@type XTheatre4DailySettleResult
    self.DailySettleData = self._Control:GetDailySettleData()
    ---@type XUiGridTheatre4Prop[]
    self.GridPropList = {}
    -- 当前繁荣度
    self.CurProsperity = 0
    ---@type XUiTheatre4RollingNumber
    self.ProsperityNumber = false
end

function XUiTheatre4PopupEndTurn:OnEnable()
    self:RefreshInfo()
    self:RefreshItemList()
    if self.IsSkipAnim then
        self:RefreshAfterAnim()
    else
        self:RefreshBeforeAnim()
        if XEnumConst.Theatre4.IsDebug then
            self:CheckAnimEffectDataValid()
        end
    end
    -- 播放动画
    self:PlayAnimationWithMask("PopupEnable", function()
        if not self.IsSkipAnim then
            self:PlayAnim()
        end
    end)
end

function XUiTheatre4PopupEndTurn:OnDisable()
    if self.ProsperityNumber then
        self.ProsperityNumber:StopTimer()
    end
    self.CurProsperity = 0
    self.Effect.gameObject:SetActiveEx(false)
end

function XUiTheatre4PopupEndTurn:OnDestroy()
    self._Control:ClearDailySettleData()
end

-- 刷新信息
function XUiTheatre4PopupEndTurn:RefreshInfo()
    -- 章节名称
    self.TxtChapterName.text = self._Control.MapSubControl:GetCurrentChapterName()
    -- 跳过按钮状态
    self.BtnSkip:SetButtonState(self.IsSkipAnim and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    -- 繁荣度图片
    local prosperityIcon = self._Control.AssetSubControl:GetAssetIcon(XEnumConst.Theatre4.AssetType.Prosperity)
    if prosperityIcon then
        self.RImgScore:SetRawImage(prosperityIcon)
    end
    -- 金币图片
    local goldIcon = self._Control.AssetSubControl:GetAssetIcon(XEnumConst.Theatre4.AssetType.Gold)
    if goldIcon then
        self.RImgGold:SetRawImage(goldIcon)
    end
    -- 金币数量
    self.TxtGoldNum.text = string.format("+%s", self.DailySettleData:GetInterest())
    -- 金币上限
    self.TxtTips.text = XUiHelper.GetText("Theatre4DailySettleGoldLimitTips", self.DailySettleData:GetInterestLimit())
    -- 建造点图片
    local buildPointIcon = self._Control.AssetSubControl:GetAssetIcon(XEnumConst.Theatre4.AssetType.BuildPoint)
    if buildPointIcon then
        self.RImgEnergy:SetRawImage(buildPointIcon)
    end
    -- 建造点数量
    self.TxtEnergyNum.text = string.format("+%s", self.DailySettleData:GetBuildPoint())
end

-- 刷新藏品列表
function XUiTheatre4PopupEndTurn:RefreshItemList()
    local itemDataList = self.DailySettleData:GetItemDataList()
    if XTool.IsTableEmpty(itemDataList) then
        if self.TxtItemNone then
            self.TxtItemNone.gameObject:SetActiveEx(true)
        end
        return
    end
    local type = XEnumConst.Theatre4.AssetType.Item
    for index, itemData in ipairs(itemDataList) do
        local grid = self.GridPropList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridProp, self.ListProp)
            grid = XUiGridTheatre4Prop.New(go, self)
            self.GridPropList[index] = grid
        end
        grid:Open()
        grid:Refresh({ UId = itemData.UId, Id = itemData.ItemId, Type = type })
        grid:HideQuality()
    end
    for i = #itemDataList + 1, #self.GridPropList do
        self.GridPropList[i]:Close()
    end
end

-- 刷新资源点
function XUiTheatre4PopupEndTurn:RefreshColorResource(colorDataList)
    if not self.PanelColour then
        ---@type XUiTheatre4ColorResource
        self.PanelColour = XUiTheatre4ColorResource.New(self.ListColour, self, nil, true, false, true)
    end
    self.PanelColour:Open()
    self.PanelColour:RefreshData(colorDataList)
end

-- 刷新动画前数据
function XUiTheatre4PopupEndTurn:RefreshBeforeAnim()
    self:RefreshProsperity(self.DailySettleData:GetProsperityBefore())
    self:RefreshColorResource(self.DailySettleData:GetColorInfoListBefore())
end

-- 刷新动画后数据
function XUiTheatre4PopupEndTurn:RefreshAfterAnim()
    self:RefreshProsperity(self.DailySettleData:GetProsperityAfter())
    self:RefreshColorResource(self.DailySettleData:GetCrossColorInfoList())
end

-- 播放动画
function XUiTheatre4PopupEndTurn:PlayAnim()
    local asynItemAnim = asynTask(self.PlayItemAnim, self)
    local asynProsperityAnim = asynTask(self.PlayProsperityAnim, self)
    RunAsyn(function()
        XLuaUiManager.SetMask(true)
        -- 藏品特效
        for _, grid in ipairs(self.GridPropList) do
            local effectData = self.DailySettleData:GetItemEffectData(grid:GetUId())
            if not self:CheckEffectDataEmpty(effectData) then
                asynWaitSecond(0.2)
                asynItemAnim(grid, effectData)
            end
        end
        -- 刷新颜色资源最终值
        self:RefreshColorResource(self.DailySettleData:GetColorInfoListAfter())
        -- 刷新颜色倍率最终值 只有大于1的才刷新
        for colorId = 1, 3 do
            local rate = self.DailySettleData:GetColorExtra()
            if rate > 1 then
                self.PanelColour:RefreshMarkupRate(colorId, rate)
            end
        end
        -- 等待一段时间
        asynWaitSecond(0.5)
        -- 繁荣度特效
        for colorId = 1, 3 do
            local prosperity = self.DailySettleData:CalculateProsperity(colorId)
            if prosperity >= 0 then
                asynProsperityAnim(colorId, prosperity)
            end
        end
        -- 刷新繁荣度最终值
        self:RefreshAfterAnim()
        XLuaUiManager.SetMask(false)
    end)
end

-- 检查特效数据是否为空
function XUiTheatre4PopupEndTurn:CheckEffectDataEmpty(effectData)
    if XTool.IsTableEmpty(effectData) then
        return true
    end
    for _, data in pairs(effectData) do
        if XTool.IsNumberValid(data.ColorLevel) or XTool.IsNumberValid(data.ColorResource) or XTool.IsNumberValid(data.MarkupRate) then
            return false
        end
    end
    return true
end

-- 播放藏品动画
---@param grid XUiGridTheatre4Prop
---@param effectData table<number, { ColorLevel:number, ColorResource:number, MarkupRate:number }>
---@param callback function
function XUiTheatre4PopupEndTurn:PlayItemAnim(grid, effectData, callback)
    -- 播放动画
    grid:PlayAnim(function()
        -- 播放资源
        self.PanelColour:PlayAnim(effectData, callback)
    end)
end

-- 繁荣度数字跳动特效
function XUiTheatre4PopupEndTurn:PlayProsperityAnim(colorId, prosperity, callback)
    -- 显示结果
    self.PanelColour:ShowProsperity(colorId, prosperity, function()
        -- 数字跳动
        local targetProsperity = prosperity + self.CurProsperity
        self:RefreshProsperity(targetProsperity, true, callback)
    end)
end

-- 设置繁荣度数字
function XUiTheatre4PopupEndTurn:SetProsperityNum(num)
    self.TxtScoreNum.text = num
end

-- 设置繁荣度完成
function XUiTheatre4PopupEndTurn:SetProsperityFinish(num)
    self.CurProsperity = num
    self:SetProsperityNum(num)
end

-- 刷新繁荣度信息
function XUiTheatre4PopupEndTurn:RefreshProsperity(prosperity, isAnim, callback)
    if isAnim and prosperity > self.CurProsperity then
        self:PlayProsperityNumberAnim(self.CurProsperity, prosperity, callback)
    else
        if self.ProsperityNumber then
            self.ProsperityNumber:StopTimer()
        end
        self:SetProsperityFinish(prosperity)
        if callback then
            callback()
        end
    end
end

-- 播放繁荣度动画
function XUiTheatre4PopupEndTurn:PlayProsperityNumberAnim(startValue, endValue, callback)
    if not self.ProsperityNumber then
        self.ProsperityNumber = XUiTheatre4RollingNumber.New(function(value)
            if XTool.UObjIsNil(self.GameObject) then
                return
            end
            self:SetProsperityNum(value)
        end, function(value)
            if XTool.UObjIsNil(self.GameObject) then
                return
            end
            self:SetProsperityFinish(value)
            self.Effect.gameObject:SetActiveEx(false)
        end, true)
    end
    local duration = self._Control:GetClientConfig("ProsperityRollingNumberTime", 1, true) / 1000
    self.ProsperityNumber:SetData(startValue, endValue, duration, callback)
    -- 播放特效
    self.Effect.gameObject:SetActiveEx(false)
    self.Effect.gameObject:SetActiveEx(true)
end

function XUiTheatre4PopupEndTurn:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnSkip, self.OnBtnSkipClick)
end

function XUiTheatre4PopupEndTurn:OnBtnCloseClick()
    XLuaUiManager.CloseWithCallback(self.Name, self.Callback)
end

function XUiTheatre4PopupEndTurn:OnBtnSkipClick()
    self.IsSkipAnim = self.BtnSkip:GetToggleState()
    self._Control:SaveRoundSettleSkipAnim(self.IsSkipAnim)
end

-- 检查效果动画数据是否正常
function XUiTheatre4PopupEndTurn:CheckAnimEffectDataValid()
    -- 藏品Id列表
    local itemDataList = self.DailySettleData:GetItemDataList()
    -- 收集颜色信息
    local resourceList, levelList, rateList = {}, {}, {}
    for _, data in ipairs(itemDataList) do
        local effectData = self.DailySettleData:GetItemEffectData(data.UId)
        if not self:CheckEffectDataEmpty(effectData) then
            for colorId, effect in pairs(effectData) do
                if XTool.IsNumberValid(effect.ColorLevel) then
                    levelList[colorId] = (levelList[colorId] or 0) + effect.ColorLevel
                end
                if XTool.IsNumberValid(effect.ColorResource) then
                    resourceList[colorId] = (resourceList[colorId] or 0) + effect.ColorResource
                end
                if XTool.IsNumberValid(effect.MarkupRate) then
                    rateList[colorId] = (rateList[colorId] or 0) + effect.MarkupRate
                end
            end
        end
    end
    -- 输出信息
    local prosperityBefore = self.DailySettleData:GetProsperityBefore()
    local prosperityAfter = self.DailySettleData:GetProsperityAfter()
    local colorInfoListBefore = self.DailySettleData:GetColorInfoListBefore()
    local colorInfoListAfter = self.DailySettleData:GetColorInfoListAfter()
    local extra = self.DailySettleData:GetColorExtra()
    XLog.Debug(string.format("<color=#F1D116>Theatre4:</color> Prosperity Before: %s, After: %s", prosperityBefore, prosperityAfter))
    for _, colorId in pairs(XEnumConst.Theatre4.ColorType) do
        local resource = resourceList[colorId] or 0
        local level = levelList[colorId] or 0
        local rate = rateList[colorId] or 0
        local prosperity = self.DailySettleData:CalculateProsperity(colorId)
        XLog.Debug(string.format("<color=#F1D116>Theatre4:</color> ColorId: %s =============================", colorId))
        XLog.Debug(string.format("Before Resource: %s, Level: %s", colorInfoListBefore[colorId].Resource, colorInfoListBefore[colorId].Level))
        XLog.Debug(string.format("Effect Resource: %s, Level: %s, Rate: %s", resource, level, rate))
        XLog.Debug(string.format("After  Resource: %s, Level: %s, Rate: %s, Prosperity: %s", colorInfoListAfter[colorId].Resource, colorInfoListAfter[colorId].Level, extra, prosperity))
    end
end

return XUiTheatre4PopupEndTurn
