local XUiFavorabilityLineRoomCharacter = XLuaUiManager.Register(XLuaUi, "UiFavorabilityLineRoomCharacter")

local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

--region 生命周期
function XUiFavorabilityLineRoomCharacter:OnAwake()
    self:InitUi()

    local root = self.UiModelGo.transform
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = root:FindTransform("ImgEffectHuanren1")
    self.ImgEffectHuanren1.gameObject:SetActive(false)
    self.ImgEffectHuanren.gameObject:SetActive(false)
    self.BtnFashion.gameObject:SetActiveEx(not XUiManager.IsHideFunc)
    self.IsInitRefresh = nil -- 初次进入默认选择主界面展示的看板娘，在该界面再切换时 默认选择就不根据看板娘了。用这个参数来区别
    self.SelectIndex = 1 -- 当前选中的角色列表下标。包括模型、右边角色信息都根据这个下标展示
end

function XUiFavorabilityLineRoomCharacter:OnStart()
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true)

    XEventManager.AddEventListener(XEventId.EVENT_FAVORABILITY_ASSISTLIST_CHANGE, self.RefreshDynamicTable, self)
end

function XUiFavorabilityLineRoomCharacter:OnEnable()
    self:RefreshDynamicTable()
    local curAssistantId = self:GetCurrSelectChar().Id
    local charType = XMVCA.XCharacter:GetCharacterType(curAssistantId)
    if charType == 1 then
        self.ImgEffectHuanren.gameObject:SetActive(false)
        self.ImgEffectHuanren.gameObject:SetActive(true)
    else
        self.ImgEffectHuanren1.gameObject:SetActive(false)
        self.ImgEffectHuanren1.gameObject:SetActive(true)
    end
end

function XUiFavorabilityLineRoomCharacter:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_FAVORABILITY_ASSISTLIST_CHANGE, self.RefreshDynamicTable, self)
end
--endregion

--region 初始化
function XUiFavorabilityLineRoomCharacter:InitUi()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.BtnBack.CallBack = function()
        self:Close()
    end

    self.BtnMainUi.CallBack = function()
        XLuaUiManager.RunMain()
    end

    -- 设为首席助理
    self.BtnSetFav.CallBack = function()
        self:OnBtnSetFavClick()
    end
    
    self.BtnSetFav2.CallBack=function()
        self:OnBtnSetFavClick()
    end

    -- 更换助理
    self.BtnExchange.CallBack = function()
        self:OnBtnExchangeClick()
    end

    self.BtnFashion.CallBack = function()
        self:OnBtnFashionClick()
    end

    self.DynamicTableCharacter = XDynamicTableNormal.New(self.SViewCharacterList.gameObject)
    self.DynamicTableCharacter:SetProxy(XUiGridLineCharacter,self)
    self.DynamicTableCharacter:SetDelegate(self)

    --2.7首席助理专位
    self.MainAssistantCtrl=XUiGridLineCharacter.New(self.PanelMainLineCharacter,self)
    XUiHelper.RegisterClickEvent(self.MainAssistantCtrl,self.MainAssistantCtrl.Button,function() self:OnSelectMainAssist() end)
end
--endregion

