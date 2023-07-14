local XUiFubenSideDynamicTable = XClass(XSignalData, "XUiFubenSideDynamicTable")

function XUiFubenSideDynamicTable:Ctor(ui, proxy, ...)
    XUiHelper.InitUiClass(self, ui)
    self.DynamicTable = XDynamicTableCurve.New(self.GameObject)
    self.DynamicTable:SetProxy(proxy, ...)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:GetImpl().IsForceTweenOver = true
    self.GridDic = {}
    -- 当前选中的格子下标
    self.CurrentSelectedIndex = 0
    self.IsDraging = false
end

function XUiFubenSideDynamicTable:RefreshList(datas, index)
    if index == nil then index = self.CurrentSelectedIndex end
    self.CurrentSelectedIndex = index
    self.DynamicTable:SetDataSource(datas)
    self.DynamicTable:ReloadData(index)
end

function XUiFubenSideDynamicTable:GuideCallback(...)
    -- 侧边栏由于有滚动动画，会被新手指引卡住，所以在这里加一个让侧边栏直接不滚动完成最终状态的样子的函数
    local args = {...}
    local currentSelectedIndex = args[2]
    for index, v in pairs(self.GridDic) do
        if index > currentSelectedIndex then
            v:PlayMoveDownAnim(false)
            v:SetIsSelected(false)
        end
        -- 触发上侧格子
        if index < currentSelectedIndex  then
            v:PlayMoveUpAnim(false)
            v:SetIsSelected(false)
        end
    end
end

function XUiFubenSideDynamicTable:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if index < 0 then return end
        self.GridDic[index] = grid
        grid:SetData(index, self.DynamicTable.DataSource[index + 1])
        grid:SetIsSelected(self.CurrentSelectedIndex == index, self.IsDraging)
        grid:ResetPosition()
        if self.CurrentSelectedIndex == index then
            grid:PlayCenterAnim(true)
        elseif index > self.CurrentSelectedIndex then
            grid:PlayMoveDownAnim(true)
        elseif index < self.CurrentSelectedIndex then
            grid:PlayMoveUpAnim(true)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_TWEEN_OVER then
        if index < 0 then index = self.DynamicTable:GetTweenIndex() end
        if self.IsDraging then
            -- 找到上一个格子和下一个格子之间的格子播放位移动画
            for _, v in pairs(self.GridDic) do
                -- 触发下侧格子
                if v.GridIndex > index then
                    v:PlayMoveDownAnim()
                elseif v.GridIndex < index then
                    v:PlayMoveUpAnim()
                end
                v:SetIsSelected(v.GridIndex == index, true )
            end
            self.CurrentSelectedIndex = index
            self.IsDraging = false
        else
            -- 已经打开了就不需要处理
            if self.CurrentSelectedIndex == index then return end
            local currentGrid = self.GridDic[self.CurrentSelectedIndex]
            -- 下边被点击
            if index > self.CurrentSelectedIndex then
                currentGrid:PlayMoveUpAnim()
            else -- 上边被点击
                currentGrid:PlayMoveDownAnim()
            end
            -- 找到上一个格子和下一个格子之间的格子播放位移动画
            for _, v in pairs(self.GridDic) do
                -- 触发下侧格子
                if index > self.CurrentSelectedIndex 
                    and v.GridIndex < index and v.GridIndex > self.CurrentSelectedIndex then
                    v:PlayMoveUpAnim()
                end
                -- 触发上侧格子
                if index < self.CurrentSelectedIndex 
                    and v.GridIndex < self.CurrentSelectedIndex and v.GridIndex > index then
                    v:PlayMoveDownAnim()
                end
                v:SetIsSelected(v.GridIndex == index, false)
            end
            -- 选中播放打开动画
            self.GridDic[index]:PlayCenterAnim(true, index < self.CurrentSelectedIndex)
            self.CurrentSelectedIndex = index
        end
        self:EmitSignal("DYNAMIC_TWEEN_OVER", index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_BEGIN_DRAG then
        if self.IsDraging then return end
        for _, v in pairs(self.GridDic) do
            if v.GridIndex ~= self.CurrentSelectedIndex then
                v:PlayCenterAnim(true, v.GridIndex < self.CurrentSelectedIndex)
            end
            v:SetIsSelected(false, true, true)
        end
        self.IsDraging = true
    end
end

function XUiFubenSideDynamicTable:TweenToIndex(index)
    self.DynamicTable:TweenToIndex(index)
end

function XUiFubenSideDynamicTable:GetCurrentSelectedIndex()
    return self.CurrentSelectedIndex
end

function XUiFubenSideDynamicTable:GetGridDic()
    return self.GridDic
end

function XUiFubenSideDynamicTable:OnDestroy()
    if self.GridDic then
        for k, grid in pairs(self.GridDic) do
            if grid and grid.OnDestroy then
                grid:OnDestroy()
            end
        end
    end
end

return XUiFubenSideDynamicTable