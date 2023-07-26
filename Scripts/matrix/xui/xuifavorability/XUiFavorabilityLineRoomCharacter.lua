local XUiFavorabilityLineRoomCharacter = XLuaUiManager.Register(XLuaUi, "UiFavorabilityLineRoomCharacter")

local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

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

    -- 更换助理
    self.BtnExchange.CallBack = function()
        self:OnBtnExchangeClick()
    end

    self.BtnFashion.CallBack = function()
        self:OnBtnFashionClick()
    end

    self.DynamicTableCharacter = XDynamicTableNormal.New(self.SViewCharacterList.gameObject)
    self.DynamicTableCharacter:SetProxy(XUiGridLineCharacter)
    self.DynamicTableCharacter:SetDelegate(self)
end

function XUiFavorabilityLineRoomCharacter:OnStart()
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true)

    XEventManager.AddEventListener(XEventId.EVENT_FAVORABILITY_ASSISTLIST_CHANGE, self.RefreshDynamicTable, self)
end

function XUiFavorabilityLineRoomCharacter:RefreshDynamicTable()
    self.Characters = self:GetCharaterList()
    local isIn, index = table.contains(XPlayer.DisplayCharIdList, XDataCenter.DisplayManager.GetDisplayChar().Id)
    local isSmaller = self.SelectIndex <= #XPlayer.DisplayCharIdList 
    -- 下标位置逻辑
    -- 1.进入该界面【第一次】刷新，定位在UiMain看板娘的位置
    -- 2.被点击选中的格子会记录下标
    -- 3.若刷新前检测出【记录中的下标】比【列表长度】长，则使用列表的最后1个格子作为下标(删除最后1个构造体会出现的情况)
    self.SelectIndex = (isIn and not self.IsInitRefresh and index) or (isSmaller and self.SelectIndex or #XPlayer.DisplayCharIdList) or 1
    self.IsInitRefresh = true
    
    self.DynamicTableCharacter:SetDataSource(self.Characters)
    self.DynamicTableCharacter:ReloadDataASync(index)
    local curAssistantId = self:GetCurrSelectChar().Id
    self:UpdateRightCharInfo(curAssistantId)
    self:UpdateRoleModel(curAssistantId)
end

function XUiFavorabilityLineRoomCharacter:GetCurrSelectChar()
    if not self.Characters then
        self.Characters = self:GetCharaterList()
    end
    local charId = self.Characters[self.SelectIndex].Id
    return XDataCenter.CharacterManager.GetCharacter(charId)
end

function XUiFavorabilityLineRoomCharacter:OnEnable()
    self:RefreshDynamicTable()
    local curAssistantId = self:GetCurrSelectChar().Id
    local charType = XCharacterConfigs.GetCharacterType(curAssistantId)
    if charType == 1 then
        self.ImgEffectHuanren.gameObject:SetActive(false)
        self.ImgEffectHuanren.gameObject:SetActive(true)
    else
        self.ImgEffectHuanren1.gameObject:SetActive(false)
        self.ImgEffectHuanren1.gameObject:SetActive(true)
    end
end

-- 刷新右侧角色数据
function XUiFavorabilityLineRoomCharacter:UpdateRightCharInfo(characterId)
    self.BtnSetFav:SetDisable(characterId == XPlayer.DisplayCharIdList[1])
    local charConfig = XCharacterConfigs.GetCharacterTemplate(characterId)
    self.TxtName.text = charConfig.Name
    self.TxtNameOther.text = charConfig.TradeName
    self.TxtNameVocal.text = XFavorabilityConfigs.GetCharacterCvById(characterId)

    local character = XDataCenter.CharacterManager.GetCharacter(characterId)
    self.RImgTypeIcon:SetRawImage(XCharacterConfigs.GetNpcTypeIcon(character.Type))
end

function XUiFavorabilityLineRoomCharacter:GetCharaterList()
    local result = {}
    for i, charId in ipairs(XPlayer.DisplayCharIdList) do
        local isOwn = XDataCenter.CharacterManager.IsOwnCharacter(charId) 
        if isOwn then
            local char =  XDataCenter.CharacterManager.GetCharacter(charId)
            table.insert(result, {
                Id = charId,
                TrustLv = char.TrustLv or 1,
                ChiefAssistant = i == 1,
            })
        end
    end
    -- 如果还没到最大数，最后要显示一个Add按钮
    local maxAssistantNum = CS.XGame.Config:GetInt("AssistantNum")
    if #result < maxAssistantNum then
        table.insert(result, {
            IsAdd = true
        })
    end
    return result
end

-- [监听动态列表事件]
function XUiFavorabilityLineRoomCharacter:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
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
            -- if self.CurCharacter then
            --     self.CurCharacter.Selected = false
            -- end
            self.CurCharacterGrid:OnSelect(false)
        end
        -- self.CurCharacter = self.Characters[index]

        -- self.CurCharacter.Selected = true
        self.SelectIndex = index
        self.CurCharacterGrid = grid
        grid:OnSelect(true)
        self:UpdateRoleModel(self:GetCurrSelectChar().Id)
        self:UpdateRightCharInfo(self:GetCurrSelectChar().Id)
    end
end

function XUiFavorabilityLineRoomCharacter:OnBtnSetFavClick()
    -- 避免重复设置
    if self:GetCurrSelectChar().Id == XPlayer.DisplayCharIdList[1] then
        return
    end

    local charId = self:GetCurrSelectChar().Id
    XDataCenter.DisplayManager.SetDisplayCharIdFirstRequest(charId, function (res)
        self.SelectIndex = 1 -- 设置首席后重新选定默认下标为1
        local charConfig = XCharacterConfigs.GetCharacterTemplate(charId)
        local name = charConfig.Name.. "·"..charConfig.TradeName
        XUiManager.TipMsg(CS.XTextManager.GetText("FavorabilitySetChiefAssistSucc", name))
    end)
end

function XUiFavorabilityLineRoomCharacter:OnBtnExchangeClick()
    XLuaUiManager.Open("UiFavorabilityLineRoomCharacterSelect", self:GetCurrSelectChar())
end

function XUiFavorabilityLineRoomCharacter:OnBtnFashionClick()
    if not self:GetCurrSelectChar() then return end
    local isOwn = XDataCenter.CharacterManager.IsOwnCharacter(self:GetCurrSelectChar().Id)
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

function XUiFavorabilityLineRoomCharacter:UpdateRoleModel(characterId)
    local charType = XCharacterConfigs.GetCharacterType(characterId)
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

function XUiFavorabilityLineRoomCharacter:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_FAVORABILITY_ASSISTLIST_CHANGE, self.RefreshDynamicTable, self)
end