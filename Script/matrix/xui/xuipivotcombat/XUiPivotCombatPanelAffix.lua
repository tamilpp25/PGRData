
local XUiPivotCombatPanelAffix = XClass(nil, "XUiPivotCombatPanelAffix")

--===========================================================================
 ---@desc 关卡详情 --> 词缀界面
--===========================================================================
function XUiPivotCombatPanelAffix:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self.GridBuff.gameObject:SetActiveEx(false)
    self.AffixItems = {}
end 

function XUiPivotCombatPanelAffix:Refresh(data)
    local isEmpty = XTool.IsTableEmpty(data)
    if not isEmpty then
        for idx, config in ipairs(data) do
            local grid = self.AffixItems[idx]
            if not grid then
                grid = {}
                local ui = CS.UnityEngine.Object.Instantiate(self.GridBuff, self.PanelAffixList)
                XTool.InitUiObjectByUi(grid, ui)
                self.AffixItems[idx] = grid
            end
            grid.GameObject:SetActiveEx(true)
            grid.RImgIcon:SetRawImage(config.Icon)
            grid.BtnClick.CallBack = function() 
                self:OnClickAffix(config.Id)
            end
        end
    end
    self.PanelAffixList.gameObject:SetActiveEx(not isEmpty)
    self.PanelBuffNone.gameObject:SetActiveEx(isEmpty)
    
    --不显示多余的词缀
    for idx, grid in ipairs(self.AffixItems) do
        grid.GameObject:SetActiveEx(idx <= #data)
    end
end

function XUiPivotCombatPanelAffix:OnClickAffix(affixId)
    local fightEventDetailConfig = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(affixId)
    XUiManager.UiFubenDialogTip(fightEventDetailConfig.Name, fightEventDetailConfig.Description)
end


return XUiPivotCombatPanelAffix