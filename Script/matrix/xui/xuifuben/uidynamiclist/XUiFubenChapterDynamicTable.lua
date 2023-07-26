local XUiFubenChapterDynamicTable = XClass(nil, "XUiFubenChapterDynamicTable")
local UNITY = CS.UnityEngine

function XUiFubenChapterDynamicTable:Ctor(rootUi, ui, proxy, ...)
    XUiHelper.InitUiClass(self, ui)
    -- 动态列表
    self.RootUi = rootUi
    self.DynamicTable = XDynamicTableCurve.New(self.GameObject)
    self.DynamicTable:GetImpl().IsForceTweenOver = true
    self.DynamicTable:SetProxy(proxy, ...)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetChapterGuide()
    self.GridDic = {}
    -- 当前选中的格子下标
    self.CurrentSelectedIndex = 0
    self.CanvasGroup = self.Transform:GetComponent("CanvasGroup")
    self.IsDraging = false
    self.Callback = nil
    self.WaitTime = -1

    local behaviour = self.GameObject:AddComponent(typeof(CS.XLuaBehaviour))
    if self.Update then
        behaviour.LuaUpdate = function() self:Update() end
    end
end

function XUiFubenChapterDynamicTable:Update()
    if self.IsDraging then -- unity会出现偶尔不调用onEndDrag的bug，用该方法替代
        if UNITY.Input.GetMouseButtonUp(0) or (UNITY.Input.touchCount > 0 and UNITY.Input.GetTouch(0).phase == UNITY.TouchPhase.Ended) then
            self:OnDynamicTableEvent(DYNAMIC_DELEGATE_EVENT.DYNAMIC_TWEEN_OVER, -1)
        end
    end
end

function XUiFubenChapterDynamicTable:RefreshList(datas, index, isFirstChange)
    if index == nil then index = self.CurrentSelectedIndex end
    self.IsFirstChange = isFirstChange -- 当前是1级标签切换，1级标签切换要播Open动画，其他时候不用
    self.CurrentSelectedIndex = index
    self.DynamicTable:SetDataSource(datas)
    self.DynamicTable:ReloadData(index)
end

-- 将当前选中的格子设为展开样式
function XUiFubenChapterDynamicTable:SetCurrGridOpen()
    self.CurrGrid = self.GridDic[self.CurrentSelectedIndex]
    self.CurrGrid:PlayOpenAnim(false, self.RootUi)
end

function XUiFubenChapterDynamicTable:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if index < 0 then return end
        self.GridDic[index] = grid
        grid:SetData(index, self.DynamicTable.DataSource[index + 1])
        grid:ResetPosition()
        if self.IsDraging then
            if index == self.CurrentSelectedIndex then
                grid:PlayCloseAnim(false, self.RootUi)
            else
                grid:PlayCloseAnim(false, self.RootUi)
                grid:PlayCenterAnim(false, index > self.CurrentSelectedIndex)
            end
        else
            if self.CurrentSelectedIndex == index then
                grid:PlayCenterAnim(false)
                if self.IsFirstChange and not XDataCenter.GuideManager.CheckIsInGuide() then
                    self.IsFirstChange = false
                    grid:PlayOpenAnim(true, self.RootUi)
                else
                    grid:PlayOpenAnim(false, self.RootUi)
                end
                -- XLuaUiManager.SetMask(true)
                self.Timer1 = XScheduleManager.ScheduleOnce(function()
                    -- 松开时开启点击
                    -- XLuaUiManager.SetMask(false)
                end, math.max(math.ceil(self.GridDic[index]:GetOpenDuration() * 1000 - 500), 500))
            elseif index > self.CurrentSelectedIndex then
                grid:PlayMoveRightAnim(false, true)
                grid:PlayCloseAnim(false, self.RootUi)
            elseif index < self.CurrentSelectedIndex then
                grid:PlayMoveLeftAnim(false, true)
                grid:PlayCloseAnim(false, self.RootUi)
            end
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_TWEEN_OVER then
        if index < 0 then index = self.DynamicTable:GetTweenIndex() end
        self:UpdateSelectedIndex(index, grid)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_BEGIN_DRAG then
        if self.IsDraging then return end
        if #self.DynamicTable.DataSource <= 1 then return end
        for _, v in pairs(self.GridDic) do
            if v.GridIndex == self.CurrentSelectedIndex then
                v:PlayCloseAnim(true, self.RootUi)
            else
                v:PlayCloseAnim(false, self.RootUi)
                v:PlayCenterAnim(true, v.GridIndex > self.CurrentSelectedIndex, false)
            end
        end
        self.IsDraging = true
        -- XLuaUiManager.SetMask(true)
    end
