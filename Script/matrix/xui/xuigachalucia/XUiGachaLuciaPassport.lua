---@class XUiGachaLuciaPassport : XLuaUi 使用皮肤和场景弹框
local XUiGachaLuciaPassport = XLuaUiManager.Register(XLuaUi, "UiGachaLuciaPassport")

function XUiGachaLuciaPassport:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnWear, self.OnWear)
    self:RegisterClickEvent(self.BtnSetAssistant, self.OnSetAssistant)
end

function XUiGachaLuciaPassport:OnStart(reward, callBack)
    self._CallBack = callBack
    self._Reward = reward
    self._IsBackGround = reward.RewardType == XRewardManager.XRewardType.Background
    self._IsFashion = reward.RewardType == XRewardManager.XRewardType.Fashion
    self.BgCoating.gameObject:SetActiveEx(self._IsFashion)
    self.BgChangjing.gameObject:SetActiveEx(self._IsBackGround)
    self.BtnSetAssistant.gameObject:SetActiveEx(self._IsFashion)
    self.BtnWear:SetNameByGroup(0, XUiHelper.GetText(self._IsBackGround and "GachaLuciaBgBtn" or "GachaLuciaFashionBtn"))

    if self._IsFashion then
        self._FashionId = self._Reward.TemplateId
        self._CharacterId = XFashionConfigs.GetFashionTemplate(self._FashionId).CharacterId

        if not XTool.IsNumberValid(self._CharacterId) or not XMVCA.XCharacter:IsOwnCharacter(self._CharacterId) then
            self.BtnWear:SetDisable(true)
            self._LockUse = true
        end

        if XPlayer.DisplayCharIdList[1] == self._CharacterId or not XMVCA.XCharacter:IsOwnCharacter(self._CharacterId) then
            self.BtnSetAssistant.gameObject:SetActiveEx(false)
        end
    end
end

function XUiGachaLuciaPassport:Close()
    self.Super.Close(self)
    if self._CallBack then
        self._CallBack()
    end
end

function XUiGachaLuciaPassport:OnWear()
    if self._IsWore then
        return
    end

    if self._IsBackGround then
        local backgroundId = self._Reward.TemplateId
        local _curChara = XDataCenter.DisplayManager.GetDisplayChar()
        XDataCenter.PhotographManager.ChangeDisplay(backgroundId, _curChara.Id, _curChara.FashionId, function()
            XUiManager.TipText("PhotoModeChangeSuccess")
            self.BtnWear:SetDisable(true)
            self._IsWore = true
        end)
    elseif self._IsFashion then
        if self._LockUse then
            local charConfig = XMVCA.XCharacter:GetCharacterTemplate(self._CharacterId)
            local text = CS.XTextManager.GetText("LottoKareninaNotOwnTip", charConfig.Name, charConfig.TradeName)
            XUiManager.TipError(text)
            return
        end

        XDataCenter.FashionManager.UseFashion(self._FashionId, function()
            XUiManager.TipText("UseSuccess")
            self.BtnWear:SetDisable(true)
            self._IsWore = true
        end)
    end
end

function XUiGachaLuciaPassport:OnSetAssistant()
    self.BtnSetAssistant.gameObject:SetActiveEx(false)

    local showTipFun = function()
        local charConfig = XMVCA.XCharacter:GetCharacterTemplate(self._CharacterId)
        local name = charConfig.Name .. "·" .. charConfig.TradeName
        XUiManager.TipMsg(CS.XTextManager.GetText("FavorabilitySetChiefAssistSucc", name))
    end

    if table.contains(XPlayer.DisplayCharIdList, self._CharacterId) then
        -- 如果在队列
        XDataCenter.DisplayManager.SetDisplayCharIdFirstRequest(self._CharacterId, showTipFun)
    else
        -- 不在队列有两种情况
        -- 1队列没满，先入队再设为首席
        if #XPlayer.DisplayCharIdList < CS.XGame.Config:GetInt("AssistantNum") then
            XDataCenter.DisplayManager.AddPlayerDisplayCharIdRequest(self._CharacterId, function()
                XDataCenter.DisplayManager.SetDisplayCharIdFirstRequest(self._CharacterId, showTipFun)
            end)
        else
            -- 2队列已满，直接空降替换首席
            local oldCharId = XPlayer.DisplayCharIdList[1]
            XDataCenter.DisplayManager.UpdatePlayerDisplayCharIdRequest(oldCharId, self._CharacterId, showTipFun)
        end
    end
end

return XUiGachaLuciaPassport