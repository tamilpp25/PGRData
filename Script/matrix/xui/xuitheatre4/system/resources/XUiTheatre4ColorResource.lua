local XUiTheatre4ColorResourceGrid = require("XUi/XUiTheatre4/System/Resources/XUiTheatre4ColorResourceGrid")
---@field _Control XTheatre4Control
---@class XUiTheatre4ColorResource : XUiNode
local XUiTheatre4ColorResource = XClass(XUiNode, "XUiTheatre4ColorResource")

function XUiTheatre4ColorResource:OnStart(callback, isNotRefresh, isPlayAnim, isPlayAudio)
    self.Callback = callback
    self.IsRefresh = not isNotRefresh
    self.IsPlayAnim = isPlayAnim
    self.IsPlayAudio = isPlayAudio
    if not self.BtnColour then
        self.BtnColour = XUiHelper.TryGetComponent(self.Transform, "BtnColour", "Transform")
    end
    self.BtnColour.gameObject:SetActiveEx(false)
    ---@type XUiTheatre4ColorResourceGrid[]
    self.GridResourceList = {}
end

function XUiTheatre4ColorResource:OnEnable()
    self:Refresh()
end

function XUiTheatre4ColorResource:OnGetLuaEvents()
    return {
        XEventId.EVENT_THEATRE4_UPDATE_ADVENTURE_DATA,
        XEventId.EVENT_THEATRE4_UPDATE_COLOR_DATA,
    }
end

function XUiTheatre4ColorResource:OnNotify(evt, ...)
    self:Refresh(self.IsPlayAnim)
end

-- 刷新
function XUiTheatre4ColorResource:Refresh(isAnim)
    if not self.IsRefresh then
        return
    end
    local colorIds = self._Control:GetColorIds()
    for _, id in ipairs(colorIds) do
        local grid = self.GridResourceList[id]
        if not grid then
            local go = XUiHelper.Instantiate(self.BtnColour, self.Transform)
            grid = XUiTheatre4ColorResourceGrid.New(go, self)
            self.GridResourceList[id] = grid
        end
        grid:Open()
        grid:Refresh(id, isAnim)
    end
    for id, grid in pairs(self.GridResourceList) do
        if not table.contains(colorIds, id) then
            grid:Close()
        end
    end
end

-- 刷新数据
---@param dataList { Id:number, Resource:number, Level:number, TalentLevel:number }[]
function XUiTheatre4ColorResource:RefreshData(dataList)
    if not dataList then
        return
    end
    for _, data in ipairs(dataList) do
        local grid = self.GridResourceList[data.Id]
        if not grid then
            local go = XUiHelper.Instantiate(self.BtnColour, self.Transform)
            grid = XUiTheatre4ColorResourceGrid.New(go, self)
            self.GridResourceList[data.Id] = grid
        end
        grid:Open()
        grid:RefreshData(data)
    end
    for id, grid in pairs(self.GridResourceList) do
        local isExist = false
        for _, data in ipairs(dataList) do
            if data.Id == id then
                isExist = true
                break
            end
        end
        if not isExist then
            grid:Close()
        end
    end
end

-- 获取当前颜色资源
---@param colorId number 颜色ID
function XUiTheatre4ColorResource:GetColorResource(colorId)
    local grid = self.GridResourceList[colorId]
    if not grid then
        return 0
    end
    return grid:GetColorResource()
end

-- 获取当前颜色等级
---@param colorId number 颜色ID
function XUiTheatre4ColorResource:GetColorLevel(colorId)
    local grid = self.GridResourceList[colorId]
    if not grid then
        return 0
    end
    return grid:GetColorLevel()
end

-- 获取当前倍率
---@param colorId number 颜色ID
function XUiTheatre4ColorResource:GetMarkupRate(colorId)
    local grid = self.GridResourceList[colorId]
    if not grid then
        return 0
    end
    return grid:GetMarkupRate()
end

-- 刷新颜色资源
---@param colorId number 颜色ID
---@param colorResource number 颜色资源
function XUiTheatre4ColorResource:RefreshColorResource(colorId, colorResource, isAnim)
    local grid = self.GridResourceList[colorId]
    if not grid then
        return
    end
    grid:RefreshColorResource(colorResource, isAnim)
end

-- 刷新颜色等级
---@param colorId number 颜色ID
---@param colorLevel number 颜色等级
function XUiTheatre4ColorResource:RefreshColorLevel(colorId, colorLevel, isAnim)
    local grid = self.GridResourceList[colorId]
    if not grid then
        return
    end
    grid:RefreshColorLevel(colorLevel, isAnim)
end

-- 刷新倍率
---@param colorId number 颜色ID
---@param rate number 倍率
function XUiTheatre4ColorResource:RefreshMarkupRate(colorId, rate)
    local grid = self.GridResourceList[colorId]
    if not grid then
        return
    end
    grid:RefreshMarkupRate(rate)
