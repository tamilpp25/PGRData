local XUiEpicFashionGachaQuickWear = XLuaUiManager.Register(XLuaUi, "UiEpicFashionGachaQuickWear")

function XUiEpicFashionGachaQuickWear:OnAwake()
    self:InitButton()
end

function XUiEpicFashionGachaQuickWear:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnWear, self.OnBtnWearClick)
    XUiHelper.RegisterClickEvent(self, self.BtnSetAssistant, self.OnBtnSetAssistantClick)
end

function XUiEpicFashionGachaQuickWear:OnStart(templateId, titleTxt)
    self.FashionId = templateId
    if not string.IsNilOrEmpty(titleTxt) then
        self.TxtDesc.text = titleTxt
    end
end

function XUiEpicFashionGachaQuickWear:OnEnable()
    local grid = XUiGridCommon.New(self, self.GridFashion)
    grid:Refresh({TemplateId = self.FashionId})

    -- 穿戴按钮
    local config = XFashionConfigs.GetAllConfigs(XFashionConfigs.TableKey.Fashion)
    local charId = nil
    for k, v in pairs(config) do
        if v.Id == self.FashionId then
            charId = v.CharacterId
        end
    end
    self.CharacterId = charId
    if not XTool.IsNumberValid(charId) or not XMVCA.XCharacter:IsOwnCharacter(charId) then
        self.BtnWear:SetDisable(true)
        self.LockUse = true
    end

    -- 首席按钮
    if XPlayer.DisplayCharIdList[1] == charId or not XMVCA.XCharacter:IsOwnCharacter(charId) then
        self.BtnSetAssistant.gameObject:SetActiveEx(false)
    end
end

function XUiEpicFashionGachaQuickWear:OnBtnWearClick()
    if self.IsWore then
        return
    end

    self.BtnWear:SetDisable(true)
    if self.LockUse then
        local charConfig = XMVCA.XCharacter:GetCharacterTemplate(self.CharacterId)
        local text = CS.XTextManager.GetText("LottoKareninaNotOwnTip", charConfig.Name, charConfig.TradeName)
        XUiManager.TipError(text)
        return 
    end

    XDataCenter.FashionManager.UseFashion(self.FashionId, function()
        XUiManager.TipText("UseSuccess")
        self.IsWore = true
    end)
end

function XUiEpicFashionGachaQuickWear:OnBtnSetAssistantClick()
    self.BtnSetAssistant.gameObject:SetActiveEx(false)

    local showTipFun = function ()
        local charConfig = XMVCA.XCharacter:GetCharacterTemplate(self.CharacterId)
        local name = charConfig.Name.. "·"..charConfig.TradeName
        XUiManager.TipMsg(CS.XTextManager.GetText("FavorabilitySetChiefAssistSucc", name))
    end

    if table.contains(XPlayer.DisplayCharIdList, self.CharacterId) then -- 如果在队列
        XDataCenter.DisplayManager.SetDisplayCharIdFirstRequest(self.CharacterId, showTipFun)
    else
        -- 不在队列有两种情况
        -- 1队列没满，先入队再设为首席
        if #XPlayer.DisplayCharIdList < CS.XGame.Config:GetInt("AssistantNum") then
            XDataCenter.DisplayManager.AddPlayerDisplayCharIdRequest(self.CharacterId, function ()
                XDataCenter.DisplayManager.SetDisplayCharIdFirstRequest(self.CharacterId, showTipFun)
            end)
        else
        -- 2队列已满，直接空降替换首席
            local oldCharId = XPlayer.DisplayCharIdList[1]
            XDataCenter.DisplayManager.UpdatePlayerDisplayCharIdRequest(oldCharId, self.CharacterId, showTipFun)
        end
    end
end