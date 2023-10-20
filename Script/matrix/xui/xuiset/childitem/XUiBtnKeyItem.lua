local XUiBtnKeyItem = XClass(XUiNode, "XUiBtnKeyItem")

local XInputManager = CS.XInputManager
local ToInt32 = CS.System.Convert.ToInt32

function XUiBtnKeyItem:OnStart()
    self._KeySetType = self._KeySetType or false

    if self.BtnClear then
        XUiHelper.RegisterClickEvent(self, self.BtnClear, self.OnBtnClearClick)
        self.BtnClear.gameObject:SetActiveEx(true)
    end
end

function XUiBtnKeyItem:OnBtnClearClick()
    if not self.Data then
        return
    end
    CS.XInputManager.ClearKeySetting(self.Data.OperationKey, ToInt32(self._KeySetType), self.CurOperationType)
    self:Refresh()
end

function XUiBtnKeyItem:SetKeySetType(keySetType)
    self._KeySetType = keySetType
end

function XUiBtnKeyItem:IsKeyboard()
    return self._KeySetType == CS.KeySetType.Keyboard
end

function XUiBtnKeyItem:SetData(data, cb, curOperationType)
    if data and not self.Data then
        self.Data = data    --KeyboardMap、ControllerMap配置
        self.Cb = cb
    end
    self.CurOperationType = curOperationType or self.CurOperationType
end

function XUiBtnKeyItem:Refresh(data, cb, resetTextOnly, curOperationType)
    self:SetData(data, cb, curOperationType)
    
    local isKeyboard = self:IsKeyboard()
    local operationKey = self.Data.OperationKey

    self.TxtTitle.text = self.Data.Title
    if operationKey and self._KeySetType then
        local operationTypeToEnum = CS.XOperationType.__CastFrom(self.CurOperationType)
        local name = XInputManager.GetKeyCodeString(self._KeySetType, operationTypeToEnum, operationKey)
        self.BtnKeyItem:SetName(name)

        if isKeyboard then
            self.GroupRecommend.gameObject:SetActiveEx(false)
            if XDataCenter.UiPcManager.IsPc() then
                self.Icon1.gameObject:SetActiveEx(false)
                self.Icon2.gameObject:SetActiveEx(false)
            end
        else
            local icons = XInputManager.GetKeyCodeIcon(self._KeySetType, operationTypeToEnum, operationKey, CS.PressKeyIndex.End)
            if icons and icons.Count ~= 0 then
                self.Icon1:SetSprite(icons[0])
                self.Icon1.gameObject:SetActiveEx(true)
                if icons.Count > 1 then
                    self.Icon2:SetSprite(icons[1])
                    self.Icon2.gameObject:SetActiveEx(true)
                    self.BtnKeyItem:SetName("+")
                    self.TxtKeyName.gameObject:SetActiveEx(true)
                else
                    self.TxtKeyName.gameObject:SetActiveEx(false)
                    self.Icon2.gameObject:SetActiveEx(false)
                end
            else
                self.Icon1.gameObject:SetActiveEx(false)
                self.Icon2.gameObject:SetActiveEx(false)
                self.TxtKeyName.gameObject:SetActiveEx(false)
            end
        end
        
        local isCustom = XInputManager.IsCustomKey(operationKey, 0, self._KeySetType, self.CurOperationType)
        self.BtnKeyItem.enabled = isCustom
        self.BtnKeyItem.CallBack = function()
            self.Cb(operationKey, self)
        end
        if (resetTextOnly == true) and not XDataCenter.UiPcManager.IsPc() then
            return
        end

        self:SetRecommendText(operationKey)
    else
        self.GroupRecommend.gameObject:SetActiveEx(false)
        self.BtnKeyItem.enabled = false
        self.TxtKeyName.text = self.Data.KeyName
    end
end

function XUiBtnKeyItem:SetRecommendText(operationKey)
    local recommendKey = XInputManager.GetRecommendKeyIcoPath(self._KeySetType, operationKey)
    if not recommendKey.Count or recommendKey.Count == 0 then
        self.GroupRecommend.gameObject:SetActiveEx(false)
        self.ImgGamePad1.gameObject:SetActiveEx(false)
        self.TxtPlus.gameObject:SetActiveEx(false)
        self.ImgGamePad2.gameObject:SetActiveEx(false)
        return
    end

    if recommendKey.Count == 1 then
        self.Parent:SetUiSprite(self.ImgGamePad1, recommendKey[0])
        self.ImgGamePad1.gameObject:SetActiveEx(true)
        self.TxtPlus.gameObject:SetActiveEx(false)
        self.ImgGamePad2.gameObject:SetActiveEx(false)
    elseif recommendKey.Count == 2 then
        self.ImgGamePad1.gameObject:SetActiveEx(true)
        self.TxtPlus.gameObject:SetActiveEx(true)
        self.ImgGamePad2.gameObject:SetActiveEx(true)
        self.Parent:SetUiSprite(self.ImgGamePad1, recommendKey[0])
        self.Parent:SetUiSprite(self.ImgGamePad2, recommendKey[1])
    end
    self.GroupRecommend.gameObject:SetActiveEx(true)
end

return XUiBtnKeyItem