local XUiLottoFashionSelfChoiceDialog = XLuaUiManager.Register(XLuaUi, "UiLottoFashionSelfChoiceDialog")

function XUiLottoFashionSelfChoiceDialog:OnAwake()
    self.GridRewardDic = {}
    self:InitButton()
    
    -- 二次弹窗cd，不能让玩家点太快
    self.EnableClickBtnYes = false
    local cdTime = CS.XGame.ClientConfig:GetInt("XUiGachaFashionSelfChoiceDialogConfirmCD")
    self.CDTime = cdTime
    self.BtnYes:SetNameByGroup(1, string.format("%dS", self.CDTime / XScheduleManager.SECOND))
    self.BtnYes:SetDisable(true)
    self.Timer = XScheduleManager.ScheduleForever(function() 
        self.CDTime = self.CDTime - XScheduleManager.SECOND

        if self.CDTime < 0 then
            self.EnableClickBtnYes = true
            self.BtnYes:SetDisable(false)
            self:StopTimer()
        else
            self.BtnYes:SetNameByGroup(1, string.format("%dS", self.CDTime / XScheduleManager.SECOND))
        end
    end, XScheduleManager.SECOND, 0)
end

function XUiLottoFashionSelfChoiceDialog:InitButton()
    self.BtnTanchuangCloseBig.CallBack = function() self:Close() end
    self.BtnYes.CallBack = function() self:OnBtnYesClick() end
    self.BtnCancel.CallBack = function() self:Close() end
end

function XUiLottoFashionSelfChoiceDialog:OnBtnYesClick()
    if not self.EnableClickBtnYes then
        XUiManager.TipMsg(CS.XTextManager.GetText("ConfirmSpeedLimit"))
        return
    end

    if self.ConfirmCb then
        self.ConfirmCb(self.LottoId)
    end
    self:Close()
end

function XUiLottoFashionSelfChoiceDialog:OnStart(lottoId, isAllGet, confirmCb)
    self.LottoId = lottoId
    self.ConfirmCb = confirmCb

    ---@type XTableGachaFashionSelfChoiceResources
    local lottoResConfig = XLottoConfigs.GetAllConfigs(XLottoConfigs.TableKey.LottoFashionSelfChoiceResources)[lottoId]
    local fashionId = lottoResConfig.SpecialRewardTemplateIds[1] -- 第1个默认是涂装id(写死)
    local fashionConfig = XFashionConfigs.GetFashionTemplate(fashionId)

    local charId = fashionConfig.CharacterId
    local name = XMVCA.XCharacter:GetCharacterName(charId)
    local tradeName = XMVCA.XCharacter:GetCharacterTradeName(charId)
    local charName = XUiHelper.GetText("CharacterFullName2", name, tradeName)
    local text = nil
    if isAllGet then
        text = XUiHelper.FormatText(XGachaConfigs.GetClientConfig('GachaFashionSelfChoiceDialogText1'), charName, lottoResConfig.Desc)
    else
        text = XUiHelper.FormatText(XGachaConfigs.GetClientConfig('GachaFashionSelfChoiceDialogText2'), charName, lottoResConfig.Desc)
    end
    self.TxtInfo.text = XUiHelper.ConvertLineBreakSymbol(text)

    -- 奖励
    local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
    for k, templateId in ipairs(lottoResConfig.SpecialRewardTemplateIds) do
        local grid = self.GridRewardDic[k]
        if not grid then
            local ui = (k == 1) and self.Grid256New or XUiHelper.Instantiate(self.Grid256New, self.Grid256New.parent)
            grid = XUiGridCommon.New(self, ui)
            self.GridRewardDic[k] = grid
        end

        grid:Refresh({TemplateId = templateId}, nil, nil, nil, isAllGet and -1 or 1)
    end
end

function XUiLottoFashionSelfChoiceDialog:OnDestroy()
    self:StopTimer()
end

function XUiLottoFashionSelfChoiceDialog:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end