--######################## XUiReformBuffGrid ########################
local XUiReformBuffGrid = XClass(nil, "XUiReformBuffGrid")

function XUiReformBuffGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiReformBuffGrid:SetData(data)
    self.RImgIcon:SetRawImage(data.Icon)
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
end

function XUiReformBuffTips:OnStart(datas, title)
    self.Datas = datas
    self.TxtTitle.text = title
    self:RefreshDataList()
end

--######################## 私有方法 ########################

function XUiReformBuffTips:RegisterUiEvents()
    self.BtnClose.CallBack = function() self:Close() end
end

function XUiReformBuffTips:RefreshDataList()
    local go
    local grid
    for _, data in ipairs(self.Datas) do
        go = CS.UnityEngine.Object.Instantiate(self.GridBuff.gameObject)
        go.transform:SetParent(self.PanelContent.transform, false)
        grid = XUiReformBuffGrid.New(go)
        grid:SetData(data)
    end
end

return XUiReformBuffTips