end

function XUiFubenChapterDynamicTable:UpdateSelectedIndex(index, grid)
    if not index or not self.GridDic or not next(self.GridDic) or not self.GridDic[index] then
        return
    end
    if self.IsDraging then
        -- 选中播放打开动画
        self.GridDic[index]:PlayOpenAnim(nil, self.RootUi)
        -- 找到上一个格子和下一个格子之间的格子播放位移动画
        for _, v in pairs(self.GridDic) do
            -- 触发右侧格子
            if v.GridIndex > index then
                v:PlayMoveRightAnim(true, true)
            elseif v.GridIndex < index then
                v:PlayMoveLeftAnim(true, true)
            end
        end
        self.CurrentSelectedIndex = index
        self.IsDraging = false
    else
        -- 已经打开了就不需要处理
        if self.CurrentSelectedIndex == index then return end
        -- 获取上一个open的格子，播放关闭动画
        local currentGrid = self.GridDic[self.CurrentSelectedIndex]
        currentGrid:PlayCloseAnim(nil, self.RootUi)
        if index > self.CurrentSelectedIndex then
            currentGrid:PlayMoveLeftAnim(true, true)
        elseif index < self.CurrentSelectedIndex then
            currentGrid:PlayMoveRightAnim(true, true)
        end
        -- 找到上一个格子和下一个格子之间的格子播放位移动画
        for _, v in pairs(self.GridDic) do
            -- 触发右侧格子
            if index > self.CurrentSelectedIndex
                and v.GridIndex < index and v.GridIndex > self.CurrentSelectedIndex then
                v:PlayMoveLeftAnim(true, true)
            end
            -- 触发左侧格子
            if index < self.CurrentSelectedIndex
                and v.GridIndex < self.CurrentSelectedIndex and v.GridIndex > index then
                v:PlayMoveRightAnim(true, true)
            end
        end
        -- 选中播放打开动画
        local isRight = index > self.CurrentSelectedIndex
        self.CurrentSelectedIndex = index
        self.GridDic[index]:PlayCenterAnim(true, isRight, true)
        self.GridDic[index]:PlayOpenAnim(nil, self.RootUi)
        -- XLuaUiManager.SetMask(true)
    end
    local time
    if self.WaitTime and self.WaitTime > 0 then
        time = self.WaitTime
    else 
        time = math.max(math.ceil(self.GridDic[index]:GetOpenDuration() * 1000 - 500), 500)
    end
    self.Timer2 = XScheduleManager.ScheduleOnce(function()
        -- 松开时开启点击
        -- XLuaUiManager.SetMask(false)
        if self.Callback then
            self.Callback()
            self.Callback = nil
            self.WaitTime = -1
        end
    end, time)
end

function XUiFubenChapterDynamicTable:TweenToIndex(index, waitTime, callback)
    self.DynamicTable:TweenToIndex(index)
    self.Callback = callback
    self.WaitTime = waitTime
end

function XUiFubenChapterDynamicTable:StopTimer()
    if self.Timer1 then
        XScheduleManager.UnSchedule(self.Timer1)
    end
    self.Timer1 = nil

    if self.Timer2 then
        XScheduleManager.UnSchedule(self.Timer2)
    end
    self.Timer2 = nil
end

function XUiFubenChapterDynamicTable:GetCurrentSelectedIndex()
    return self.CurrentSelectedIndex
end

function XUiFubenChapterDynamicTable:GetGridDic()
    return self.GridDic
end

function XUiFubenChapterDynamicTable:OnDestroy()
    self:StopTimer()
    if self.GridDic then
        for k, grid in pairs(self.GridDic) do
            if grid and grid.OnDestroy then
                grid:OnDestroy()
            end
        end
    end
end

return XUiFubenChapterDynamicTable