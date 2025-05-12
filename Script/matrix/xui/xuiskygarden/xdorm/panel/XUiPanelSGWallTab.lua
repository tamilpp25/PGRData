---@class XUiPanelSGWallTab : XUiNode
---@field _Control XSkyGardenDormControl
---@field Parent XUiPanelSGWall
---@field _TabBtnList XUiComponent.XUiButton[]
local XUiPanelSGWallTab = XClass(XUiNode, "XUiPanelSGWallTab")

function XUiPanelSGWallTab:OnStart(areaType, selectIndex)
    self._AreaType = areaType
    self._DefaultIndex = selectIndex
    self:InitUi()
    self:InitCb()
end

function XUiPanelSGWallTab:OnEnable()
    if self._DefaultIndex then
        self.BtnContent:SelectIndex(self._DefaultIndex)
    end
end

function XUiPanelSGWallTab:OnDisable()
    self._DefaultIndex = self._TabIndex
    self._TabIndex = nil
end

function XUiPanelSGWallTab:Refresh()
end

function XUiPanelSGWallTab:InitUi()
    self.BtnFirst.gameObject:SetActiveEx(false)
    self.BtnSecond.gameObject:SetActiveEx(false)
    
    local list = self._Control:GetFurnitureTypeList(self._AreaType)

    local btnIndex = 0
    local btnList = {}
    local tab2Id = {}
    for _, ids in pairs(list) do
        local hasChild = ids and #ids > 1
        
        local btn = self:GetButton(true)
        btnIndex = btnIndex + 1
        btnList[#btnList + 1] = btn
        btn:ShowReddot(self:CheckRedPoint(btnIndex))
        local typeId = ids[1]
        btn:SetNameByGroup(0, self._Control:GetFurnitureMajorName(typeId))
        tab2Id[#tab2Id + 1] = typeId
        if hasChild then
            local firstIndex = btnIndex
            for _, id in pairs(ids) do
                local childBtn = self:GetButton(false)
                childBtn.SubGroupIndex = firstIndex
                btnIndex = btnIndex + 1
                btnList[#btnList + 1] = childBtn
                childBtn:SetNameByGroup(0, self._Control:GetFurnitureMinorName(id))
                childBtn:ShowReddot(self:CheckRedPoint(btnIndex))
                tab2Id[#tab2Id + 1] = id
            end
        end
    end
    self.BtnContent:SetIsXScale(true)
    self._TabBtnList = btnList
    self._Tab2Id = tab2Id
    self.BtnContent:Init(btnList, function(index) self:OnSelectTab(index) end)
end

function XUiPanelSGWallTab:InitCb()
end

function XUiPanelSGWallTab:OnSelectTab(tabIndex)
    if self._TabIndex == tabIndex then
        return
    end
    local btn = self._TabBtnList[tabIndex]
    btn:ShowReddot(self:CheckRedPoint(tabIndex))
    if btn.SubGroupIndex and btn.SubGroupIndex > 0 then
        local btn1 = self._TabBtnList[btn.SubGroupIndex]
        btn1:ShowReddot(self:CheckRedPoint(tabIndex)) 
    end
    self._TabIndex = tabIndex
    local id = self._SelectFurnitureId
    self._SelectFurnitureId = nil
    self.Parent:OnSelectTab(self._Tab2Id[tabIndex], id)
end

---@return XUiComponent.XUiButton
function XUiPanelSGWallTab:GetButton(isParent)
    local prefab = isParent and self.BtnFirst or self.BtnSecond
    local btn = XUiHelper.Instantiate(prefab, self.BtnContent.transform)
    btn.gameObject:SetActiveEx(true)
    return btn
end

function XUiPanelSGWallTab:OnSelectByTypeId(typeId, furnitureId)
    local index
    for i, tId in pairs(self._Tab2Id) do
        if tId == typeId then
            index = i
            break
        end
    end
    if not index then
        return
    end
    if self._TabIndex == index then
        return self.Parent:OnSelectTab(typeId, furnitureId)
    end
    self._SelectFurnitureId = furnitureId
    self.BtnContent:SelectIndex(index)
end

function XUiPanelSGWallTab:SelectIndex(tabIndex)
    if self._TabIndex == tabIndex then
        return self.Parent:OnSelectTab(self._Tab2Id[tabIndex])
    end
    self.BtnContent:SelectIndex(tabIndex)
end

function XUiPanelSGWallTab:CheckRedPoint(tabIndex)
    return false
end

return XUiPanelSGWallTab