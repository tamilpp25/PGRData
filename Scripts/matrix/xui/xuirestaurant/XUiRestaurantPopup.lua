
---@class XUiRestaurantPopup : XLuaUi
local XUiRestaurantPopup = XLuaUiManager.Register(XLuaUi, "UiRestaurantPopup")

function XUiRestaurantPopup:OnAwake()
    self:InitUi()
    self:InitCb()
end 

function XUiRestaurantPopup:OnStart(title, content, itemData, cancelCb, confirmCb)
    self.Title = title
    self.Content = XUiHelper.ReplaceTextNewLine(content)
    self.CancelCb = cancelCb
    self.ConfirmCb = confirmCb
    self.ItemData = itemData
    
    self:InitView()
end

function XUiRestaurantPopup:InitUi()
end 

function XUiRestaurantPopup:InitCb()
    self.BtnClose.CallBack = function() 
        self:Close()
    end

    self.BtnCancel.CallBack = function()
        self:OnBtnCancelClick()
    end

    self.BtnConfirm.CallBack = function()
        self:OnBtnConfirmClick()
    end
end 

function XUiRestaurantPopup:InitView()
    self.TxtTittle.text = self.Title
    local isItem = self.ItemData ~= nil
    self.PanelMassage.gameObject:SetActiveEx(not isItem)
    self.PanelMassageTwo.gameObject:SetActiveEx(isItem)
    if isItem then
        self.TxtMassage2.text = self.Content
        if self.ItemData.Icon then
            self.RImgIcon:SetRawImage(self.ItemData.Icon)
        end
        if self.ItemData.Count then
            self.TxtCount.text = self.ItemData.Count
        end
    else
        self.TxtMassage1.text = self.Content
    end
    
end

function XUiRestaurantPopup:OnBtnConfirmClick()
    self:Close()
    if self.ConfirmCb then self.ConfirmCb() end
end

function XUiRestaurantPopup:OnBtnCancelClick()
    self:Close()
    if self.CancelCb then self.CancelCb() end
end 