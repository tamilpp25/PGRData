local XUiShop = XLuaUiManager.Register(XLuaUi, "UiShop")
local Dropdown = CS.UnityEngine.UI.Dropdown
local type = type
local DEFAULT_TOG_INDEX = 1

function XUiShop:OnAwake()
    self:InitAutoScript()
end

function XUiShop:OnStart(typeId, cb, configShopId)

    if type(typeId) == "function" then
        cb = typeId
        typeId = nil
    end

    if typeId then
        self.Type = typeId
    else
        self.Type = XShopManager.ShopType.Common
    end

    self.cb = cb
    self.ConfigShopId = configShopId

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelActivityAsset,nil,self,true)
    self.ItemList = XUiPanelItemList.New(self.PanelItemList, self)
    self.FashionList = XUiPanelFashionList.New(self.PanelFashionList, self)
    self.ShopPeriod = XUiPanelShopPeriod.New(self.PanelShopPeriod, self)

    self.AssetActivityPanel:HidePanel()
    self.ItemList:HidePanel()
    self.FashionList:HidePanel()
    self.ShopPeriod:HidePanel()

    self.CallSerber = false
    self.BtnGoList = {}
    self.ShopTables = {}
    self.tagCount = 1
    self.shopGroup = {}

    self.BtnFirst.gameObject:SetActiveEx(false)
    self.BtnSecond.gameObject:SetActiveEx(false)

    self.ScreenGroupIDList = {}
    self.ScreenNum = 1
    self.IsHasScreen = false

    XShopManager.ClearBaseInfoData()

    XShopManager.GetBaseInfo(function()
        self:SetShopBtn(self.Type)
        self:UpdateTog()
    end)

    self:SetTitleName(typeId)
end
-- auto
-- Automatic generation of code, forbid to edit
function XUiShop:InitAutoScript()
    self:AutoAddListener()
end

function XUiShop:GetAutoKey(uiNode, eventName)
    if not uiNode then return end
    return eventName .. uiNode:GetHashCode()
end

function XUiShop:AutoAddListener()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self.BtnScreenGroup.CallBack = function()
        self:OnBtnScreenGroupClick()
    end
    self.BtnScreenWords.onValueChanged:AddListener(function()
            self.SelectTag = self.BtnScreenWords.captionText.text
            self:UpdateList(self.CurShopId, false)
        end)
end

function XUiShop:OnBtnBackClick()
    self:Close()
    if self.cb then
        self.cb()
    end
    self.AssetActivityPanel:HidePanel()
    self.ItemList:HidePanel()
    self.FashionList:HidePanel()
    self.ShopPeriod:HidePanel()
end

function XUiShop:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
    self.AssetActivityPanel:HidePanel()
    self.ItemList:HidePanel()
    self.FashionList:HidePanel()
    self.ShopPeriod:HidePanel()
end

function XUiShop:OnBtnScreenGroupClick()
    if self.ScreenGroupIDList and #self.ScreenGroupIDList > 0 then
        self.ScreenNum = self.ScreenNum + 1
        if self.ScreenNum > #self.ScreenGroupIDList then
            self.ScreenNum = 1
        end
    end
    self:UpdateDropdown()
end


function XUiShop:OnDestroy()
    self.AssetActivityPanel:HidePanel()
    self.ItemList:HidePanel()
    self.FashionList:HidePanel()
    self.ShopPeriod:HidePanel()
end

function XUiShop:SetShopBtn(shopType)
    local btnList = {}

    table.insert(btnList, self.BtnEcerdayShop)
    table.insert(btnList, self.BtnActivityShop)
    self.ShopBtnGroup:Init(btnList, function(index) self:OnSelectedShopBtn(index) end)

    local togActlist = XShopManager.GetShopBaseInfoByTypeAndTag(XShopManager.ShopType.Activity)
    if #togActlist <= 0 then
        self.BtnActivityShop:SetButtonState(CS.UiButtonState.Disable)
    end

    if shopType == XShopManager.ShopType.Common then
        self.ShopBtnGroup.gameObject:SetActiveEx(true)
        self.ShopBtnGroup:SelectIndex(XShopManager.ShopType.Common)
    elseif shopType == XShopManager.ShopType.Activity then
        self.ShopBtnGroup.gameObject:SetActiveEx(true)
        self.ShopBtnGroup:SelectIndex(XShopManager.ShopType.Activity)
    else
        self.ShopBtnGroup.gameObject:SetActiveEx(false)
    end
