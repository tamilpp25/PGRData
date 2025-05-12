local XUiBtnKeyItem = require("XUi/XUiSet/ChildItem/XUiBtnKeyItem")
local XUiNotCustomKeyItem = XClass(XUiBtnKeyItem, "XUiNotCustomKeyItem")

local XInputManager = CS.XInputManager

function XUiNotCustomKeyItem:Refresh(data, cb, resetTextOnly, curInputMapId, curOperationType)
    self:SetData(data, cb, curInputMapId, curOperationType)
    
    local isKeyboard = self:IsKeyboard()
    local operationKey = self.DefaultKeyMapTable and self.DefaultKeyMapTable.OperationKey

    self.TxtTitle.text = self.Data.Title
    if operationKey and self._KeySetType then
        if isKeyboard then
            self.GroupRecommend.gameObject:SetActiveEx(false)
        else
            self.GroupRecommend.gameObject:SetActiveEx(true)
        end
        
        local isCustom = XInputManager.IsCustomKey(operationKey, 0, self._KeySetType, self.CurOperationType)
        self.BtnKeyItem.enabled = isCustom
        local name = XInputManager.GetKeyCodeString(self._KeySetType, CS.XInputMapId.__CastFrom(self.CurOperationType), operationKey, 
                CS.XInputManager.XOperationType.__CastFrom(self.CurOperationType))
        self.BtnKeyItem:SetName(name)
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

return XUiNotCustomKeyItem