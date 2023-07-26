XUiAttentionDesc = XLuaUiManager.Register(XLuaUi, "UiAttentionDesc")

function XUiAttentionDesc:OnStart(panelTitle, contextList, contextTitleList)
    self.PanelTitle = panelTitle
    self.ContextList = contextList
    self.ContextTitleList = contextTitleList
    self:AutoAddListener()
    self.PanelTxt.gameObject:SetActiveEx(false)
    self:Refresh()
end

function XUiAttentionDesc:Refresh()
    self.TxtlTitle.text = self.PanelTitle
    for k, _ in pairs(self.ContextTitleList) do
        local go = CS.UnityEngine.Object.Instantiate(self.PanelTxt, self.PanelContent)
        local tmpObj = {}
        tmpObj.Transform = go.transform
        tmpObj.GameObject = go.gameObject
        XTool.InitUiObject(tmpObj)
        tmpObj.TxtRuleTittle.text = self.ContextTitleList[k]
        tmpObj.TxtRule.text = self.ContextList[k]
        tmpObj.GameObject:SetActiveEx(true)
    end
end

function XUiAttentionDesc:AutoAddListener()
    self.BtnTanchuangClose.CallBack = function()
        self:OnBtnCloseClick()
    end
    self.BtnClose.CallBack = function()
        self:OnBtnCloseClick()
    end
end

function XUiAttentionDesc:OnBtnCloseClick()
    self:Close()
end