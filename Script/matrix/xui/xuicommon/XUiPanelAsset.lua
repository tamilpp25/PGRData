---@class XUiPanelAsset : XUiNode
XUiPanelAsset = XClass(XUiNode, "XUiPanelAssetCommon")
local insert = table.insert
local min = math.min

function XUiPanelAsset:InitNode(ui, parent, ...)
    XUiPanelAsset.Super.InitNode(self, parent, ui, ...)
end

function XUiPanelAsset:OnStart(...)
    self:InitAutoScript()
    self:InitBtnSound()
    
    self.ItemIds = { ... }
    self._BindNodes = {}
    self:InitAssert(self.ItemIds)
end

function XUiPanelAsset:RefreshBindItem(...)
    self.ItemIds = { ... }
    self._BindNodes = {}
    self:InitAssert(self.ItemIds)
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelAsset:InitAutoScript()
    self:AutoInitUi()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiPanelAsset:AutoInitUi()
    self.PanelTool3 = XUiHelper.TryGetComponent(self.Transform, "PanelTool3", nil)
    self.RImgTool3 = XUiHelper.TryGetComponent(self.Transform, "PanelTool3/RImgTool3", "RawImage")
    self.TxtTool3 = XUiHelper.TryGetComponent(self.Transform, "PanelTool3/TxtTool3", "Text")
    self.BtnBuyJump3 = XUiHelper.TryGetComponent(self.Transform, "PanelTool3/BtnBuyJump3", "Button")
    self.PanelTool2 = XUiHelper.TryGetComponent(self.Transform, "PanelTool2", nil)
    self.RImgTool2 = XUiHelper.TryGetComponent(self.Transform, "PanelTool2/RImgTool2", "RawImage")
    self.TxtTool2 = XUiHelper.TryGetComponent(self.Transform, "PanelTool2/TxtTool2", "Text")
    self.BtnBuyJump2 = XUiHelper.TryGetComponent(self.Transform, "PanelTool2/BtnBuyJump2", "Button")
    self.PanelTool1 = XUiHelper.TryGetComponent(self.Transform, "PanelTool1", nil)
    self.RImgTool1 = XUiHelper.TryGetComponent(self.Transform, "PanelTool1/RImgTool1", "RawImage")
    self.TxtTool1 = XUiHelper.TryGetComponent(self.Transform, "PanelTool1/TxtTool1", "Text")
    self.BtnBuyJump1 = XUiHelper.TryGetComponent(self.Transform, "PanelTool1/BtnBuyJump1", "Button")
end

function XUiPanelAsset:RegisterJumpCallList(callList)
    self.JumpCallList = callList
end

function XUiPanelAsset:GetAutoKey(uiNode, eventName)
    if not uiNode then
        return
    end
    return eventName .. uiNode:GetHashCode()
end

function XUiPanelAsset:RegisterListener(uiNode, eventName, func)
    local key = self:GetAutoKey(uiNode, eventName)
    if not key then
        return
    end
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiPanelAsset:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XSoundManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiPanelAsset:AutoAddListener()
    self.AutoCreateListeners = {}
    XUiHelper.RegisterClickEvent(self, self.BtnBuyJump3, self.OnBtnBuyJump3Click)
    XUiHelper.RegisterClickEvent(self, self.BtnBuyJump2, self.OnBtnBuyJump2Click)
    XUiHelper.RegisterClickEvent(self, self.BtnBuyJump1, self.OnBtnBuyJump1Click)
end
-- auto
function XUiPanelAsset:InitBtnSound()
    if self.BtnBuyJump3 then
        self.SpecialSoundMap[self:GetAutoKey(self.BtnBuyJump3, "onClick")] = 1013
    end

    if self.BtnBuyJump2 then
        self.SpecialSoundMap[self:GetAutoKey(self.BtnBuyJump2, "onClick")] = 1013
    end

    if self.BtnBuyJump1 then
        self.SpecialSoundMap[self:GetAutoKey(self.BtnBuyJump1, "onClick")] = 1013
    end
end

function XUiPanelAsset:OnBtnBuyJump1Click()
    self:BuyJump(1)
end

function XUiPanelAsset:OnBtnBuyJump2Click()
    self:BuyJump(2)
end

function XUiPanelAsset:OnBtnBuyJump3Click()
    self:BuyJump(3)
end