end

function XUiShop:OnSelectedShopBtn(index)
    if index == XShopManager.ShopType.Common then
        self:OnBtnCommonShopClick()
    else
        self:OnBtnActivityShopClick()
    end
end

function XUiShop:OnBtnActivityShopClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopActive) then
        return
    end
    if self.Type == XShopManager.ShopType.Activity then
        return
    end

    local togActlist = XShopManager.GetShopBaseInfoByTypeAndTag(XShopManager.ShopType.Activity)
    if #togActlist <= 0 then
        XUiManager.TipText("ShopCannotFindActiveShop")
        self.ShopBtnGroup:SelectIndex(XShopManager.ShopType.Common)
        return
    end

    self.Type = XShopManager.ShopType.Activity
    self:UpdateTog()

end

function XUiShop:OnBtnCommonShopClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon) then
        return
    end

    if self.Type == XShopManager.ShopType.Common then
        return
    end

    self.Type = XShopManager.ShopType.Common
    self:UpdateTog()

end

function XUiShop:UpdateTog()
    local shopId = self.ConfigShopId
    self.ConfigShopId = nil
    local infoList = XShopManager.GetShopBaseInfoByTypeAndTag(self.Type)
    local selectIndex = DEFAULT_TOG_INDEX
    local SubGroupIndexMemo = 0
    if #infoList == 0 then
        self.Type = XShopManager.ShopType.Common
        infoList = XShopManager.GetShopBaseInfoByTypeAndTag(self.Type)
    end

    for i = 1, #self.BtnGoList do
        self.BtnGoList[i].gameObject:SetActiveEx(false)
    end

    for index, info in pairs(infoList) do
        local btn = self.BtnGoList[self.tagCount]
        if self.shopGroup[info.Type] then
            if self.shopGroup[info.Type] [index] then
                btn = self.BtnGoList[self.shopGroup[info.Type] [index]]
            end
        end

        if not btn then
            local name
            local SubGroupIndex

            if info.SecondType == 0 then
                if info.IsHasSnd then
                    btn = CS.UnityEngine.Object.Instantiate(self.BtnFirstHasSnd)
                else
                    btn = CS.UnityEngine.Object.Instantiate(self.BtnFirst)
                end
                SubGroupIndexMemo = self.tagCount
                SubGroupIndex = 0
            else
                if info.SecondTagType == XShopManager.SecondTagType.Top then
                    btn = CS.UnityEngine.Object.Instantiate(self.BtnSecondTop)
                elseif info.SecondTagType == XShopManager.SecondTagType.Mid then
                    btn = CS.UnityEngine.Object.Instantiate(self.BtnSecond)
                elseif info.SecondTagType == XShopManager.SecondTagType.Btm then
                    btn = CS.UnityEngine.Object.Instantiate(self.BtnSecondBottom)
                else
                    btn = CS.UnityEngine.Object.Instantiate(self.BtnSecondAll)
                end

                SubGroupIndex = SubGroupIndexMemo
            end

            name = info.Name

            if btn then
                if not self.shopGroup[info.Type] then
                    self.shopGroup[info.Type] = {}
                end
                table.insert(self.shopGroup[info.Type], self.tagCount)
                self.tagCount = self.tagCount + 1

                table.insert(self.ShopTables, info)

                btn.transform:SetParent(self.TabBtnContent, false)
                local uiButton = btn:GetComponent("XUiButton")
                uiButton.SubGroupIndex = SubGroupIndex
                uiButton:SetName(name)
                table.insert(self.BtnGoList, uiButton)
                btn.gameObject.name = info.Id
            end
        end

        btn.gameObject:SetActiveEx(true)

        if shopId and info.Id == shopId then
            selectIndex = self.shopGroup[info.Type] [index]
        end

        if not shopId then
            selectIndex = self.shopGroup[info.Type] [1]
        end
    end

    if #infoList <= 0 then
        return
    end

    self.TabBtnGroup:Init(self.BtnGoList, function(index) self:OnSelectedTog(index) end)
    self.TabBtnGroup:SelectIndex(selectIndex)
end

