local CSXTextManagerGetText = CS.XTextManager.GetText
local XUiSpecialRegulationShow = XLuaUiManager.Register(XLuaUi, "UiSpecialRegulationShow")

function XUiSpecialRegulationShow:OnStart(data)
    self.data = data
    self:AutoAddListener()
    self:Refresh()
end

function XUiSpecialRegulationShow:AutoAddListener()
    self.BtnConfirmB.CallBack = function()
        if XLuaUiManager.IsUiLoad("UiDialog") then
            XLuaUiManager.Remove("UiDialog")
        end
        self:Close() 
    end
end

function XUiSpecialRegulationShow:Refresh()
    local info = ""
    if self.data.type == 1 then
        local consumeName = XDataCenter.ItemManager.GetItemName(self.data.consumeId)
        if consumeName then
            info = CSXTextManagerGetText("JPBusinessLawsDetails1",consumeName)
        else
            XLog.Error("consumeId is not Exist："..self.data.consumeId)
        end
    else
        info = CSXTextManagerGetText("JPBusinessLawsDetails"..self.data.type,self.data.content)
    end
    self.TxtInfoNormal.text = string.gsub(info, "\\n", "\n")
end