
---@class XUiAreaWarRepeatChallenge : XLuaUi
local XUiAreaWarRepeatChallenge = XLuaUiManager.Register(XLuaUi, "UiAreaWarRepeatChallenge")

local ColorEnum = {
    Enough = XUiHelper.Hexcolor2Color("0F70BC"),
    NotEnough = XUiHelper.Hexcolor2Color("ff0000")
}

function XUiAreaWarRepeatChallenge:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiAreaWarRepeatChallenge:OnStart(count, maxCount, consumeId, consumeRatio, 
                                           title, tips, confirmCb, closeCb)
    self.Count = count
    self.MaxCount = maxCount
    self.ConsumeId = consumeId
    self.ConsumeRatio = consumeRatio

    if not string.IsNilOrEmpty(title) then
        self.TxtTitle.text = title
    end
    
    if not string.IsNilOrEmpty(tips) then
        self.TxtTips.text = tips
    end
    
    self.ConfirmCb = confirmCb
    self.CloseCb = closeCb
    
    self.RImgIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(consumeId))
    
    self:RefreshView()
end

function XUiAreaWarRepeatChallenge:InitUi()
end

function XUiAreaWarRepeatChallenge:InitCb()
    self.BtnEnter.CallBack = function() 
        self:OnBtnEnterClick()
    end
    
    self.BtnClose.CallBack = function() 
        self:Close()
    end
    
    self.BtnSub.CallBack = function() 
        self:OnBtnSubClick()
    end
    
    self.BtnAdd.CallBack = function() 
        self:OnBtnAddClick()
    end
    
    self.BtnMax.CallBack = function() 
        self:OnBtnMaxClick()
    end
end

function XUiAreaWarRepeatChallenge:OnBtnEnterClick()
    if self.Count <= 0 then
        return
    end
    
    local count = XDataCenter.ItemManager.GetCount(self.ConsumeId)
    local need = self.Count * self.ConsumeRatio
    if need > count then
        XUiManager.TipText("PokemonUpgradeItemNotEnough")
        return
    end
    self:Close()
    if self.ConfirmCb then
        self.ConfirmCb(self.Count)
    end
end

function XUiAreaWarRepeatChallenge:OnBtnSubClick()
    if self.Count <= 1 then
        self.Count = 1
        return
    end
    self.Count = self.Count - 1
    self:RefreshView()
end

function XUiAreaWarRepeatChallenge:OnBtnAddClick()
    if self.Count >= self.MaxCount then
        self.Count = self.MaxCount
        return
    end
    self.Count = self.Count + 1
    if self.Count >= self.MaxCount then
        XDataCenter.AreaWarManager.GetPersonal():MarkMaxRedPoint()
    end
    self:RefreshView()
end

function XUiAreaWarRepeatChallenge:OnBtnMaxClick()
    self.Count = self.MaxCount
    XDataCenter.AreaWarManager.GetPersonal():MarkMaxRedPoint()
    self:RefreshView()
end

function XUiAreaWarRepeatChallenge:RefreshView()
    self.TxtRewardNum.text = string.format("X%d", self.Count)
    self.TxtChallengeNum.text = self.Count
    
    local isLessZero = self.Count <= 0
    local isLessOne = self.Count <= 1
    
    self.BtnEnter:SetDisable(isLessZero, not isLessZero)
    self.BtnSub:SetDisable(isLessOne, not isLessOne)
    
    local isBiggerMax = self.Count >= self.MaxCount
    self.BtnAdd:SetDisable(isBiggerMax, not isBiggerMax)
    
    self.TxtATNums.text = self.Count * self.ConsumeRatio
    local isEnough = XDataCenter.ItemManager.CheckItemCountById(self.ConsumeId, self.Count * self.ConsumeRatio)
    self.TxtATNums.color = isEnough and ColorEnum.Enough or ColorEnum.NotEnough
    
    self.BtnMax:ShowReddot(XDataCenter.AreaWarManager.GetPersonal():CheckMaxRedPoint())
end

function XUiAreaWarRepeatChallenge:Close()
    XLuaUi.Close(self)
    if self.CloseCb then self.CloseCb() end
end