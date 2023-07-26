XUiBaseView = XClass(XUiBaseComponent, "XUiBaseView")

-- function XUiBaseView:Ctor(rootUi, ui)
-- end

-- for override
function XUiBaseView:Show()
    self.GameObject:SetActiveEx(true)
    self:Refresh()
end

-- for override
function XUiBaseView:Close()
    self.GameObject:SetActiveEx(false)
end

-- for override
function XUiBaseView:Refresh()
end


-- self:AddTemplate(self.GridCommon, self.PanelReward, XUiGridCommon) -- 封装继承XUiBaseComponent
-- self:UpdateTemplateList(self.GridCommon, datas)
--==== 创建模板列表 begin

-- 设置模板对象
function XUiBaseComponent:AddTemplate(templateGO, parent, component)
    if XTool.UObjIsNil(templateGO) then
        XLog.Error("模板对象设置失败，为nil")
        return
    end
    self:_TryInitData()
    if not self._TemplateComponentMap[templateGO] then
        templateGO.gameObject:SetActiveEx(false)
        self._TemplateComponentMap[templateGO] = component
        self._TemplateParentMap[templateGO] = parent
        self._TemplateList[templateGO] = {}
    end
end

-- 刷新模板对象列表
function XUiBaseComponent:UpdateTemplateList(templateGO, dataList)
    if not self._TemplateList[templateGO] or not self._TemplateParentMap[templateGO] then
        XLog.Error("模板对象列表刷新失败，未初始化go或parent")
        return
    end
    
    -- 隐藏多余对象
    local list = self._TemplateList[templateGO]
    local len = #dataList
    if #list > len then
        for i = len + 1, #list do
            list[i].GameObject:SetActiveEx(false)
        end
    end

    -- 刷新列表对象
    for i, data in ipairs(dataList) do
        local comp = self:_GetTemplateComponent(templateGO, i)
        comp.GameObject:SetActiveEx(true)
        comp:Refresh(data)
    end
end

function XUiBaseComponent:_TryInitData()
    if not self._TemplateComponentMap then
        self._TemplateComponentMap = {}
        self._TemplateParentMap = {}
        self._TemplateList = {}
    end
end

function XUiBaseComponent:_GetTemplateComponent(templateGO, index)
    local list = self._TemplateList[templateGO]
    local comp = list[index]
    if not comp then
        local parent = self._TemplateParentMap[templateGO]
        local component = self._TemplateComponentMap[templateGO]
        local go = CS.UnityEngine.Object.Instantiate(templateGO)
        go.transform:SetParent(parent, false)
        comp = component.New(go)
        list[index] = comp
    end
    return comp
end
--==== 创建模板列表 end