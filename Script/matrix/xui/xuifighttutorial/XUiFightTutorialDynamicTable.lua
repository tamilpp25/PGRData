local XDynamicTableCurve = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableCurve")
local XUiFightTutorialDynamicTable = XClass(XSignalData, "XUiFightTutorialDynamicTable")

function XUiFightTutorialDynamicTable:Ctor(parent, ui, proxy, ...)
    XUiHelper.InitUiClass(self, ui)
    self.DynamicTable = XDynamicTableCurve.New(self.GameObject)
    self.DynamicTable:SetProxy(proxy, ...)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:GetImpl().IsForceTweenOver = true
    self.GridDic = {}
    self.ParentUI = parent
    -- ��ǰѡ�еĸ����±�
    self.CurrentSelectedIndex = 0
    self.IsDraging = false
end

function XUiFightTutorialDynamicTable:RefreshList(datas, index)
    if index == nil then index = self.CurrentSelectedIndex end
    self.CurrentSelectedIndex = index
    self.DynamicTable:SetDataSource(datas)
    self.DynamicTable:ReloadData(index)
    self.ParentUI:SwitchToIndex(index)
end

function XUiFightTutorialDynamicTable:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if index < 0 then return end
        self.GridDic[index] = grid
        grid:SetData(index, self.DynamicTable.DataSource[index + 1])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_TWEEN_OVER then
        if index < 0 then index = self.DynamicTable:GetTweenIndex() end
        if self.IsDraging then
            self.IsDraging = false
        end

        if self.CurrentSelectedIndex == index then return end

        self.CurrentSelectedIndex = index
        self.ParentUI:SwitchToIndex(index)
        self:EmitSignal("DYNAMIC_TWEEN_OVER", index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_BEGIN_DRAG then
        if self.IsDraging then return end
        self.IsDraging = true
        self:StopAll()
    end
end

function XUiFightTutorialDynamicTable:TweenToIndex(index)
    self.DynamicTable:TweenToIndex(index)
end

function XUiFightTutorialDynamicTable:GetCurrentSelectedIndex()
    return self.CurrentSelectedIndex
    
end

function XUiFightTutorialDynamicTable:GetGridDic()
    return self.GridDic
end

function XUiFightTutorialDynamicTable:StopAll()
    for k, v in pairs(self.GridDic) do
        v:Stop()
        v:SetIsSelected(false)
    end
end

function XUiFightTutorialDynamicTable:OnDestroy()
    if self.GridDic then
        for k, grid in pairs(self.GridDic) do
            if grid and grid.OnDestroy then
                grid:OnDestroy()
            end
        end
    end
end

return XUiFightTutorialDynamicTable