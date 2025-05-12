local XUiGridDraft = XClass(nil, "XUiGridDraft")

function XUiGridDraft:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    XTool.InitUiObject(self)
    self:AutoAddListener()
    self:SetSelected(false)
end

function XUiGridDraft:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiGridDraft:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiGridDraft:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiGridDraft:AutoAddListener()
    self:RegisterClickEvent(self.BtnClick, self.OnBtnClickClick)
end

function XUiGridDraft:OnBtnClickClick()
    XEventManager.DispatchEvent(XEventId.EVENT_CLICKDRAFT_GRID, self.Data.Id, self.Data.Count, self)
end

function XUiGridDraft:SetSelected(status)
    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActive(status)
    end
end

function XUiGridDraft:IsSelected()
    return self.ImgSelect and self.ImgSelect.gameObject.activeSelf
end

function XUiGridDraft:Refresh(data, count)
    self.Data = data

    self:SetSelected(self.RootUi:GetGridSelected(data.Id))

    self.RImgIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(data.Id), nil, true)
    local quality = XDataCenter.ItemManager.GetItemQuality(data.Id)
    self.RootUi:SetUiSprite(self.ImgQuality, XArrangeConfigs.GeQualityBgPath(quality))

    self.TxtDraftName.text = XDataCenter.ItemManager.GetItemName(data.Id)

    if data.Count >= count then
        self.TxtDraftCount.text = CS.XTextManager.GetText("DormBuildEnoughCount", data.Count)
    else
        self.TxtDraftCount.text = CS.XTextManager.GetText("DormBuildNoEnoughCount", data.Count)
    end
    
    self:RefreshLabel(data.Id)
end

function XUiGridDraft:RefreshLabel(templateId)
    if self.GoodsLabel then
        self.GoodsLabel:Close()
    end
    if not XTool.IsNumberValid(templateId) then
        return
    end
    if not XUiConfigs.CheckHasLabel(templateId) then
        return
    end
    if not self.GoodsLabel then
        self.GoodsLabel = XUiHelper.CreateGoodsLabel(templateId, self.Transform, self.PanelPet)
    end
    self.GoodsLabel:Refresh(templateId, self.PanelPet ~= nil)
end

return XUiGridDraft