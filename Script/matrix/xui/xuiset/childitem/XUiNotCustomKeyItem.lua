local XUiBtnKeyItem = require("XUi/XUiSet/ChildItem/XUiBtnKeyItem")
local XUiNotCustomKeyItem = XClass(XUiBtnKeyItem, "XUiNotCustomKeyItem")

local XInputManager = CS.XInputManager

function XUiNotCustomKeyItem:Refresh(data, cb, resetTextOnly, curOperationType)
    self:SetData(data, cb, curOperationType)
    
    local isKeyboard = self:IsKeyboard()
    local operationKey = self.Data.OperationKey

    self.TxtTitle.text = self.Data.Title
    if operationKey and self._KeySetType then
        if isKeyboard then
            self.GroupRecommend.gameObject:SetActiveEx(false)
        else
            self.GroupRecommend.gameObject:SetActiveEx(true)
        end
        
        local isCustom = XInputManager.IsCustomKey(operationKey, 0)
        self.BtnKeyItem.enabled = isCustom
        local name = XInputManager.GetKeyCodeString(self._KeySetType, CS.XOperationType.__CastFrom(self.CurOperationType), operationKey)
        self.BtnKeyItem:SetName(name)
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

return XUiNotCustomKeyItem