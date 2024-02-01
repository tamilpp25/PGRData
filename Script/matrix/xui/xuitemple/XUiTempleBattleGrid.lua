---@field _Control XTempleControl
---@class XUiTempleBattleGrid:XUiNode
local XUiTempleBattleGrid = XClass(XUiNode, "XUiTempleBattleGrid")

function XUiTempleBattleGrid:Ctor()
    ---@type XTempleUiDataGrid
    self._Data = nil
    
    self._IsCanClick = false
end

function XUiTempleBattleGrid:OnStart()
    self.Bg = XUiHelper.TryGetComponent(self.Transform, "Bg", "Transform")

    self.EffectOn = XUiHelper.TryGetComponent(self.Transform, "EffecOn", "Transform")

    self.Floor = XUiHelper.TryGetComponent(self.Transform, "Floor", "RectTransform")

    if self.PanelScore then
        self.PanelScore.gameObject:SetActiveEx(false)
    end
end

function XUiTempleBattleGrid:RegisterClick()
    if not self._IsCanClick then
        self._IsCanClick = true
        XUiHelper.RegisterClickEvent(self, self.ButtonGrid, function()
            self:OnClick()
        end)
    end
end

---@param data XTempleUiDataGrid
function XUiTempleBattleGrid:Update(data)
    if data.Hide then
        self.Image.gameObject:SetActiveEx(false)
        if self.Bg then
            self.Bg.gameObject:SetActiveEx(false)
        end
        if self.BgRed then
            self.BgRed.gameObject:SetActiveEx(false)
        end
        if self.Floor then
            self.Floor.gameObject:SetActiveEx(true)
        end
    else
        self.Image.gameObject:SetActiveEx(true)
        --self.Image:SetRawImage(data.Icon)
        if self.Image.SetSprite then
            self.Image:SetSprite(data.Icon)
        end
        if self.Bg then
            self.Bg.gameObject:SetActiveEx(true)
        end
        ---@type UnityEngine.RectTransform
        local transform = self.Image.transform
        transform.eulerAngles = Vector3(0, 0, data.Rotation)

        if self.EffectOn then
            if self._Data and self._Data.Icon ~= data.Icon then
                self.EffectOn.gameObject:SetActiveEx(false)
                self.EffectOn.gameObject:SetActiveEx(true)
            end
        end

        if self._IsCanClick then
            if self.PanelScore then
                if data.Score and data.Score ~= 0 then
                    self.PanelScore.gameObject:SetActiveEx(true)
                    self.TxtScore.text = data.Score
                else
                    self.PanelScore.gameObject:SetActiveEx(false)
                end
            end
        end

        if self.Bg then
            if data.Red then
                self.Bg.gameObject:SetActiveEx(false)
            else
                self.Bg.gameObject:SetActiveEx(true)
            end
        end

        if self.BgRed then
            if data.Red then
                self.BgRed.gameObject:SetActiveEx(true)
            else
                self.BgRed.gameObject:SetActiveEx(false)
            end
        end

        --if self.Floor then
        --    self.Floor.gameObject:SetActiveEx(false)
        --end
    end
    self._Data = data

    if data.UiName then
        self.Transform.name = data.UiName
    end
end

function XUiTempleBattleGrid:OnClick()
    if self._Data then
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_ON_CLICK_GRID, self._Data, self)
    end
end

return XUiTempleBattleGrid
