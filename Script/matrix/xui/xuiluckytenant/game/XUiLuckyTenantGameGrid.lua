---@class XUiLuckyTenantGameGrid : XUiNode
---@field _Control XLuckyTenantControl
local XUiLuckyTenantGameGrid = XClass(XUiNode, "XUiLuckyTenantGameGrid")

function XUiLuckyTenantGameGrid:OnStart()
    ---@type XUiComponent.XUiButton
    local button = self.Button
    if button then
        button.CallBack = function()
            self:OnClick()
        end
    end
    if not self.Effect then
        self.Effect = XUiHelper.TryGetComponent(self.Transform, "Effect", "Transform")
    end
    if self.Effect then
        self.Effect.gameObject:SetActiveEx(false)
    end
    --self._TimerEffect = false
end

--function XUiLuckyTenantGameGrid:OnDestroy()
--    if self._TimerEffect then
--        XScheduleManager.UnSchedule(self._TimerEffect)
--        self._TimerEffect = false
--    end
--end

function XUiLuckyTenantGameGrid:UpdateRound(round)
    if round then
        self.TxtRound.text = round
        self.PanleRound.gameObject:SetActiveEx(true)
    else
        self.PanleRound.gameObject:SetActiveEx(false)
    end
end

---@param data XUiLuckyTenantGameGridData
function XUiLuckyTenantGameGrid:Update(data)
    if data and data.JustChangeRound ~= nil then
        self:UpdateRound(data.JustChangeRound)
        return
    end

    self._Data = data
    if not data then
        --XLog.Error("[XUiLuckyTenantGameGrid] 棋子数据为空")
        return
    end
    if data.IsValid then
        if self.Root then
            self.Root.gameObject:SetActiveEx(true)
        end
        --self.Image:SetSprite(data.Icon)
        if self.RImgIcon then
            self.RImgIcon:SetRawImage(data.Icon)
        end
        self.ImgQuality:SetSprite(data.Quality)
        self.TxtCost.text = data.Score or data.Value
        --self.Select
        if self.TxtName then
            self.TxtName.text = data.Name
        end
        self:UpdateRound(data.Round)
        if data.X and data.Y then
            self.Transform.name = "Chess_" .. data.X .. "_" .. data.Y
        end
    else
        if self.Root then
            self.Root.gameObject:SetActiveEx(false)
        end
    end
end

function XUiLuckyTenantGameGrid:OnClick()
    if self._Data and self._Data.IsValid then
        self._Control:UpdatePieceDataOnChessboard(self._Data)
        XEventManager.DispatchEvent(XEventId.EVENT_LUCKY_TENANT_ON_CLICK_PIECE_ON_CHESSBOARD, self._Data)
    end
end

function XUiLuckyTenantGameGrid:ShowEffect()
    if self._Data.IsValid then
        --self.Effect.gameObject:SetActiveEx(true)
        --self._TimerEffect = XScheduleManager.ScheduleOnce(function()
        --    self.Effect.gameObject:SetActiveEx(false)
        --    self._TimerEffect = false
        --end, 800)
        self:PlayAnimation("Refresh")
    end
end

return XUiLuckyTenantGameGrid