function XUiShop:SetTitleName(typeId)
    if typeId ~= XShopManager.ShopType.Common and typeId ~= XShopManager.ShopType.Activity then
        self.BtnTitle.gameObject:SetActiveEx(true)
    else
        self.BtnTitle.gameObject:SetActiveEx(false)
    end
    self.BtnEcerdayShop:SetNameByGroup(0,XShopManager.GetShopTypeDataById(XShopManager.ShopType.Common).TypeName)
    self.BtnActivityShop:SetNameByGroup(0,XShopManager.GetShopTypeDataById(XShopManager.ShopType.Activity).TypeName)
    self.BtnTitle:SetNameByGroup(0,XShopManager.GetShopTypeDataById(typeId).TypeName)

    self.BtnEcerdayShop:SetNameByGroup(1,XShopManager.GetShopTypeDataById(XShopManager.ShopType.Common).Desc)
    self.BtnActivityShop:SetNameByGroup(1,XShopManager.GetShopTypeDataById(XShopManager.ShopType.Activity).Desc)
    self.BtnTitle:SetNameByGroup(1,XShopManager.GetShopTypeDataById(typeId).Desc)
end

function XUiShop:ShowShop(shopId)
    XShopManager.GetShopInfo(shopId, function()
        self:UpdateInfo(shopId)
    end)
end

--显示商品信息
function XUiShop:OnSelectedTog(index)
    local shopId = self.ShopTables[index].Id
    self.CurShopId = shopId
    self:ShowShop(shopId)
    self:PlayAnimation("AnimQieHuan")
end

function XUiShop:GetCurShopId()
    return self.CurShopId
end

--初始化列表
function XUiShop:UpdateInfo(shopId)
    self.ShopPeriod:HidePanel()
    self.ShopPeriod:ShowPanel(shopId)
    self:InitScreen(shopId)
    self:UpdateDropdown()
    self:UpdateList(shopId,false)

end

function XUiShop:InitScreen(shopId)
    self.ScreenGroupIDList = XShopManager.GetShopScreenGroupIDList(shopId)
    if self.ScreenGroupIDList and #self.ScreenGroupIDList > 0 then
        self.IsHasScreen = true
        self.ScreenNum = 1
        self.BtnScreenGroup.gameObject:SetActiveEx(#self.ScreenGroupIDList > 1)
    else
        self.IsHasScreen = false
    end
    self.PanelShaixuan.gameObject:SetActiveEx(self.IsHasScreen)
end

function XUiShop:UpdateDropdown()
    if not self.IsHasScreen then
       return
    end
    local icon = XShopManager.GetShopScreenGroupIconById(self.ScreenGroupIDList[self.ScreenNum])
    if icon then
        self.BtnScreenGroup:SetSprite(icon)
    end
    self.BtnScreenGroup:SetName(XShopManager.GetShopScreenGroupNameById(self.ScreenGroupIDList[self.ScreenNum]))
    self.ScreenTagList = XShopManager.GetScreenTagListById(self.CurShopId,self.ScreenGroupIDList[self.ScreenNum])
    self.BtnScreenWords:ClearOptions()
    self.BtnScreenWords.captionText.text = CS.XTextManager.GetText("ScreenAll")
    for _,v in pairs(self.ScreenTagList or {}) do
        local op = Dropdown.OptionData()
        op.text = v.Text
        self.BtnScreenWords.options:Add(op)
    end
    self.BtnScreenWords.value = 0
    self.SelectTag = self.BtnScreenWords.captionText.text
end

function XUiShop:UpdateList(shopId)
    self.AssetActivityPanel:Refresh(XShopManager.GetShopShowIdList(shopId))
    self.ItemList:ShowScreenPanel(shopId,self.ScreenGroupIDList[self.ScreenNum],self.SelectTag)
    self.FashionList:ShowScreenPanel(shopId,self.ScreenGroupIDList[self.ScreenNum],self.SelectTag)
end

function XUiShop:UpdateBuy(data, cb)
    XLuaUiManager.Open("UiShopItem",self,data, cb)
    self:PlayAnimation("AnimTanChuang")
end

function XUiShop:RefreshBuy()
    self.AssetActivityPanel:Refresh(XShopManager.GetShopShowIdList(self.CurShopId))
    self.ShopPeriod:UpdateShopBuyInfo()
    self:UpdateList(self.CurShopId)
end