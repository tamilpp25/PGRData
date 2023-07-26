local XUiPanelExpeditionFashionList = XClass(nil, "XUiPanelExpeditionFashionList")

local GridType = {
    FashionCharacter = 1,--成员涂装
    FashionWeapon = 2,--武器涂装
}

local ClassGrids = {
    [GridType.FashionCharacter] = require("XUi/XUiExpedition/Recruit/XUiExpeditionRoleDetails/XUiGridExpeditionFashion"),
    [GridType.FashionWeapon] = require("XUi/XUiExpedition/Recruit/XUiExpeditionRoleDetails/XUiGridExpeditionWeaponFashion"),
}

function XUiPanelExpeditionFashionList:Ctor(type, ui, rootUi)
    self.Type = type
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:RegisterUiEvents()
    self.GridCostItem.gameObject:SetActiveEx(false)
    self.GridFashionList = {}
end

function XUiPanelExpeditionFashionList:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnReceive, self.OnBtnReceiveClick)
end

function XUiPanelExpeditionFashionList:OnBtnReceiveClick()
    if self.IsDressed then
        return
    end
    
    local curGrid = self.CurrentSelectGrid
    if not curGrid then
        return
    end
    
    if self.Type == GridType.FashionCharacter then
        XDataCenter.FashionManager.UseFashion(curGrid.FashionId,
                function()
                    XUiManager.TipText("UseSuccess")
                    self:RefreshFashion()
                end
        )
    elseif self.Type == GridType.FashionWeapon then
        XDataCenter.WeaponFashionManager.UseFashion(curGrid.FashionId, self.CharacterId, 
                function()
                    XUiManager.TipText("UseSuccess")
                    self:RefreshFashion()
                end
        )
    end
end

function XUiPanelExpeditionFashionList:Refresh(fashionList, characterId, robotId)
    self.CharacterId = characterId
    self.RobotId = robotId
    self.FashionList = self:FilterFashionList(fashionList)
    
    for index, fashionId in pairs(self.FashionList) do
        local grid = self.GridFashionList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridCostItem, self.PanelPainting)
            grid = ClassGrids[self.Type].New(go, self)
            self.GridFashionList[index] = grid
        end
        grid:Refresh(fashionId, characterId, robotId)
        grid.GameObject:SetActiveEx(true)
    end

    for i = #self.FashionList + 1, #self.GridFashionList do
        self.GridFashionList[i].GameObject:SetActiveEx(false)
    end
    
    local isShow = XTool.IsTableEmpty(self.FashionList)
    self.BtnReceive.gameObject:SetActiveEx(not isShow) -- 没有涂装信息时隐藏切换按钮
    self.GridCostItem02.gameObject:SetActiveEx(isShow)
end

function XUiPanelExpeditionFashionList:FilterFashionList(fashionList)
    local tempFashionList = {}
    for _, fashionId in pairs(fashionList) do
        local status
        local fashionStatus
        if self.Type == GridType.FashionCharacter then
            status = XDataCenter.FashionManager.GetFashionStatus(fashionId)
            fashionStatus = XDataCenter.FashionManager.FashionStatus
        elseif self.Type == GridType.FashionWeapon then
            status = XDataCenter.WeaponFashionManager.GetFashionStatus(fashionId, self.CharacterId)
            fashionStatus = XDataCenter.WeaponFashionManager.FashionStatus
        end
        if status == fashionStatus.Dressed or status == fashionStatus.UnLock then
            table.insert(tempFashionList, fashionId)
        end
    end
    return tempFashionList
end

function XUiPanelExpeditionFashionList:RefreshFashion()
    for index, fashionId in pairs(self.FashionList) do
        local grid = self.GridFashionList[index]
        if not grid then
            return
        end
        grid:Refresh(fashionId, self.CharacterId, self.RobotId)
    end
    
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_EXPEDITION_RECRUIT_FASHION_UPDATE)
end

function XUiPanelExpeditionFashionList:OnChildBtnClick(grid)
    self.IsDressed = grid:CheckDressedState()
    self.BtnReceive:SetButtonState(self.IsDressed and XUiButtonState.Disable or XUiButtonState.Normal)
    
    local curGrid = self.CurrentSelectGrid
    if curGrid and curGrid.FashionId == grid.FashionId then
        return
    end

    -- 取消上一个选择
    if curGrid then
        curGrid:SetSelect(false)
    end

    -- 选中当前选择
    grid:SetSelect(true)
    
    self.CurrentSelectGrid = grid
end

function XUiPanelExpeditionFashionList:CancelSelect()
    if not self.CurrentSelectGrid then
        return false
    end

    self.CurrentSelectGrid:SetSelect(false)
    self.CurrentSelectGrid = nil
end

return XUiPanelExpeditionFashionList