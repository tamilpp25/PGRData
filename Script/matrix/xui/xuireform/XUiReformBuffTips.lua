--######################## XUiReformBuffGrid ########################
local XUiReformBuffGrid = XClass(nil, "XUiReformBuffGrid")

function XUiReformBuffGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiReformBuffGrid:SetData(data, isUseImage)
    if isUseImage then
        self.ImgIcon:SetSprite(data.Icon)
    else
        self.RImgIcon:SetRawImage(data.Icon)
    end
    self.ImgIcon.gameObject:SetActiveEx(isUseImage)
    self.RImgIcon.gameObject:SetActiveEx(not isUseImage)
    self.TxtName.text = data.Name
    self.TxtDesc.text = data.Description
    self.GameObject:SetActiveEx(true)
end

--######################## XUiReformBuffTips ########################
local XUiReformBuffTips = XLuaUiManager.Register(XLuaUi, "UiReformBuffTips")

function XUiReformBuffTips:OnAwake()
    self.GridBuff.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
    self.Datas = nil
    self.CloseCallback = nil
    self.IsUseImage = nil
end

function XUiReformBuffTips:OnStart(datas, title, isUseImage, closeCallback)
    if isUseImage == nil then isUseImage = false end
    self.Datas = datas
    self.TxtTitle.text = title
    self.IsUseImage = isUseImage
    self.CloseCallback = closeCallback
    self:RefreshDataList()
end

--######################## 私有方法 ########################

function XUiReformBuffTips:RegisterUiEvents()
    self.BtnClose.CallBack = function() 
        self:Close() 
        if self.CloseCallback then
            self.CloseCallback()
        end
    end
end

function XUiReformBuffTips:RefreshDataList()
    local go
    local grid
    for _, data in ipairs(self.Datas) do
        go = CS.UnityEngine.Object.Instantiate(self.GridBuff.gameObject)
        go.transform:SetParent(self.PanelContent.transform, false)
        grid = XUiReformBuffGrid.New(go)
        grid:SetData(data, self.IsUseImage)
    end
end

return XUiReformBuffTips