--region 数据更新
function XUiFavorabilityLineRoomCharacter:RefreshDynamicTable()
    self.Characters,self.MainAsstantData = self:GetCharaterList()
    local curId=XDataCenter.DisplayManager.GetDisplayChar().Id
    local isIn = table.contains(XPlayer.DisplayCharIdList, curId)
    local index=0
    for i, char in ipairs(self.Characters) do
        if char.Id==curId then
            index=i
            break
        end
    end
    local isSmaller = self.SelectIndex <= #XPlayer.DisplayCharIdList-1
    -- 下标位置逻辑
    -- 1.进入该界面【第一次】刷新，定位在UiMain看板娘的位置
    -- 2.被点击选中的格子会记录下标
    -- 3.若刷新前检测出【记录中的下标】比【列表长度】长，则使用列表的最后1个格子作为下标(删除最后1个构造体会出现的情况)
    self.SelectIndex = (isIn and not self.IsInitRefresh and index) or (isSmaller and self.SelectIndex or #XPlayer.DisplayCharIdList-1) or 1
    self.IsInitRefresh = true

    self.DynamicTableCharacter:SetDataSource(self.Characters)
    self.DynamicTableCharacter:ReloadDataASync(index)
    local curAssistantId = self:GetCurrSelectChar().Id
    self:UpdateRightCharInfo(curAssistantId)
    self:UpdateRoleModel(curAssistantId)
    self.MainAssistantCtrl:RefreshAssist(self.MainAsstantData,self)
    self.BtnSetFav.gameObject:SetActiveEx(true) --普通助理设置首席的按钮
    self.BtnSetFav2.gameObject:SetActiveEx(false) --首席助理设置首席的按钮
    if self.SelectIndex==0 then  self:OnSelectMainAssist() end
end

-- 刷新右侧角色数据
function XUiFavorabilityLineRoomCharacter:UpdateRightCharInfo(characterId)
    self.IsFocusMainAssistant=characterId == XPlayer.DisplayCharIdList[1]
    --self.BtnSetFav:SetDisable(characterId == XPlayer.DisplayCharIdList[1])
    local charConfig = XMVCA.XCharacter:GetCharacterTemplate(characterId)
    self.TxtName.text = charConfig.Name
    self.TxtNameOther.text = charConfig.TradeName
    self.TxtNameVocal.text = XMVCA.XFavorability:GetCharacterCvById(characterId)

    local character = XMVCA.XCharacter:GetCharacter(characterId)
    self.RImgTypeIcon:SetRawImage(XMVCA.XCharacter:GetNpcTypeIcon(character.Type))
end

function XUiFavorabilityLineRoomCharacter:UpdateRoleModel(characterId)
    local charType = XMVCA.XCharacter:GetCharacterType(characterId)
    self.RoleModelPanel:UpdateCharacterModel(characterId, self.PanelRoleModel, XModelManager.MODEL_UINAME.XUiFavorabilityLineRoomCharacter, nil, function()
        if charType == 1 then
            self.ImgEffectHuanren.gameObject:SetActive(false)
            self.ImgEffectHuanren.gameObject:SetActive(true)
        else
            self.ImgEffectHuanren1.gameObject:SetActive(false)
            self.ImgEffectHuanren1.gameObject:SetActive(true)
        end
    end)
end
--endregion

--region 数据处理
function XUiFavorabilityLineRoomCharacter:GetCurrSelectChar()
    if not self.Characters then
        self.Characters = self:GetCharaterList()
    end
    local charId = self.Characters[self.SelectIndex].Id
    return XMVCA.XCharacter:GetCharacter(charId)
end

function XUiFavorabilityLineRoomCharacter:GetCharaterList()
    local result = {}
    local mainAssistant=nil
    for i, charId in ipairs(XPlayer.DisplayCharIdList) do
        local isOwn = XMVCA.XCharacter:IsOwnCharacter(charId)
        if isOwn then
            local char =  XMVCA.XCharacter:GetCharacter(charId)
            local charData={
                Id = charId,
                TrustLv = char.TrustLv or 1,
                ChiefAssistant = i == 1,
            }
            if charData.ChiefAssistant then
                mainAssistant=charData
                result[0]=mainAssistant
            else
                table.insert(result,charData)
            end
        end
    end

    table.sort(result,function(a, b)
        --信赖等级高的在前
        if a.TrustLv>b.TrustLv then
            return true
        elseif a.TrustLv<b.TrustLv then
            return false
        end

        --成员ID大的在前
        if a.Id>b.Id then
            return true
        end

        return false
    end)

    -- 如果还没到最大数，最后要显示一个Add按钮
    local maxAssistantNum = CS.XGame.Config:GetInt("AssistantNum")-1
    if #result < maxAssistantNum then
        table.insert(result, {
            IsAdd = true
        })
    end
    return result,mainAssistant
end
--endregion

--region 事件
-- [监听动态列表事件]
function XUiFavorabilityLineRoomCharacter:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.Characters[index]
        if not data then return end
        grid:RefreshAssist(self.Characters[index], self)
        local selected = index == self.SelectIndex
        -- local selected = data.Selected or false
        grid:OnSelect(selected)
        if selected then
            -- self.CurCharacter = self.Characters[index]
            self.CurCharacterGrid = grid
        end

        if data.Id == XDataCenter.DisplayManager.GetDisplayChar().Id then
            self.CurAssist = grid
        end

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if grid.CharacterData.IsAdd then
            self:OnBtnAddAssistListClick()
            return
        end

        if not self.Characters[index] then return end
        if self.CurCharacterGrid then
            self.CurCharacterGrid:OnSelect(false)
        end

        self.SelectIndex = index
        self.CurCharacterGrid = grid
        self.BtnExchange.gameObject:SetActiveEx(true)
        self.BtnSetFav.gameObject:SetActiveEx(true) --普通助理设置首席的按钮
        self.BtnSetFav2.gameObject:SetActiveEx(false) --首席助理设置首席的按钮
        grid:OnSelect(true)
        self:UpdateRoleModel(self:GetCurrSelectChar().Id)
        self:UpdateRightCharInfo(self:GetCurrSelectChar().Id)
    end
end

function XUiFavorabilityLineRoomCharacter:OnBtnSetFavClick()
    -- 避免重复设置
    --[[if self:GetCurrSelectChar().Id == XPlayer.DisplayCharIdList[1] then
        return
    end--]]

    if self.IsFocusMainAssistant then
        --打开首席选择界面
        XLuaUiManager.Open("UiFavorabilityLineRoomCharacterMainSelect",self:GetCurrSelectChar())
    else
        local charId = self:GetCurrSelectChar().Id
        XDataCenter.DisplayManager.SetDisplayCharIdFirstRequest(charId, function (res)
            self.SelectIndex = 0 -- 设置首席后重新选定默认下标为0
            local charConfig = XMVCA.XCharacter:GetCharacterTemplate(charId)
            local name = charConfig.Name.. "·"..charConfig.TradeName
            XUiManager.TipMsg(CS.XTextManager.GetText("FavorabilitySetChiefAssistSucc", name))
        end)
    end
end

function XUiFavorabilityLineRoomCharacter:OnBtnExchangeClick()
    XLuaUiManager.Open("UiFavorabilityLineRoomCharacterSelect", self:GetCurrSelectChar())
end

function XUiFavorabilityLineRoomCharacter:OnBtnFashionClick()
    if not self:GetCurrSelectChar() then return end
    local isOwn = XMVCA.XCharacter:IsOwnCharacter(self:GetCurrSelectChar().Id)
    if not isOwn then
        XUiManager.TipMsg(CS.XTextManager.GetText("FavorabilityNotOwnChar"))
        return
    end

    XLuaUiManager.Open("UiFashion", self:GetCurrSelectChar().Id)
end

function XUiFavorabilityLineRoomCharacter:OnBtnAddAssistListClick()
    -- 打开添加助理队列ui
    XLuaUiManager.Open("UiFavorabilityLineRoomCharacterSelect")
end

function XUiFavorabilityLineRoomCharacter:OnSelectMainAssist()
    if self.CurCharacterGrid then
        self.CurCharacterGrid:OnSelect(false)
    end

    self.SelectIndex = 0
    self.CurCharacterGrid = self.MainAssistantCtrl
    self.MainAssistantCtrl:OnSelect(true)
    self.BtnExchange.gameObject:SetActiveEx(false)
    self:UpdateRoleModel(self:GetCurrSelectChar().Id)
    self:UpdateRightCharInfo(self:GetCurrSelectChar().Id)
    self.BtnSetFav.gameObject:SetActiveEx(false) --普通助理设置首席的按钮
    self.BtnSetFav2.gameObject:SetActiveEx(true) --首席助理设置首席的按钮
end
--endregion