end

-- 显示资源数字文本
function XUiTheatre4ColorResource:ShowResourceCountText(colorId, txtNum)
    local grid = self.GridResourceList[colorId]
    if not grid then
        return
    end
    grid:ShowResourceCountText(txtNum)
end

-- 显示等级数字文本
function XUiTheatre4ColorResource:ShowLevelCountText(colorId, txtNum)
    local grid = self.GridResourceList[colorId]
    if not grid then
        return
    end
    grid:ShowLevelCountText(txtNum)
end

-- 显示倍率
function XUiTheatre4ColorResource:ShowMarkupRate(colorId, rate)
    local grid = self.GridResourceList[colorId]
    if not grid then
        return
    end
    grid:ShowMarkupRate(rate)
end

-- 显示数字文本
function XUiTheatre4ColorResource:ShowCountTextByEffect(effectData)
    local isShowLevel, isShowResource, isShowRate = false
    for colorId, data in pairs(effectData) do
        if XTool.IsNumberValid(data.ColorLevel) then
            self:ShowLevelCountText(colorId, data.ColorLevel)
            isShowLevel = true
        end
        if XTool.IsNumberValid(data.ColorResource) then
            self:ShowResourceCountText(colorId, data.ColorResource)
            isShowResource = true
        end
        if XTool.IsNumberValid(data.MarkupRate) then
            -- 修正倍率
            local curRate = self:GetMarkupRate(colorId)
            if curRate <= 0 then
                self:RefreshMarkupRate(colorId, 1.0)
            end
            self:ShowMarkupRate(colorId, data.MarkupRate)
            isShowRate = true
        end
    end
    return isShowLevel, isShowResource, isShowRate
end

-- 刷新颜色信息
function XUiTheatre4ColorResource:RefreshColorDataByEffect(effectData)
    for colorId, data in pairs(effectData) do
        if XTool.IsNumberValid(data.ColorLevel) then
            local targetLevel = data.ColorLevel + self:GetColorLevel(colorId)
            self:RefreshColorLevel(colorId, targetLevel, true)
        end
        if XTool.IsNumberValid(data.ColorResource) then
            local targetResource = data.ColorResource + self:GetColorResource(colorId)
            self:RefreshColorResource(colorId, targetResource, true)
        end
        if XTool.IsNumberValid(data.MarkupRate) then
            local targetRate = data.MarkupRate + self:GetMarkupRate(colorId)
            self:RefreshMarkupRate(colorId, targetRate)
        end
    end
end

-- 播放动画
---@param effectData table<number, { ColorLevel:number, ColorResource:number, MarkupRate:number }>
---@param callback function
function XUiTheatre4ColorResource:PlayAnim(effectData, callback)
    local isShowLevel, isShowResource, isShowRate = self:ShowCountTextByEffect(effectData)
    if not isShowLevel and not isShowResource and not isShowRate then
        if callback then
            callback()
        end
        return
    end
    local time = self._Control:GetClientConfig("ColorResourceAnimTime", 1, true)
    local resourceDuration = self._Control:GetClientConfig("ResourceRollingNumberTime", 1, true)
    local levelDuration = self._Control:GetClientConfig("LevelRollingNumberTime", 1, true)
    -- 嵌套计时器
    -- 等待数字文字结束
    XScheduleManager.ScheduleOnce(function()
        self:RefreshColorDataByEffect(effectData)
        local duration = 0
        if isShowLevel then
            duration = math.max(duration, levelDuration)
        end
        if isShowResource then
            duration = math.max(duration, resourceDuration)
        end
        if duration <= 0 then
            if callback then
                callback()
            end
            return
        end
        -- 等待颜色资源\等级数字结束
        XScheduleManager.ScheduleOnce(function()
            if callback then
                callback()
            end
        end, duration)
    end, time)
end

-- 显示繁荣度 叉乘后的结果 使用繁荣度替换掉颜色资源
---@param colorId number 颜色ID
---@param prosperity number 繁荣度
function XUiTheatre4ColorResource:ShowProsperity(colorId, prosperity, callback)
    self:RefreshColorResource(colorId, 0)
    self:RefreshColorLevel(colorId, 0)
    self:RefreshMarkupRate(colorId, 0)
    local isResourceAnim = prosperity > 0
    self:RefreshColorResource(colorId, prosperity, isResourceAnim)
    if not isResourceAnim then
        if callback then
            callback()
        end
        return
    end
    local resourceDuration = self._Control:GetClientConfig("ResourceRollingNumberTime", 1, true)
    -- 等待颜色资源数字结束
    XScheduleManager.ScheduleOnce(function()
        if callback then
            callback()
        end
    end, resourceDuration)
end

return XUiTheatre4ColorResource
