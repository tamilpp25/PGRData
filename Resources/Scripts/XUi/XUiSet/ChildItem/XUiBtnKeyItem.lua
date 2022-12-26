local XUiBtnKeyItem = XClass(nil, "XUiBtnKeyItem")

local NpcOperationKey = CS.XNpcOperationClickKey
local XInputManager = CS.XInputManager

function XUiBtnKeyItem:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    XTool.InitUiObject(self)
    self._KeySetType = false
end

function XUiBtnKeyItem:SetKeySetType(keySetType)
    self._KeySetType = keySetType
end

function XUiBtnKeyItem:IsPcKeyboard()
    return self._KeySetType == CS.KeySetType.Keyboard and XDataCenter.UiPcManager.IsPc()
end

function XUiBtnKeyItem:Refresh(data, cb, resetTextOnly)
    if data and not self.Data then
        self.Data = data
        self.Cb = cb
    end
    local isPcKeyboard = self:IsPcKeyboard()

    self.TxtTitle.text = self.Data.Title
    if self.Data.NpcOperationKey and self._KeySetType then
        local keyCode = NpcOperationKey.__CastFrom(self.Data.NpcOperationKey)

        if isPcKeyboard then
            self.GroupRecommend.gameObject:SetActiveEx(false)
        else
            self.GroupRecommend.gameObject:SetActiveEx(true)
        end
        self.BtnKeyItem.enabled = true
        self.BtnKeyItem.CallBack = function()
            self.Cb(keyCode, self)
        end
        
        local name = XInputManager.GetKeyCodeString(self._KeySetType, keyCode)
        self.BtnKeyItem:SetName(name)
        if (resetTextOnly == true) then
            return
        end

        local recommendKey = XInputManager.GetRecommendKeyIcoPath(self._KeySetType ,keyCode)

        if recommendKey.Count == 0 then
            self.ImgGamePad1.gameObject:SetActiveEx(false)
            self.TxtPlus.gameObject:SetActiveEx(false)
            self.ImgGamePad2.gameObject:SetActiveEx(false)
        elseif recommendKey.Count == 1 then
            self.UiRoot:SetUiSprite(self.ImgGamePad1, recommendKey[0])
            self.ImgGamePad1.gameObject:SetActiveEx(true)
            self.TxtPlus.gameObject:SetActiveEx(false)
            self.ImgGamePad2.gameObject:SetActiveEx(false)
        elseif recommendKey.Count == 2 then
            self.ImgGamePad1.gameObject:SetActiveEx(true)
            self.TxtPlus.gameObject:SetActiveEx(true)
            self.ImgGamePad2.gameObject:SetActiveEx(true)
            self.UiRoot:SetUiSprite(self.ImgGamePad1, recommendKey[0])
            self.UiRoot:SetUiSprite(self.ImgGamePad2, recommendKey[1])
        end
    else

        self.GroupRecommend.gameObject:SetActiveEx(false)
        self.BtnKeyItem.enabled = false
        self.TxtKeyName.text = self.Data.KeyName
    end
end

return XUiBtnKeyItem