---负责管理动态列表的类
local XDynamicSceneList=XClass(XSignalData,"XDynamicSceneList")

---动态列表里每个元素的控制器
local XDynamicSceneGrid=require('XUi/XUiSceneSettingMain/XDynamicSceneGrid')

---@dynamicTable 包含了动态列表组件的UI
function XDynamicSceneList:Ctor(dynamicTable)
    --实例化动态列表管理器
    self.DynamicTable=XDynamicTableNormal.New(dynamicTable)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XDynamicSceneGrid)
end

---@data 外部传入的数据
function XDynamicSceneList:RefreshTableData(data)
    self.SceneIdList=data
    self.DynamicTable:SetDataSource(data)
    self.DynamicTable:ReloadDataASync()
end

---更新当前使用的场景
function XDynamicSceneList:RefreshCurrentSceneId(curSceneId, previewId)
    self.CurSceneId=curSceneId
    self.PreviewId=previewId
end

---更新各场景的拥有情况
function XDynamicSceneList:RefreshIsHasData(data)
    self.IsHasData=data
end

---重置数据
function XDynamicSceneList:ResetData()
    self.IsHasData=nil
    self.CurSceneId=nil
    self.SceneIdList=nil
    self.PreviewId=nil
end

---更新选中场景的红点显示
function XDynamicSceneList:RefreshSelectedOneRedPoint()
    self.SelectedOne:RefreshRedPoint()
end

---切换选中的场景
function XDynamicSceneList:ChangeSelectedOne(selected,fitter)
    --如果点击的是同一个按钮，不做任何响应
    if self.SelectedOne and self.SelectedOne.Id==selected.Id then return end
    
    --如果先前有选择，则取消先前的选择
    if self.SelectedOne then
        self.SelectedOne:SetSelect(false)
    end
    --设置新的选择
    self.SelectedOne=selected
    self.PreviewId=selected.Id
    self.SelectedOne:SetSelect(true)

    --发送切换选中的信号
    if not fitter then
        self:EmitSignal('ChangeSceneSelected')
    end

    --更新场景使用状态
    local state= XSaveTool.GetData(XDataCenter.PhotographManager.GetSceneStateKey(self.SelectedOne.Id))
    if state~=1 and state~=2 and XDataCenter.PhotographManager.CheckSceneIsHaveById(self.SelectedOne.Id) then
        state=1
        XSaveTool.SaveData(XDataCenter.PhotographManager.GetSceneStateKey(self.SelectedOne.Id),state)
    end
    self.SelectedOne:RefreshRedPoint()
end

---获取当前显示的场景的Id
function XDynamicSceneList:GetCurDisplaySceneId()
    if self.PreviewId then return self.PreviewId end
    return self.SelectedOne and self.SelectedOne.Id or self.CurSceneId
end

---动态列表的事件回调
function XDynamicSceneList:OnDynamicTableEvent(event, index, grid)
    --动态列表遍历更新事件
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        --根据索引获取指定的场景数据
        local _sceneId=self.SceneIdList[index]
        local _isHave=self.IsHasData[index]
        --更新当前元素
        grid:RefreshDisplay(_sceneId,_isHave)
        --选中并显示当前使用的场景的tag
        if self.PreviewId==_sceneId then
            self:ChangeSelectedOne(grid,true)
        else
            grid:SetSelect(false)
        end

        if self.CurSceneId==_sceneId then
            grid:SetUsedTag(true)
        else
            grid:SetUsedTag(false)
        end
        
    --动态列表元素点击事件
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        --更新元素的选择及其显示
        self:ChangeSelectedOne(grid)
    end
end

return XDynamicSceneList