local XUiGridCond = require("XUi/XUiSettleWinMainLine/XUiGridCond")
local UiMainLineSettlement = require('XUi/XUiSettleWinMainLine/XUiSettleWinMainLine')
---@class XUiMechanismSettle
---@field _Control XMechanismActivityControl
local XUiMechanismSettlement = XLuaUiManager.Register(UiMainLineSettlement, 'UiMechanismSettlement')

-- 显示胜利满足的条件
---@overload
function XUiMechanismSettlement:UpdateConditions(stageId, starMap)
    self.GridCond.gameObject:SetActive(false)
    if starMap == nil then
        return
    end
    local starDecs = self._Control:GetStageStarDescList(stageId)
    self.GridCondList = {}
    for i = 1, #starMap do
        if not string.IsNilOrEmpty(starDecs[i]) then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridCond)
            local grid = XUiGridCond.New(ui)
            grid.Transform:SetParent(self.PanelCondContent, false)
            grid:Refresh(starDecs[i], starMap[i])
            grid.GameObject:SetActive(true)
            self.GridCondList[i] = grid
        end
    end
end

---@overload
function XUiMechanismSettlement:SetBtnsInfo(data)
    local starDecs = self._Control:GetStageStarDescList(data.StageId)
    --根据挑战目标数控制显示
    if XTool.IsTableEmpty(starDecs) then
        self.PanelCond.gameObject:SetActive(false)
    else
        self.PanelCond.gameObject:SetActive(true)
        self:UpdateConditions(data.StageId, data.StarsMap)
    end

    local beginData = XMVCA.XFuben:GetFightBeginData()
    if (self.StageCfg.HaveFirstPass and not beginData.LastPassed) or self.OnlyTouchBtn then
        self.PanelTouch.gameObject:SetActive(true)
        self.PanelBtns.gameObject:SetActive(false)
    else
        local leftType = self.StageCfg.FunctionLeftBtn
        local rightType = self.StageCfg.FunctionRightBtn

        self.BtnLeft.gameObject:SetActive(leftType > 0)
        self.BtnRight.gameObject:SetActive(rightType > 0)
        self.TxtLeft.text = XRoomSingleManager.GetBtnText(leftType)
        self.TxtRight.text = XRoomSingleManager.GetBtnText(rightType)

        self.PanelTouch.gameObject:SetActive(false)
        self.PanelBtns.gameObject:SetActive(true)
    end
end

return XUiMechanismSettlement