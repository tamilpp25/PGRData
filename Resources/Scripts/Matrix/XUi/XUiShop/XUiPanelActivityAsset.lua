XUiPanelActivityAsset = XClass(nil, "XUiPanelActivityAsset")

function XUiPanelActivityAsset:Ctor(ui, deleteDes, base ,hideAssetPanel, hideSkipBtn)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.DeleteDes = deleteDes
    self.Base = base
    self.HideAssetPanel = hideAssetPanel
    self.HideSkipBtn = hideSkipBtn
    self:InitAutoScript()
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelActivityAsset:InitAutoScript()
    XTool.InitUiObject(self)
    self:AutoAddListener()
end

function XUiPanelActivityAsset:AutoAddListener()
    self.BtnClick1.CallBack = function()
        self:OnBtnClick1Click()
    end
    self.BtnClick2.CallBack = function()
        self:OnBtnClick2Click()
    end
    self.BtnClick3.CallBack = function()
        self:OnBtnClick3Click()
    end
end
-- auto
function XUiPanelActivityAsset:OnBtnClick1Click()
    self:OnBtnClick(1)
end

function XUiPanelActivityAsset:OnBtnClick2Click()
    self:OnBtnClick(2)
end

function XUiPanelActivityAsset:OnBtnClick3Click()
    self:OnBtnClick(3)
end

function XUiPanelActivityAsset:OnBtnClick(index)
    if not self.ItemIds or not self.ItemIds[index] then
        return
    end
    local item = XDataCenter.ItemManager.GetItem(self.ItemIds[index])
    local data = {
        Id = self.ItemIds[index],
        Count = item ~= nil and tostring(item.Count) or "0"
    }
    if self.QueryFunc then
        local itemId = self.ItemIds[index]
        data = XTool.Clone(XGoodsCommonManager.GetGoodsShowParamsByTemplateId(itemId))
        data.IsTempItemData = true
        data.Count = self.QueryFunc(item) or data.Count
        data.Description = XGoodsCommonManager.GetGoodsDescription(itemId)
        data.WorldDesc = XGoodsCommonManager.GetGoodsWorldDesc(itemId)
    end
    XLuaUiManager.Open("UiTip", data, self.HideSkipBtn)
end

function XUiPanelActivityAsset:HidePanel()
    if not XTool.UObjIsNil(self.GameObject) then
        self.GameObject:SetActiveEx(false)
    end
end

function XUiPanelActivityAsset:SetQueryFunc(func)
    -- 用于构造本地数据时通过自定义查询器获取
    self.QueryFunc = func
end

function XUiPanelActivityAsset:Refresh(idlist)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end

    --读取数据
    if idlist == nil then
        self.GameObject:SetActive(false)
        return
    end
    self.ItemIds = idlist
    self.GameObject:SetActive(true)
    for i = 1, 3 do
        if i > #self.ItemIds then
            self["PanelSpecialTool" .. i].gameObject:SetActive(false)
        else
            self["PanelSpecialTool" .. i].gameObject:SetActive(true)
        end
    end

    if self.HideAssetPanel and self.Base then
        self.Base.AssetPanel.GameObject:SetActiveEx(not (self.PanelSpecialTool3.gameObject.activeSelf or self.PanelSpecialTool2.gameObject.activeSelf or self.PanelSpecialTool1.gameObject.activeSelf))
    end
    self.PanelSpecialTool.gameObject:SetActiveEx(self.PanelSpecialTool3.gameObject.activeSelf or self.PanelSpecialTool2.gameObject.activeSelf or self.PanelSpecialTool1.gameObject.activeSelf)

    local items = {}
    for _, id in pairs(self.ItemIds) do
        table.insert(items, XDataCenter.ItemManager.GetItem(id))
    end

    for i = 1, #items do
        local item = items[i]
        local count = item ~= nil and tostring(item.Count) or "0"
        if self.QueryFunc then
            count = self.QueryFunc(item) or count
        end
        self["PanelSpecialTool" .. i].gameObject:SetActive(true)
        self["TxtSpecialTool" .. i].text = not self.DeleteDes and CS.XTextManager.GetText("ShopActivityItemCount", count) or count
        if items[i].Template.ItemType == 2 then
            self["TxtSpecialTool" .. i].text = count .. "/" .. XDataCenter.ItemManager.GetMaxActionPoints()
        end

        local rImgSpecialTool = self["RImgSpecialTool" .. i]
        if rImgSpecialTool and rImgSpecialTool:Exist() then
            rImgSpecialTool:SetRawImage(items[i].Template.Icon)
        end
    end
end