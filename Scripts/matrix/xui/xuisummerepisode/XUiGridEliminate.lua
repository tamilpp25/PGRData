local XUiGridEliminate = XClass(nil, "XUiGridEliminate")

function XUiGridEliminate:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self.BtnMatch.CallBack = function()
        self:OnBtnMatchClick()
    end
    self.PanelSelect.gameObject:SetActiveEx(false)
    self.PanelNeighSelected.gameObject:SetActiveEx(false)
    self.FlipEffect.gameObject:SetActiveEx(false)
    self.IsSelected = false
    self.NeighborSelected = false
    self.SelectEnable = false
end

function XUiGridEliminate:SetData(data, gameId)
    self.GameId = gameId
    self.GridData = data
end

--覆盖
function XUiGridEliminate:SetupFlip()
    self.PanelForbidden.gameObject:SetActiveEx(false)
    self.PanelMask.gameObject:SetActiveEx(true)
    self.PanelNeighSelected.gameObject:SetActiveEx(false)
    self.SelectEnable = false
    self.MaskEffect.gameObject:SetActiveEx(self:CheckCanFlipGrid())
end

function XUiGridEliminate:CheckCanFlipGrid()

    local gameData = XDataCenter.EliminateGameManager.GetEliminateGameData(self.GameId)
    if not gameData then
        return
    end

    local flipCostItem = gameData.Config.FlipItemId
    local count = XDataCenter.ItemManager.GetCount(flipCostItem)
    local name = XDataCenter.ItemManager.GetItemName(flipCostItem)
    if count <= 0 or count < gameData.Config.FlipItemCount then
        --XUiManager.TipMsg(string.format(CS.XTextManager.GetText("EliminateFlipItemLack"), gameData.Config.FlipItemCount, name))
        return false
    end

    return true
end


--障碍
function XUiGridEliminate:SetupForbidden()
    self.PanelForbidden.gameObject:SetActiveEx(true)
    self.PanelMask.gameObject:SetActiveEx(false)
    self.PanelNeighSelected.gameObject:SetActiveEx(false)

    self.SelectEnable = false
end

--一般
function XUiGridEliminate:SetupNormal()
    self.PanelForbidden.gameObject:SetActiveEx(false)
    self.PanelMask.gameObject:SetActiveEx(false)
    self.PanelNeighSelected.gameObject:SetActiveEx(false)
end

--消除了
function XUiGridEliminate:SetupReward()
    self.PanelForbidden.gameObject:SetActiveEx(false)
    self.PanelMask.gameObject:SetActiveEx(false)
    self.PanelNeighSelected.gameObject:SetActiveEx(false)
end

--空的
function XUiGridEliminate:SetupEmpty()
    self.PanelForbidden.gameObject:SetActiveEx(false)
    self.PanelMask.gameObject:SetActiveEx(false)
    self.PanelNeighSelected.gameObject:SetActiveEx(false)
end

function XUiGridEliminate:SetSelectedEnable(enable)
    self.SelectEnable = enable
end


function XUiGridEliminate:SetSelected(selected)
    self.PanelSelect.gameObject:SetActiveEx(selected)
    self.IsSelected = selected
end

function XUiGridEliminate:SetNeighBorSelected(selected)
    self.PanelNeighSelected.gameObject:SetActiveEx(selected)
    self.NeighborSelected = selected
end

function XUiGridEliminate:OnBtnMatchClick()
    self.RootUi:OnClickGrid(self.GridData)
end

function XUiGridEliminate:IsObstacle()
    local id = self.GridData.Id
    local gridCfg = XEliminateGameConfig.GetEliminateGameGrid(id)
    return gridCfg.Type == 0
end


function XUiGridEliminate:PlayFlipTimeline(cb)
    self.Timeline:PlayTimelineAnimation(function()
        self.FlipEffect.gameObject:SetActiveEx(true)
        if cb then
            cb()
        end
    end)

end

return XUiGridEliminate