function XUiPanelAsset:BuyJump(index)
    -- 联机中不给跳转，防止跳出联机房间
    --local unionFightData = XDataCenter.FubenUnionKillRoomManager.GetUnionRoomData()
    --if unionFightData and unionFightData.Id then
    --    XUiManager.TipMsg(CS.XTextManager.GetText("UnionCantLeaveRoom"))
    --    return
    --end
    --if XDataCenter.FubenUnionKillRoomManager.IsMatching() then
    --    XUiManager.TipMsg(CS.XTextManager.GetText("UnionInMatching"))
    --    return
    --end

    if XLuaUiManager.IsUiShow("UiMain") then
        if self.ItemIds[index] == XDataCenter.ItemManager.ItemId.FreeGem then
            XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnAddFreeGem)
        elseif self.ItemIds[index] == XDataCenter.ItemManager.ItemId.ActionPoint then
            XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnAddActionPoint)
        elseif self.ItemIds[index] == XDataCenter.ItemManager.ItemId.Coin then
            XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnAddCoin)
        end
    end
    
    if self.JumpCallList and self.JumpCallList[index] and type(self.JumpCallList[index]) == "function" then
        self.JumpCallList[index]()
        return
    end
    
    
    if self.ItemIds[index] == XDataCenter.ItemManager.ItemId.FreeGem then
        XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.HK)
    elseif self.ItemIds[index] == XDataCenter.ItemManager.ItemId.HongKa then
        if XLuaUiManager.IsUiShow("UiMain") then
            XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnAddFreeGem)
        end
        XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.Pay)
    elseif self.ItemIds[index] == XDataCenter.ItemManager.ItemId.DoubleTower then
        --展示物品详情
        local item = XDataCenter.ItemManager.GetItem(self.ItemIds[index])
        local data = {
            Id = self.ItemIds[index],
            Count = item ~= nil and tostring(item.Count) or "0"
        }
        if self.QueryFunc then
            data = XTool.Clone(XGoodsCommonManager.GetGoodsShowParamsByTemplateId(itemId))
            data.IsTempItemData = true
            data.Count = self.QueryFunc(item) or data.Count
            data.Description = XGoodsCommonManager.GetGoodsDescription(self.ItemIds[index])
            data.WorldDesc = XGoodsCommonManager.GetGoodsWorldDesc(self.ItemIds[index])
        end
        XLuaUiManager.Open("UiTip", data, self.HideSkipBtn)
    elseif self.ItemIds[index] == XDataCenter.PivotCombatManager.GetActivityCoinId() 
            or self.ItemIds[index] == XDataCenter.ItemManager.ItemId.SkillPoint
            or self.ItemIds[index] == XMazeConfig.GetTicketItemId()
    then
        local id = self.ItemIds[index]
        XLuaUiManager.Open("UiTip", id)
    elseif not XDataCenter.ItemManager.GetBuyAssetTemplate(self.ItemIds[index], 1, true) then -- 没有购买数据的话就打开详情
        local id = self.ItemIds[index]
        XLuaUiManager.Open("UiTip", id)
    else
        XUiManager.OpenBuyAssetPanel(self.ItemIds[index])
    end
end

function XUiPanelAsset:InitAssert()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end

    local panels = {}
    if self.PanelTool1 then
        insert(panels, self.PanelTool1)
        self.PanelTool1.gameObject:SetActive(false)
    end

    if self.PanelTool2 then
        insert(panels, self.PanelTool2)
        self.PanelTool2.gameObject:SetActive(false)
    end

    if self.PanelTool3 then
        insert(panels, self.PanelTool3)
        self.PanelTool3.gameObject:SetActive(false)
    end

    local itemIds = self.ItemIds

    if #itemIds > #panels then
        XLog.Warning("XUiPanelAsset:InitAssert Warning: use item id morn than panel count, panel count is " .. #panels .. "use item id is ", itemIds)
    end
    local panelCount = min(#itemIds, #panels)

    local func = function(textTool, id)
        local itemCount = XDataCenter.ItemManager.GetCount(id)
        if id == XDataCenter.ItemManager.ItemId.ActionPoint then
            textTool.text = itemCount .. "/" .. XDataCenter.ItemManager.GetMaxActionPoints()
        elseif id == XGuildWarConfig.ActivityPointItemId then
            textTool.text = itemCount .. "/" .. XDataCenter.GuildWarManager.GetMaxActionPoint()
        else
            textTool.text = itemCount
        end
    end
    self:RemoveCountUpdateListener()
    for i = 1, panelCount do
        local panel = panels[i]
        local item = XDataCenter.ItemManager.GetItem(itemIds[i])
        local rawImageIcon = self["RImgTool" .. i];
        if rawImageIcon ~= nil and rawImageIcon:Exist() then
            --self.RootUi:SetUiSprite(self["ImgTool" .. i], item.Template.Icon)
            rawImageIcon:SetRawImage(item.Template.Icon, nil, false)
        end
        local f = function()
            func(self["TxtTool" .. i], itemIds[i])
        end
        local node = self["TxtTool" .. i]
        table.insert(self._BindNodes, node)
        XDataCenter.ItemManager.AddCountUpdateListener(itemIds[i], f, node)
        func(self["TxtTool" .. i], itemIds[i])
        panel.gameObject:SetActive(true)
    end
end

function XUiPanelAsset:RemoveCountUpdateListener()
    for _, node in ipairs(self._BindNodes) do
        XDataCenter.ItemManager.RemoveCountUpdateListener(node)
    end
    self._BindNodes = {}
end

function XUiPanelAsset:OnDestroy()
    self:RemoveCountUpdateListener()
end

function XUiPanelAsset:HideBtnBuy()
    self.BtnBuyJump1.gameObject:SetActiveEx(false)
    self.BtnBuyJump2.gameObject:SetActiveEx(false)
    self.BtnBuyJump3.gameObject:SetActiveEx(false)
end 