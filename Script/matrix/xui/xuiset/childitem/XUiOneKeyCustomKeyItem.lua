local XUiBtnKeyItem = require("XUi/XUiSet/ChildItem/XUiBtnKeyItem")
local XUiOneKeyCustomKeyItem = XClass(XUiBtnKeyItem, "XUiOneKeyCustomKeyItem")

local XInputManager = CS.XInputManager

function XUiOneKeyCustomKeyItem:Refresh(data, cb, resetTextOnly, curOperationType)
    self:SetData(data, cb, curOperationType)
    
    local isKeyboard = self:IsKeyboard()
    local operationKey = self.Data.OperationKey

    self.TxtTitle.text = self.Data.Title
    if operationKey and self._KeySetType then
        local operationTypeToEnum = CS.XOperationType.__CastFrom(self.CurOperationType)
        self.GroupRecommend.gameObject:SetActiveEx(not isKeyboard)

        local isCustom = XInputManager.IsCustomKey(operationKey, 0)
        self.BtnKeyItem.enabled = isCustom
        local name = XInputManager.GetKeyCodeString(self._KeySetType, operationTypeToEnum, operationKey, CS.PressKeyIndex.One)
        self.BtnKeyItem:SetName(name)
        if isCustom then
            self.BtnKeyItem.CallBack = function()
                local keyCodeType = CS.XInputManager.GetKeyCodeTypeByInt(operationKey, self.CurOperationType)
                if keyCodeType == XSetConfigs.KeyCodeType.KeyMouseCustom and not CS.XCustomUi.PCForceSetKeyCode then
                    XLuaUiManager.Open("UiMouseButtonConfig")
                elseif keyCodeType == XSetConfigs.KeyCodeType.OneKeyCustom and not CS.XCustomUi.PCForceSetKeyCode then
                    XUiManager.TipMsg(CS.XTextManager.GetText("PcKeyBoardButtonNoCusTip"))
                else
                    self.Cb(operationKey, self, XSetConfigs.PressKeyIndex.One, self.CurOperationType)
                end
            end
        end
        
        isCustom = XInputManager.IsCustomKey(operationKey, 1)
        self.BtnKeyItem2.enabled = isCustom
        name = XInputManager.GetKeyCodeString(self._KeySetType, operationTypeToEnum, operationKey, CS.PressKeyIndex.Two)
        self.BtnKeyItem2:SetName(name)
        self.BtnKeyItem2.CallBack = function()
            self.Cb(operationKey, self, XSetConfigs.PressKeyIndex.Two, self.CurOperationType)
        end
        if (resetTextOnly == true) then
            return
        end

        self:SetRecommendText(operationKey)
    else

        self.GroupRecommend.gameObject:SetActiveEx(false)
        self.BtnKeyItem.enabled = false
        self.TxtKeyName.text = self.Data.KeyName
    end
end

return XUiOneKeyCustomKeyItem