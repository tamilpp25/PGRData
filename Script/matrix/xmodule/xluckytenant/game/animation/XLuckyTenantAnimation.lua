local XLuckyTenantEnum = require("XModule/XLuckyTenant/Game/XLuckyTenantEnum")

---@class XLuckyTenantAnimation
local XLuckyTenantAnimation = XClass(nil, "XLuckyTenantAnimation")

function XLuckyTenantAnimation:Ctor(params)
    self._Type = params.Type
    self._Params = params
    self._Position = params.Position
    self._PieceUiData = params.PieceUiData
    self._Value = params.Value
    self._IsFinish = false
    self._IsStart = false
    self._Time = 0
    self._EndTime = 0
    if params.Duration then
        self._EndTime = params.Duration
    end
end

---@param ui XUiLuckyTenantGame
function XLuckyTenantAnimation:OnStart(ui)
    --XMVCA.XLuckyTenant:Print("播放动画, 类型是:", self._Type)
    if self._Type == XLuckyTenantEnum.Animation.Shake then
        local grid = ui:GetGrid(self._Position)
        if grid then
            grid:PlayAnimation("GridChessShock")
            self._EndTime = 1 / 30 * (5 + 1)
        else
            self._IsFinish = true
        end
        return
    end
    if self._Type == XLuckyTenantEnum.Animation.AddPiece then
        self._EndTime = 1 / 30 * 3

        local grid = ui:GetGrid(self._Position)
        if grid then
            grid:Update(self._PieceUiData)
            grid:ShowEffect()
        else
            self._IsFinish = true
        end
        return
    end
    if self._Type == XLuckyTenantEnum.Animation.AddScore then
        self._EndTime = 1 / 30 * 3

        local grid = ui:GetGrid(self._Position)
        if grid then
            grid:Update(self._PieceUiData)
        else
            self._IsFinish = true
        end
        return
    end
    if self._Type == XLuckyTenantEnum.Animation.GetScore then
        if self._Value > 0 then
            self._EndTime = 0.7

            ui:PlayAnimationGetScore(self._Position, self._Value, self._EndTime, function()
                local uiData = ui:GetUiData()
                uiData.Score = uiData.Score + self._Value
                uiData.AddScore = uiData.AddScore + self._Value
                ui:SetScore(uiData.Score)
                ui:SetAddScore(uiData.AddScore)
                self._IsFinish = true
                XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.LuckyTenantGetScore)
            end)

            local grid = ui:GetGrid(self._Position)
            if grid then
                grid:Update(self._PieceUiData)
            end
        else
            XMVCA.XLuckyTenant:Print("播放得分动画, 但是分数为0")
            self._IsFinish = true
        end
        return
    end
    if self._Type == XLuckyTenantEnum.Animation.DeletePiece then
        self._EndTime = 1 / 30 * 10
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.LuckyTenantDeletePiece)

        local grid = ui:GetGrid(self._Position)
        if grid then
            grid:Update({ IsValid = false })
        else
            self._IsFinish = true
        end

        return
    end
    if self._Type == XLuckyTenantEnum.Animation.SetPiece then
        self._EndTime = 1 / 30 * 10

        local grid = ui:GetGrid(self._Position)
        if not grid or not self._PieceUiData then
            self._IsFinish = true
        end
        return
    end
    if self._Type == XLuckyTenantEnum.Animation.Wait then
        -- 等待一段时间
        return
    end
    if self._Type == XLuckyTenantEnum.Animation.PlayRollAnimation then
        ui:PlayAnimationRollShow()
        return
    end
    self._EndTime = 0
end

---@param ui XUiLuckyTenantGame
function XLuckyTenantAnimation:Update(deltaTime, ui)
    self._Time = self._Time + deltaTime
    if self._Time >= self._EndTime then
        self._IsFinish = true
        self:OnAnimationEnd(ui)
        return
    end
end

---@param ui XUiLuckyTenantGame
function XLuckyTenantAnimation:OnAnimationEnd(ui)
    if self._Type == XLuckyTenantEnum.Animation.SetPiece then
        local grid = ui:GetGrid(self._Position)
        if grid and self._PieceUiData then
            grid:Update(self._PieceUiData)
        end
        return
    end
    if self._Type == XLuckyTenantEnum.Animation.UpdateChessboard then
        ui:SetUiDirtyAndUpdate()
        return
    end
end

function XLuckyTenantAnimation:IsFinish()
    return self._IsFinish
end

function XLuckyTenantAnimation:IsStart()
    return self._IsStart
end

function XLuckyTenantAnimation:SetStart(value)
    self._IsStart = value
end

return XLuckyTenantAnimation