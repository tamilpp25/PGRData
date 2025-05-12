local XUiBtnKeyItem = require("XUi/XUiSet/ChildItem/XUiBtnKeyItem")
local XUiOneKeyCustomKeyItem = XClass(XUiBtnKeyItem, "XUiOneKeyCustomKeyItem")

local XInputManager = CS.XInputManager

function XUiOneKeyCustomKeyItem:Refresh(data, cb, resetTextOnly, curInputMapId, curOperationType)
    self:SetData(data, cb, curInputMapId, curOperationType)
    
    local isKeyboard = self:IsKeyboard()
    local operationKey = self.DefaultKeyMapTable and self.DefaultKeyMapTable.OperationKey

    self.TxtTitle.text = self.Data.Title
    if operationKey and self._KeySetType then
        local curInputMapIdEnum = CS.XInputMapId.__CastFrom(self.CurInputMapId)
        local operationTypeToEnum = CS.XInputManager.XOperationType.__CastFrom(self.CurOperationType)
        self.GroupRecommend.gameObject:SetActiveEx(not isKeyboard)

        local keyCodeType = CS.XInputManager.GetKeyCodeTypeByInt(operationKey, self.CurInputMapId, self.CurOperationType)
        local isCustom = CS.XCustomUi.PCForceSetKeyCode or XInputManager.IsCustomKey(operationKey, 0, self._KeySetType, self.CurOperationType)
        local oneKeyIsCustom = (keyCodeType == XSetConfigs.KeyCodeType.KeyMouseCustom or keyCodeType == XSetConfigs.KeyCodeType.OneKeyCustom) and not CS.XCustomUi.PCForceSetKeyCode
        self.BtnKeyItem.enabled = isCustom or oneKeyIsCustom
        local name = XInputManager.GetKeyCodeString(self._KeySetType, curInputMapIdEnum, operationKey, operationTypeToEnum, CS.PressKeyIndex.One)
        self.BtnKeyItem:SetName(name)
        if isCustom or oneKeyIsCustom then
            self.BtnKeyItem.CallBack = function()
                if keyCodeType == XSetConfigs.KeyCodeType.KeyMouseCustom and not CS.XCustomUi.PCForceSetKeyCode then
                    XLuaUiManager.Open("UiMouseButtonConfig")
                elseif oneKeyIsCustom then
                    XUiManager.TipMsg(CS.XTextManager.GetText("PcKeyBoardButtonNoCusTip"))
                else
                    self.Cb(operationKey, self, XSetConfigs.PressKeyIndex.One, self.CurOperationType)
                end
            end
        end
        
        isCustom = XInputManager.IsCustomKey(operationKey, 1, self._KeySetType, self.CurOperationType)
        self.BtnKeyItem2.enabled = isCustom
        name = XInputManager.GetKeyCodeString(self._KeySetType, curInputMapIdEnum, operationKey, operationTypeToEnum, CS.PressKeyIndex.Two)
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
        self.TxtKeyName.text = ""
    end
end

return XUiOneKeyCustomKeyItem