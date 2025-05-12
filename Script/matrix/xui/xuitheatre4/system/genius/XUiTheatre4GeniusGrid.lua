local XUiTheatre4GeniusSubGrid = require("XUi/XUiTheatre4/System/Genius/XUiTheatre4GeniusSubGrid")

---@class XUiTheatre4GeniusGrid : XUiNode
---@field _Control XTheatre4Control
local XUiTheatre4GeniusGrid = XClass(XUiNode, "XUiTheatre4GeniusGrid")

function XUiTheatre4GeniusGrid:Ctor()
    self.BigGenius.gameObject:SetActiveEx(false)
    ---@type XUiTheatre4GeniusSubGrid
    self._BigGenius = XUiTheatre4GeniusSubGrid.New(self.BigGenius, self)
    if self.GridGenius then
        self.GridGenius.gameObject:SetActiveEx(false)
    end
    if self.GridGenius2 then
        self.GridGenius2.gameObject:SetActiveEx(false)
    end
    if self.GridGenius3 then
        self.GridGenius3.gameObject:SetActiveEx(false)
    end
    ---@type XUiTheatre4GeniusSubGrid[]
    self._Genius = {
        XUiTheatre4GeniusSubGrid.New(self.GridGenius, self),
        XUiTheatre4GeniusSubGrid.New(self.GridGenius2, self),
        XUiTheatre4GeniusSubGrid.New(self.GridGenius3, self),
    }

    self._Index = 0
    self._IsBig = false
    self._Data = nil
end

function XUiTheatre4GeniusGrid:OnStart()
    if self.Effect then
        self.Effect.gameObject:SetActiveEx(false)
    end
end

function XUiTheatre4GeniusGrid:SetAlpha(alpha)
    self:_InitCanvasGroup()
    if not XTool.UObjIsNil(self._CanvasGroup) then
        self._CanvasGroup.alpha = alpha
    end
end

---@param data XTheatre4SetControlGeniusData
function XUiTheatre4GeniusGrid:Update(data, index)
    self._Data = data

    self._Index = index
    --if data.TalentPoint then
    --    self.TxtScoreNumNow.text = data.TalentPoint
    --    self.PanelNow.gameObject:SetActiveEx(true)
    --else
    --    self.PanelNow.gameObject:SetActiveEx(false)
    --end

    if data.IsActive then
        --self.PanelUnlockBg.gameObject:SetActiveEx(true)
        self.PanelLockBg.gameObject:SetActiveEx(false)
        self.TxtScoreNum.text = data.UnlockPoint

        if self.TxtClassNumOn then
            self.TxtClassNumOn.text = data.Index
            self.Normal.gameObject:SetActiveEx(true)
            self.Dis.gameObject:SetActiveEx(false)
        end
    else
        --self.PanelUnlockBg.gameObject:SetActiveEx(false)
        self.PanelLockBg.gameObject:SetActiveEx(true)
        self.TxtScoreNum.text = data.UnlockPoint

        if self.TxtClassNumOff then
            self.TxtClassNumOff.text = data.Index
            self.Normal.gameObject:SetActiveEx(false)
            self.Dis.gameObject:SetActiveEx(true)
        end
    end

    if data.IsBig then
        self._BigGenius:Open()
        self._BigGenius:Update(data.List[1])
        self._IsBig = true
        -- 就算没有数据，也要隐藏
        XTool.UpdateDynamicItem(self._Genius, {}, self.GridGenius, XUiTheatre4GeniusSubGrid, self)
        self.ListSmallGenius.gameObject:SetActiveEx(false)
    else
        self.ListSmallGenius.gameObject:SetActiveEx(true)
        self._BigGenius:Close()
        self._IsBig = false
        XTool.UpdateDynamicItem(self._Genius, data.List, self.GridGenius, XUiTheatre4GeniusSubGrid, self)
    end

    self:SetColor(data.ColorType)
    self:UpdateUnlockEffect()

    local icon = self._Control.AssetSubControl:GetAssetIcon(XEnumConst.Theatre4.AssetType.ColoPoint, data.ColorType)
    self.ImgIcon:SetSprite(icon)
end

function XUiTheatre4GeniusGrid:UpdateUnlockEffect()
    local data = self._Data
    if data then
        if not data.IsPlayEffect then
            return
        end
        local isPlayEffect
        if data.IsActive then
            local key = self._Control:GetSaveKey() .. "GeniusGridUnlockEffect" .. XPlayer.Id .. data.ColorType .. data.Index
            if not XSaveTool.GetData(key) then
                XSaveTool.SaveData(key, true)
                isPlayEffect = true
            end
        end

        if isPlayEffect then
            if self.Effect then
                self.Effect.gameObject:SetActiveEx(true)
                return
            end
        end
    end
    self.Effect.gameObject:SetActiveEx(false)
end

function XUiTheatre4GeniusGrid:SetColor(colorType)
    if self.ImgBlueBg then
        if colorType == XEnumConst.Theatre4.ColorType.Red then
            self.ImgRedBg.gameObject:SetActiveEx(true)
            self.ImgBlueBg.gameObject:SetActiveEx(false)
            self.ImgYellowBg.gameObject:SetActiveEx(false)

        elseif colorType == XEnumConst.Theatre4.ColorType.Blue then
            self.ImgRedBg.gameObject:SetActiveEx(false)
            self.ImgBlueBg.gameObject:SetActiveEx(true)
            self.ImgYellowBg.gameObject:SetActiveEx(false)

        elseif colorType == XEnumConst.Theatre4.ColorType.Yellow then
            self.ImgRedBg.gameObject:SetActiveEx(false)
            self.ImgBlueBg.gameObject:SetActiveEx(false)
            self.ImgYellowBg.gameObject:SetActiveEx(true)
        end
    end
end

function XUiTheatre4GeniusGrid:GetIndex()
    return self._Index
end

function XUiTheatre4GeniusGrid:GetIsBig()
    return self._IsBig
end

function XUiTheatre4GeniusGrid:_InitCanvasGroup()
    if XTool.UObjIsNil(self._CanvasGroup) then
        self._CanvasGroup = self.Transform:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
    end
end

return XUiTheatre4GeniusGrid